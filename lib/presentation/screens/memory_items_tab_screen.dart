import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:my_thesis_project/presentation/widgets/task_box_widget.dart';

enum TaskFilter { pending, overdue, completed }

class MemoryItemsTabScreen extends StatefulWidget {
  final Store store;

  const MemoryItemsTabScreen({super.key, required this.store});

  @override
  State<MemoryItemsTabScreen> createState() => _MemoryItemsTabScreenState();
}

class _MemoryItemsTabScreenState extends State<MemoryItemsTabScreen> {
  TaskFilter _currentFilter = TaskFilter.pending;
  late final Box<MemoryItem> _memoryBox;

  @override
  void initState() {
    super.initState();
    _memoryBox = widget.store.box<MemoryItem>();
  }

  List<MemoryItem> _getFilteredItems() {
    final now = DateTime.now();
    // Fetch items not deleted
    final items = _memoryBox.query(MemoryItem_.isDeleted.equals(false)).build().find();
    
    return items.where((item) {
      final task = item.todoTask.target;
      if (task == null) return false;
      
      switch (_currentFilter) {
        case TaskFilter.pending:
          return !task.taskCompleted && (task.dueDate == null || !task.dueDate!.isBefore(now));
        case TaskFilter.overdue:
          return !task.taskCompleted && task.dueDate != null && task.dueDate!.isBefore(now);
        case TaskFilter.completed:
          return task.taskCompleted;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _getFilteredItems();
    // Sort by urgency (closest deadline at top)
    items.sort((a, b) {
      final dateA = a.todoTask.target?.dueDate;
      final dateB = b.todoTask.target?.dueDate;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateA.compareTo(dateB);
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildHeader(items.length),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildFilterPills(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildTaskList(items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    String text;
    switch (_currentFilter) {
      case TaskFilter.pending:
        text = "You have $count task(s) this week";
        break;
      case TaskFilter.overdue:
        text = "You have a total of $count missed task(s)";
        break;
      case TaskFilter.completed:
        text = "You have completed $count task(s)";
        break;
    }
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.cascadingWhite,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'Courier',
      ),
    );
  }

  Widget _buildFilterPills() {
    return Row(
      children: [
        Expanded(child: _buildPill("Pending", TaskFilter.pending, AppColors.pastelYellow)),
        const SizedBox(width: 8),
        Expanded(child: _buildPill("Overdue", TaskFilter.overdue, AppColors.taskRed)),
        const SizedBox(width: 8),
        Expanded(child: _buildPill("Completed", TaskFilter.completed, AppColors.taskGreen)),
      ],
    );
  }

  Widget _buildPill(String label, TaskFilter filter, Color activeColor) {
    final bool isActive = _currentFilter == filter;
    return InkWell(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isActive ? activeColor : Colors.white),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : AppColors.cascadingWhite,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<MemoryItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text("No tasks found", style: TextStyle(color: Colors.grey)));
    }

    // Grouping logic
    final Map<String, List<MemoryItem>> grouped = {};
    for (var item in items) {
      final date = item.todoTask.target?.dueDate;
      String groupKey;
      if (date == null) {
        groupKey = "No Deadline";
      } else {
        final now = DateTime.now();
        if (date.year == now.year && date.month == now.month) {
          groupKey = "This ${DateFormat('MMMM').format(date)}:";
        } else if (date.isAfter(now)) {
          groupKey = "This upcoming months:";
        } else {
          groupKey = "From ${DateFormat('MMMM').format(date)}:";
        }
      }
      grouped.putIfAbsent(groupKey, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                entry.key,
                style: const TextStyle(color: AppColors.cascadingWhite, fontSize: 16),
              ),
            ),
            ...entry.value.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TaskBoxWidget(
                task: item.todoTask.target!,
                store: widget.store,
                onTaskUpdated: () => setState(() {}),
              ),
            )),
          ],
        );
      }).toList(),
    );
  }
}
