import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:objectbox/objectbox.dart';

class TaskBoxEditScreen extends StatefulWidget {
  final TodoTask task;
  final Store store;

  const TaskBoxEditScreen({
    super.key,
    required this.task,
    required this.store,
  });

  @override
  State<TaskBoxEditScreen> createState() => _TaskBoxEditScreenState();
}

class _TaskBoxEditScreenState extends State<TaskBoxEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.taskTitle);
    _noteController = TextEditingController(text: widget.task.taskNote);
    _selectedDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.lightYellow,
              onPrimary: Colors.black,
              surface: AppColors.secondaryDark,
              onSurface: AppColors.cascadingWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _save() {
    widget.task.taskTitle = _titleController.text;
    widget.task.taskNote = _noteController.text;
    widget.task.dueDate = _selectedDate;
    if (_selectedDate != null) {
      widget.task.taskDeadline = DateFormat('MMMM d, h:mm a').format(_selectedDate!);
    }
    widget.store.box<TodoTask>().put(widget.task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Title:'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.cascadingWhite, fontStyle: FontStyle.italic),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Specifics:", style: TextStyle(color: AppColors.cascadingWhite)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildPickerRow(
                    icon: Icons.access_time,
                    label: "Time",
                    value: _selectedDate == null ? "Set Time" : DateFormat('h:mm a').format(_selectedDate!),
                    onTap: _pickDate,
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  _buildPickerRow(
                    icon: Icons.calendar_today,
                    label: "Date",
                    value: _selectedDate == null ? "Set Date" : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                    onTap: _pickDate,
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Note", style: TextStyle(color: AppColors.cascadingWhite, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          maxLines: 5,
                          style: const TextStyle(color: AppColors.cascadingWhite),
                          decoration: const InputDecoration(
                            hintText: "Add notes...",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cascadingWhite,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Save", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerRow({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: AppColors.cascadingWhite),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(color: AppColors.cascadingWhite, fontSize: 16)),
            const Spacer(),
            Text(value, style: const TextStyle(color: AppColors.cascadingWhite, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
