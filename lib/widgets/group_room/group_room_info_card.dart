import 'package:flutter/cupertino.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/room_provider.dart';

class GroupRoomInfoCard extends StatelessWidget {
  const GroupRoomInfoCard({
    super.key,
    required this.roomProvider,
    required this.isOwner,
    required this.onCopyCode,
    required this.onShareCode,
  });

  final RoomProvider roomProvider;
  final bool isOwner;
  final VoidCallback onCopyCode;
  final VoidCallback onShareCode;

  @override
  Widget build(BuildContext context) {
    final room = roomProvider.room;
    final members = room?.memberIds ?? [];
    final joinedMembers = members.where((id) => id != room?.ownerId).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.separator),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                roomProvider.currentRoomCode ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              if (isOwner) ...[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  onPressed: onCopyCode,
                  child: const Icon(CupertinoIcons.doc_on_doc, size: 18, color: AppColors.textPrimary),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  onPressed: onShareCode,
                  child: const Icon(CupertinoIcons.share, size: 18, color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
          if (joinedMembers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MemberAvatars(joinedMembers: joinedMembers),
          ],
        ],
      ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars({required this.joinedMembers});

  final List<String> joinedMembers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: joinedMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final memberId = entry.value;
          final initials = memberId.substring(0, 2).toUpperCase();
          final totalWidth = joinedMembers.length * 24.0 + 12;
          final startOffset = -totalWidth / 2;
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 - 24 - 18 + startOffset + (index * 24.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
