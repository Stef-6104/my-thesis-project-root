import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/presentation/screens/task_box_edit_screen.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:objectbox/objectbox.dart';

class TaskBoxWidget extends StatefulWidget {
  final TodoTask task;
  final Store store;
  final VoidCallback? onTaskUpdated;

  const TaskBoxWidget({
    super.key,
    required this.task,
    required this.store,
    this.onTaskUpdated,
  });

  @override
  State<TaskBoxWidget> createState() => _TaskBoxWidgetState();
}

class _TaskBoxWidgetState extends State<TaskBoxWidget> {
  void _toggleCompleted() {
    setState(() {
      widget.task.taskCompleted = !widget.task.taskCompleted;
      widget.store.box<TodoTask>().put(widget.task);
    });
    if (widget.onTaskUpdated != null) {
      widget.onTaskUpdated!();
    }
  }

  void _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskBoxEditScreen(
          task: widget.task,
          store: widget.store,
        ),
      ),
    );
    if (widget.onTaskUpdated != null) {
      widget.onTaskUpdated!();
    }
    setState(() {}); // Refresh state in case of edits
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.task.taskCompleted;
    final bool isOverdue = !isCompleted &&
        widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now());

    Color stateColor;
    if (isCompleted) {
      stateColor = AppColors.taskGreen;
    } else if (isOverdue) {
      stateColor = AppColors.taskRed;
    } else {
      stateColor = AppColors.lightYellow;
    }

    String displayDate = '';
    if (widget.task.dueDate != null) {
      displayDate = DateFormat('MMMM d, h:mm a').format(widget.task.dueDate!);
    } else if (widget.task.taskDeadline.isNotEmpty) {
      displayDate = widget.task.taskDeadline;
    }

    return GestureDetector(
      onTap: _navigateToEdit,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkGray,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: stateColor, width: 1),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleCompleted,
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: stateColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.taskTitle,
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (displayDate.isNotEmpty)
                    Text(
                      displayDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
