import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';

class SessionCompletedScreen extends StatelessWidget {
  const SessionCompletedScreen({
    super.key,
    required this.completedPomodoros,
    required this.onContinue,
  });

  final int completedPomodoros;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          const Text(
            'Complimenti!',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Avete costruito un nuovo mattoncino',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.brickyCelebration,
                width: 170,
                height: 170,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '$completedPomodoros ${completedPomodoros == 1 ? 'mattoncino costruito' : 'mattoncini costruiti'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            color: AppColors.cta,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onPressed: () {
              HapticFeedback.mediumImpact();
              onContinue();
            },
            child: const SizedBox(
              width: double.infinity,
              child: Center(
                child: Text(
                  'Continua a costruire',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
