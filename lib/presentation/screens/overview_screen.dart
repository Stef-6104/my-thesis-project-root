import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';

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
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _deadlineController;

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
    
    widget.store.box<MemoryItem>().put(widget.item);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved Successfully!")),
    );
    
    if (widget.isPreSave) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _deleteItem() {
    if (!widget.isPreSave) {
      final task = widget.item.todoTask.target;
      if (task != null) {
        widget.store.box<TodoTask>().remove(task.id);
      }
      widget.store.box<MemoryItem>().remove(widget.item.id);
    }
    Navigator.pop(context);
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
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'delete', child: Text('Delete Item')),
              ],
              onSelected: (value) {
                if (value == 'delete') _deleteItem();
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightYellow, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
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
                    child: TextField(
                      controller: _titleController,
                      enabled: widget.isPreSave,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        TextField(
                          controller: _bodyController,
                          enabled: widget.isPreSave,
                          maxLines: null,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                        const Divider(color: Colors.black26),
                        TextField(
                          controller: _deadlineController,
                          enabled: widget.isPreSave,
                          style: const TextStyle(color: Colors.black, fontSize: 12),
                          decoration: const InputDecoration(
                            prefixText: 'Deadline: ',
                            border: InputBorder.none,
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
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightYellow),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radio_button_unchecked, color: AppColors.cascadingWhite),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text,
                          style: const TextStyle(color: AppColors.cascadingWhite, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                        Text(
                          _deadlineController.text,
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            ] else ...[
              const Text("Add:", style: TextStyle(color: AppColors.cascadingWhite)),
              const SizedBox(height: 10),
              _buildActionItem(Icons.add, "Add on a specific category"),
              _buildActionItem(Icons.grid_view, "Add on Archives"),
              _buildActionItem(Icons.calendar_today, "Add as a calendar event", isStub: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, {bool isStub = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightYellow),
      ),
      child: InkWell(
        onTap: isStub ? () {} : () { /* TODO */ },
        child: Row(
          children: [
            Icon(icon, color: AppColors.cascadingWhite),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(color: AppColors.cascadingWhite)),
          ],
        ),
      ),
    );
  }
}
