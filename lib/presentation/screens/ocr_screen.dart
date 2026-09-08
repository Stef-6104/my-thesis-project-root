import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:my_thesis_project/presentation/screens/overview_screen.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/services/embedding_service.dart';
import 'package:my_thesis_project/presentation/screens/search_screen.dart';

class OCRScreen extends StatefulWidget {
  final Store store;
  const OCRScreen({super.key, required this.store});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final ImagePicker _picker = ImagePicker();
  final EmbeddingService _embeddingService = EmbeddingService();
  bool _loading = false;

  Future<Map<String, dynamic>> extractStructuredData(String ocrText) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );

    final prompt = '''
  You are an intelligent multimodal parser and summarizer for a productivity and memory management app.
  Analyze the following unstructured OCR text extracted from an image or screenshot.
  
  Extract and synthesize the information into the following structured JSON format:
  
  {
    "title": "A concise, clear document/event/task title (max 6-8 words)",
    "summary": [
      "Key takeaway or description bullet point 1",
      "Key takeaway or description bullet point 2",
      "Key takeaway or description bullet point 3"
    ],
    "deadline": "Formatted deadline or event timestamp (e.g. MM/DD/YYYY, HH:MM AM/PM or YYYY-MM-DD HH:mm). If none exists, return null.",
    "task": {
      "title": "Actionable task name",
      "due_date_time": "ISO-8601 string (YYYY-MM-DDTHH:mm:ss) or readable format if a due date/time is mentioned, otherwise null"
    }
  }
  
  CRITICAL RULES:
  1. DO NOT copy-paste the entire raw OCR paragraph into the summary. Synthesize the text into 2 to 4 concise, high-value bullet points.
  2. Search aggressively for dates, deadlines, assembly times, and submission cutoffs. Convert relative dates or explicit dates into clean, standardized formats.
  3. If no deadline exists, return null for "deadline".
  4. Return ONLY valid, parseable JSON matching the schema above.
  
  OCR TEXT:
  $ocrText
  ''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text?.trim() ?? '{}';

      String cleanedJson = rawText;
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.replaceFirst('```json', '');
      }
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.replaceFirst('```', '');
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      return jsonDecode(cleanedJson);
    } catch (e) {
      return {
        "title": "Scan Result",
        "summary": ["Failed to parse structured summary."],
        "deadline": null,
        "task": null,
      };}}

  // Future<Map<String, dynamic>> extractStructuredData(String ocrText) async {
  //   final model = FirebaseAI.googleAI().generativeModel(
  //     model: 'gemini-2.5-flash',
  //   );
  //
  //   final response = await model.generateContent([
  //     Content.text('''
  //       Analyze the following OCR text and extract structured information.
  //
  //       Return ONLY valid JSON with these fields:
  //       {
  //         "title": "...",
  //         "date": "...",
  //         "deadline": "...",
  //         "body": "..."
  //       }
  //
  //       OCR TEXT:
  //       $ocrText
  //       ''')
  //   ]);
  //
  //   final text = response.text ?? '{}';
  //   final cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();
  //
  //   try {
  //     return jsonDecode(cleanedText);
  //   } catch (e) {
  //     return {"title": "Scan Result", "body": ocrText};
  //   }
  // }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file == null) return;

    setState(() => _loading = true);

    final inputImage = InputImage.fromFile(File(file.path));
    final recognizer = TextRecognizer();
    
    try {
      final RecognizedText result = await recognizer.processImage(inputImage);
      final aiData = await extractStructuredData(result.text);

      // Generate EmbeddingGemma vector
      final embeddingService = EmbeddingService();

      // Generate embedding from the extracted document information
      final textForEmbedding = '''
        Title: ${aiData['title'] ?? 'Untitled Scan'}
        Body: ${aiData['body'] ?? ''}
        Date: ${aiData['date'] ?? ''}
        Deadline: ${aiData['deadline'] ?? ''}
        OCR Text: ${result.text}
      ''';

      final embedding =
      await _embeddingService.generateDocumentEmbedding(
        textForEmbedding,
      );

      print('===== EMBEDDING GENERATED =====');
      print('Embedding length: ${embedding.length}');
      print('Embedding generated: ${embedding.length} dimensions');

      final newTask = TodoTask(
        image: file.path,
        taskTitle: aiData['title'] ?? 'Untitled Scan',
        taskDescription: aiData['body'] ?? '',
        taskCreated: DateTime.now().toIso8601String(),
        taskDeadline: aiData['deadline'] ?? '',
        ocrText: result.text,
        embedding: embedding,
      );

      await embeddingService.dispose();

      final memoryItem = MemoryItem();
      memoryItem.todoTask.target = newTask;

      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OverviewScreen(
            item: memoryItem,
            store: widget.store,
            isPreSave: true,
          ),
        ),
      );
    } finally {
      await recognizer.close();
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _embeddingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionCard(
              icon: Icons.camera_alt,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 30),
            _buildActionCard(
              icon: Icons.image,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_loading) ...[
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: AppColors.lightYellow),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lightYellow,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(icon, size: 80, color: Colors.black),
      ),
    );
  }
}
