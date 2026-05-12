import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/screens/chat_screen.dart';
import 'package:powerful_students/screens/mode_selection_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _goToChat() {
    _dismissKeyboard();
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
    );
  }

  void _goToHome() {
    _dismissKeyboard();
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
    );
  }

  void _startBuddySession() {
    final pomodoro = context.read<PomodoroProvider>();
    pomodoro.selectMode(StudyMode.buddy);
    pomodoro.startWorkSession();
    Navigator.pushNamed(context, '/timer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null) {
            _dismissKeyboard();
          }
          return false;
        },
        child: PageView(
          controller: _pageController,
          children: [
            ModeSelectionScreen(onChatPressed: _goToChat),
            ChatScreen(
              onBackPressed: _goToHome,
              onStartSession: _startBuddySession,
            ),
          ],
        ),
      ),
    );
  }
}
