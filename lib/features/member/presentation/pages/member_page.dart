import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../menu/presentation/pages/subscription_page.dart';
import 'member_details_page.dart';

class MemberPage extends StatefulWidget {
  final bool embedded;
  const MemberPage({super.key, this.embedded = false});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  String _messId = '';
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _loadMessId();
  }

  Future<void> _loadMessId() async {
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

      if (mounted) {
        setState(() {
          _messId = messId;
          _isManager = role == 'manager' || role == 'admin';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _messId.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
        ),
      ],
    );

    final fab = _isManager
        ? FloatingActionButton.extended(
            onPressed: _showAddMemberDialog,
            backgroundColor: AppColors.primaryGreen,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Add Member',
              style: TextStyle(color: Colors.white),
            ),
          )
        : null;

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          if (fab != null) Positioned(bottom: 16, right: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: body,
      floatingActionButton: fab,
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryGreen,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your mess members',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              if (_isManager)
                IconButton(
                  icon: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _showAddMemberDialog,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isManager) return _buildMembersList();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('joinRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        final pendingDocs = snap.data?.docs ?? [];
        if (pendingDocs.isEmpty) return _buildMembersList();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // Pending requests banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pending_actions,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pending Requests (${pendingDocs.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...pendingDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] as String? ?? 'Unknown';
                    final phone = data['phone'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.orange.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Approve
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            ),
                            tooltip: 'Approve',
                            onPressed: () => _approveRequest(doc.id, data),
                          ),
                          // Reject
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 28,
                            ),
                            tooltip: 'Reject',
                            onPressed: () => _rejectRequest(doc.id),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Members list below
            _buildMembersList(),
          ],
        );
      },
    );
  }

  Future<void> _approveRequest(String userId, Map<String, dynamic> data) async {
    try {
      final name = data['name'] as String? ?? 'Member';
      final phone = data['phone'] as String? ?? '';
      final batch = FirebaseFirestore.instance.batch();

      // Add to members subcollection
      final memberRef = FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('members')
          .doc(userId);
      batch.set(memberRef, {
        'name': name,
        'phone': phone,
        'balance': 0,
        'isActive': true,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Update join request status
      final reqRef = FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('joinRequests')
          .doc(userId);
      batch.update(reqRef, {'status': 'approved'});

      // Update user's joinStatus → approved
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      batch.update(userRef, {'joinStatus': 'approved'});

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name approved!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  Future<void> _rejectRequest(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Delete join request
      batch.delete(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(_messId)
            .collection('joinRequests')
            .doc(userId),
      );

      // Clear user's messId and joinStatus
      batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
        'messId': '',
        'joinStatus': 'rejected',
        'role': 'member',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  Widget _buildMembersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No members yet',
                  style: TextStyle(fontSize: 16, color: AppColors.textLight),
                ),
                if (_isManager) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                    ),
                    onPressed: _showAddMemberDialog,
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      'Add First Member',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;
        final active = docs.where((d) {
          final val = d.data() is Map ? (d.data() as Map)['isActive'] : null;
          return val != false;
        }).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Total',
                    '$total',
                    Icons.people,
                    AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Active',
                    '$active',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Inactive',
                    '${total - active}',
                    Icons.cancel,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _memberCard(doc.id, data);
            }),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(String docId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'Unknown';
    final phone = data['phone'] as String? ?? '';
    final balance = (data['balance'] as num?)?.toDouble() ?? 0;
    final isActive = data['isActive'] != false; // null or true → active
    final initials = name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();
    final isNeg = balance < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_isManager) {
              _showMemberOptions(docId, data);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MemberDetailsPage(memberId: docId, memberName: name),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryGreen.withValues(
                    alpha: 0.12,
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 13,
                            color: isNeg ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BDT ${balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isNeg ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isManager)
                  const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemberOptions(String docId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'Member';
    final isActive = data['isActive'] != false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _optionTile(
              ctx,
              Icons.person_outline,
              'View Details',
              AppColors.primaryGreen,
              () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MemberDetailsPage(memberId: docId, memberName: name),
                  ),
                );
              },
            ),
            _optionTile(
              ctx,
              Icons.toggle_on_rounded,
              isActive ? 'Mark Inactive' : 'Mark Active',
              isActive ? Colors.orange : Colors.green,
              () async {
                await FirebaseFirestore.instance
                    .collection('messes')
                    .doc(_messId)
                    .collection('members')
                    .doc(docId)
                    .update({'isActive': !isActive});
                if (mounted) Navigator.pop(ctx);
              },
            ),
            _optionTile(
              ctx,
              Icons.delete_rounded,
              'Remove Member',
              Colors.red,
              () => _confirmRemove(ctx, docId, name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: color),
      ),
      onTap: onTap,
    );
  }

  void _confirmRemove(BuildContext sheetCtx, String docId, String name) {
    Navigator.pop(sheetCtx);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Member'),
        content: Text('Remove $name from the mess?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('messes')
                  .doc(_messId)
                  .collection('members')
                  .doc(docId)
                  .delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    _checkMemberLimit(() {
      final phoneCtrl = TextEditingController();
      final balanceCtrl = TextEditingController(text: '0');
      Map<String, dynamic>? foundUser;
      bool isSearching = false;
      String searchStatus = '';

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Add New Member'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Phone + Search button
                  Row(
                    children: [
                      Expanded(
                        child: _dialogField(
                          phoneCtrl,
                          'Phone Number',
                          Icons.phone,
                          type: TextInputType.phone,
                          onChanged: (_) {
                            if (searchStatus.isNotEmpty) {
                              setS(() {
                                searchStatus = '';
                                foundUser = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onPressed: isSearching
                              ? null
                              : () async {
                                  final phone = phoneCtrl.text.trim();
                                  if (phone.isEmpty) return;
                                  setS(() {
                                    isSearching = true;
                                    searchStatus = '';
                                    foundUser = null;
                                  });
                                  try {
                                    // Normalize: try exact, also try with/without +88
                                    String phone = phoneCtrl.text.trim();
                                    List<String> variants = [phone];
                                    if (phone.startsWith('0')) {
                                      variants.add('+88$phone');
                                    } else if (phone.startsWith('+88')) {
                                      variants.add(phone.substring(3));
                                    }

                                    QuerySnapshot? snap;
                                    for (final v in variants) {
                                      final result = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .where('mobile', isEqualTo: v)
                                          .limit(1)
                                          .get();
                                      if (result.docs.isNotEmpty) {
                                        snap = result;
                                        break;
                                      }
                                    }
                                    // Fallback: try legacy 'phone' field
                                    if (snap == null || snap.docs.isEmpty) {
                                      snap = await FirebaseFirestore.instance
                                          .collection('users')
                                          .where('phone', isEqualTo: phone)
                                          .limit(1)
                                          .get();
                                    }
                                    if (snap.docs.isEmpty) {
                                      setS(() {
                                        isSearching = false;
                                        searchStatus = 'not_found';
                                      });
                                    } else {
                                      final userData =
                                          Map<String, dynamic>.from(
                                            snap.docs.first.data()
                                                    as Map<String, dynamic>? ??
                                                {},
                                          );
                                      final existingMessId =
                                          userData['messId'] as String? ?? '';
                                      if (existingMessId == _messId) {
                                        setS(() {
                                          isSearching = false;
                                          searchStatus = 'already_member';
                                        });
                                      } else {
                                        setS(() {
                                          isSearching = false;
                                          searchStatus = 'found';
                                          foundUser = {
                                            ...userData,
                                            'uid': snap!.docs.first.id,
                                          };
                                        });
                                      }
                                    }
                                  } catch (_) {
                                    setS(() {
                                      isSearching = false;
                                      searchStatus = 'not_found';
                                    });
                                  }
                                },
                          child: isSearching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Search',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status banners
                  if (searchStatus == 'not_found')
                    _statusBanner(
                      Icons.error_outline,
                      'No account found with this number.\nUser must register on Meal Manager first.',
                      Colors.red,
                    ),
                  if (searchStatus == 'already_member')
                    _statusBanner(
                      Icons.info_outline,
                      'This user is already a member of this mess.',
                      Colors.orange,
                    ),
                  if (searchStatus == 'found' && foundUser != null) ...[
                    _statusBanner(
                      Icons.check_circle_outline,
                      'Account verified: ${foundUser!['name'] ?? 'User'}',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      balanceCtrl,
                      'Initial Balance (BDT)',
                      Icons.wallet,
                      type: TextInputType.number,
                    ),
                  ],
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
                  backgroundColor: searchStatus == 'found'
                      ? AppColors.primaryGreen
                      : Colors.grey.shade300,
                ),
                onPressed: searchStatus == 'found' && foundUser != null
                    ? () async {
                        try {
                          final uid = foundUser!['uid'] as String;
                          final name =
                              foundUser!['name'] as String? ?? 'Member';
                          final phone =
                              foundUser!['mobile'] as String? ??
                              foundUser!['phone'] as String? ??
                              '';
                          final balance =
                              double.tryParse(balanceCtrl.text) ?? 0;

                          // Get manager info
                          final managerDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .get();
                          final managerName =
                              managerDoc.data()?['name'] as String? ??
                              'Manager';

                          // Get mess name
                          final messDoc = await FirebaseFirestore.instance
                              .collection('messes')
                              .doc(_messId)
                              .get();
                          final messName =
                              messDoc.data()?['name'] as String? ?? 'Mess';

                          // Send invitation instead of direct add
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('invitations')
                              .doc(_messId)
                              .set({
                                'messId': _messId,
                                'messName': messName,
                                'managerId':
                                    FirebaseAuth.instance.currentUser?.uid,
                                'managerName': managerName,
                                'initialBalance': balance,
                                'memberName': name,
                                'memberPhone': phone,
                                'status': 'pending',
                                'sentAt': FieldValue.serverTimestamp(),
                              });

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invitation sent to $name!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
                    : null,
                child: const Text(
                  'Add Member',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statusBanner(IconData icon, String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }

  Future<void> _checkMemberLimit(VoidCallback onAllowed) async {
    try {
      final messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .get();
      final plan = messDoc.data()?['subscription'] as String? ?? 'free';
      final snap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('members')
          .get();
      final count = snap.docs.length;
      final limit = plan == 'free'
          ? 3
          : plan == 'lite'
          ? 10
          : plan == 'plus'
          ? 20
          : plan == 'pro'
          ? 30
          : 999;
      if (count >= limit) {
        if (mounted) _showUpgradePrompt();
      } else {
        onAllowed();
      }
    } catch (_) {
      onAllowed();
    }
  }

  void _showUpgradePrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade Required'),
          ],
        ),
        content: const Text(
          'You\'ve reached the member limit for your plan. Upgrade to add more members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionPage()),
              );
            },
            child: const Text('Upgrade', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
