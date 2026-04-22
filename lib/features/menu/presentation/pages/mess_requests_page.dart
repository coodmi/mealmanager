import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';

class MessRequestsPage extends StatefulWidget {
  const MessRequestsPage({super.key});

  @override
  State<MessRequestsPage> createState() => _MessRequestsPageState();
}

class _MessRequestsPageState extends State<MessRequestsPage>
    with SingleTickerProviderStateMixin {
  String _messId = '';
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (mounted) {
      setState(() {
        _messId = doc.data()?['messId'] as String? ?? '';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mess Requests',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved / Rejected'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messId.isEmpty
          ? const Center(child: Text('No mess found'))
          : TabBarView(
              controller: _tabController,
              children: [
                _RequestList(
                  messId: _messId,
                  statusFilter: 'pending',
                  onApprove: _approveRequest,
                  onReject: _rejectRequest,
                ),
                _RequestList(messId: _messId, statusFilter: 'history'),
              ],
            ),
    );
  }

  Future<void> _approveRequest(String userId, Map<String, dynamic> data) async {
    try {
      final name = data['name'] as String? ?? 'Member';
      final phone = data['phone'] as String? ?? '';
      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(_messId)
            .collection('members')
            .doc(userId),
        {
          'name': name,
          'phone': phone,
          'balance': 0,
          'isActive': true,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(_messId)
            .collection('joinRequests')
            .doc(userId),
        {'status': 'approved'},
      );

      batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
        'joinStatus': 'approved',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name approved and added to mess!'),
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

  Future<void> _rejectRequest(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Request'),
        content: Text('Reject $name\'s request to join the mess?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(_messId)
            .collection('joinRequests')
            .doc(userId),
        {'status': 'rejected'},
      );

      batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
        'messId': '',
        'joinStatus': 'rejected',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Request List Widget ───────────────────────────────────────────────────

class _RequestList extends StatelessWidget {
  final String messId;
  final String statusFilter; // 'pending' or 'history'
  final Future<void> Function(String userId, Map<String, dynamic> data)?
  onApprove;
  final Future<void> Function(String userId, String name)? onReject;

  const _RequestList({
    required this.messId,
    required this.statusFilter,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('messes')
        .doc(messId)
        .collection('joinRequests');

    if (statusFilter == 'pending') {
      query = query.where('status', isEqualTo: 'pending');
    }
    // history tab shows approved + rejected (all non-pending)

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snap.data?.docs ?? [];

        // For history tab, filter out pending in-memory
        if (statusFilter == 'history') {
          docs = docs
              .where((d) => (d.data() as Map)['status'] != 'pending')
              .toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statusFilter == 'pending'
                      ? Icons.inbox_outlined
                      : Icons.history,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  statusFilter == 'pending'
                      ? 'No pending requests'
                      : 'No request history',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.id;
            final name = data['name'] as String? ?? 'Unknown';
            final phone = data['phone'] as String? ?? '';
            final email = data['email'] as String? ?? '';
            final status = data['status'] as String? ?? 'pending';
            final requestedAt = data['requestedAt'] as Timestamp?;

            return _RequestCard(
              userId: userId,
              name: name,
              phone: phone,
              email: email,
              status: status,
              requestedAt: requestedAt,
              onApprove: onApprove != null
                  ? () => onApprove!(userId, data)
                  : null,
              onReject: onReject != null ? () => onReject!(userId, name) : null,
            );
          },
        );
      },
    );
  }
}

// ─── Request Card ──────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String status;
  final Timestamp? requestedAt;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _RequestCard({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
    this.requestedAt,
    this.onApprove,
    this.onReject,
  });

  void _showDetails(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusLabel = 'Pending';
    }

    final initials = name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    String? timeStr;
    if (requestedAt != null) {
      final dt = requestedAt!.toDate();
      timeStr =
          '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: statusColor.withValues(alpha: 0.12),
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 13, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Info rows
            _infoRow(Icons.phone, 'Phone', phone.isNotEmpty ? phone : '—'),
            const SizedBox(height: 12),
            _infoRow(Icons.email, 'Email', email.isNotEmpty ? email : '—'),
            const SizedBox(height: 12),
            _infoRow(Icons.access_time, 'Requested', timeStr ?? '—'),
            const SizedBox(height: 28),
            // Action buttons (only for pending)
            if (status == 'pending' && (onApprove != null || onReject != null))
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onReject!();
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  if (onApprove != null && onReject != null)
                    const SizedBox(width: 12),
                  if (onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onApprove!();
                        },
                        icon: const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Approve',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusLabel = 'Pending';
    }

    String? timeStr;
    if (requestedAt != null) {
      final dt = requestedAt!.toDate();
      timeStr =
          '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      child: Text(
                        initials.isEmpty ? '?' : initials,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (timeStr != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Requested: $timeStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
                // Quick action buttons for pending (also available in detail sheet)
                if (status == 'pending' &&
                    (onApprove != null || onReject != null)) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (onReject != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: onReject,
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text(
                              'Reject',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      if (onApprove != null && onReject != null)
                        const SizedBox(width: 10),
                      if (onApprove != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: onApprove,
                            icon: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Approve',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
