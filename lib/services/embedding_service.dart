import 'package:flutter_gemma/flutter_gemma.dart';

class EmbeddingService {
EmbeddingModel? _model;

/// Install the EmbeddingGemma model and set it as active.
Future<void> installModel() async {
print('Installing EmbeddingGemma...');

await FlutterGemma.installEmbedder()
    .modelFromNetwork(
'https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/embeddinggemma-300M_seq256_mixed-precision.tflite',
)
    .tokenizerFromNetwork(
'https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/sentencepiece.model',
)
    .install();

print('EmbeddingGemma installation complete.');
}

/// Load the active EmbeddingGemma model.
Future<void> loadModel() async {
print('Loading EmbeddingGemma...');

if (!FlutterGemma.hasActiveEmbedder()) {
await installModel();
}

_model = await FlutterGemma.getActiveEmbedder();

print('EmbeddingGemma loaded.');
}

/// Generate one 768-dimensional embedding.
Future<List<double>> generateDocumentEmbedding(String text) async {
if (_model == null) {
await loadModel();
}

final vector = await _model!.generateEmbedding(text);

print('Generated embedding dimension: ${vector.length}');

return vector;
}

/// Close the model when finished.
Future<void> dispose() async {
await _model?.close();
_model = null;
}
}

