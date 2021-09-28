library story_creator;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:ui' as ui;

class StoryCreator extends StatefulWidget {
  StoryCreator({
    Key? key,
    this.filePath,
    this.bgColor,
  }) : super(key: key);

  final String? filePath;
  final Color? bgColor;

  @override
  _StoryCreatorState createState() => _StoryCreatorState();
}

class _StoryCreatorState extends State<StoryCreator> {
  static const List<String> fontFamilyList = [
    "Lato",
    "Montserrat",
    "Lobster",
    "Spectral SC",
    "Dancing Script",
    "Oswald",
    "Turret Road",
    "Noto Serif",
    "Anton"
  ];

  final GlobalKey previewContainer = GlobalKey();

  final ValueNotifier<Color?> bgColor = ValueNotifier(null);

  List<EditableItem> stackData = [];

  final ValueNotifier<EditableItem?> _activeItem = ValueNotifier(null);

  Offset? initialPostition;
  double? initialScale;
  double? initialRotation;

  final ValueNotifier<bool> isOnDelete = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    bgColor.value = widget.bgColor;

    if (stackData.isEmpty && widget.filePath != null)
      stackData.add(EditableItem(
        type: ItemType.Image,
        value: widget.filePath,
        position: Offset(0.5, 0.5),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color?>(
      valueListenable: bgColor,
      child: GestureDetector(
        onScaleStart: (details) {
          if (_activeItem.value == null) return;

          initialPostition = _activeItem.value!.position.value;
          initialScale = _activeItem.value!.scale.value;
          initialRotation = _activeItem.value!.rotation.value;
        },
        onScaleUpdate: (details) {
          if (_activeItem.value == null ||
              initialPostition == null ||
              initialScale == null ||
              initialRotation == null) return;

          final delta = details.delta;
          final left = delta.dx / MediaQuery.of(context).size.width;
          final top = delta.dy / MediaQuery.of(context).size.height;

          _activeItem.value!.position.value =
              Offset(left, top) + initialPostition!;
          _activeItem.value!.rotation.value =
              details.rotation + initialRotation!;
          _activeItem.value!.scale.value = details.scale * initialScale!;
        },
        child: Stack(
          children: [
            SafeArea(
              child: RepaintBoundary(
                key: previewContainer,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: _editOrAddItem,
                    ),
                    if (stackData.isEmpty)
                      GestureDetector(
                        onTap: _editOrAddItem,
                        child: Center(
                          child: Text(
                            'Tap to type',
                            style:
                                Theme.of(context).textTheme.headline5?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.color
                                          ?.withOpacity(0.4),
                                    ),
                          ),
                        ),
                      ),
                    ...stackData.map(_buildItemWidget),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: Icon(
                  Icons.color_lens,
                  color: Colors.white,
                  size: 33,
                ),
                onPressed: () async {
                  final rslt = await _pickColor(
                    bgColor.value ??
                        Theme.of(context).textTheme.headline5?.color ??
                        Colors.white,
                  );
                  if (rslt != null) bgColor.value = rslt;
                },
              ),
            ),
            ValueListenableBuilder<EditableItem?>(
              valueListenable: _activeItem,
              child: Positioned(
                bottom: 20,
                right: 20,
                child: TextButton(
                  onPressed: () async {
                    //done: save image and return captured image to previous screen

                    RenderRepaintBoundary boundary =
                        previewContainer.currentContext!.findRenderObject()
                            as RenderRepaintBoundary;
                    ui.Image image = await boundary.toImage(
                      pixelRatio: 2.0,
                    );
                    final directory = (await getTemporaryDirectory()).path;
                    ByteData? byteData = await image.toByteData(
                      format: ui.ImageByteFormat.png,
                    );
                    Uint8List pngBytes = byteData!.buffer.asUint8List();
                    // print(pngBytes);

                    File imgFile = File(
                        '$directory/' + DateTime.now().toString() + '.png');
                    imgFile.writeAsBytes(pngBytes).then((value) {
                      // done: return imgFile
                      Navigator.of(context).pop(imgFile);
                    });
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all(
                      Colors.black.withOpacity(0.7),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              builder: (context, activeItem, child) => Visibility(
                visible: activeItem == null && stackData.isNotEmpty,
                child: child!,
              ),
            ),
            ValueListenableBuilder<EditableItem?>(
              valueListenable: _activeItem,
              child: Positioned(
                bottom: MediaQuery.of(context).size.height * 0.02,
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isOnDelete,
                    builder: (context, isOnDelete, _) {
                      return Container(
                        height: !isOnDelete ? 60.0 : 100,
                        width: !isOnDelete ? 60.0 : 100,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.all(
                            Radius.circular(!isOnDelete ? 30 : 50),
                          ),
                        ),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: !isOnDelete ? 30 : 50,
                        ),
                      );
                    },
                  ),
                ),
              ),
              builder: (context, activeItem, child) {
                return Visibility(
                  visible: activeItem != null,
                  child: child!,
                );
              },
            ),
          ],
        ),
      ),
      builder: (context, bgColor, body) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: bgColor,
          body: body,
        );
      },
    );
  }

  void _editOrAddItem([EditableItem? activeItem]) async {
    final item = activeItem?.copy() ?? EditableItem(type: ItemType.Text);
    final TextEditingController itemTextController =
        TextEditingController(text: item.value.value);

    final rslt = await Navigator.of(context).push<EditableItem?>(
      DialogRoute(
        context: context,
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 1.5,
                  child: ValueListenableBuilder<int>(
                    valueListenable: item.textStyle,
                    child: ValueListenableBuilder<int>(
                      valueListenable: item.fontFamily,
                      builder: (context, fontFamily, child) =>
                          ValueListenableBuilder<Color?>(
                        valueListenable: item.color,
                        builder: (context, color, child) =>
                            ValueListenableBuilder<double>(
                          valueListenable: item.fontSize,
                          builder: (context, fontSize, child) => TextFormField(
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style:
                                GoogleFonts.getFont(fontFamilyList[fontFamily])
                                    .copyWith(
                              color: color,
                              fontSize: fontSize,
                            ),
                            onChanged: (t) => item.value.value = t,
                            controller: itemTextController,
                            cursorColor: color,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (input) {
                              if (input.isNotEmpty) {
                                Navigator.of(context).pop(item);
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    builder: (context, textStyle, child) {
                      return Container(
                        padding: textStyle != 0
                            ? EdgeInsets.only(
                                left: 7,
                                right: 7,
                                top: 5,
                                bottom: 5,
                              )
                            : EdgeInsets.zero,
                        decoration: textStyle != 0
                            ? BoxDecoration(
                                color: textStyle == 1
                                    ? Colors.black.withOpacity(1.0)
                                    : Colors.white.withOpacity(1.0),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              )
                            : BoxDecoration(),
                        child: child,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.color_lens_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          final rslt = await _pickColor(
                            item.color.value ??
                                Theme.of(context).textTheme.headline5?.color ??
                                Colors.white,
                          );
                          if (rslt != null) item.color.value = rslt;
                        },
                      ),
                      IconButton(
                        icon: ValueListenableBuilder<int>(
                          valueListenable: item.textStyle,
                          builder: (context, textStyle, child) => Container(
                            padding: textStyle != 0
                                ? EdgeInsets.only(
                                    left: 7,
                                    right: 7,
                                    top: 5,
                                    bottom: 5,
                                  )
                                : EdgeInsets.zero,
                            decoration: textStyle != 0
                                ? BoxDecoration(
                                    color: textStyle == 1
                                        ? Colors.black.withOpacity(1.0)
                                        : Colors.white.withOpacity(1.0),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  )
                                : BoxDecoration(),
                            child: Icon(Icons.auto_awesome,
                                color: textStyle != 2
                                    ? Colors.white
                                    : Colors.black),
                          ),
                        ),
                        onPressed: () {
                          if (item.textStyle.value < 2) {
                            item.textStyle.value++;
                          } else {
                            item.textStyle.value = 0;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 45,
                left: -120,
                child: Transform(
                  alignment: FractionalOffset.center,
                  // Rotate sliders by 90 degrees
                  transform: Matrix4.identity()..rotateZ(270 * 3.1415927 / 180),
                  child: SizedBox(
                    width: 300,
                    child: ValueListenableBuilder<double>(
                      valueListenable: item.fontSize,
                      builder: (context, fontSize, child) => Slider(
                        value: fontSize,
                        min: 14,
                        max: 74,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white.withOpacity(0.4),
                        onChanged: (input) {
                          item.fontSize.value = input;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height / 25,
                left: MediaQuery.of(context).size.width / 6,
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    height: 40,
                    alignment: Alignment.center,
                    child: ListView.builder(
                      itemCount: fontFamilyList.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            item.fontFamily.value = index;
                          },
                          child: ValueListenableBuilder<int>(
                            valueListenable: item.fontFamily,
                            builder: (context, fontFamily, child) => Container(
                              height: 40,
                              width: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index == fontFamily
                                    ? Colors.white
                                    : Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Aa',
                                style:
                                    GoogleFonts.getFont(fontFamilyList[index])
                                        .copyWith(
                                  color: index == fontFamily
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 35,
                right: 20,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(item);
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all(
                      Colors.black.withOpacity(0.7),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (rslt != null)
      setState(
        () {
          if (activeItem == null)
            stackData.add(rslt);
          else {
            stackData
              ..remove(activeItem)
              ..add(rslt);
          }
        },
      );
  }

  Widget _buildItemWidget(EditableItem e) {
    final screen = MediaQuery.of(context).size;

    late Widget widget;

    switch (e.type) {
      case ItemType.Text:
        widget = ValueListenableBuilder<int?>(
          valueListenable: e.fontFamily,
          builder: (context, fontFamily, _) {
            return Text(
              e.value.value ?? '',
              style:
                  GoogleFonts.getFont(fontFamilyList[fontFamily ?? 0]).copyWith(
                color: e.color.value,
                fontSize: e.fontSize.value,
              ),
            );
          },
        );
        if (e.textStyle.value == 1 || e.textStyle.value == 2) {
          widget = Container(
            padding: EdgeInsets.only(left: 7, right: 7, top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(1.0),
              borderRadius: BorderRadius.all(
                Radius.circular(4),
              ),
            ),
            child: widget,
          );
        }
        break;
      case ItemType.Image:
        widget = Image.file(
          File(stackData[0].value.value!),
          // fit: BoxFit.fitHeight,
        );
        break;
    }
    return ValueListenableBuilder<Offset>(
      valueListenable: e.position,
      child: ValueListenableBuilder<double>(
        valueListenable: e.rotation,
        child: ValueListenableBuilder<double>(
          valueListenable: e.scale,
          child: ConstrainedBox(
            key: e.key,
            constraints: BoxConstraints.loose(MediaQuery.of(context).size),
            child: GestureDetector(
              onTap: () => _editOrAddItem(e),
              child: Listener(
                onPointerDown: (details) {
                  _activeItem.value = e;

                  initialPostition = details.position;
                  initialScale = e.scale.value;
                  initialRotation = e.rotation.value;
                },
                onPointerUp: (details) {
                  if (isOnDelete.value) {
                    setState(() => stackData.remove(e));
                    isOnDelete.value = false;
                  }
                  _activeItem.value = null;
                },
                onPointerCancel: (details) {},
                onPointerMove: (details) {
                  if (e.position.value.dy >= 0.88 &&
                      e.position.value.dx >= 0.45 &&
                      e.position.value.dx <= 0.55) {
                    isOnDelete.value = true;
                  } else {
                    isOnDelete.value = false;
                  }
                },
                child: widget,
              ),
            ),
          ),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
        ),
        builder: (context, rotation, child) => Transform.rotate(
          angle: rotation,
          child: child,
        ),
      ),
      builder: (context, position, child) {
        if (e.key.currentContext == null)
          return Align(
            alignment: Alignment.center,
            child: child!,
          );

        return Positioned(
          top: (position.dy * screen.height) -
              ((e.key.currentContext
                          ?.findRenderObject()
                          ?.paintBounds
                          .size
                          .height ??
                      screen.height) /
                  2),
          left: (position.dx * screen.width) -
              ((e.key.currentContext
                          ?.findRenderObject()
                          ?.paintBounds
                          .size
                          .width ??
                      screen.width) /
                  2),
          child: child!,
        );
      },
    );
  }

  Future<Color?> _pickColor(Color initial) async {
    Color picked = initial;
    return await showDialog<Color?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initial,
              onColorChanged: (color) {
                picked = color;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () => Navigator.of(context).pop(picked),
            ),
          ],
        );
      },
    );
  }
}

enum ItemType { Image, Text }

class EditableItem {
  final ItemType type;
  final GlobalKey key;
  ValueNotifier<Offset> position;
  ValueNotifier<double> scale;
  ValueNotifier<double> rotation;
  ValueNotifier<String?> value;
  ValueNotifier<Color?> color;
  ValueNotifier<int> textStyle;
  ValueNotifier<double> fontSize;
  ValueNotifier<int> fontFamily;

  EditableItem({
    required this.type,
    GlobalKey? key,
    Offset position = const Offset(0.5, 0.5),
    double scale = 1,
    double rotation = 0,
    String? value,
    Color? color,
    int textStyle = 0,
    double fontSize = 25,
    int fontFamily = 0,
  })  : key = key ?? GlobalKey(),
        position = ValueNotifier(position),
        scale = ValueNotifier(scale),
        rotation = ValueNotifier(rotation),
        value = ValueNotifier(value),
        color = ValueNotifier(color),
        textStyle = ValueNotifier(textStyle),
        fontSize = ValueNotifier(fontSize),
        fontFamily = ValueNotifier(fontFamily);

  EditableItem copy() {
    return EditableItem(
      key: key,
      type: type,
      position: position.value,
      scale: scale.value,
      rotation: rotation.value,
      value: value.value,
      color: color.value,
      textStyle: textStyle.value,
      fontSize: fontSize.value,
      fontFamily: fontFamily.value,
    );
  }
}
