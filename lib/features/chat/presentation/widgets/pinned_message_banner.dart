import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/chat_message_model.dart';

class PinnedMessageBanner extends StatelessWidget {
  final ChatMessageModel? message;
  final VoidCallback? onTap;

  const PinnedMessageBanner({super.key, this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final preview = message!.text.length > 80
        ? '${message!.text.substring(0, 80)}...'
        : message!.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
          border: Border(
            bottom: BorderSide(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, size: 14, color: AppColors.primaryGreen),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '📌 $preview',
                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
