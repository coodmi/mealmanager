import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_card.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _search = '';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search + filter bar
          AdminCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name, email, phone...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filterStatus,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AdminCard(
              padding: EdgeInsets.zero,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  var docs = snap.data!.docs;

                  // Filter
                  docs = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name = (d['name'] as String? ?? '').toLowerCase();
                    final email = (d['email'] as String? ?? '').toLowerCase();
                    final mobile = (d['mobile'] as String? ?? '').toLowerCase();
                    final blocked = d['isBlocked'] == true;

                    if (_search.isNotEmpty &&
                        !name.contains(_search) &&
                        !email.contains(_search) &&
                        !mobile.contains(_search))
                      return false;
                    if (_filterStatus == 'blocked' && !blocked) return false;
                    if (_filterStatus == 'active' && blocked) return false;
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            _th('User', flex: 3),
                            _th('Contact', flex: 3),
                            _th('Role', flex: 2),
                            _th('Status', flex: 2),
                            _th('Joined', flex: 2),
                            _th('Actions', flex: 2),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final doc = docs[i];
                            final d = doc.data() as Map<String, dynamic>;
                            return _UserRow(uid: doc.id, data: d);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${docs.length} users',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  const _UserRow({required this.uid, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '—';
    final email = data['email'] as String? ?? '—';
    final mobile = data['mobile'] as String? ?? '—';
    final role = data['role'] as String? ?? 'member';
    final blocked = data['isBlocked'] == true;
    final ts = data['createdAt'] as Timestamp?;
    final joined = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // User
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryGreen.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Contact
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  mobile,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          // Role
          Expanded(flex: 2, child: _RoleBadge(role: role)),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: blocked
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                blocked ? 'Blocked' : 'Active',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: blocked ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
          // Joined
          Expanded(
            flex: 2,
            child: Text(
              joined,
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _ActionBtn(
                  Icons.visibility_outlined,
                  Colors.blue,
                  () => _viewUser(context),
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  blocked ? Icons.lock_open : Icons.block,
                  blocked ? Colors.green : Colors.orange,
                  () => _toggleBlock(context, blocked),
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  Icons.delete_outline,
                  Colors.red,
                  () => _deleteUser(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(data['name'] as String? ?? 'User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('UID', uid),
            _infoRow('Email', data['email'] as String? ?? '—'),
            _infoRow('Mobile', data['mobile'] as String? ?? '—'),
            _infoRow('Role', data['role'] as String? ?? '—'),
            _infoRow('Mess ID', data['messId'] as String? ?? 'None'),
            _infoRow(
              'Status',
              data['isBlocked'] == true ? 'Blocked' : 'Active',
            ),
          ],
        ),
        actions: [
          // Role upgrade
          PopupMenuButton<String>(
            child: const Chip(label: Text('Change Role')),
            itemBuilder: (_) => [
              'member',
              'manager',
              'supportAdmin',
              'contentAdmin',
              'superAdmin',
            ].map((r) => PopupMenuItem(value: r, child: Text(r))).toList(),
            onSelected: (role) async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'role': role});
              if (context.mounted) Navigator.pop(context);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _toggleBlock(BuildContext context, bool currentlyBlocked) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isBlocked': !currentlyBlocked,
    });
  }

  Future<void> _deleteUser(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('This will permanently delete the user. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (role) {
      case 'superAdmin':
      case 'manager':
        c = Colors.deepPurple;
        break;
      case 'systemAdmin':
        c = Colors.indigo;
        break;
      case 'supportAdmin':
        c = Colors.blue;
        break;
      case 'contentAdmin':
        c = Colors.teal;
        break;
      default:
        c = Colors.grey;
    }
    final label = role == 'manager' ? 'Super Admin' : role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
