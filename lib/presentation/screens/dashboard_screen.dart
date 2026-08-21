import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/objectbox.g.dart';
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
  late Stream<List<MemoryItem>> _memoryStream;
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _memoryBox = widget.store.box<MemoryItem>();
    _memoryStream = _memoryBox
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Memory Hub',
                    style: TextStyle(
                      color: AppColors.cascadingWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier', // For that typewriter look in the screenshot
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomSearchBar(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Category:',
                        style: TextStyle(color: AppColors.cascadingWhite, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.cascadingWhite),
                        onPressed: () {
                          // TODO: Folder creation
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 160,
              padding: const EdgeInsets.only(left: 20),
              decoration: const BoxDecoration(
                color: AppColors.pastelYellow,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: const [
                  CategoryCard(title: 'Activities', count: 1),
                  CategoryCard(title: 'Quizzes', count: 0),
                  CategoryCard(title: 'Exam', count: 0),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.secondaryDark,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
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
      ),
    );
  }
}
