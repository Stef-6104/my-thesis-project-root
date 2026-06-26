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

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
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
    //1. Create Task from JSON
    final newTask = TodoTask(
      image: imageFile.path,
      taskTitle: aiData['title'] ?? 'Untitled Scan',
      taskDescription: aiData ['body'] ?? '',
      taskCreated: DateTime.now().toIso8601String(),
      taskDeadline: aiData['deadline'] ?? '',
      taskNote: 'Generated via OCR',
      ocrText: recognizedText,
      fileSizeBytes: await imageFile.length(),
      documentDate: aiData['date'],
    );

    //2. Create the MemoryItem wrapper
    final memoryItem = MemoryItem();
    memoryItem.todoTask.target = newTask;
    memoryItem.memoryNum = true;

    //3. Save to db
    store.box<MemoryItem>().put(memoryItem);

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

  Future<Map<String, dynamic>> extractStructuredData(
      String ocrText,
      ) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );

    final response = await model.generateContent([
      Content.text('''
Analyze the following OCR text.

Determine:

1. title
   - Main heading or title of the document.
   - If none exists, return null.

2. date
   - The primary document date.
   - Convert to YYYY-MM-DD when possible.
   - If none exists, return null.

3. deadline
   - Submission date, due date, closing date, deadline, etc.
   - Convert to YYYY-MM-DD when possible.
   - If none exists, return null.

4. body
   - The main content of the document excluding title and dates.

Return ONLY valid JSON.

Format:

{
  "title": "...",
  "date": "...",
  "deadline": "...",
  "body": "..."
}

OCR TEXT:

$ocrText
''')
    ]);

    final text = response.text ?? '{}';

    try {
      return jsonDecode(text);
    } catch (_) {
      return {
        "error": "Invalid JSON returned",
        "rawResponse": text,
      };
    }
  }

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