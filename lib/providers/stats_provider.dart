import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsProvider extends ChangeNotifier {
  static const _keyDailyBricks = 'daily_bricks';
  static const _keyTotalBricks = 'total_bricks';
  static const _keyTotalMinutes = 'total_minutes';
  static const _keyBestStreak = 'best_streak';

  SharedPreferences? _prefs;

  // Daily bricks map: 'yyyy-MM-dd' -> count
  Map<String, int> _dailyBricks = {};
  int _totalBricks = 0;
  int _totalMinutes = 0;
  int _bestStreak = 0;

  int get totalBricks => _totalBricks;
  int get totalMinutes => _totalMinutes;
  int get bestStreak => _bestStreak;

  /// Current consecutive days streak (including today if bricks were built).
  int get currentStreak {
    if (_dailyBricks.isEmpty) return 0;

    var streak = 0;
    var date = DateTime.now();
    final todayKey = _dateKey(date);

    // If no bricks today, start checking from yesterday
    if (!_dailyBricks.containsKey(todayKey) ||
        _dailyBricks[todayKey]! <= 0) {
      date = date.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = _dateKey(date);
      if (_dailyBricks.containsKey(key) && _dailyBricks[key]! > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Bricks built today.
  int get todayBricks {
    final key = _dateKey(DateTime.now());
    return _dailyBricks[key] ?? 0;
  }

  /// Returns the last N days of brick counts (most recent first).
  List<DayStats> getRecentDays(int count) {
    final result = <DayStats>[];
    final now = DateTime.now();

    for (var i = 0; i < count; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      result.add(DayStats(
        date: date,
        bricks: _dailyBricks[key] ?? 0,
      ));
    }

    return result;
  }

  /// Average bricks per day over the last N days.
  double averageBricksPerDay(int days) {
    final recent = getRecentDays(days);
    if (recent.isEmpty) return 0;
    final total = recent.fold<int>(0, (sum, d) => sum + d.bricks);
    return total / days;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _totalBricks = _prefs?.getInt(_keyTotalBricks) ?? 0;
    _totalMinutes = _prefs?.getInt(_keyTotalMinutes) ?? 0;
    _bestStreak = _prefs?.getInt(_keyBestStreak) ?? 0;

    final dailyJson = _prefs?.getString(_keyDailyBricks);
    if (dailyJson != null) {
      final decoded = jsonDecode(dailyJson) as Map<String, dynamic>;
      _dailyBricks = decoded.map((k, v) => MapEntry(k, v as int));
    }

    notifyListeners();
  }

  /// Records a completed brick (Pomodoro session).
  Future<void> recordBrick({int durationMinutes = 25}) async {
    _totalBricks++;
    _totalMinutes += durationMinutes;

    final key = _dateKey(DateTime.now());
    _dailyBricks[key] = (_dailyBricks[key] ?? 0) + 1;

    // Update best streak
    final streak = currentStreak;
    if (streak > _bestStreak) {
      _bestStreak = streak;
    }

    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs?.setInt(_keyTotalBricks, _totalBricks);
    await _prefs?.setInt(_keyTotalMinutes, _totalMinutes);
    await _prefs?.setInt(_keyBestStreak, _bestStreak);
    await _prefs?.setString(_keyDailyBricks, jsonEncode(_dailyBricks));
  }

  /// Resets all statistics.
  Future<void> resetStats() async {
    _totalBricks = 0;
    _totalMinutes = 0;
    _bestStreak = 0;
    _dailyBricks.clear();
    await _save();
    notifyListeners();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class DayStats {
  final DateTime date;
  final int bricks;

  const DayStats({required this.date, required this.bricks});
}
