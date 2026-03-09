import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:powerful_students/models/daily_stats.dart';

/// Service per gestire le statistiche giornaliere su Firestore
class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'daily_stats';

  /// Salva o aggiorna le statistiche di oggi
  Future<void> saveTodayStats(DailyStats stats) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(stats.id)
          .set(stats.toFirestore(), SetOptions(merge: true));
      debugPrint('✅ Stats salvate: ${stats.id} - ${stats.completedPomodoros} mattoncini, ${stats.totalMinutes} minuti');
    } catch (e) {
      debugPrint('❌ Errore salvataggio stats: $e');
      rethrow;
    }
  }

  /// Recupera le statistiche di oggi per l'utente
  Future<DailyStats?> getTodayStats(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final docId = DailyStats.generateId(userId, today);

      final doc = await _firestore.collection(_collectionName).doc(docId).get();

      if (doc.exists) {
        return DailyStats.fromFirestore(doc);
      } else {
        // Crea nuovo documento per oggi
        final newStats = DailyStats.createToday(userId);
        await saveTodayStats(newStats);
        return newStats;
      }
    } catch (e) {
      debugPrint('❌ Errore recupero stats oggi: $e');
      return null;
    }
  }

  /// Incrementa il contatore di pomodori completati oggi
  Future<void> incrementTodayPomodoros(String userId, int sessionMinutes) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final docId = DailyStats.generateId(userId, today);

      await _firestore.collection(_collectionName).doc(docId).set({
        'userId': userId,
        'date': Timestamp.fromDate(today),
        'completedPomodoros': FieldValue.increment(1),
        'totalMinutes': FieldValue.increment(sessionMinutes),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Se il documento non esisteva, aggiungi createdAt
      final doc = await _firestore.collection(_collectionName).doc(docId).get();
      if (!doc.data()!.containsKey('createdAt')) {
        await _firestore.collection(_collectionName).doc(docId).update({
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Incrementato pomodoro per oggi: $docId');
    } catch (e) {
      debugPrint('❌ Errore incremento pomodoro: $e');
      rethrow;
    }
  }

  /// Recupera lo storico delle statistiche (per grafici futuri)
  Future<List<DailyStats>> getStatsHistory(String userId, {int days = 30}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => DailyStats.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Errore recupero storico stats: $e');
      return [];
    }
  }

  /// Calcola totale mattoncini di sempre (per badge futuri)
  Future<int> getTotalPomodorosAllTime(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['completedPomodoros'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      debugPrint('❌ Errore calcolo totale pomodori: $e');
      return 0;
    }
  }

  /// Verifica se è necessario resettare (cambio giorno)
  /// Ritorna true se l'ultima data salvata è diversa da oggi
  static bool shouldReset(DateTime? lastDate) {
    if (lastDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastDate.year, lastDate.month, lastDate.day);

    return today.isAfter(last);
  }
}
