import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/presentation/screens/overview_screen.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:my_thesis_project/presentation/widgets/memory_item_card.dart';

class TrashScreen extends StatefulWidget {
  final Store store;

  const TrashScreen({super.key, required this.store});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late final Box<MemoryItem> _memoryBox;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _memoryBox = widget.store.box<MemoryItem>();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _restoreSelected() {
    if (_selectedIds.isEmpty) return;
    for (var id in _selectedIds) {
      final item = _memoryBox.get(id);
      if (item != null) {
        item.isDeleted = false;
        _memoryBox.put(item);
      }
    }
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Items restored")));
  }

  void _permanentlyDeleteSelected() {
    if (_selectedIds.isEmpty) return;
    
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
              for (var id in _selectedIds) {
                final item = _memoryBox.get(id);
                if (item != null) {
                  final task = item.todoTask.target;
                  if (task != null) {
                    widget.store.box<TodoTask>().remove(task.id);
                  }
                  _memoryBox.remove(item.id);
                }
              }
              Navigator.pop(context);
              _clearSelection();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Items permanently deleted")));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _permanentlyDeleteAll() {
    final deletedItems = _memoryBox.query(MemoryItem_.isDeleted.equals(true)).build().find();
    if (deletedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDark,
        title: const Text("Empty Trash?", style: TextStyle(color: Colors.white)),
        content: const Text("All items in trash will be permanently deleted.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              for (var item in deletedItems) {
                final task = item.todoTask.target;
                if (task != null) {
                  widget.store.box<TodoTask>().remove(task.id);
                }
                _memoryBox.remove(item.id);
              }
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trash emptied")));
            },
            child: const Text("Empty All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _memoryBox.query(MemoryItem_.isDeleted.equals(true)).build();
    final items = query.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
        actions: [
          if (!_isSelectionMode)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'select') setState(() => _isSelectionMode = true);
                if (value == 'empty') _permanentlyDeleteAll();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'select', child: Text('Select')),
                const PopupMenuItem(value: 'empty', child: Text('Permanently Delete All', style: TextStyle(color: Colors.red))),
              ],
            )
          else ...[
             PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'restore') _restoreSelected();
                if (value == 'delete') _permanentlyDeleteSelected();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'restore', child: Text('Restore')),
                const PopupMenuItem(value: 'delete', child: Text('Permanently Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            ),
          ]
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text("Trash is empty", style: TextStyle(color: Colors.grey)))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return MemoryItemCard(
                  item: item,
                  isSelectionMode: _isSelectionMode,
                  isSelected: _selectedIds.contains(item.id),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(item.id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OverviewScreen(
                            item: item,
                            store: widget.store,
                            isPreSave: false,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _toggleSelection(item.id);
                    }
                  },
                );
              },
            ),
    );
  }
}
