import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../data/models/task_schedule_model.dart';

class TaskSchedulePage extends StatefulWidget {
  const TaskSchedulePage({super.key});

  @override
  State<TaskSchedulePage> createState() => _TaskSchedulePageState();
}

class _TaskSchedulePageState extends State<TaskSchedulePage> {
  bool _isLoading = true;
  bool _isManager = false;
  String _messId = '';
  List<Map<String, dynamic>> _members = [];
  List<TaskScheduleModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final messId = userDoc.data()?['messId'] as String? ?? '';
      final role = userDoc.data()?['role'] as String? ?? 'member';
      if (messId.isEmpty) return;

      final membersSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('members')
          .get();

      // Load tasks for next 14 days
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = from.add(const Duration(days: 14));

      final tasksSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('taskSchedule')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('date', isLessThan: Timestamp.fromDate(to))
          .orderBy('date')
          .get();

      if (mounted) {
        setState(() {
          _messId = messId;
          _isManager = role == 'manager' || role == 'admin';
          _members = membersSnap.docs
              .map((d) => {'id': d.id, 'name': d.data()['name'] ?? ''})
              .toList();
          _tasks = tasksSnap.docs
              .map((d) => TaskScheduleModel.fromFirestore(d))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _memberName(String id) {
    final m = _members.firstWhere(
      (m) => m['id'] == id,
      orElse: () => {'name': 'Unknown'},
    );
    return m['name'] as String;
  }

  List<TaskScheduleModel> _tasksForDate(DateTime date) {
    return _tasks.where((t) {
      final d = t.date;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();
  }

  void _showAddTaskDialog(DateTime date) async {
    if (!_isManager) {
      showNoPermissionSnack(context);
      return;
    }
    final taskCtrl = TextEditingController();
    String? selectedMemberId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Task · ${DateFormat('EEE, MMM d').format(date)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskCtrl,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'e.g. Bathroom clean',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMemberId,
                decoration: InputDecoration(
                  labelText: 'Assign to Member',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
                items: _members
                    .map(
                      (m) => DropdownMenuItem<String>(
                        value: m['id'] as String,
                        child: Text(m['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setS(() => selectedMemberId = v),
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
                if (taskCtrl.text.trim().isEmpty || selectedMemberId == null) {
                  return;
                }
                final task = TaskScheduleModel(
                  id: '',
                  taskName: taskCtrl.text.trim(),
                  memberId: selectedMemberId!,
                  memberName: _memberName(selectedMemberId!),
                  date: date,
                  messId: _messId,
                  createdAt: DateTime.now(),
                );
                await FirebaseFirestore.instance
                    .collection('messes')
                    .doc(_messId)
                    .collection('taskSchedule')
                    .add(task.toFirestore());
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: const Text(
                'Add Task',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(TaskScheduleModel task) async {
    if (!_isManager) {
      showNoPermissionSnack(context);
      return;
    }
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('taskSchedule')
        .doc(task.id)
        .delete();
    await _load();
  }

  Future<void> _toggleComplete(TaskScheduleModel task) async {
    await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('taskSchedule')
        .doc(task.id)
        .update({'isCompleted': !task.isCompleted});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (i) {
      final d = today.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Task Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final tasks = _tasksForDate(date);
                final isToday = index == 0;
                final isTomorrow = index == 1;

                String dayLabel = DateFormat('EEE, MMM d').format(date);
                if (isToday) dayLabel = 'Today · $dayLabel';
                if (isTomorrow) dayLabel = 'Tomorrow · $dayLabel';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: isToday
                        ? Border.all(
                            color: Colors.teal.withValues(alpha: 0.4),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Colors.teal
                                    : Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.task_alt_rounded,
                                color: isToday ? Colors.white : Colors.teal,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dayLabel,
                                style: TextStyle(
                                  fontWeight: isToday || isTomorrow
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            if (_isManager)
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.teal,
                                  size: 22,
                                ),
                                onPressed: () => _showAddTaskDialog(date),
                                tooltip: 'Add Task',
                              ),
                          ],
                        ),
                      ),
                      // Tasks
                      if (tasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            'No tasks scheduled',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      else
                        ...tasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleComplete(task),
                                  child: Icon(
                                    task.isCompleted
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color: task.isCompleted
                                        ? Colors.teal
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.taskName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: task.isCompleted
                                              ? Colors.grey
                                              : AppColors.textDark,
                                          decoration: task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        task.memberName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isManager)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () => _deleteTask(task),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
