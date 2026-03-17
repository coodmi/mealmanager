import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_card.dart';

class AdminLogsPage extends StatefulWidget {
  const AdminLogsPage({super.key});

  @override
  State<AdminLogsPage> createState() => _AdminLogsPageState();
}

class _AdminLogsPageState extends State<AdminLogsPage> {
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
                hintText: 'Search by name, email, phone, or user ID...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AdminCard(
              padding: EdgeInsets.zero,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('userLogs')
                    .orderBy('timestamp', descending: true)
                    .limit(200)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  var docs = snap.data!.docs;

                  if (_search.isNotEmpty) {
                    docs = docs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final name = (d['userName'] as String? ?? '')
                          .toLowerCase();
                      final email = (d['userEmail'] as String? ?? '')
                          .toLowerCase();
                      final uid = (d['userId'] as String? ?? '').toLowerCase();
                      final mobile = (d['userMobile'] as String? ?? '')
                          .toLowerCase();
                      return name.contains(_search) ||
                          email.contains(_search) ||
                          uid.contains(_search) ||
                          mobile.contains(_search);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No logs found',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
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
                            _th('Action', flex: 4),
                            _th('Details', flex: 4),
                            _th('Time', flex: 2),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            final ts = d['timestamp'] as Timestamp?;
                            final dt = ts?.toDate();
                            final timeStr = dt != null
                                ? '${dt.day}/${dt.month}/${dt.year}\n${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                                : '—';
                            final action = d['action'] as String? ?? '—';
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d['userName'] as String? ?? '—',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          d['userEmail'] as String? ??
                                              d['userMobile'] as String? ??
                                              '—',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: _ActionChip(action: action),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      d['details'] as String? ?? '—',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      timeStr,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${docs.length} logs',
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

  Widget _th(String label, {int flex = 1}) => Expanded(
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

class _ActionChip extends StatelessWidget {
  final String action;
  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (action.contains('delete') || action.contains('remove')) {
      color = Colors.red;
    } else if (action.contains('create') ||
        action.contains('add') ||
        action.contains('join')) {
      color = Colors.green;
    } else if (action.contains('update') ||
        action.contains('edit') ||
        action.contains('change')) {
      color = Colors.blue;
    } else if (action.contains('login') || action.contains('logout')) {
      color = Colors.purple;
    } else {
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        action,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
