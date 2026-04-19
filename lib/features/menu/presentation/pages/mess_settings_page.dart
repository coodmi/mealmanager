import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../member/presentation/pages/member_page.dart';
import 'subscription_page.dart';

class MessSettingsPage extends StatefulWidget {
  const MessSettingsPage({super.key});

  @override
  State<MessSettingsPage> createState() => _MessSettingsPageState();
}

class _MessSettingsPageState extends State<MessSettingsPage> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _messId = '';
  String _plan = 'free';
  int _memberCount = 0;
  String _mealEntryMode = 'manual';
  bool _isManager = false;
  bool _isFirstSetup = false; // true when coming from mess creation

  @override
  void initState() {
    super.initState();
    _loadMessData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      user ??= await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final messId = userDoc.data()?['messId'] as String? ?? '';
      final role = userDoc.data()?['role'] as String? ?? 'member';
      if (messId.isEmpty) return;

      final messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .get();
      final data = messDoc.data() ?? {};
      final setupComplete = data['setupComplete'] as bool? ?? false;

      final membersSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('members')
          .get();

      if (mounted) {
        setState(() {
          _messId = messId;
          _nameCtrl.text = data['name'] as String? ?? '';
          _addressCtrl.text = data['address'] as String? ?? '';
          _plan = data['subscription'] as String? ?? 'free';
          _mealEntryMode = data['mealEntryMode'] as String? ?? 'manual';
          _memberCount = membersSnap.docs.length;
          _isManager = role == 'manager' || role == 'admin';
          _isFirstSetup = !setupComplete;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_isManager) {
      showNoPermissionSnack(context);
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mess name cannot be empty'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .update({
            'name': _nameCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'setupComplete': true,
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // If first-time setup, go to dashboard
        if (_isFirstSetup) {
          context.go(AppRouter.dashboard);
        }
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _setMealEntryMode(String mode) async {
    if (!_isManager) {
      showNoPermissionSnack(context);
      return;
    }
    setState(() => _mealEntryMode = mode);
    try {
      await FirebaseFirestore.instance.collection('messes').doc(_messId).update(
        {'mealEntryMode': mode},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Meal entry set to ${mode == 'auto' ? 'Auto' : 'Manual'}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isFirstSetup ? 'Setup Your Mess' : 'Mess Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
        automaticallyImplyLeading: !_isFirstSetup,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildMealEntrySection(),
                  const SizedBox(height: 16),
                  _buildEditForm(),
                  const SizedBox(height: 16),
                  _buildMessIdCard(),
                  const SizedBox(height: 16),
                  _buildQuickLinks(),
                  if (_isManager) ...[
                    const SizedBox(height: 16),
                    _buildDangerZone(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.buttonGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isEmpty ? 'Your Mess' : _nameCtrl.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: $_messId',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _infoBadge('$_memberCount Members'),
                    const SizedBox(width: 8),
                    _infoBadge(_plan.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealEntrySection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Meal Entry System',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how meals are recorded each day.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _modeOption(
                  label: 'Manual',
                  subtitle: 'Members enter meals themselves',
                  icon: Icons.edit_note,
                  selected: _mealEntryMode == 'manual',
                  onTap: () => _setMealEntryMode('manual'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modeOption(
                  label: 'Auto',
                  subtitle: 'Meals counted automatically daily',
                  icon: Icons.auto_mode,
                  selected: _mealEntryMode == 'auto',
                  onTap: () => _setMealEntryMode('auto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryGreen : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.primaryGreen : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryGreen,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mess Information',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _field(_nameCtrl, 'Mess Name', Icons.home_work),
          const SizedBox(height: 14),
          _field(_addressCtrl, 'Address (optional)', Icons.location_on),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isFirstSetup ? 'Save & Go to Dashboard' : 'Save Changes',
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

  Widget _buildMessIdCard() {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code, color: Colors.blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mess ID',
                  style: TextStyle(fontSize: 13, color: AppColors.textLight),
                ),
                Text(
                  _messId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.blue),
            tooltip: 'Copy ID',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _messId));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mess ID copied!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Setup & Management',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _linkTile(
            icon: Icons.people,
            color: Colors.blue,
            title: 'Members Setup',
            subtitle: 'Add, remove or manage members',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberPage()),
            ),
          ),
          const Divider(height: 1),
          _linkTile(
            icon: Icons.shopping_basket,
            color: Colors.orange,
            title: 'Bazar Schedule',
            subtitle: 'Set up bazar duty rotation',
            onTap: () => _showBazarScheduleDialog(),
          ),
          const Divider(height: 1),
          _linkTile(
            icon: Icons.workspace_premium,
            color: Colors.amber.shade700,
            title: 'Subscription',
            subtitle: 'Manage your mess plan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionPage()),
            ),
          ),
          const Divider(height: 1),
          _linkTile(
            icon: Icons.calendar_month,
            color: Colors.teal,
            title: 'Month Close',
            subtitle: 'Close current month and generate summary',
            onTap: () => _confirmMonthClose(),
          ),
          if (_isManager) ...[
            const Divider(height: 1),
            _linkTile(
              icon: Icons.swap_horiz,
              color: Colors.deepPurple,
              title: 'Transfer Managership',
              subtitle: 'Hand over manager role to another member',
              onTap: () => _showTransferManagership(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text(
                'Delete Mess',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _confirmDeleteMess(),
            ),
          ),
        ],
      ),
    );
  }

  void _showBazarScheduleDialog() async {
    if (!_isManager) {
      showNoPermissionSnack(context);
      return;
    }
    // Load current schedule from Firestore
    final messDoc = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .get();
    final existing = List<String>.from(messDoc.data()?['bazarSchedule'] ?? []);

    final membersSnap = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('members')
        .get();

    if (!mounted) return;

    final selected = List<String>.from(existing);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Bazar Schedule'),
          content: SizedBox(
            width: double.maxFinite,
            child: membersSnap.docs.isEmpty
                ? const Text('No members found. Add members first.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select members for bazar duty rotation:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...membersSnap.docs.map((doc) {
                        final name =
                            (doc.data())['name'] as String? ?? 'Unknown';
                        final isChecked = selected.contains(doc.id);
                        return CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          title: Text(name),
                          activeColor: AppColors.primaryGreen,
                          onChanged: (v) => setS(() {
                            if (v == true)
                              selected.add(doc.id);
                            else
                              selected.remove(doc.id);
                          }),
                        );
                      }),
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
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('messes')
                    .doc(_messId)
                    .update({'bazarSchedule': selected});
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bazar schedule saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmMonthClose() {
    if (!_isManager) {
      showNoPermissionSnack(context);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Close Month?'),
        content: const Text(
          'This will finalize all meals and expenses for the current month and generate a summary report. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doMonthClose();
            },
            child: const Text(
              'Close Month',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doMonthClose() async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Gather totals for the month
      final mealsSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('meals')
          .where('monthKey', isEqualTo: monthKey)
          .get();

      final expSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('expenses')
          .where('monthKey', isEqualTo: monthKey)
          .get();

      double totalExpense = 0;
      for (final d in expSnap.docs) {
        totalExpense += (d.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      final totalMeals = mealsSnap.docs.length;
      final mealRate = totalMeals > 0 ? totalExpense / totalMeals : 0.0;

      // Save month summary
      await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('monthSummaries')
          .doc(monthKey)
          .set({
            'monthKey': monthKey,
            'totalMeals': totalMeals,
            'totalExpense': totalExpense,
            'mealRate': mealRate,
            'closedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Month $monthKey closed! Meal rate: ৳${mealRate.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.teal,
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

  void _showTransferManagership() async {
    final membersSnap = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('members')
        .get();

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final otherMembers = membersSnap.docs
        .where((d) => d.id != user?.uid)
        .toList();

    if (otherMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other members to transfer to.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Transfer Managership'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select the member to become the new manager:'),
              const SizedBox(height: 12),
              ...otherMembers.map((doc) {
                final name = (doc.data())['name'] as String? ?? 'Unknown';
                return RadioListTile<String>(
                  value: doc.id,
                  groupValue: selectedId,
                  title: Text(name),
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) => setS(() => selectedId = v),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedId != null
                    ? Colors.deepPurple
                    : Colors.grey,
              ),
              onPressed: selectedId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _doTransferManagership(selectedId!);
                    },
              child: const Text(
                'Transfer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doTransferManagership(String newManagerId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final batch = FirebaseFirestore.instance.batch();

      // New manager
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(newManagerId),
        {'role': 'manager'},
      );
      // Old manager becomes member
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {'role': 'member'},
      );
      // Update mess managerId
      batch.update(
        FirebaseFirestore.instance.collection('messes').doc(_messId),
        {'managerId': newManagerId},
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Managership transferred!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // go back from settings
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDeleteMess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Mess?', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Your mess will be moved to the recycle bin. If deleted by the Manager, users may contact support. Deleted mess can be recovered within 30 days only after deletion from Admin Panel > Mess > Recycle Bin. After 30 days, data recovery is not possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doDeleteMess();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _doDeleteMess() async {
    try {
      await FirebaseFunctions.instance.httpsCallable('softDeleteMess').call({
        'messId': _messId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mess deleted. Recoverable within 30 days.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/create-join-mess');
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _linkTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
