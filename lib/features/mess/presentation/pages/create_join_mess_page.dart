import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firebase_mess_service.dart';

class CreateJoinMessPage extends StatefulWidget {
  const CreateJoinMessPage({super.key});
  @override
  State<CreateJoinMessPage> createState() => _CreateJoinMessPageState();
}

class _CreateJoinMessPageState extends State<CreateJoinMessPage> {
  final _joinFormKey = GlobalKey<FormState>();
  final _createFormKey = GlobalKey<FormState>();
  final _messIdController = TextEditingController();
  final _messNameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedDistrict;
  String? _selectedDivision;
  bool _isLoading = false;

  List<Map<String, dynamic>> _joinedMesses = [];
  List<Map<String, dynamic>> _invitations = [];
  bool _loadingJoined = true;

  static const int _maxMesses = 3;

  static const Map<String, List<String>> _divisionDistricts = {
    'Barisal': [
      'Barguna',
      'Barisal',
      'Bhola',
      'Jhalokati',
      'Patuakhali',
      'Pirojpur',
    ],
    'Chittagong': [
      'Bandarban',
      'Brahmanbaria',
      'Chandpur',
      'Chattogram',
      "Cox's Bazar",
      'Cumilla',
      'Feni',
      'Khagrachhari',
      'Lakshmipur',
      'Noakhali',
      'Rangamati',
    ],
    'Dhaka': [
      'Dhaka',
      'Faridpur',
      'Gazipur',
      'Gopalganj',
      'Kishoreganj',
      'Madaripur',
      'Manikganj',
      'Munshiganj',
      'Narayanganj',
      'Narsingdi',
      'Rajbari',
      'Shariatpur',
      'Tangail',
    ],
    'Khulna': [
      'Bagerhat',
      'Chuadanga',
      'Jessore',
      'Jhenaidah',
      'Khulna',
      'Kushtia',
      'Magura',
      'Meherpur',
      'Narail',
      'Satkhira',
    ],
    'Mymensingh': ['Jamalpur', 'Mymensingh', 'Netrokona', 'Sherpur'],
    'Rajshahi': [
      'Bogura',
      'Chapainawabganj',
      'Joypurhat',
      'Naogaon',
      'Natore',
      'Pabna',
      'Rajshahi',
      'Sirajganj',
    ],
    'Rangpur': [
      'Dinajpur',
      'Gaibandha',
      'Kurigram',
      'Lalmonirhat',
      'Nilphamari',
      'Panchagarh',
      'Rangpur',
      'Thakurgaon',
    ],
    'Sylhet': ['Habiganj', 'Moulvibazar', 'Sunamganj', 'Sylhet'],
  };

  List<String> get _filteredDistricts =>
      _selectedDivision == null ? [] : _divisionDistricts[_selectedDivision]!;

  bool get _atMaxLimit => _joinedMesses.length >= _maxMesses;

  @override
  void initState() {
    super.initState();
    _loadJoinedMesses();
    _loadInvitations();
  }

