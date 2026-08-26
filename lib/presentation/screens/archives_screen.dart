import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/presentation/screens/overview_screen.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:my_thesis_project/presentation/widgets/memory_item_card.dart';

class ArchivesScreen extends StatefulWidget {
  final Store store;

  const ArchivesScreen({super.key, required this.store});

  @override
  State<ArchivesScreen> createState() => _ArchivesScreenState();
}

class _ArchivesScreenState extends State<ArchivesScreen> {
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

  void _removeFromArchives() {
    if (_selectedIds.isEmpty) return;
    
    for (var id in _selectedIds) {
      final item = _memoryBox.get(id);
      if (item != null) {
        item.isArchived = false;
        _memoryBox.put(item);
      }
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Removed from archives")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _memoryBox.query(
      MemoryItem_.isArchived.equals(true).and(MemoryItem_.isDeleted.equals(false))
    ).build();
    final items = query.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
        actions: [
          if (!_isSelectionMode)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'select') setState(() => _isSelectionMode = true);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'select', child: Text('Select')),
              ],
            )
          else ...[
            TextButton(
              onPressed: _removeFromArchives,
              child: const Text('Remove from archives', style: TextStyle(color: AppColors.lightYellow)),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            ),
          ]
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text("No archived items", style: TextStyle(color: Colors.grey)))
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
