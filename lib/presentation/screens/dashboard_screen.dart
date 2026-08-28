import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/category.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/presentation/screens/archives_screen.dart';
import 'package:my_thesis_project/presentation/screens/memory_items_tab_screen.dart';
import 'package:my_thesis_project/presentation/screens/trash_screen.dart';
import 'package:my_thesis_project/presentation/screens/folder_container_screen.dart';
import 'package:my_thesis_project/presentation/screens/ocr_screen.dart';
import 'package:my_thesis_project/presentation/screens/overview_screen.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:my_thesis_project/presentation/widgets/category_card.dart';
import 'package:my_thesis_project/presentation/widgets/memory_item_card.dart';
import 'package:my_thesis_project/presentation/widgets/search_bar.dart';
import 'package:my_thesis_project/services/embedding_service.dart';
import 'package:my_thesis_project/services/semantic_search_service.dart';

class DashboardScreen extends StatefulWidget {
  final Store store;
  const DashboardScreen({super.key, required this.store});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Box<MemoryItem> _memoryBox;
  late final Box<Category> _categoryBox;

  late final EmbeddingService _embeddingService;
  late final SemanticSearchService _semanticSearchService;

  List<SemanticSearchResult> _semanticResults = [];

  bool _semanticSearching = false;

  late Stream<List<MemoryItem>> _memoryStream;
  late Stream<List<Category>> _categoryStream;
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _memoryBox = widget.store.box<MemoryItem>();
    _categoryBox = widget.store.box<Category>();

    _embeddingService = EmbeddingService();

    _semanticSearchService = SemanticSearchService(
      store: widget.store,
      embeddingService: _embeddingService,
    );

    _memoryStream = _memoryBox
        .query(MemoryItem_.isDeleted.equals(false))
        .watch(triggerImmediately: true)
        .map((query) => query.find());
        
    _categoryStream = _categoryBox
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find());

    // Listen to memory changes to update category counts reactively
    _memoryBox.query().watch().listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _performSemanticSearch(String query) async {
    query = query.trim();

    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _semanticResults = [];
        _semanticSearching = false;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _semanticSearching = true;
    });

    try {
      final results = await _semanticSearchService.search(
        query,
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _semanticResults = results;
        _semanticSearching = false;
      });
    } catch (e) {
      print('Semantic search error: $e');

      if (!mounted) return;

      setState(() {
        _semanticResults = [];
        _semanticSearching = false;
      });
    }
  }

  void _navigateToOcrScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OCRScreen(store: widget.store),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Icon(
        icon,
        color: isSelected ? AppColors.cascadingWhite : Colors.grey,
        size: 28,
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Floating Pill Container
            Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.secondaryDark,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(icon: Icons.home_rounded, index: 0),
                  _buildNavItem(icon: Icons.psychology_outlined, index: 1),
                  const SizedBox(width: 56), // Gap for FAB
                  _buildNavItem(icon: Icons.grid_view_rounded, index: 2),
                  _buildNavItem(icon: Icons.delete_outline_rounded, index: 3),
                ],
              ),
            ),

            // 2. Elevated Floating Add Button
            Positioned(
              top: -24,
              child: GestureDetector(
                onTap: _navigateToOcrScreen,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.lightYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildDashboard() {
    return SafeArea(
      bottom: false,
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
                    _performSemanticSearch(value);
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
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.only(left: 15),
            decoration: BoxDecoration(
              color: AppColors.pastelYellow,
              borderRadius: BorderRadius.circular(30),
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
                        count: category.memoryItems.where((item) => !item.isDeleted).length,
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

                final allItems = snapshot.data!;

                final List<MemoryItem> items;

                if (_searchQuery.trim().isEmpty) {
                  items = allItems;
                } else {
                  items = _semanticResults
                      .map((result) {
                    final taskId = result.task.id;

                    return allItems.cast<MemoryItem?>().firstWhere(
                          (item) => item?.todoTask.target?.id == taskId,
                      orElse: () => null,
                    );
                  })
                      .whereType<MemoryItem>()
                      .toList();
                }

                if (_semanticSearching) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lightYellow,
                    ),
                  );
                }

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
    );
  }

  @override
  void dispose() {
    _embeddingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          MemoryItemsTabScreen(store: widget.store),
          ArchivesScreen(store: widget.store),
          TrashScreen(store: widget.store),
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }
}
