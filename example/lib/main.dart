import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:story_creator/story_creator.dart';

void main() {
  runApp(
    new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? editedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story Creator Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            editedFile != null
                ? Image.file(
                    editedFile!,
                    fit: BoxFit.cover,
                  )
                : SizedBox.shrink(),
            TextButton(
              onPressed: () async {
                final picker = ImagePicker();
                await picker
                    .pickImage(source: ImageSource.gallery)
                    .then((file) async {
                  editedFile = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StoryCreator(
                        filePath: file!.path,
                      ),
                    ),
                  );

                  // ------- you have editedFile

                  if (editedFile != null) {
                    print('editedFile: ' + editedFile!.path);
                    setState(() {});
                  }
                });
              },
              child: Text('Pick Image'),
            ),
            TextButton(
              onPressed: () async {
                editedFile = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StoryCreator(
                      bgColor: Colors.amber,
                    ),
                  ),
                );

                // ------- you have editedFile

                if (editedFile != null) {
                  print('editedFile: ' + editedFile!.path);
                  setState(() {});
                }
              },
              child: Text('Create Text'),
            ),
          ],
        ),
      ),
    );
  }
}
