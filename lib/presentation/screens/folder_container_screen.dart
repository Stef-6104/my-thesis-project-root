import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/category.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/presentation/screens/overview_screen.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:my_thesis_project/presentation/widgets/memory_item_card.dart';

class FolderContainerScreen extends StatefulWidget {
  final Category category;
  final Store store;

  const FolderContainerScreen({
    super.key,
    required this.category,
    required this.store,
  });

  @override
  State<FolderContainerScreen> createState() => _FolderContainerScreenState();
}

class _FolderContainerScreenState extends State<FolderContainerScreen> {
  late TextEditingController _titleController;
  final List<int> _selectedItemIds = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _updateFolderName() {
    if (_titleController.text.trim().isNotEmpty && _titleController.text != widget.category.name) {
      widget.category.name = _titleController.text.trim();
      widget.store.box<Category>().put(widget.category);
    }
  }

  void _deleteFolder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDark,
        title: const Text('Delete Folder?', style: TextStyle(color: AppColors.cascadingWhite)),
        content: const Text(
          'This will remove the category but keep your memory items.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              widget.store.box<Category>().remove(widget.category.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _removeSelectedFromFolder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDark,
        title: const Text('Remove from folder?', style: TextStyle(color: AppColors.cascadingWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final memoryBox = widget.store.box<MemoryItem>();
              for (var id in _selectedItemIds) {
                final item = memoryBox.get(id);
                if (item != null) {
                  item.category.target = null;
                  memoryBox.put(item);
                }
              }
              setState(() {
                _selectedItemIds.clear();
                _isSelectionMode = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.lightYellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            _updateFolderName();
            Navigator.pop(context);
          },
        ),
        title: TextField(
          controller: _titleController,
          style: const TextStyle(
            color: AppColors.cascadingWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
          decoration: const InputDecoration(border: InputBorder.none),
          onSubmitted: (_) => _updateFolderName(),
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedItemIds.clear();
                  _isSelectionMode = false;
                });
              },
            )
          else
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _deleteFolder();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Folder'),
                ),
              ],
            ),
          if (_isSelectionMode)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') _removeSelectedFromFolder();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove from folder'),
                ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<List<MemoryItem>>(
        stream: widget.store.box<MemoryItem>()
            .query(MemoryItem_.category.equals(widget.category.id))
            .watch(triggerImmediately: true)
            .map((q) => q.find()),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          
          if (items.isEmpty) {
            return const Center(
              child: Text("This folder is empty", style: TextStyle(color: Colors.grey)),
            );
          }

          return GridView.builder(
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
              final isSelected = _selectedItemIds.contains(item.id);

              return Stack(
                children: [
                  MemoryItemCard(
                    item: item,
                    onTap: () {
                      if (_isSelectionMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedItemIds.remove(item.id);
                            if (_selectedItemIds.isEmpty) _isSelectionMode = false;
                          } else {
                            _selectedItemIds.add(item.id);
                          }
                        });
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
                        );
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedItemIds.add(item.id);
                        });
                      }
                    },
                  ),
                  if (_isSelectionMode)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IgnorePointer(
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.lightYellow : Colors.white70,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
