import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/objectbox.g.dart';

class TaskInfoScreen extends StatefulWidget {
  final TodoTask task;
  final Store store; // We need the store to save changes

  const TaskInfoScreen({super.key, required this.task, required this.store});

  @override
  State<TaskInfoScreen> createState() => _TaskInfoScreenState();
}

class _TaskInfoScreenState extends State<TaskInfoScreen> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with existing notes
    _notesController = TextEditingController(text: widget.task.taskNote);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveTask() {
    setState(() {
      widget.task.taskNote = _notesController.text;
    });
    // Update the task in ObjectBox
    widget.store.box<TodoTask>().put(widget.task);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Changes Saved!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.taskTitle),
        // AppBar turns green if the task is completed
        backgroundColor: widget.task.taskCompleted
            ? Colors.green
            : Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
            tooltip: 'Save Notes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 5),
            Text(widget.task.taskDescription, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 15),
            Text("Created: ${widget.task.taskCreated}"),
            Text("Deadline: ${widget.task.taskDeadline}"),
            const Divider(height: 30),

            const Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),

            // 2. Editable Notes Field
            TextField(
              controller: _notesController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: "Enter your notes here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    widget.task.taskCompleted = !widget.task.taskCompleted;
                  });
                  // Save completion status to DB
                  widget.store.box<TodoTask>().put(widget.task);
                },
                icon: Icon(widget.task.taskCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                label: Text(widget.task.taskCompleted ? "Completed" : "Mark as Complete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.task.taskCompleted ? Colors.green : null,
                  foregroundColor: widget.task.taskCompleted ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}