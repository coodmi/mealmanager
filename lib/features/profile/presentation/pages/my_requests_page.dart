import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _pushNotificationsEnabled = true;
  static const _pushPrefKey = 'push_notifications_enabled';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPushPref();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPushPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled = prefs.getBool(_pushPrefKey) ?? true;
    });
  }

  Future<void> _togglePush(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushPrefKey, val);
    setState(() => _pushNotificationsEnabled = val);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('invitations')
          .orderBy('sentAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final allDocs = snap.data?.docs ?? [];
        final pending = allDocs
            .where((d) => (d['status'] ?? 'pending') == 'pending')
            .toList();
        final approved = allDocs
            .where((d) => (d['status'] ?? '') == 'accepted')
            .toList();
        final rejected = allDocs
            .where((d) => (d['status'] ?? '') == 'rejected')
            .toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'My Requests',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            centerTitle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            elevation: 0,
            actions: [
              // Push notification toggle in app bar
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Icon(
                      _pushNotificationsEnabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: _pushNotificationsEnabled,
                        onChanged: _togglePush,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.white.withValues(alpha: 0.4),
                        inactiveThumbColor: Colors.white54,
                        inactiveTrackColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(90),
              child: Column(
                children: [
                  // Summary chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        _summaryChip('Pending', pending.length, Colors.orange),
                        const SizedBox(width: 8),
                        _summaryChip('Approved', approved.length, Colors.green),
                        const SizedBox(width: 8),
                        _summaryChip('Rejected', rejected.length, Colors.red),
                      ],
                    ),
                  ),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'Approved'),
                      Tab(text: 'Rejected'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: snap.connectionState == ConnectionState.waiting
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(pending, 'pending', uid),
                    _buildList(approved, 'accepted', uid),
                    _buildList(rejected, 'rejected', uid),
                  ],
                ),
        );
      },
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'Pending')
            const Icon(
              Icons.notifications_active_outlined,
              size: 12,
              color: Colors.white,
            ),
          if (label != 'Pending')
            Icon(
              label == 'Approved'
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 12,
              color: Colors.white,
            ),
          const SizedBox(width: 4),
          Text(
            '$label ',
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: count > 0 ? color : Colors.white30,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs, String type, String uid) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              type == 'pending'
                  ? 'No pending requests'
                  : type == 'accepted'
                  ? 'No approved requests'
                  : 'No rejected requests',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final docId = docs[i].id;
        return _buildRequestCard(data, docId, uid, type);
      },
    );
  }

  Widget _buildRequestCard(
    Map<String, dynamic> data,
    String docId,
    String uid,
    String type,
  ) {
    final messName = data['messName'] as String? ?? 'Unknown Mess';
    final managerName = data['managerName'] as String? ?? 'Manager';
    final status = data['status'] as String? ?? 'pending';
    final sentAt = data['sentAt'] as Timestamp?;
    final timeAgo = sentAt != null ? _timeAgo(sentAt.toDate()) : '';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Avatar with status badge
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.home_work_rounded,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(statusIcon, size: 8, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mess Invitation',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        managerName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              '$managerName is inviting you to join "$messName".',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),

          // Action buttons (only for pending)
          if (status == 'pending') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  // Reject button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectInvitation(docId, uid),
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accept button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptInvitation(data, docId, uid),
                      icon: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // OK button for accepted/rejected (read confirmation)
          if (status != 'pending') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            status == 'accepted'
                                ? 'You joined "$messName"'
                                : 'Invitation rejected',
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: () => _dismissRequest(docId, uid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(
    Map<String, dynamic> inv,
    String docId,
    String uid,
  ) async {
    final messId = inv['messId'] as String? ?? '';
    final memberName = inv['memberName'] as String? ?? '';
    final memberPhone = inv['memberPhone'] as String? ?? '';
    final initialBalance = (inv['initialBalance'] as num?)?.toDouble() ?? 0;

    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('members')
            .doc(uid),
        {
          'name': memberName,
          'phone': memberPhone,
          'balance': initialBalance,
          'isActive': true,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('invitations')
            .doc(docId),
        {'status': 'accepted'},
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final existing = List<String>.from(
        userDoc.data()?['messIds'] as List? ?? [],
      );
      if (!existing.contains(messId)) existing.add(messId);
      batch.update(FirebaseFirestore.instance.collection('users').doc(uid), {
        'messIds': existing,
        'messId': messId,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined mess successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvitation(String docId, String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('invitations')
          .doc(docId)
          .update({'status': 'rejected'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation rejected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _dismissRequest(String docId, String uid) async {
    // Mark as read/dismissed — just delete the local doc or mark dismissed
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('invitations')
          .doc(docId)
          .update({'dismissed': true});
    } catch (_) {}
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
