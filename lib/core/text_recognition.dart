import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:my_thesis_project/presentation/screens/overview_screen.dart';
import 'package:firebase_ai/firebase_ai.dart';

import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/objectbox.g.dart';

class OCRScreen extends StatefulWidget {
  final Store store;
  const OCRScreen({super.key, required this.store});

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
    // 1. Convert summary list to bulleted string
    final List<dynamic> summaryList = aiData['summary'] ?? [];
    final String summaryText = summaryList.map((e) => '• $e').join('\n');

    // 2. Parse due_date_time if present
    DateTime? dueDate;
    final taskData = aiData['task'];
    if (taskData != null && taskData['due_date_time'] != null) {
      dueDate = DateTime.tryParse(taskData['due_date_time'].toString());
    }

    // 3. Create Task from JSON
    final newTask = TodoTask(
      image: imageFile.path,
      taskTitle: aiData['title'] ?? 'Untitled Scan',
      taskDescription: summaryText,
      taskCreated: DateTime.now().toIso8601String(),
      taskDeadline: aiData['deadline'] ?? '',
      taskNote: 'Generated via OCR',
      ocrText: recognizedText,
      fileSizeBytes: await imageFile.length(),
      dueDate: dueDate,
    );

    // 4. Create the MemoryItem wrapper
    final memoryItem = MemoryItem();
    memoryItem.todoTask.target = newTask;
    memoryItem.memoryNum = true;

    // 5. Save to db
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

  Future<Map<String, dynamic>> extractStructuredData(String ocrText) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2, // Low temperature for deterministic, structured extraction
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

      // Clean markdown code blocks if present
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

      final Map<String, dynamic> data = jsonDecode(cleanedJson);
      return data;
    } catch (e) {
      print('Error parsing Gemini extraction: $e');
      return {
        "title": "Untitled Scan",
        "summary": ["Failed to parse structured summary."],
        "deadline": null,
        "task": null,
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

      // PRINT THE RESULT HERE
      print("AI Result: $aiData");

      // 1. Prepare bulleted summary
      final List<dynamic> summaryList = aiData['summary'] ?? [];
      final String summaryText = summaryList.map((e) => '• $e').join('\n');

      // 2. Parse due_date_time
      DateTime? dueDate;
      final taskData = aiData['task'];
      if (taskData != null && taskData['due_date_time'] != null) {
        dueDate = DateTime.tryParse(taskData['due_date_time'].toString());
      }

      final newTask = TodoTask(
        image: imageFile.path,
        taskTitle: aiData['title'] ?? 'Untitled Scan',
        taskDescription: summaryText,
        taskCreated: DateTime.now().toIso8601String(),
        taskDeadline: aiData['deadline'] ?? '',
        ocrText: result.text,
        dueDate: dueDate,
      );

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