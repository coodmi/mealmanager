import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_card.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          _KpiGrid(),
          const SizedBox(height: 28),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _RecentUsers(),
        ],
      ),
    );
  }
}

// ─── KPI Grid ──────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('messes').snapshots(),
          builder: (context, messSnap) {
            final totalUsers = usersSnap.data?.docs.length ?? 0;
            final totalMess = messSnap.data?.docs.length ?? 0;

            final now = DateTime.now();
            final last7 = now.subtract(const Duration(days: 7));
            final last30 = now.subtract(const Duration(days: 30));

            int newLast7 = 0, newLast30 = 0, premiumMess = 0;
            if (usersSnap.hasData) {
              for (final doc in usersSnap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final ts = d['createdAt'] as Timestamp?;
                if (ts != null) {
                  if (ts.toDate().isAfter(last7)) newLast7++;
                  if (ts.toDate().isAfter(last30)) newLast30++;
                }
              }
            }
            if (messSnap.hasData) {
              for (final doc in messSnap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                if (d['isPremium'] == true) premiumMess++;
              }
            }

            final kpis = [
              _KpiData(
                'Total Users',
                '$totalUsers',
                Icons.people_alt_rounded,
                Colors.blue,
              ),
              _KpiData(
                'Total Mess',
                '$totalMess',
                Icons.home_work_rounded,
                AppColors.primaryGreen,
              ),
              _KpiData(
                'Premium Mess',
                '$premiumMess',
                Icons.workspace_premium_rounded,
                Colors.amber.shade700,
              ),
              _KpiData(
                'Free Mess',
                '${totalMess - premiumMess}',
                Icons.home_outlined,
                Colors.teal,
              ),
              _KpiData(
                'New (7 days)',
                '$newLast7',
                Icons.person_add_rounded,
                Colors.purple,
              ),
              _KpiData(
                'New (30 days)',
                '$newLast30',
                Icons.trending_up_rounded,
                Colors.deepOrange,
              ),
            ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 600
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: kpis.length,
                  itemBuilder: (_, i) => _KpiCard(data: kpis[i]),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _KpiData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: data.color,
                ),
              ),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Recent Users ──────────────────────────────────────────────────────────
class _RecentUsers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .limit(8)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recently Registered Users',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final ts = d['createdAt'] as Timestamp?;
                final date = ts != null
                    ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                    : '—';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.15,
                    ),
                    child: Text(
                      (d['name'] as String? ?? '?').isNotEmpty
                          ? (d['name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    d['name'] as String? ?? '—',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    d['email'] as String? ?? d['mobile'] as String? ?? '—',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  trailing: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