  @override
  void dispose() {
    _messIdController.dispose();
    _messNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadJoinedMesses() async {
    setState(() => _loadingJoined = true);
    try {
      final ids = await FirebaseMessService.getJoinedMessIds();
      final messes = <Map<String, dynamic>>[];
      for (final id in ids) {
        final data = await FirebaseMessService.getMessDataById(id);
        if (data != null) messes.add(data);
      }
      if (mounted)
        setState(() {
          _joinedMesses = messes;
          _loadingJoined = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingJoined = false);
    }
  }

  Future<void> _loadInvitations() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('invitations')
          .where('status', isEqualTo: 'pending')
          .get();
      if (mounted) {
        setState(() {
          _invitations = snap.docs
              .map((d) => {...d.data(), 'id': d.id})
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Messes'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await FirebaseAuth.instance.signOut();
                if (mounted) context.go('/');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_invitations.isNotEmpty) ...[
              _buildInvitationsSection(),
              const SizedBox(height: 16),
            ],
            _buildAlreadyJoinedSection(),
            const SizedBox(height: 24),
            _buildJoinMessSection(),
            const SizedBox(height: 16),
            _buildCreateMessSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Invitations Section ───────────────────────────────────────────────────
  Widget _buildInvitationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mail_outline, color: Colors.orange, size: 18),
            const SizedBox(width: 6),
            Text(
              'Pending Invitations (${_invitations.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._invitations.map((inv) => _buildInvitationCard(inv)),
      ],
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> inv) {
    final messName = inv['messName'] as String? ?? 'Unknown Mess';
    final managerName = inv['managerName'] as String? ?? 'Manager';
    final invId = inv['id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have been invited to join',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '"$messName"',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'from manager $managerName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectInvitation(invId, messName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _atMaxLimit ? null : () => _acceptInvitation(inv),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          if (_atMaxLimit)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Leave a mess first to accept this invitation.',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(Map<String, dynamic> inv) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final messId = inv['messId'] as String? ?? '';
    final invId = inv['id'] as String? ?? '';
    final memberName = inv['memberName'] as String? ?? '';
    final memberPhone = inv['memberPhone'] as String? ?? '';
    final initialBalance = (inv['initialBalance'] as num?)?.toDouble() ?? 0;

    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Add to members subcollection
      batch.set(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('members')
            .doc(uid),
        {
          'name': memberName,
          'phone': memberPhone,
          'balance': initialBalance,
          'isActive': true,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      // Mark invitation as accepted
      batch.update(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('invitations')
            .doc(invId),
        {'status': 'accepted'},
      );

      await batch.commit();

      // Update messIds
      final joined = await FirebaseMessService.getJoinedMessIds();
      if (!joined.contains(messId)) {
        final newIds = [...joined, messId];
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'messIds': newIds,
          'messId': messId,
        });
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have joined the mess!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadJoinedMesses();
        _loadInvitations();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _rejectInvitation(String invId, String messName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('invitations')
          .doc(invId)
          .update({'status': 'rejected'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation to "$messName" rejected.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadInvitations();
      }
    } catch (_) {}
  }

  // ── Already Joined Section ────────────────────────────────────────────────
  Widget _buildAlreadyJoinedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Already Joined',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            if (!_loadingJoined)
              Text(
                '${_joinedMesses.length}/$_maxMesses',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        if (!_loadingJoined) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _joinedMesses.length / _maxMesses,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _atMaxLimit ? Colors.red : AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _atMaxLimit
                ? 'Maximum limit reached. Leave a mess to join/create a new one.'
                : 'You have joined ${_joinedMesses.length}/$_maxMesses messes',
            style: TextStyle(
              fontSize: 12,
              color: _atMaxLimit ? Colors.red : Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_loadingJoined)
          const Center(child: CircularProgressIndicator())
        else if (_joinedMesses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 40,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Text(
                  'Not joined any messes yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...(_joinedMesses.map((mess) => _buildMessCard(mess))),
      ],
    );
  }

  Widget _buildMessCard(Map<String, dynamic> mess) {
    final messId = mess['id'] as String? ?? '';
    final name = mess['name'] as String? ?? 'Unknown Mess';
    final setupComplete = mess['setupComplete'] as bool? ?? false;
    final subscription = mess['subscription'] as String? ?? 'free';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _enterMess(messId, setupComplete),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        messId,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subscription.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _confirmLeave(messId, name),
                      child: Text(
                        'Leave',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _enterMess(String messId, bool setupComplete) async {
    // Set this as active mess
    await _setActiveMess(messId);
    if (!mounted) return;
    context.go(setupComplete ? AppRouter.dashboard : AppRouter.messSettings);
  }

  Future<void> _setActiveMess(String messId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'messId': messId,
    });
  }

  void _confirmLeave(String messId, String messName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Mess?'),
        content: Text('Are you sure you want to leave "$messName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final result = await FirebaseMessService.leaveMessById(messId);
              setState(() => _isLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                );
                if (result['success'] == true) _loadJoinedMesses();
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Join Section ──────────────────────────────────────────────────────────
  Widget _buildJoinMessSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _joinFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Existing Mess',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messIdController,
                decoration: InputDecoration(
                  labelText: 'Enter Mess ID',
                  hintText: 'M00000',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Get the Mess ID from your mess manager.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _atMaxLimit)
                      ? null
                      : _handleJoinMess,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Join Mess'),
                ),
              ),
              if (_atMaxLimit) ...[
                const SizedBox(height: 8),
                _maxLimitWarning(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Create Section ────────────────────────────────────────────────────────
  Widget _buildCreateMessSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _createFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Mess',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messNameController,
                decoration: const InputDecoration(labelText: 'Mess Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Mess Address'),
                maxLines: 1,
                textInputAction: TextInputAction.done,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedDivision,
                decoration: const InputDecoration(labelText: 'Mess Division'),
                items: _divisionDistricts.keys
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedDivision = v;
                  _selectedDistrict = null;
                }),
                validator: (v) => v == null ? 'Select a division' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(labelText: 'Mess District'),
                items: _filteredDistricts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: _selectedDivision == null
                    ? null
                    : (v) => setState(() => _selectedDistrict = v),
                validator: (v) => v == null ? 'Select a district' : null,
                hint: Text(
                  _selectedDivision == null
                      ? 'Select division first'
                      : 'Select district',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _atMaxLimit)
                      ? null
                      : _handleCreateMess,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Create Mess'),
                ),
              ),
              if (_atMaxLimit) ...[
                const SizedBox(height: 8),
                _maxLimitWarning(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _maxLimitWarning() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'You have reached the maximum limit of $_maxMesses messes. Leave a mess to join or create a new one.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
          ),
        ),
      ],
    ),
  );

