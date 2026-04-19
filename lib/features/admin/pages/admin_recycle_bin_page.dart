import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_card.dart';

class AdminRecycleBinPage extends StatelessWidget {
  const AdminRecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deleted_messes')
            .orderBy('deletedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorWidget(message: snap.error.toString(), onRetry: () {});
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_sweep_rounded,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Recycle Bin is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No deleted messes found.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _RecycleBinCard(messId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}

// ─── Recycle Bin Card ──────────────────────────────────────────────────────
class _RecycleBinCard extends StatefulWidget {
  final String messId;
  final Map<String, dynamic> data;

  const _RecycleBinCard({required this.messId, required this.data});

  @override
  State<_RecycleBinCard> createState() => _RecycleBinCardState();
}

class _RecycleBinCardState extends State<_RecycleBinCard> {
  bool _isRestoring = false;

  int _daysRemaining(Timestamp deletedAt) {
    final diff = DateTime.now().difference(deletedAt.toDate()).inDays;
    return 30 - diff;
  }

  String _formatDate(Timestamp ts) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
  }

  Future<void> _restore(BuildContext context) async {
    setState(() => _isRestoring = true);
    try {
      await FirebaseFunctions.instance.httpsCallable('restoreMess').call({
        'messId': widget.messId,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mess restored successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] as String? ?? 'Unnamed Mess';
    final deletedBy = widget.data['deletedBy'] as String? ?? '—';
    final deletionReason = widget.data['deletionReason'] as String? ?? '—';
    final deletedAtTs = widget.data['deletedAt'] as Timestamp?;

    final daysRemaining = deletedAtTs != null ? _daysRemaining(deletedAtTs) : 0;
    final deletedAtFormatted = deletedAtTs != null
        ? _formatDate(deletedAtTs)
        : '—';

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (daysRemaining > 0)
                _RestoreButton(
                  isRestoring: _isRestoring,
                  onRestore: () => _restore(context),
                )
              else
                const Chip(
                  label: Text(
                    'Expired',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Details grid
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _InfoRow(label: 'Mess ID', value: widget.messId),
              _InfoRow(label: 'Deleted At', value: deletedAtFormatted),
              _InfoRow(label: 'Deleted By', value: deletedBy),
              _InfoRow(label: 'Reason', value: _formatReason(deletionReason)),
              _InfoRow(
                label: 'Days Remaining',
                value: daysRemaining > 0
                    ? '$daysRemaining day${daysRemaining == 1 ? '' : 's'}'
                    : 'Expired',
                valueColor: daysRemaining > 0
                    ? (daysRemaining <= 7
                          ? Colors.orange
                          : AppColors.primaryGreen)
                    : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatReason(String reason) {
    switch (reason) {
      case 'manager_request':
        return 'Manager Request';
      case 'inactivity':
        return 'Inactivity';
      default:
        return reason;
    }
  }
}

// ─── Restore Button ────────────────────────────────────────────────────────
class _RestoreButton extends StatelessWidget {
  final bool isRestoring;
  final VoidCallback onRestore;

  const _RestoreButton({required this.isRestoring, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isRestoring ? null : onRestore,
      icon: isRestoring
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.restore_rounded, size: 16),
      label: Text(isRestoring ? 'Restoring...' : 'Restore'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Info Row ──────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

// ─── Error Widget ──────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            'Failed to load recycle bin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
