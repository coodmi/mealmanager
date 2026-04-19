import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

class AdminVideosPage extends StatelessWidget {
  const AdminVideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tutorial Videos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(context, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tutorialVideos')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No videos yet. Add your first video.',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _VideoCard(
                      docId: doc.id,
                      data: data,
                      onEdit: () => _showAddEditDialog(context, doc),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, DocumentSnapshot? doc) {
    final data = doc?.data() as Map<String, dynamic>?;
    final titleCtrl = TextEditingController(text: data?['title'] ?? '');
    final descCtrl = TextEditingController(text: data?['description'] ?? '');
    final urlCtrl = TextEditingController(text: data?['url'] ?? '');
    final orderCtrl = TextEditingController(
      text: (data?['order'] ?? 0).toString(),
    );
    final isEdit = doc != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Edit Video' : 'Add Video Link',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titleCtrl, 'Title', Icons.title_rounded),
              const SizedBox(height: 12),
              _field(descCtrl, 'Short Description', Icons.description_rounded),
              const SizedBox(height: 12),
              _field(urlCtrl, 'YouTube URL', Icons.link_rounded),
              const SizedBox(height: 12),
              _field(
                orderCtrl,
                'Order (1, 2, 3...)',
                Icons.sort_rounded,
                isNumber: true,
              ),
            ],
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty)
                return;
              final payload = {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'url': urlCtrl.text.trim(),
                'order': int.tryParse(orderCtrl.text.trim()) ?? 0,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (isEdit) {
                await FirebaseFirestore.instance
                    .collection('tutorialVideos')
                    .doc(doc.id)
                    .update(payload);
              } else {
                payload['createdAt'] = FieldValue.serverTimestamp();
                await FirebaseFirestore.instance
                    .collection('tutorialVideos')
                    .add(payload);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  const _VideoCard({
    required this.docId,
    required this.data,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_display_rounded,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if ((data['description'] as String? ?? '').isNotEmpty)
                  Text(
                    data['description'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                Text(
                  data['url'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Video?'),
        content: Text('Delete "${data['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('tutorialVideos')
                  .doc(docId)
                  .delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
