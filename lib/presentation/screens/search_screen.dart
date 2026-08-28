import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';

import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/services/embedding_service.dart';
import 'package:my_thesis_project/services/semantic_search_service.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  final Store store;

  const SearchScreen({
    super.key,
    required this.store,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  late final EmbeddingService _embeddingService;
  late final SemanticSearchService _searchService;

  List<SemanticSearchResult> _results = [];

  bool _searching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();

    _embeddingService = EmbeddingService();

    _searchService = SemanticSearchService(
      store: widget.store,
      embeddingService: _embeddingService,
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
      });
      return;
    }

    setState(() {
      _searching = true;
      _lastQuery = query;
    });

    try {
      final results = await _searchService.search(
        query,
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _results = results;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Search failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _embeddingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semantic Search'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // SEARCH BOX
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Search your memories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _performSearch,
                ),
                filled: true,
                fillColor: AppColors.darkGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_searching)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),

            if (!_searching &&
                _lastQuery.isNotEmpty &&
                _results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No matching memories found.',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),

            if (!_searching &&
                _lastQuery.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Try searching for something like:\n'
                      '"fun run registration"\n'
                      '"thesis deadline"\n'
                      '"school assignment"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),

            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final task = result.task;

                  return _buildResultCard(
                    task,
                    result.similarity,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
      TodoTask task,
      double similarity,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightYellow,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.taskTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            task.taskDescription,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.lightYellow,
              ),
              const SizedBox(width: 6),
              Text(
                'Similarity: ${(similarity * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.lightYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (task.taskDeadline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Deadline: ${task.taskDeadline}',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}