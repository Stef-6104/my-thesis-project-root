import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_thesis_project/core/text_recognition.dart';
import 'package:my_thesis_project/data/gallery%20example/gallery_filesEx.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:my_thesis_project/presentation/screens/todo_list_screen.dart';
import 'package:objectbox/objectbox.dart';

import 'objectbox.g.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleSignIn.instance.initialize(
    serverClientId: '432820843570-8tq99r3llpbp2h1fhiarq227h4ph757d.apps.googleusercontent.com',
  );

  final store = await openStore();

  runApp( MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store store;
  const MyApp({super.key, required this.store});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/database',
      routes: {
        "/gallery" : (_) => const GalleryFilesEx(),
        "/recognition" : (_) => OCRScreen(store: store),
        "/database" : (_) => MyHomePage(title: 'Memory Hub', store: store),
      },
    );

  }

}


class MyHomePage extends StatefulWidget {
  final Store store;
  final String title;


  const MyHomePage({super.key, required this.title, required this.store});




  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Box<MemoryItem> _memoryBox;
  SyncClient? _syncClient;

  late Stream<List<MemoryItem>> _memoryStream;

  @override
  void initState() {
    super.initState();
        _memoryBox = widget.store.box<MemoryItem>();
        // 1. Corrected URI format
        var syncServerIp = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
        // 2. Initialize and START the client
        _syncClient = SyncClient(
            widget.store,
            ['ws://$syncServerIp:9999'],
            [SyncCredentials.none()]
        );
        _syncClient?.start();

        _memoryStream = _memoryBox
            .query()
            .watch(triggerImmediately: true)
            .map((query) => query.find());

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
          widget.store.box<TodoTask>().put(exampleTask);

          final exampleItem = MemoryItem();
          exampleItem.todoTask.target = exampleTask;
          _memoryBox.put(exampleItem);
        }
        // 3. Fetch item inside the callback to ensure _memoryBox is ready



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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OCRScreen(store: widget.store)),
              )

          )
        ],
      ),
      body: StreamBuilder<List<MemoryItem>>(
        stream: _memoryStream,
        builder: (context, snapshot){
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Your Memory Hub is Empty"));

          }
          final items = snapshot.data!;

          // 4. GridView to show multiple tasks
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (context, index){
              final item = items[index];
              final task = item.todoTask.target;

              return GestureDetector(
                  onTap: (){
                    if (task != null){
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TaskInfoScreen(task: task, store: widget.store),
                          )
                      );
                    }
                  },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12
                    ),
                  ),
                  padding: const EdgeInsets.all(15),
                  alignment: Alignment.center,
                  child: Text(
                    task?.taskTitle ??'No Task title',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),



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
    super.dispose();

  }
}

