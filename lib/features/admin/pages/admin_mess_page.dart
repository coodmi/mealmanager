import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_card.dart';

class AdminMessPage extends StatefulWidget {
  const AdminMessPage({super.key});

  @override
  State<AdminMessPage> createState() => _AdminMessPageState();
}

class _AdminMessPageState extends State<AdminMessPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AdminCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search mess by name...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messes')
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                var docs = snap.data!.docs;
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final name = ((d.data() as Map)['name'] as String? ?? '')
                        .toLowerCase();
                    return name.contains(_search);
                  }).toList();
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _MessCard(
                    messId: docs[i].id,
                    data: docs[i].data() as Map<String, dynamic>,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessCard extends StatelessWidget {
  final String messId;
  final Map<String, dynamic> data;
  const _MessCard({required this.messId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Unnamed Mess';
    final isPremium = data['isPremium'] == true;
    final isActive = data['isActive'] != false;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _row(
            'Mess ID',
            messId.length > 12 ? '${messId.substring(0, 12)}...' : messId,
          ),
          _row('Status', isActive ? 'Active' : 'Inactive'),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _viewDetail(context),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _deleteMess(context),
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('Delete', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _viewDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _MessDetailDialog(messId: messId, data: data),
    );
  }

  Future<void> _deleteMess(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Mess'),
        content: const Text(
          'This will permanently delete this mess. Continue?',
        ),
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
      await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .delete();
    }
  }
}

class _MessDetailDialog extends StatelessWidget {
  final String messId;
  final Map<String, dynamic> data;
  const _MessDetailDialog({required this.messId, required this.data});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['name'] as String? ?? 'Mess Detail',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messes')
                    .doc(messId)
                    .collection('members')
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return Text(
                    'Members: $count',
                    style: const TextStyle(color: AppColors.textLight),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Mess ID: $messId',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 16),
              // Toggle active
              Row(
                children: [
                  const Text('Active: '),
                  Switch(
                    value: data['isActive'] != false,
                    onChanged: (v) async {
                      await FirebaseFirestore.instance
                          .collection('messes')
                          .doc(messId)
                          .update({'isActive': v});
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
