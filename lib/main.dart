import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/presentation/screens/dashboard_screen.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';
import 'package:objectbox/objectbox.dart';
import 'objectbox.g.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:my_thesis_project/services/test_embedding.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import 'services/test_embedding.dart';
import 'package:my_thesis_project/services/test_semantic_search.dart';
import 'secrets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FlutterGemma.initialize(
    huggingFaceToken: huggingFaceToken,
    embeddingBackends: [const LiteRtEmbeddingBackend()],
  );

  await testEmbedding();

  final store = await openStore();

  await testSemanticSearch(store);

  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store store;
  const MyApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Hub',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: Initializer(store: store),
    );
  }
}

class Initializer extends StatefulWidget {
  final Store store;
  const Initializer({super.key, required this.store});

  @override
  State<Initializer> createState() => _InitializerState();
}

class _InitializerState extends State<Initializer> {
  SyncClient? _syncClient;

  @override
  void initState() {
    super.initState();
    _initSync();
    _checkInitialData();
  }

  void _initSync() {
    var syncServerIp = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    _syncClient = SyncClient(
        widget.store,
        ['ws://$syncServerIp:9999'],
        [SyncCredentials.none()]
    );
    _syncClient?.start();
  }

  void _checkInitialData() {
    final memoryBox = widget.store.box<MemoryItem>();
    if (memoryBox.isEmpty()) {
      final exampleTask = TodoTask(
          image: "assets/example.png",
          taskTitle: "Complete Thesis",
          taskDescription: "Finalize the implementation of the information ingestion system.",
          taskCreated: DateTime.now().toString(),
          taskCompleted: false,
          taskNote: "Remember to test all Gradle versions.",
          taskDeadline: "2026-12-31"
      );
      widget.store.box<TodoTask>().put(exampleTask);

      final exampleItem = MemoryItem();
      exampleItem.todoTask.target = exampleTask;
      memoryBox.put(exampleItem);
    }
  }

  @override
  void dispose() {
    _syncClient?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(store: widget.store);
  }
}
