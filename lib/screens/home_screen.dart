import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/screens/chat_screen.dart';
import 'package:powerful_students/screens/dev_settings_screen.dart';
import 'package:powerful_students/screens/mode_selection_screen.dart';
import 'package:powerful_students/screens/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _devTapCount = 0;
  DateTime? _lastDevTap;

  final _pages = const [
    ModeSelectionScreen(),
    ChatScreen(),
    StatsScreen(),
  ];

  void _handleDevTap() {
    final now = DateTime.now();
    // Reset counter if more than 3 seconds between taps
    if (_lastDevTap != null &&
        now.difference(_lastDevTap!).inMilliseconds > 3000) {
      _devTapCount = 0;
    }
    _lastDevTap = now;
    _devTapCount++;

    if (_devTapCount >= 5) {
      _devTapCount = 0;
      _lastDevTap = null;
      HapticFeedback.heavyImpact();
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.bgStart, AppColors.bgEnd],
                  ),
                ),
              ),
              const DevSettingsScreen(),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              border: const Border(
                top: BorderSide(
                  color: AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TabBarItem(
                    icon: CupertinoIcons.cube_fill,
                    label: 'Studio',
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onTabTapped(0),
                  ),
                  _TabBarItem(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    label: 'Buddy',
                    isSelected: _selectedIndex == 1,
                    onTap: () => _onTabTapped(1),
                  ),
                  _TabBarItem(
                    icon: CupertinoIcons.chart_bar_fill,
                    label: 'Stats',
                    isSelected: _selectedIndex == 2,
                    onTap: () => _onTabTapped(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) {
      // Tapping the already-selected Studio tab counts toward dev access
      if (index == 0) _handleDevTap();
      return;
    }
    _devTapCount = 0;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
