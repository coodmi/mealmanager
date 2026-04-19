import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_card.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primaryGreen,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'Send Notification'),
              Tab(text: 'History'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_SendNotificationForm(), _NotificationHistory()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SendNotificationForm extends StatefulWidget {
  @override
  State<_SendNotificationForm> createState() => _SendNotificationFormState();
}

class _SendNotificationFormState extends State<_SendNotificationForm> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _target = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('adminNotifications').add({
        'title': _titleCtrl.text.trim(),
        'message': _msgCtrl.text.trim(),
        'target': _target,
        'sentAt': FieldValue.serverTimestamp(),
        'openCount': 0,
      });
      _titleCtrl.clear();
      _msgCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Notification / Announcement',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            decoration: _inputDec('Title', Icons.title),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            decoration: _inputDec('Message', Icons.message_outlined),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _target,
            decoration: _inputDec('Target Audience', Icons.group_outlined),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Users')),
              DropdownMenuItem(value: 'manager', child: Text('Mess Managers')),
              DropdownMenuItem(value: 'free', child: Text('Free Users')),
              DropdownMenuItem(value: 'premium', child: Text('Premium Users')),
            ],
            onChanged: (v) => setState(() => _target = v!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              label: Text(
                _sending ? 'Sending...' : 'Send Now',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

class _NotificationHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adminNotifications')
            .orderBy('sentAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const Center(
              child: Text(
                'No notifications sent yet',
                style: TextStyle(color: AppColors.textLight),
              ),
            );
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final ts = d['sentAt'] as Timestamp?;
              final date = ts != null
                  ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                  : '—';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                ),
                title: Text(
                  d['title'] as String? ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  d['message'] as String? ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      'To: ${d['target'] ?? 'all'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
