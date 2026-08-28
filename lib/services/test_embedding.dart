import 'package:my_thesis_project/services/embedding_service.dart';

Future<void> testEmbedding() async {
  final service = EmbeddingService();

  try {
    await service.loadModel();

    final vector = await service.generateDocumentEmbedding(
      'I need to submit my thesis research paper next week.',
    );

    print('====================================');
    print('EMBEDDING TEST SUCCESSFUL');
    print('Vector length: ${vector.length}');
    print('First 10 values: ${vector.take(10).toList()}');
    print('====================================');
  } catch (e, stackTrace) {
    print('====================================');
    print('EMBEDDING TEST FAILED');
    print('Error: $e');
    print(stackTrace);
    print('====================================');
  } finally {
    await service.dispose();
  }
}