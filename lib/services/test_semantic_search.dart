import 'package:objectbox/objectbox.dart';
import 'package:my_thesis_project/services/embedding_service.dart';
import 'package:my_thesis_project/services/semantic_search_service.dart';

Future<void> testSemanticSearch(Store store) async {
  print('==============================');
  print('SEMANTIC SEARCH TEST');
  print('==============================');

  final embeddingService = EmbeddingService();

  try {
    await embeddingService.loadModel();

    final searchService = SemanticSearchService(
      store: store,
      embeddingService: embeddingService,
    );

    final results = await searchService.search(
      'fun run registration',
      limit: 5,
    );

    print('');
    print('Returned ${results.length} results.');

    print('==============================');
    print('SEMANTIC SEARCH TEST COMPLETE');
    print('==============================');
  } finally {
    await embeddingService.dispose();
  }
}