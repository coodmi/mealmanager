import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/chat_message_model.dart';

class ReplyPreviewBar extends StatelessWidget {
  final ReplyReference replyTo;
  final VoidCallback onCancel;

  const ReplyPreviewBar({
    super.key,
    required this.replyTo,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final preview = replyTo.text.length > 60
        ? '${replyTo.text.substring(0, 60)}...'
        : replyTo.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
          left: const BorderSide(color: AppColors.primaryGreen, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${replyTo.senderName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey.shade500,
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
