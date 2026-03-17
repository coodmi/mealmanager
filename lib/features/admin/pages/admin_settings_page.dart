import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_card.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
            tabs: const [
              Tab(text: 'App Settings'),
              Tab(text: 'Pricing / Plans'),
              Tab(text: 'Admin Roles'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_AppSettingsTab(), _PricingTab(), _AdminRolesTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Settings ──────────────────────────────────────────────────────────
class _AppSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appSettings')
          .doc('config')
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        return SingleChildScrollView(
          child: AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feature Toggles',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _ToggleRow(
                  label: 'Subscription Feature',
                  subtitle: 'Enable/disable premium subscriptions',
                  icon: Icons.workspace_premium_rounded,
                  color: Colors.amber,
                  value: data['subscriptionEnabled'] != false,
                  onChanged: (v) => _update('subscriptionEnabled', v),
                ),
                _ToggleRow(
                  label: 'Ads Feature',
                  subtitle: 'Show/hide ads in the app',
                  icon: Icons.ad_units_rounded,
                  color: Colors.blue,
                  value: data['adsEnabled'] == true,
                  onChanged: (v) => _update('adsEnabled', v),
                ),
                _ToggleRow(
                  label: 'Donation Feature',
                  subtitle: 'Enable/disable donation button',
                  icon: Icons.favorite_rounded,
                  color: Colors.pink,
                  value: data['donationEnabled'] != false,
                  onChanged: (v) => _update('donationEnabled', v),
                ),
                const Divider(height: 32),
                const Text(
                  'Force Update',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Force App Update',
                  subtitle: 'Force users to update the app',
                  icon: Icons.system_update_rounded,
                  color: Colors.red,
                  value: data['forceUpdate'] == true,
                  onChanged: (v) => _update('forceUpdate', v),
                ),
                const SizedBox(height: 12),
                _TextFieldSetting(
                  label: 'Minimum App Version',
                  value: data['minVersion'] as String? ?? '1.0.0',
                  onSave: (v) => _update('minVersion', v),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _update(String key, dynamic value) async {
    await FirebaseFirestore.instance
        .collection('appSettings')
        .doc('config')
        .set({key: value}, SetOptions(merge: true));
  }
}

class _ToggleRow extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _TextFieldSetting extends StatefulWidget {
  final String label, value;
  final ValueChanged<String> onSave;
  const _TextFieldSetting({
    required this.label,
    required this.value,
    required this.onSave,
  });

  @override
  State<_TextFieldSetting> createState() => _TextFieldSettingState();
}

class _TextFieldSettingState extends State<_TextFieldSetting> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              labelText: widget.label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          onPressed: () => widget.onSave(_ctrl.text.trim()),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ─── Pricing Tab ───────────────────────────────────────────────────────────
class _PricingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subscriptionPlans')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                onPressed: () => _addPlan(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text(
                  'Add Plan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: docs.length,
                itemBuilder: (_, i) => _PlanCard(
                  docId: docs[i].id,
                  data: docs[i].data() as Map<String, dynamic>,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addPlan(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Subscription Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Plan Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (BDT)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('subscriptionPlans')
                    .add({
                      'name': nameCtrl.text.trim(),
                      'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
                      'isActive': true,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _PlanCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '—';
    final price = data['price'] ?? 0;
    final isActive = data['isActive'] != false;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (v) => FirebaseFirestore.instance
                    .collection('subscriptionPlans')
                    .doc(docId)
                    .update({'isActive': v}),
                activeColor: AppColors.primaryGreen,
              ),
            ],
          ),
          const Spacer(),
          Text(
            '৳$price / month',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => FirebaseFirestore.instance
                    .collection('subscriptionPlans')
                    .doc(docId)
                    .delete(),
                child: const Text('Delete', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Admin Roles Tab ───────────────────────────────────────────────────────
class _AdminRolesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(
            'role',
            whereIn: [
              'superAdmin',
              'systemAdmin',
              'supportAdmin',
              'contentAdmin',
              'manager',
            ],
          )
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                onPressed: () => _promoteUser(context),
                icon: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text(
                  'Add Admin',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AdminCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final role = d['role'] as String? ?? '—';
                    final isSuperAdmin =
                        role == 'superAdmin' || role == 'manager';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryGreen.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          (d['name'] as String? ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        d['name'] as String? ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        d['email'] as String? ?? '—',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButton<String>(
                            value: role,
                            underline: const SizedBox(),
                            items:
                                [
                                      'member',
                                      'manager',
                                      'supportAdmin',
                                      'contentAdmin',
                                      'systemAdmin',
                                      'superAdmin',
                                    ]
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(
                                          r,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (newRole) async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(docs[i].id)
                                  .update({'role': newRole});
                            },
                          ),
                          if (!isSuperAdmin) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(docs[i].id)
                                    .update({'role': 'member'});
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _promoteUser(BuildContext context) {
    final emailCtrl = TextEditingController();
    String selectedRole = 'supportAdmin';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Promote User to Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'User Email'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items:
                    [
                          'supportAdmin',
                          'contentAdmin',
                          'systemAdmin',
                          'superAdmin',
                        ]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (v) => setS(() => selectedRole = v!),
              ),
            ],
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
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                final query = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();
                if (query.docs.isNotEmpty) {
                  await query.docs.first.reference.update({
                    'role': selectedRole,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text(
                'Promote',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
