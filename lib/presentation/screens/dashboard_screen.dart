import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/category.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/presentation/screens/folder_container_screen.dart';
import 'package:my_thesis_project/presentation/screens/ocr_screen.dart';
import 'package:my_thesis_project/presentation/screens/overview_screen.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:my_thesis_project/presentation/widgets/category_card.dart';
import 'package:my_thesis_project/presentation/widgets/memory_item_card.dart';
import 'package:my_thesis_project/presentation/widgets/search_bar.dart';

class DashboardScreen extends StatefulWidget {
  final Store store;
  const DashboardScreen({super.key, required this.store});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Box<MemoryItem> _memoryBox;
  late final Box<Category> _categoryBox;
  late Stream<List<MemoryItem>> _memoryStream;
  late Stream<List<Category>> _categoryStream;
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _memoryBox = widget.store.box<MemoryItem>();
    _categoryBox = widget.store.box<Category>();
    
    _memoryStream = _memoryBox
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find());
        
    _categoryStream = _categoryBox
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDark,
        title: const Text('Create New Category', style: TextStyle(color: AppColors.cascadingWhite)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.cascadingWhite),
          decoration: const InputDecoration(
            hintText: 'Folder Name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.lightYellow)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _categoryBox.put(Category(name: controller.text.trim()));
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.lightYellow)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false, // Let the bottom bar handle its own safe area
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Memory Hub',
                    style: TextStyle(
                      color: AppColors.cascadingWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 15),
                  CustomSearchBar(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Category:',
                        style: TextStyle(color: AppColors.cascadingWhite, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.cascadingWhite),
                        onPressed: _showCreateFolderDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 140,
              padding: const EdgeInsets.only(left: 20),
              decoration: const BoxDecoration(
                color: AppColors.pastelYellow,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: StreamBuilder<List<Category>>(
                stream: _categoryStream,
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  
                  if (categories.isEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(right: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.darkGray,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          "No folders yet",
                          style: TextStyle(color: AppColors.cascadingWhite),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderContainerScreen(
                                category: category,
                                store: widget.store,
                              ),
                            ),
                          );
                        },
                        child: CategoryCard(
                          title: category.name,
                          count: category.memoryItems.length,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<List<MemoryItem>>(
                stream: _memoryStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "Your Memory Hub is Empty",
                        style: TextStyle(color: AppColors.cascadingWhite),
                      ),
                    );
                  }
                  
                  final items = snapshot.data!.where((item) {
                    final title = item.todoTask.target?.taskTitle.toLowerCase() ?? '';
                    return title.contains(_searchQuery);
                  }).toList();

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return MemoryItemCard(
                        item: items[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OverviewScreen(
                                item: items[index],
                                store: widget.store,
                                isPreSave: false,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.secondaryDark,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60, // Standard height
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.delete_outline), label: ''),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OCRScreen(store: widget.store),
            ),
          );
        },
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
