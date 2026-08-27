import 'package:firebase_ai/firebase_ai.dart';


class AIService {
  Future<List<double>> getEmbedding(String text) async {
    final model = FirebaseAI.googleAI().generativeModel(model: 'text-embedding-004');
    final result = await model.embedContent(Content.text(text));
    return result.embedding.values;
  }

  Future<String> generateRAGResponse(String userQuery, String context) async {
    final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-1.5-flash');
    final response = await model.generateContent([
      Content.text('''
        You are a personal memory assistant. Use the following context from the user's scanned documents to answer their question.
        
        CONTEXT:
        $context
        
        USER QUESTION:
        "$userQuery"
        
        Answer in ONE clear, helpful sentence. If the answer isn't in the context, say "I couldn't find any documents related to that."
      ''')
    ]);
    return response.text ?? "";
  }
}
