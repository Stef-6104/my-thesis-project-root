import 'dart:math';

import 'package:objectbox/objectbox.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/services/embedding_service.dart';

class SemanticSearchResult {
  final TodoTask task;
  final double similarity;

  SemanticSearchResult({
    required this.task,
    required this.similarity,
  });
}

class SemanticSearchService {
  final Store store;
  final EmbeddingService embeddingService;

  SemanticSearchService({
    required this.store,
    required this.embeddingService,
  });

  /// Search TodoTasks using semantic similarity.
  Future<List<SemanticSearchResult>> search(
      String query, {
        int limit = 10,
      }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    print('===== SEMANTIC SEARCH =====');
    print('Query: $query');

    // Generate embedding for the user's search query.
    final queryEmbedding =
    await embeddingService.generateDocumentEmbedding(query);

    print('Query embedding length: ${queryEmbedding.length}');

    final tasks = store.box<TodoTask>().getAll();

    final results = <SemanticSearchResult>[];

    for (final task in tasks) {
      final embedding = task.embedding;

      // Skip tasks that don't have embeddings.
      if (embedding == null || embedding.isEmpty) {
        continue;
      }

      // Make sure the dimensions match.
      if (embedding.length != queryEmbedding.length) {
        print(
          'Skipping task ${task.id}: '
              'embedding dimension ${embedding.length} != '
              'query dimension ${queryEmbedding.length}',
        );
        continue;
      }

      final similarity = _cosineSimilarity(
        queryEmbedding,
        embedding,
      );

      results.add(
        SemanticSearchResult(
          task: task,
          similarity: similarity,
        ),
      );
    }

    // Highest similarity first.
    results.sort(
          (a, b) => b.similarity.compareTo(a.similarity),
    );

    final limitedResults = results.take(limit).toList();

    print('===== SEARCH RESULTS =====');

    for (final result in limitedResults) {
      print('');
      print('Task ID: ${result.task.id}');
      print('Title: ${result.task.taskTitle}');
      print('Similarity: ${result.similarity}');
      print('Description: ${result.task.taskDescription}');
      print('Deadline: ${result.task.taskDeadline}');
      print('Embedding length: ${result.task.embedding?.length}');
    }

    print('==========================');

    return limitedResults;
  }

  double _cosineSimilarity(
      List<double> a,
      List<double> b,
      ) {
    double dotProduct = 0;
    double magnitudeA = 0;
    double magnitudeB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      magnitudeA += a[i] * a[i];
      magnitudeB += b[i] * b[i];
    }

    if (magnitudeA == 0 || magnitudeB == 0) {
      return 0;
    }

    return dotProduct /
        (sqrt(magnitudeA) * sqrt(magnitudeB));
  }
}