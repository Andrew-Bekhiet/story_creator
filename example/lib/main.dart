import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:story_creator/story_creator.dart';
import 'package:story_creator/centered_stack.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

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
  Story? story;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story Creator Example'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (story != null)
              CenteredStack(
                alignment: Alignment.center,
                children: [
                  Image.file(
                    story!.image,
                    fit: BoxFit.cover,
                  ),
                  ...story!.gifs.map(
                    (gif) => Positioned(
                      top: gif.position.dy,
                      left: gif.position.dx,
                      child: Transform.rotate(
                        angle: gif.rotation,
                        child: Transform.scale(
                          scale: gif.scale,
                          child: ConstrainedBox(
                            constraints: BoxConstraints.loose(
                                MediaQuery.of(context).size),
                            child: Image.network(gif.url),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            TextButton(
              onPressed: () async {
                final picker = ImagePicker();
                await picker
                    .pickImage(source: ImageSource.gallery)
                    .then((file) async {
                  story = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StoryCreator(
                        toolbarAlignment: Alignment.center,
                        toolbarMainAxisAlignment: MainAxisAlignment.spaceAround,
                        filePath: file!.path,
                      ),
                    ),
                  );

                  // ------- you have editedFile

                  if (story != null) {
                    setState(() {});
                  }
                });
              },
              child: Text('Pick Image'),
            ),
            TextButton(
              onPressed: () async {
                story = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StoryCreator(
                      toolbarAlignment: Alignment.topCenter,
                      toolbarMainAxisAlignment: MainAxisAlignment.spaceAround,
                      bgColor: Colors.amber,
                    ),
                  ),
                );

                if (story != null) {
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
