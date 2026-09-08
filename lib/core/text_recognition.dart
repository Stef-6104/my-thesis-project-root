import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:my_thesis_project/main.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:my_thesis_project/firebase_options.dart';

import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/objectbox.g.dart';
import 'package:my_thesis_project/services/embedding_service.dart';

class OCRScreen extends StatefulWidget {
  final Store store;
  const OCRScreen({super.key, required this.store});


  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {

  final EmbeddingService _embeddingService = EmbeddingService();

  final ImagePicker _picker = ImagePicker();

  File? _image;
  String _recognizedText = '';
  bool _loading = false;

  Future<void> saveOCRToObjectBox({
    required File imageFile,
    required String recognizedText,
    required Map<String, dynamic> aiData,
    required Store store,
  }) async {
    // 1. Prepare the text for EmbeddingGemma
    final textForEmbedding = '''
Title: ${aiData['title'] ?? 'Untitled Scan'}
Body: ${aiData['body'] ?? ''}
Date: ${aiData['date'] ?? ''}
Deadline: ${aiData['deadline'] ?? ''}
OCR Text: $recognizedText
''';

    // 2. Generate the 768-dimensional embedding
    final embedding =
    await _embeddingService.generateDocumentEmbedding(
      textForEmbedding,
    );

    print('Generated embedding length: ${embedding.length}');

    // 3. Create the TodoTask
    final newTask = TodoTask(
      image: imageFile.path,
      taskTitle: aiData['title'] ?? 'Untitled Scan',
      taskDescription: aiData['body'] ?? '',
      taskCreated: DateTime.now().toIso8601String(),
      taskDeadline: aiData['deadline'] ?? '',
      taskNote: 'Generated via OCR',
      ocrText: recognizedText,
      fileSizeBytes: await imageFile.length(),
      documentDate: aiData['date'],

      // Save EmbeddingGemma vector
      embedding: embedding,
    );

    // 4. Create MemoryItem wrapper
    final memoryItem = MemoryItem();
    memoryItem.todoTask.target = newTask;
    memoryItem.memoryNum = true;

    // 5. Save to ObjectBox
    store.box<MemoryItem>().put(memoryItem);

    print('===== EMBEDDING SAVED =====');
    print('Embedding exists: ${newTask.embedding != null}');
    print('Embedding length: ${newTask.embedding?.length}');
    print('First 5 values: ${newTask.embedding?.take(5).toList()}');
  }

  Future<void> saveOcrAsJson({
    required File imageFile,
    required String recognizedText,
    required Map<String, dynamic> aiData,
  }) async {
    final directory = await getApplicationDocumentsDirectory();

    final imageName = imageFile.path.split('/').last;
    final imagePath = imageFile.path;
    final fileSize = await imageFile.length();

    final jsonData = {
      "timestamp": DateTime.now().toIso8601String(),
      "image": imageName,
      "imagePath": imagePath,
      "fileSizeBytes": fileSize,

      "ocrText": recognizedText,

      "aiExtracted": aiData,
    };

    final fileName =
        'ocr_${DateTime.now().millisecondsSinceEpoch}.json';

    final file = File('${directory.path}/$fileName');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonData),
    );
  }

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

//   Future<Map<String, dynamic>> extractStructuredData(
//       String ocrText,
//       ) async {
//     final model = FirebaseAI.googleAI().generativeModel(
//       model: 'gemini-2.5-flash',
//     );
//
//     final response = await model.generateContent([
//       Content.text('''
//         Analyze the following OCR text.
//
//         Determine:
//
//         1. title
//            - Main heading or title of the document.
//            - If none exists, return null.
//
//         2. date
//            - The primary document date.
//            - Convert to YYYY-MM-DD when possible.
//            - If none exists, return null.
//
//         3. deadline
//            - Submission date, due date, closing date, deadline, etc.
//            - Convert to YYYY-MM-DD when possible.
//            - If none exists, return null.
//
//         4. body
//            - The main content of the document excluding title and dates.
//
//         Return ONLY valid JSON.
//
//         Format:
//
//         {
//           "title": "...",
//           "date": "...",
//           "deadline": "...",
//           "body": "..."
//         }
//
//         OCR TEXT:
//
//         $ocrText
//         ''')
//     ]);
//
//     final text = response.text ?? '{}';
//
//     print(response.text);
//
// // Remove Markdown code fences if present.
//     final cleanedText = text
//         .replaceAll('```json', '')
//         .replaceAll('```', '')
//         .trim();
//
//     print("Gemini Response:");
//     print(cleanedText);
//
//     try {
//       return jsonDecode(cleanedText);
//     } catch (e) {
//       print("JSON Decode Error: $e");
//
//       return {
//         "error": "Invalid JSON returned",
//         "rawResponse": cleanedText,
//       };
//     }
//   }



  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);

    if (file == null) return;

    setState(() {
      _loading = true;
      _image = File(file.path);
      _recognizedText = '';
    });

    await _recognizeText(File(file.path));

    setState(() {
      _loading = false;
    });
  }

  Future<void> _recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final recognizer = TextRecognizer();

    try {
      final RecognizedText result =
      await recognizer.processImage(inputImage);

      setState(() {
        _recognizedText = result.text;
      });



      final aiData = await extractStructuredData(
        result.text,
      );

      // PRINT THE RESULT HERE
      print("AI Result:");
      print(aiData);

      print("Title: ${aiData["title"]}");
      print("Date: ${aiData["date"]}");
      print("Deadline: ${aiData["deadline"]}");
      print("Body: ${aiData["body"]}");

      await saveOCRToObjectBox(
          imageFile: imageFile,
          recognizedText: result.text,
          aiData: aiData,
          store: widget.store,
      );

      await saveOcrAsJson(
        imageFile: imageFile,
        recognizedText: result.text,
        aiData: aiData,
      );

    } finally {
      await recognizer.close();
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
        title: const Text('OCR Scanner'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          )

      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              Expanded(
                flex: 2,
                child: Image.file(_image!),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_loading)
              const CircularProgressIndicator(),

            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _recognizedText.isEmpty
                        ? 'Recognized text will appear here'
                        : _recognizedText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}