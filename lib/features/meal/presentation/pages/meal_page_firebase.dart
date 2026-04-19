import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_mess_service.dart';
import '../../../../core/services/active_month_service.dart';
import '../../../../core/utils/app_date_picker.dart';
import '../../data/models/meal_model.dart';
import '../../data/services/firebase_meal_service.dart';
import '../../../member/data/models/member_model.dart';
import '../../../member/data/services/firebase_member_service.dart';

class MealPageFirebase extends StatefulWidget {
  const MealPageFirebase({super.key});

  @override
  State<MealPageFirebase> createState() => _MealPageFirebaseState();
}

class _MealPageFirebaseState extends State<MealPageFirebase>
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
  }

  Future<void> _loadMessId() async {
    final messId = await FirebaseMessService.getMessId();
    setState(() {
      _messId = messId;
      _isLoading = false;
    });
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
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
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
            onPressed: () async {
              final range = await ActiveMonthService.getRunningMonthRange(
                _messId,
              );
              final prev = _selectedDate.subtract(const Duration(days: 1));
              if (!prev.isBefore(range.start)) {
                setState(() => _selectedDate = prev);
              }
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
            onPressed: () async {
              final range = await ActiveMonthService.getRunningMonthRange(
                _messId,
              );
              final next = _selectedDate.add(const Duration(days: 1));
              if (!next.isAfter(range.end)) {
                setState(() => _selectedDate = next);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return FutureBuilder<Map<String, int>>(
      future: FirebaseMealService.getDailyMealSummary(
        messId: _messId,
        date: _selectedDate,
      ),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            {'breakfast': 0, 'lunch': 0, 'dinner': 0, 'total': 0};

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
                'Total Meals',
                stats['total'].toString(),
                Icons.restaurant,
                AppColors.primaryGreen,
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                'Breakfast',
                stats['breakfast'].toString(),
                Icons.free_breakfast,
                Colors.orange,
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                'Lunch',
                stats['lunch'].toString(),
                Icons.lunch_dining,
                Colors.blue,
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                'Dinner',
                stats['dinner'].toString(),
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
    return StreamBuilder<List<MealModel>>(
      stream: FirebaseMealService.getMealsByTypeAndDate(
        messId: _messId,
        mealType: mealType,
        date: _selectedDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final meals = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMealSummaryCard(mealType, meals.length),
            const SizedBox(height: 16),
            Text(
              'Members (${meals.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (meals.isEmpty)
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
              ...meals.map((meal) => _buildMemberMealCard(meal)),
          ],
        );
      },
    );
  }

  Widget _buildMealSummaryCard(String mealType, int count) {
    final icons = {
      'breakfast': Icons.free_breakfast,
      'lunch': Icons.lunch_dining,
      'dinner': Icons.dinner_dining,
    };

    final colors = {
      'breakfast': Colors.orange,
      'lunch': Colors.blue,
      'dinner': Colors.purple,
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

  Widget _buildMemberMealCard(MealModel meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
          child: Text(
            meal.memberName.split(' ').map((e) => e[0]).take(2).join(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        title: Text(
          meal.memberName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          '${meal.count} meal${meal.count > 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () => _removeMeal(meal),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddMealDialog() async {
    try {
      MemberModel? selectedMember;
      String selectedMealType = 'breakfast';

      // Get active members
      final membersSnapshot = await FirebaseMemberService.getActiveMembers(
        _messId,
      ).first.timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (membersSnapshot.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No members found. Please add members first from the Member tab.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Add Meal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<MemberModel>(
                  decoration: InputDecoration(
                    labelText: 'Member',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: membersSnapshot
                      .map(
                        (member) => DropdownMenuItem(
                          value: member,
                          child: Text(member.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedMember = value),
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
                  onChanged: (value) =>
                      setDialogState(() => selectedMealType = value!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedMember != null) {
                    try {
                      await FirebaseMealService.addMeal(
                        messId: _messId,
                        memberId: selectedMember!.id,
                        memberName: selectedMember!.name,
                        mealType: selectedMealType,
                        date: _selectedDate,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meal added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeMeal(MealModel meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Meal'),
        content: Text('Remove ${meal.memberName} from ${meal.mealType}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseMealService.removeMeal(meal.id);

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
