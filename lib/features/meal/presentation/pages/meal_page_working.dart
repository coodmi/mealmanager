import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_mess_service.dart';

class MealPageWorking extends StatefulWidget {
  const MealPageWorking({super.key});

  @override
  State<MealPageWorking> createState() => _MealPageWorkingState();
}

class _MealPageWorkingState extends State<MealPageWorking>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _messId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMessId();
    _addTestMembers();
  }

  Future<void> _loadMessId() async {
    final messId = await FirebaseMessService.getMessId();
    print('Loaded Mess ID: $messId');
    setState(() {
      _messId = messId;
      _isLoading = false;
    });
  }

  Future<void> _addTestMembers() async {
    try {
      final messId = await FirebaseMessService.getMessId();
      if (messId.isEmpty) {
        print('No mess ID found');
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('messId', isEqualTo: messId)
          .get();

      print('Existing members count: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) return;

      print('Adding test members...');

      final members = [
        {'name': 'John Doe', 'phone': '+880 1712-345678', 'balance': 1250.0},
        {'name': 'Jane Smith', 'phone': '+880 1812-345678', 'balance': 2100.0},
        {
          'name': 'Mike Johnson',
          'phone': '+880 1912-345678',
          'balance': -500.0,
        },
        {
          'name': 'Sarah Williams',
          'phone': '+880 1612-345678',
          'balance': 3200.0,
        },
      ];

      final batch = FirebaseFirestore.instance.batch();

      for (final member in members) {
        final docRef = FirebaseFirestore.instance.collection('members').doc();
        batch.set(docRef, {
          'name': member['name'],
          'phone': member['phone'],
          'messId': messId,
          'balance': member['balance'],
          'isActive': true,
          'joinedDate': Timestamp.now(),
        });
      }

      await batch.commit();
      print('Test members added successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test members added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding test members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding test members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildDateSelector(),
          _buildStatsRow(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMealTab('breakfast'),
                _buildMealTab('lunch'),
                _buildMealTab('dinner'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Meal', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryGreen,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meal Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track daily meals',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () => _selectDate(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Breakfast'),
                Tab(text: 'Lunch'),
                Tab(text: 'Dinner'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          Column(
            children: [
              Text(
                DateFormat('EEEE').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('meals')
          .where('messId', isEqualTo: _messId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.all(16),
            height: 100,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final todayMeals = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final mealDate = (data['date'] as Timestamp).toDate();
          return DateFormat('yyyy-MM-dd').format(mealDate) == dateKey;
        }).toList();

        final breakfastCount = todayMeals
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['mealType'] ==
                  'breakfast',
            )
            .length;
        final lunchCount = todayMeals
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['mealType'] == 'lunch',
            )
            .length;
        final dinnerCount = todayMeals
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['mealType'] == 'dinner',
            )
            .length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                (breakfastCount + lunchCount + dinnerCount).toString(),
                Icons.restaurant,
                AppColors.primaryGreen,
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                'Breakfast',
                breakfastCount.toString(),
                Icons.free_breakfast,
                Colors.orange,
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                'Lunch',
                lunchCount.toString(),
                Icons.lunch_dining,
                Colors.blue,
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                'Dinner',
                dinnerCount.toString(),
                Icons.dinner_dining,
                Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildMealTab(String mealType) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('meals')
          .where('messId', isEqualTo: _messId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final filteredMeals = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final mealDate = (data['date'] as Timestamp).toDate();
          return DateFormat('yyyy-MM-dd').format(mealDate) == dateKey &&
              data['mealType'] == mealType;
        }).toList();

        print(
          'Filtered meals for $mealType on $dateKey: ${filteredMeals.length}',
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMealSummaryCard(mealType, filteredMeals.length),
            const SizedBox(height: 16),
            Text(
              'Members (${filteredMeals.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (filteredMeals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No meals added yet',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ...filteredMeals.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final displayName =
                    data['isGuest'] == true && data['guestName'] != null
                    ? '${data['guestName']} (Guest of ${data['memberName']})'
                    : data['memberName'];
                return _buildMemberMealCard(
                  displayName,
                  doc.id,
                  data['isGuest'] ?? false,
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildMealSummaryCard(String mealType, int count) {
    final colors = {
      'breakfast': Colors.orange,
      'lunch': Colors.blue,
      'dinner': Colors.purple,
    };
    final icons = {
      'breakfast': Icons.free_breakfast,
      'lunch': Icons.lunch_dining,
      'dinner': Icons.dinner_dining,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[mealType]!, colors[mealType]!.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[mealType]!.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icons[mealType], color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count Meals',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberMealCard(String memberName, String mealId, bool isGuest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGuest ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isGuest
              ? Colors.orange.withValues(alpha: 0.1)
              : AppColors.primaryGreen.withValues(alpha: 0.1),
          child: Icon(
            isGuest ? Icons.person_outline : Icons.person,
            color: isGuest ? Colors.orange : AppColors.primaryGreen,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                memberName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (isGuest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Text(
                  'GUEST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        subtitle: const Text(
          '1 meal',
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () => _removeMeal(mealId, memberName),
        ),
      ),
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddMealDialog() async {
    print('Opening add meal dialog...');
    print('Current Mess ID: $_messId');

    try {
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('messId', isEqualTo: _messId)
          .get();

      print('Members found: ${membersSnapshot.docs.length}');

      if (!mounted) return;

      if (membersSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No members found. Adding test members...'),
            backgroundColor: Colors.orange,
          ),
        );
        await _addTestMembers();
        return;
      }

      Map<String, dynamic>? selectedMember;
      Map<String, dynamic>? guestHostMember;
      String selectedMealType = 'breakfast';
      bool isGuest = false;
      final guestNameController = TextEditingController();

      // Create unique member list using document ID as key
      final uniqueMembers = <String, Map<String, dynamic>>{};
      for (final doc in membersSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        uniqueMembers[doc.id] = data;
        print('Member: ${data['name']} (${doc.id})');
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Add Meal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Guest Meal'),
                  subtitle: const Text('Toggle for member\'s guest'),
                  value: isGuest,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (value) {
                    setDialogState(() {
                      isGuest = value;
                      if (!isGuest) {
                        guestNameController.clear();
                        guestHostMember = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (isGuest) ...[
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Host Member',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Select the member hosting the guest',
                    ),
                    items: uniqueMembers.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      print('Selected host member ID: $value');
                      setDialogState(() {
                        guestHostMember = value != null
                            ? uniqueMembers[value]
                            : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: guestNameController,
                    decoration: InputDecoration(
                      labelText: 'Guest Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ] else
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Member',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: uniqueMembers.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      print('Selected member ID: $value');
                      setDialogState(() {
                        selectedMember = value != null
                            ? uniqueMembers[value]
                            : null;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: InputDecoration(
                    labelText: 'Meal Type',
                    prefixIcon: const Icon(Icons.restaurant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'breakfast',
                      child: Text('Breakfast'),
                    ),
                    DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  ],
                  onChanged: (value) {
                    print('Selected meal type: $value');
                    setDialogState(() {
                      selectedMealType = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  print('Add button pressed');
                  print('Is guest: $isGuest');
                  print('Selected member: $selectedMember');
                  print('Guest name: ${guestNameController.text}');
                  print('Selected meal type: $selectedMealType');

                  if (isGuest) {
                    if (guestHostMember == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select host member'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    if (guestNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter guest name'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                  } else {
                    if (selectedMember == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a member'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                  }

                  try {
                    final mealDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                    );

                    print('Checking for existing meals...');

                    if (!isGuest) {
                      // Check if meal already exists for member
                      final existingMealQuery = await FirebaseFirestore.instance
                          .collection('meals')
                          .where('messId', isEqualTo: _messId)
                          .where('memberId', isEqualTo: selectedMember!['id'])
                          .where('mealType', isEqualTo: selectedMealType)
                          .where(
                            'date',
                            isEqualTo: Timestamp.fromDate(mealDate),
                          )
                          .get();

                      print(
                        'Existing meals found: ${existingMealQuery.docs.length}',
                      );

                      if (existingMealQuery.docs.isNotEmpty) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${selectedMember!['name']} already has $selectedMealType for this date!',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                    }

                    final mealData = {
                      'messId': _messId,
                      'memberId': isGuest
                          ? guestHostMember!['id']
                          : selectedMember!['id'],
                      'memberName': isGuest
                          ? guestHostMember!['name']
                          : selectedMember!['name'],
                      'guestName': isGuest
                          ? guestNameController.text.trim()
                          : null,
                      'isGuest': isGuest,
                      'mealType': selectedMealType,
                      'date': Timestamp.fromDate(mealDate),
                      'count': 1.0,
                      'createdAt': Timestamp.now(),
                    };

                    print('Adding meal with data: $mealData');

                    final docRef = await FirebaseFirestore.instance
                        .collection('meals')
                        .add(mealData);

                    print('Meal added successfully with ID: ${docRef.id}');

                    if (!mounted) return;
                    Navigator.pop(dialogContext);

                    final displayName = isGuest
                        ? '${guestNameController.text.trim()} (Guest of ${guestHostMember!['name']})'
                        : selectedMember!['name'];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${selectedMealType.toUpperCase()} added for $displayName!',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    print('Error adding meal: $e');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in _showAddMealDialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading members: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeMeal(String mealId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Meal'),
        content: Text('Remove meal for $memberName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('meals')
                    .doc(mealId)
                    .delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meal removed successfully!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove meal: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
