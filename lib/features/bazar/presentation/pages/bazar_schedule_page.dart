import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/permission_utils.dart';

class BazarSchedulePage extends StatefulWidget {
  const BazarSchedulePage({super.key});

  @override
  State<BazarSchedulePage> createState() => _BazarSchedulePageState();
}

class _BazarSchedulePageState extends State<BazarSchedulePage> {
  bool _isLoading = true;
  bool _isManager = false;
  String _messId = '';
  List<Map<String, dynamic>> _members = [];
  // schedule: list of {date, memberIds: []}
  List<Map<String, dynamic>> _schedule = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final messId = userDoc.data()?['messId'] as String? ?? '';
      final role = userDoc.data()?['role'] as String? ?? 'member';
      if (messId.isEmpty) return;

      final membersSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('members')
          .get();

      final messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .get();

      // Load bazar schedule from Firestore (stored as list of {date, memberIds})
      final rawSchedule = List<Map<String, dynamic>>.from(
        (messDoc.data()?['bazarScheduleDetailed'] as List<dynamic>? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      if (mounted) {
        setState(() {
          _messId = messId;
          _isManager = role == 'manager' || role == 'admin';
          _members = membersSnap.docs
              .map((d) => {'id': d.id, 'name': d.data()['name'] ?? ''})
              .toList();
          _schedule = rawSchedule;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _memberName(String id) {
    final m = _members.firstWhere(
      (m) => m['id'] == id,
      orElse: () => {'name': 'Unknown'},
    );
    return m['name'] as String;
  }

  List<String> _membersForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final entry = _schedule.firstWhere(
      (e) => e['date'] == dateStr,
      orElse: () => {},
    );
    if (entry.isEmpty) return [];
    return List<String>.from(entry['memberIds'] as List? ?? []);
  }

  Future<void> _saveSchedule() async {
    await FirebaseFirestore.instance.collection('messes').doc(_messId).update({
      'bazarScheduleDetailed': _schedule,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bazar schedule saved!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditDialog(DateTime date) async {
    if (!_isManager) {
      showNoPermissionSnack(context);
      return;
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final existing = _membersForDate(date);
    final selected = List<String>.from(existing);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Bazar - ${DateFormat('EEE, MMM d').format(date)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: _members.isEmpty
              ? const Text('No members found.')
              : SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _members.map((m) {
                      final isChecked = selected.contains(m['id']);
                      return CheckboxListTile(
                        dense: true,
                        value: isChecked,
                        title: Text(m['name'] as String),
                        activeColor: AppColors.primaryGreen,
                        onChanged: (v) => setS(() {
                          if (v == true)
                            selected.add(m['id'] as String);
                          else
                            selected.remove(m['id']);
                        }),
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              onPressed: () async {
                setState(() {
                  _schedule.removeWhere((e) => e['date'] == dateStr);
                  if (selected.isNotEmpty) {
                    _schedule.add({'date': dateStr, 'memberIds': selected});
                  }
                });
                await _saveSchedule();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Show next 14 days
    final days = List.generate(14, (i) {
      final d = today.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Bazar Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final memberIds = _membersForDate(date);
                final isToday = index == 0;
                final isTomorrow = index == 1;

                String dayLabel = DateFormat('EEE, MMM d').format(date);
                if (isToday) dayLabel = 'Today · $dayLabel';
                if (isTomorrow) dayLabel = 'Tomorrow · $dayLabel';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: isToday
                        ? Border.all(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.4,
                            ),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primaryGreen
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_basket_rounded,
                        color: isToday ? Colors.white : Colors.orange,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      dayLabel,
                      style: TextStyle(
                        fontWeight: isToday || isTomorrow
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: memberIds.isEmpty
                        ? Text(
                            'No one assigned',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Text(
                            memberIds.map(_memberName).join(', '),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    trailing: _isManager
                        ? IconButton(
                            icon: Icon(
                              memberIds.isEmpty
                                  ? Icons.add_circle_outline
                                  : Icons.edit_outlined,
                              color: AppColors.primaryGreen,
                            ),
                            onPressed: () => _showEditDialog(date),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
