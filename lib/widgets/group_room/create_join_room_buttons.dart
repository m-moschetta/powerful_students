import 'package:flutter/cupertino.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/room_provider.dart';

class CreateJoinRoomButtons extends StatelessWidget {
  const CreateJoinRoomButtons({
    super.key,
    required this.roomProvider,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  final RoomProvider roomProvider;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: roomProvider.isCreatingRoom ? null : onCreateRoom,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: AppColors.cta,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.ctaGlow,
            ),
            child: Center(
              child: roomProvider.isCreatingRoom
                  ? const CupertinoActivityIndicator()
                  : const Text(
                      'CREA STANZA',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: roomProvider.isJoiningRoom ? null : onJoinRoom,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.separator),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.brickyGroup,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Unisciti al mattoncino',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
