import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/category.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:my_thesis_project/presentation/widgets/task_box_widget.dart';
import 'package:my_thesis_project/services/google_calendar_service.dart';

class OverviewScreen extends StatefulWidget {
  final MemoryItem item;
  final Store store;
  final bool isPreSave;

  const OverviewScreen({
    super.key,
    required this.item,
    required this.store,
    required this.isPreSave,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _deadlineController;

  Future<void> _addToGoogleCalendar() async {
    final task = widget.item.todoTask.target;

    if (task == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No task found.'),
        ),
      );
      return;
    }

    if (task.taskDeadline == null ||
        task.taskDeadline!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This task has no deadline.'),
        ),
      );
      return;
    }

    try {
      // Parse the deadline stored in your TodoTask
      final deadline = DateTime.tryParse(
        task.taskDeadline!.trim(),
      );

      if (deadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid deadline format: ${task.taskDeadline}',
            ),
          ),
        );
        return;
      }

      // Create the Google Calendar event
      await _calendarService.createCalendarEvent(
        title: task.taskTitle ?? 'Untitled Task',
        description: task.taskDescription ?? '',
        deadline: deadline,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Added to Google Calendar!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not add to Google Calendar: $e',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final task = widget.item.todoTask.target;
    _titleController = TextEditingController(text: task?.taskTitle);
    _bodyController = TextEditingController(text: task?.taskDescription);
    _deadlineController = TextEditingController(text: task?.taskDeadline);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  void _saveItem() {
    final task = widget.item.todoTask.target!;
    task.taskTitle = _titleController.text;
    task.taskDescription = _bodyController.text;
    task.taskDeadline = _deadlineController.text;
    
    widget.store.box<TodoTask>().put(task); // Ensure task is saved
    widget.store.box<MemoryItem>().put(widget.item);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved Successfully!")),
    );
    
    if (widget.isPreSave) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {});
    }
  }

  void _archiveItem() {
    setState(() {
      widget.item.isArchived = true;
      widget.store.box<MemoryItem>().put(widget.item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to Archives")),
    );
  }

  void _deleteItem() {
    if (!widget.isPreSave) {
      widget.item.isDeleted = true;
      widget.item.isArchived = false;
      widget.store.box<MemoryItem>().put(widget.item);
    }
    Navigator.pop(context);
  }

  void _restoreItem() {
    widget.item.isDeleted = false;
    widget.store.box<MemoryItem>().put(widget.item);
    Navigator.pop(context);
  }

  void _permanentlyDeleteItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDark,
        title: const Text("Permanently Delete?", style: TextStyle(color: Colors.white)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final task = widget.item.todoTask.target;
              if (task != null) {
                widget.store.box<TodoTask>().remove(task.id);
              }
              widget.store.box<MemoryItem>().remove(widget.item.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog() {
    final categories = widget.store.box<Category>().getAll();
    int? selectedId = widget.item.category.target?.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.secondaryDark,
          title: const Text('Assign Category', style: TextStyle(color: AppColors.cascadingWhite)),
          content: categories.isEmpty
              ? const Text("No categories created yet.", style: TextStyle(color: Colors.grey))
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: categories.map((cat) {
                      return RadioListTile<int>(
                        title: Text(cat.name, style: const TextStyle(color: AppColors.cascadingWhite)),
                        value: cat.id,
                        groupValue: selectedId,
                        activeColor: AppColors.lightYellow,
                        onChanged: (value) {
                          setDialogState(() => selectedId = value);
                        },
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            if (categories.isNotEmpty)
              TextButton(
                onPressed: () {
                  final cat = widget.store.box<Category>().get(selectedId!);
                  widget.item.category.target = cat;
                  widget.store.box<MemoryItem>().put(widget.item);
                  Navigator.pop(context);
                  setState(() {}); // Refresh current screen
                },
                child: const Text('Save', style: TextStyle(color: AppColors.lightYellow)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.item.todoTask.target;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.isPreSave)
            PopupMenuButton(
              itemBuilder: (context) {
                if (widget.item.isDeleted) {
                  return [
                    const PopupMenuItem(value: 'restore', child: Text('Restore')),
                    const PopupMenuItem(value: 'perm_delete', child: Text('Permanently Delete', style: TextStyle(color: Colors.red))),
                  ];
                }
                return [
                  const PopupMenuItem(value: 'delete', child: Text('Delete Item')),
                ];
              },
              onSelected: (value) {
                if (value == 'delete') _deleteItem();
                if (value == 'restore') _restoreItem();
                if (value == 'perm_delete') _permanentlyDeleteItem();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            if (task != null && task.image.isNotEmpty)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.lightYellow, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(File(task.image), fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 20),

            // AI Summary Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightYellow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: AppColors.pastelYellow,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: widget.isPreSave
                      ? TextField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: const InputDecoration(border: InputBorder.none),
                        )
                      : Text(
                          _titleController.text,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.isPreSave
                          ? TextField(
                              controller: _bodyController,
                              maxLines: null,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(border: InputBorder.none),
                            )
                          : Text(
                              _bodyController.text,
                              style: const TextStyle(color: Colors.black),
                            ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 5),
                        widget.isPreSave
                          ? TextField(
                              controller: _deadlineController,
                              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                prefixText: 'Deadline: ',
                                prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                border: InputBorder.none,
                              ),
                            )
                          : RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black, fontSize: 14),
                                children: [
                                  const TextSpan(text: 'Deadline: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: _deadlineController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Task Item Box
            const Text("Task:", style: TextStyle(color: AppColors.cascadingWhite)),
            const SizedBox(height: 8),
            if (task != null)
              TaskBoxWidget(
                task: task,
                store: widget.store,
                onTaskUpdated: () => setState(() {}),
              ),
            const SizedBox(height: 30),

            if (widget.isPreSave) ...[
              const Center(
                child: Text("Does this summary look good?", style: TextStyle(color: AppColors.cascadingWhite)),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Save", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Discard", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ] else if (!widget.item.isDeleted) ...[
              const Text("Add:", style: TextStyle(color: AppColors.cascadingWhite)),
              const SizedBox(height: 10),
              _buildActionItem(Icons.add, "Add on a specific category", onTap: _showCategoryDialog),
              _buildActionItem(Icons.grid_view, "Add on Archives", onTap: _archiveItem),
              _buildActionItem(Icons.calendar_today, "Add as a calendar event", onTap: _addToGoogleCalendar,),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, {bool isStub = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightYellow, width: 1),
      ),
      child: InkWell(
        onTap: onTap ?? (isStub ? () {} : null),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: AppColors.cascadingWhite, size: 28),
              const SizedBox(width: 18),
              Text(
                label,
                style: const TextStyle(color: AppColors.cascadingWhite, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