  Future<void> _handleJoinMess() async {
    if (!_joinFormKey.currentState!.validate()) return;
    if (_atMaxLimit) return;
    setState(() => _isLoading = true);
    final result = await FirebaseMessService.joinMess(
      messId: _messIdController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      _messIdController.clear();
      _loadJoinedMesses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleCreateMess() async {
    if (!_createFormKey.currentState!.validate()) return;
    if (_atMaxLimit) return;
    setState(() => _isLoading = true);
    final result = await FirebaseMessService.createMess(
      messName: _messNameController.text.trim(),
      address: _addressController.text.trim(),
      district: _selectedDistrict!,
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result['success']) {
      _showSuccessDialog(result['messId']);
      _loadJoinedMesses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(String messId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('Mess Created!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryGreen),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Mess ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            messId,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: AppColors.primaryGreen,
                          ),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: messId),
                            );
                            if (ctx.mounted)
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Mess ID copied!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Next steps to set up your mess:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              _setupStep(
                '1',
                'Meal Entry System',
                'Choose Manual or Auto meal entry mode from Mess Setting',
                Icons.restaurant_menu,
              ),
              _setupStep(
                '2',
                'Add Members',
                'Add members or ask them to join using your Mess ID',
                Icons.people,
              ),
              _setupStep(
                '3',
                'Deposit',
                'Add deposit from mess members',
                Icons.account_balance_wallet,
              ),
              _setupStep(
                '4',
                'Expense Entry',
                'Record your bazar or other expenses',
                Icons.receipt_long,
              ),
              _setupStep(
                '5',
                'Bazar Schedule',
                'Set up who does bazar and when',
                Icons.shopping_basket,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.settings, color: Colors.white, size: 18),
            label: const Text(
              'Go to Mess Setting',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRouter.messSettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _setupStep(
    String number,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Icon(icon, size: 18, color: AppColors.primaryGreen),
        ],
      ),
    );
  }
}
