import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/stats_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _dailyBrickGoal = 8;
  bool _isEnglish = false;

  // Localization helpers
  String _t(String it, String en) => _isEnglish ? en : it;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<StatsProvider>(
          builder: (context, stats, _) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: stats.totalBricks == 0
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            _buildStreakCard(stats),
                            const SizedBox(height: AppSpacing.sm),
                            _buildTotalStatsCard(stats),
                            const SizedBox(height: AppSpacing.sm),
                            _buildWeeklyChart(stats),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDailyHistory(stats),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              _t('Statistiche', 'Statistics'),
              style: AppTypography.title,
            ),
          ),
          // Language toggle
          GestureDetector(
            onTap: () => setState(() => _isEnglish = !_isEnglish),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.glassBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _isEnglish ? '🇬🇧 EN' : '🇮🇹 IT',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chart_bar,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _t('Nessuna statistica ancora', 'No statistics yet'),
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _t(
                'Completa la tua prima sessione Pomodoro per iniziare a tracciare i tuoi progressi!',
                'Complete your first Pomodoro session to start tracking your progress!',
              ),
              style: AppTypography.caption.copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(StatsProvider stats) {
    final streak = stats.currentStreak;
    final best = stats.bestStreak;

    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Streak flame icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: streak > 0
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: streak > 0
                  ? Image.asset(
                      AppAssets.brickyBurn,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        CupertinoIcons.flame_fill,
                        size: 32,
                        color: Colors.orange,
                      ),
                    )
                  : Icon(
                      CupertinoIcons.flame,
                      size: 32,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          Text(
            streak == 1
                ? _t('giorno consecutivo', 'day streak')
                : _t('giorni consecutivi', 'days streak'),
            style: AppTypography.caption,
          ),
          if (best > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.cta.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _t('Record: $best giorni', 'Best: $best days'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalStatsCard(StatsProvider stats) {
    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              value: '${stats.totalBricks}',
              label: _t('Mattoncini', 'Bricks'),
              icon: AppAssets.brickyLogo,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.glassBorder,
          ),
          Expanded(
            child: _StatTile(
              value: _formatMinutes(stats.totalMinutes),
              label: _t('Tempo studio', 'Study time'),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.glassBorder,
          ),
          Expanded(
            child: _StatTile(
              value: '${stats.todayBricks}',
              label: _t('Oggi', 'Today'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(StatsProvider stats) {
    final days = stats.getRecentDays(7).reversed.toList();
    final maxBricks =
        days.fold<int>(1, (max, d) => d.bricks > max ? d.bricks : max);

    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Ultimi 7 giorni', 'Last 7 days'),
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Media: ${stats.averageBricksPerDay(7).toStringAsFixed(1)} mattoncini/giorno',
              'Average: ${stats.averageBricksPerDay(7).toStringAsFixed(1)} bricks/day',
            ),
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final fraction =
                    maxBricks > 0 ? day.bricks / maxBricks : 0.0;
                final isToday =
                    _isSameDay(day.date, DateTime.now());

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.bricks > 0)
                          Text(
                            '${day.bricks}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: fraction.clamp(0.05, 1.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: day.bricks > 0
                                    ? (isToday
                                        ? AppColors.primary
                                        : AppColors.primary
                                            .withValues(alpha: 0.5))
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: isToday
                                    ? Border.all(
                                        color: AppColors.textPrimary,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _weekdayShort(day.date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isToday
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHistory(StatsProvider stats) {
    final days = stats.getRecentDays(14);

    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Cronologia', 'History'),
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: 12),
          ...days.map((day) {
            final isToday = _isSameDay(day.date, DateTime.now());
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      isToday
                          ? _t('Oggi', 'Today')
                          : _formatDate(day.date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: day.bricks > 0
                            ? (day.bricks / _dailyBrickGoal).clamp(0.0, 1.0)
                            : 0.0,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          day.bricks > 0
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${day.bricks}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: day.bricks > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.cube_fill,
                    size: 14,
                    color: day.bricks > 0
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  String _weekdayShort(DateTime date) {
    const itDays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = _isEnglish ? enDays : itDays;
    return days[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null) ...[
          Image.asset(
            icon!,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              CupertinoIcons.cube_fill,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
