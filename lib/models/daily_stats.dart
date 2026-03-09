import 'package:cloud_firestore/cloud_firestore.dart';

/// Statistiche giornaliere per un singolo utente
/// Reset automatico a mezzanotte
class DailyStats {
  final String id; // formato: userId_YYYY-MM-DD
  final String userId;
  final DateTime date;
  final int completedPomodoros; // Mattoncini completati oggi
  final int totalMinutes; // Minuti totali studiati oggi
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyStats({
    required this.id,
    required this.userId,
    required this.date,
    required this.completedPomodoros,
    required this.totalMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor da Firestore DocumentSnapshot
  factory DailyStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyStats(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      completedPomodoros: data['completedPomodoros'] as int? ?? 0,
      totalMinutes: data['totalMinutes'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converti in Map per Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'completedPomodoros': completedPomodoros,
      'totalMinutes': totalMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Genera ID documento formato: userId_YYYY-MM-DD
  static String generateId(String userId, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${userId}_$dateStr';
  }

  /// Crea nuova stats per oggi (valori a zero)
  factory DailyStats.createToday(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DailyStats(
      id: generateId(userId, today),
      userId: userId,
      date: today,
      completedPomodoros: 0,
      totalMinutes: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copia con modifiche
  DailyStats copyWith({
    int? completedPomodoros,
    int? totalMinutes,
    DateTime? updatedAt,
  }) {
    return DailyStats(
      id: id,
      userId: userId,
      date: date,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
