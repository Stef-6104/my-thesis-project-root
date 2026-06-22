import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/gallery%20example/gallery_filesEx.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/screens/task_info_screen.dart';
import 'package:objectbox/objectbox.dart';

import 'objectbox.g.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'Thesis Application',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Memory Hub'),
      routes: {
        "/gallery": (_) => const GalleryFilesEx(),
      },
    );

  }

}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Store? _store;
  late final Box<MemoryItem> _memoryBox;
  SyncClient? _syncClient;


  MemoryItem? currentItem;

  @override
  void initState() {
    super.initState();
    openStore().then((Store store){
      if (!mounted) return;
      setState(() {
        _store = store;
        _memoryBox = store.box<MemoryItem>();
        // 1. Corrected URI format
        var syncServerIp = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
        // 2. Initialize and START the client
        _syncClient = SyncClient(
            store,
            ['ws://$syncServerIp:9999'],
            [SyncCredentials.none()]
        );
        _syncClient?.start();

        if (_memoryBox.isEmpty()) {
          final exampleTask = TodoTask(
              image: "assets/example.png",
              taskTitle: "Complete Thesis",
              taskDescription: "Finalize the implementation of the information ingestion system.",
              taskCreated: DateTime.now().toString(),
              taskCompleted: false,
              taskNote: "Remember to test all Gradle versions.",
              taskDeadline: "2026-12-31"
          );
          _store!.box<TodoTask>().put(exampleTask);

          final exampleItem = MemoryItem();
          exampleItem.todoTask.target = exampleTask;
          _memoryBox.put(exampleItem);
        }
        // 3. Fetch item inside the callback to ensure _memoryBox is ready
        currentItem = _memoryBox.getAll().firstOrNull;
      });
    });
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
        actions: [
          IconButton(
              icon: const Icon(Icons.image),
              tooltip: 'Open Gallery',
              onPressed: () => Navigator.pushNamed(context, "/gallery"),
          )
        ],
      ),
      body:
      currentItem == null
          ? const Center(child: Text("Memory Item does not Exist"),):
      GestureDetector(
        onTap: (){
          final task = currentItem?.todoTask.target;
          if (task != null){
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => TaskInfoScreen(task: task, store: _store!),
                )
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(50),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
            child: Text(currentItem!.todoTask.target?.taskTitle ??'No Task title',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      )
      );
  }
  void setNewMemoryItm(){
    setTodoTask();
  }
  void setTodoTask(){

  }

  @override
  void dispose(){
    _syncClient?.close();
    _store?.close();
    super.dispose();

  }
}

