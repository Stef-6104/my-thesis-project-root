import 'package:flutter/material.dart';

class GalleryFilesEx extends StatelessWidget{
  const GalleryFilesEx({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Gallery Files"),
      ),
    );
  }
}

