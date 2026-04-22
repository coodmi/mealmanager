import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SeenReceiptText extends StatelessWidget {
  final List<String> seenBy;
  final List<Map<String, dynamic>> activeMembers;
  final String currentUid;

  const SeenReceiptText({
    super.key,
    required this.seenBy,
    required this.activeMembers,
    required this.currentUid,
  });

  String _buildSeenText() {
    // Exclude current user from seen list for display
    final otherSeenUids = seenBy.where((uid) => uid != currentUid).toList();
    if (otherSeenUids.isEmpty) return '';

    final activeMemberUids = activeMembers
        .map((m) => m['id'] as String)
        .toSet();
    final otherActiveUids = activeMemberUids
        .where((uid) => uid != currentUid)
        .toSet();

    if (otherActiveUids.isEmpty) return '';

    // Check if everyone has seen it
    final allSeen = otherActiveUids.every((uid) => seenBy.contains(uid));
    if (allSeen) return 'Seen by Everyone';

    // Build names list
    final seenNames = <String>[];
    for (final uid in otherSeenUids) {
      final member = activeMembers.firstWhere(
        (m) => m['id'] == uid,
        orElse: () => {},
      );
      if (member.isNotEmpty) {
        final name = member['name'] as String? ?? '';
        if (name.isNotEmpty) seenNames.add(name.split(' ').first);
      }
    }

    if (seenNames.isEmpty) return '';
    if (seenNames.length <= 3) return 'Seen by ${seenNames.join(', ')}';
    final shown = seenNames.take(3).join(', ');
    final remaining = seenNames.length - 3;
    return 'Seen by $shown and $remaining more';
  }

  @override
  Widget build(BuildContext context) {
    final text = _buildSeenText();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
