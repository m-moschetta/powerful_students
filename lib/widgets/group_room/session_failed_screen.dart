import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:powerful_students/core/design_system.dart';

class SessionFailedScreen extends StatelessWidget {
  const SessionFailedScreen({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.brickyBroken,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          const Text(
            'Sessione fallita',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Qualcuno ha lasciato l\'app durante una sessione di Deep Building.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          CupertinoButton(
            padding: EdgeInsets.zero,
            color: AppColors.cta,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onPressed: onDismiss,
            child: const SizedBox(
              width: double.infinity,
              child: Center(
                child: Text(
                  'TORNA INDIETRO',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
