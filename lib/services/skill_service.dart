import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/models/study_skill.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Carica skill da bundle locale + sync Firestore (`skills_catalog/current`).
class SkillService {
  SkillService._();

  static final SkillService instance = SkillService._();

  static const _manifestPath = 'skills/manifest.json';
  static const _firestoreDocPath = 'skills_catalog/current';
  static const _prefsCatalogJson = 'skills_remote_catalog_json';
  static const _prefsCatalogVersion = 'skills_remote_catalog_version';

  final List<StudySkill> _skills = [];
  bool _loaded = false;
  int _catalogVersion = 0;
  bool _isRemoteSource = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _remoteSub;

  List<StudySkill> get skills => List.unmodifiable(_skills);
  int get catalogVersion => _catalogVersion;
  bool get isRemoteSource => _isRemoteSource;

  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    await _loadFromBundle();
    await _applyCachedRemoteIfAny();
    await refreshFromRemote();
    _loaded = true;
  }

  StudySkill? getById(String id) {
    for (final skill in _skills) {
      if (skill.id == id) {
        return skill;
      }
    }
    return null;
  }

  /// Ascolta aggiornamenti Firestore (playground → app in tempo reale).
  void startRemoteListener(VoidCallback onUpdated) {
    _remoteSub?.cancel();
    _remoteSub = FirebaseFirestore.instance
        .doc(_firestoreDocPath)
        .snapshots()
        .listen(
      (snap) async {
        if (!snap.exists || snap.data() == null) {
          return;
        }
        final changed = await _applyRemoteCatalog(snap.data()!);
        if (changed) {
          onUpdated();
        }
      },
      onError: (Object error) {
        debugPrint('Skill listener error: $error');
      },
    );
  }

  void disposeRemoteListener() {
    _remoteSub?.cancel();
    _remoteSub = null;
  }

  Future<bool> refreshFromRemote() async {
    try {
      final snap = await FirebaseFirestore.instance.doc(_firestoreDocPath).get();
      if (!snap.exists || snap.data() == null) {
        return false;
      }
      return _applyRemoteCatalog(snap.data()!);
    } catch (error) {
      debugPrint('Skill remote refresh failed: $error');
      return false;
    }
  }

  Future<void> _loadFromBundle() async {
    _skills.clear();
    final manifestRaw = await rootBundle.loadString(_manifestPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    _catalogVersion = manifest['version'] as int? ?? 1;
    _isRemoteSource = false;
    _skills.addAll(await _parseManifest(manifest, bodies: const {}));
  }

  Future<void> _applyCachedRemoteIfAny() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getInt(_prefsCatalogVersion);
      final cachedJson = prefs.getString(_prefsCatalogJson);
      if (cachedVersion == null || cachedJson == null) {
        return;
      }
      if (cachedVersion <= _catalogVersion) {
        return;
      }
      final data = jsonDecode(cachedJson) as Map<String, dynamic>;
      await _applyRemoteCatalog(data);
    } catch (error) {
      debugPrint('Skill cache apply failed: $error');
    }
  }

  Future<bool> _applyRemoteCatalog(Map<String, dynamic> data) async {
    final remoteVersion = data['catalogVersion'] as int? ?? 0;
    if (remoteVersion <= _catalogVersion && _isRemoteSource) {
      return false;
    }

    final manifest = data['manifest'];
    if (manifest is! Map<String, dynamic>) {
      return false;
    }

    final bodiesRaw = data['bodies'];
    final bodies = <String, String>{};
    if (bodiesRaw is Map) {
      for (final entry in bodiesRaw.entries) {
        if (entry.key is String && entry.value is String) {
          bodies[entry.key as String] = entry.value as String;
        }
      }
    }

    final parsed = await _parseManifest(manifest, bodies: bodies);
    if (parsed.isEmpty) {
      return false;
    }

    _skills
      ..clear()
      ..addAll(parsed);
    _catalogVersion = remoteVersion;
    _isRemoteSource = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsCatalogVersion, remoteVersion);
      await prefs.setString(_prefsCatalogJson, jsonEncode(data));
    } catch (error) {
      debugPrint('Skill cache save failed: $error');
    }

    return true;
  }

  Future<List<StudySkill>> _parseManifest(
    Map<String, dynamic> manifest, {
    required Map<String, String> bodies,
  }) async {
    final entries = manifest['skills'] as List<dynamic>? ?? [];
    final result = <StudySkill>[];

    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final id = entry['id'] as String? ?? '';
      if (id.isEmpty) {
        continue;
      }
      final name = entry['name'] as String? ?? id;
      final description = entry['description'] as String? ?? '';
      final file = entry['file'] as String?;
      final keywordsRaw = entry['keywords'];
      final keywords = keywordsRaw is List
          ? keywordsRaw.whereType<String>().toList()
          : <String>[];

      var body = bodies[id]?.trim() ?? '';
      if (body.isEmpty && file != null && file.isNotEmpty) {
        try {
          final raw = await rootBundle.loadString('skills/$file');
          body = stripFrontmatter(raw);
        } catch (_) {
          body = '';
        }
      }

      result.add(
        StudySkill(
          id: id,
          name: name,
          description: description,
          promptBody: body,
          routingKeywords: keywords,
        ),
      );
    }

    if (result.isEmpty) {
      result.add(
        const StudySkill(
          id: 'none',
          name: 'Generale',
          description: 'Buddy standard',
        ),
      );
    }

    return result;
  }

  /// Rimuove blocchi YAML `--- ... ---` in testa al file skill.
  static String stripFrontmatter(String raw) {
    final trimmed = raw.trimLeft();
    if (!trimmed.startsWith('---')) {
      return raw.trim();
    }
    final end = trimmed.indexOf('---', 3);
    if (end == -1) {
      return raw.trim();
    }
    return trimmed.substring(end + 3).trim();
  }
}
