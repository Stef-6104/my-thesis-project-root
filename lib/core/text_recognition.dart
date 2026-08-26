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

import 'package:my_thesis_project/services/calendar_service.dart';

class OCRScreen extends StatefulWidget {
  final Store store;
  const OCRScreen({super.key, required this.store});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final GoogleCalendarService _calendarService =
  GoogleCalendarService();

  Map<String, dynamic>? _aiData;

  final ImagePicker _picker = ImagePicker();

  List<File> _images = [];

  final TextEditingController _textController =
  TextEditingController();

  String _recognizedText = '';
  bool _loading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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

    print(response.text);

// Remove Markdown code fences if present.
    final cleanedText = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    print("Gemini Response:");
    print(cleanedText);

    try {
      return jsonDecode(cleanedText);
    } catch (e) {
      print("JSON Decode Error: $e");

      return {
        "error": "Invalid JSON returned",
        "rawResponse": cleanedText,
      };
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);

    if (file == null) return;

    final imageFile = File(file.path);

    setState(() {
      _loading = true;
      _images.add(imageFile);
    });

    try {
      await _recognizeText(imageFile);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer();

    try {
      final RecognizedText result =
      await recognizer.processImage(inputImage);

      setState(() {
        if (_textController.text.isEmpty) {
          _textController.text = result.text;
        } else {
          _textController.text +=
          '\n\n--- NEXT PAGE ---\n\n${result.text}';
        }

        _recognizedText = _textController.text;
      });

      print("OCR from ${imageFile.path}:");
      print(result.text);

    } finally {
      await recognizer.close();
    }
  }

  Future<void> _processDocument() async {
    if (_images.isEmpty || _recognizedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image.'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Send ALL pages to Gemini at once
      final aiData = await extractStructuredData(
        _textController.text,
      );

      setState(() {
        _aiData = aiData;
      });

      print("AI Result:");
      print(aiData);

      // Use the first image as the primary image
      // while keeping all pages available separately.
      await saveOCRToObjectBox(
        imageFile: _images.first,
        recognizedText: _recognizedText,
        aiData: aiData,
        store: widget.store,
      );

      // Save combined OCR JSON
      await saveOcrAsJson(
        imageFile: _images.first,
        recognizedText: _recognizedText,
        aiData: aiData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document processed successfully!'),
          ),
        );
      }
    } catch (e) {
      print("Processing error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing document: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _addToCalendar() async {
    if (_aiData == null) {
      return;
    }

    final deadline = _aiData!['deadline'];

    if (deadline == null ||
        deadline.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No deadline was found.'),
        ),
      );

      return;
    }

    final success = await _calendarService.addDeadline(
      title: _aiData!['title'] ?? 'OCR Deadline',
      deadline: deadline.toString(),
      description: _aiData!['body'] ?? '',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Added to Google Calendar!'
              : 'Failed to add to Google Calendar.',
        ),
      ),
    );
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
            if (_images.isNotEmpty)
              Expanded(
                flex: 2,
                child: GridView.builder(
                  itemCount: _images.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Page number
                        Positioned(
                          top: 5,
                          left: 5,
                          child: CircleAvatar(
                            radius: 14,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),

                        // Delete button
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _images.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
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

            const SizedBox(height: 10),

            if (_images.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.document_scanner),
                  label: Text(
                    'Process ${_images.length} Image'
                        '${_images.length == 1 ? '' : 's'}',
                  ),
                  onPressed: _loading ? null : _processDocument,
                ),
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
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Recognized text will appear here',
                  ),
                  onChanged: (value) {
                    _recognizedText = value;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_aiData != null &&
                _aiData!['deadline'] != null &&
                _aiData!['deadline'].toString().isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text(
                    'Add Deadline to Google Calendar',
                  ),
                  onPressed: _addToCalendar,
                ),
              ),
          ],
        ),
      ),
    );
  }
}