import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const OCRApp());
}

class OCRApp extends StatelessWidget {
  const OCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OCR Scanner',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
      ),
      home: const OCRScreen(),
    );
  }
}

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

  Future<void> saveOcrAsJson({
    required String imageName,
    required String recognizedText,
  }) async {
    final directory = await getApplicationDocumentsDirectory();

    final jsonData = {
      "timestamp": DateTime.now().toIso8601String(),
      "image": imageName,
      "text": recognizedText,
    };

    final fileName =
        'ocr_${DateTime.now().millisecondsSinceEpoch}.json';

    final file = File('${directory.path}/$fileName');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonData),
    );

    debugPrint('JSON saved: ${file.path}');
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

      // ADD THIS
      await saveOcrAsJson(
        imageName: imageFile.path.split('/').last,
        recognizedText: result.text,
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