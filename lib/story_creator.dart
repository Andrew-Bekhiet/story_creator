library story_creator;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:decorated_icon/decorated_icon.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:ui' as ui;

import 'centered_stack.dart';

class StoryCreator extends StatefulWidget {
  StoryCreator({
    Key? key,
    this.filePath,
    this.bgColor,
    this.showGIFPicker = false,
    this.onAddGIF,
    this.gifImageProvider = _defaultGIFImageProvider,
    this.fileImageProvider = _defaultFileImageProvider,
  })  : assert(!showGIFPicker || onAddGIF != null),
        super(key: key);

  final String? filePath;
  final Color? bgColor;
  final bool showGIFPicker;
  final FutureOr<EditableItem?> Function(BuildContext)? onAddGIF;
  final ImageProvider Function(String) gifImageProvider;
  final ImageProvider Function(String) fileImageProvider;

  static ExtendedNetworkImageProvider _defaultGIFImageProvider(String url) {
    return ExtendedNetworkImageProvider(
      url,
      cache: true,
      headers: {'accept': 'image/*'},
    );
  }

  static ExtendedFileImageProvider _defaultFileImageProvider(String path) {
    return ExtendedFileImageProvider(File(path));
  }

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

  final ValueNotifier<bool> isOnDelete = ValueNotifier(false);

  Size? stackSize;

  Offset? initialPosition;
  double? initialScale;
  double? initialRotation;

  @override
  void initState() {
    super.initState();

    if (stackData.isEmpty && widget.filePath != null)
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        stackData.add(EditableItem(
          type: ItemType.Image,
          value: widget.filePath,
          position: Alignment.center.alongSize(stackSize!),
        ));
        setState(() {});
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bgColor.value ??=
        widget.bgColor ?? Theme.of(context).scaffoldBackgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color?>(
      valueListenable: bgColor,
      child: Builder(
        builder: (context) {
          return SafeArea(
            child: GestureDetector(
              onScaleStart: (details) {
                if (_activeItem.value == null) return;

                initialPosition = _activeItem.value!.position.value;
                initialScale = _activeItem.value!.scale.value;
                initialRotation = _activeItem.value!.rotation.value;
              },
              onScaleUpdate: (details) {
                if (_activeItem.value == null ||
                    initialPosition == null ||
                    initialScale == null ||
                    initialRotation == null) return;

                final delta = (previewContainer.currentContext!
                        .findRenderObject() as RenderBox)
                    .globalToLocal(details.delta);
                final left = delta.dx;
                final top = delta.dy;

                _activeItem.value!.position.value =
                    Offset(left, top) + initialPosition!;
                _activeItem.value!.rotation.value =
                    details.rotation + initialRotation!;
                _activeItem.value!.scale.value = details.scale * initialScale!;
              },
              child: Stack(
                children: [
                  RepaintBoundary(
                    key: previewContainer,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        stackSize = constraints.biggest;

                        return CenteredStack(
                          alignment: Alignment.center,
                          children: [
                            ValueListenableBuilder<Color?>(
                              valueListenable: bgColor,
                              builder: (context, bgColor, child) => Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: bgColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: _editOrAddItem,
                            ),
                            if (stackData.isEmpty)
                              GestureDetector(
                                onTap: _editOrAddItem,
                                child: Center(
                                  child: Text(
                                    'Tap to type',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .headline5
                                              ?.color
                                              ?.withOpacity(0.4),
                                        ),
                                  ),
                                ),
                              ),
                            ...stackData
                                .where((item) => item.type != ItemType.GIF)
                                .map(_buildItemWidget),
                          ],
                        );
                      },
                    ),
                  ),
                  CenteredStack(
                    alignment: Alignment.center,
                    children: stackData
                        .where((item) => item.type == ItemType.GIF)
                        .map(_buildItemWidget)
                        .toList(),
                  ),
                  Align(
                    alignment: Alignment(0, -0.97),
                    child: Row(
                      children: [
                        IconButton(
                          iconSize: (IconTheme.of(context).size ?? 20) + 5,
                          padding: EdgeInsets.zero,
                          icon: DecoratedIcon(
                            Icons.color_lens,
                            color: Colors.white,
                            shadows: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius:
                                    ((IconTheme.of(context).size ?? 20) / 4) +
                                        1,
                              ),
                            ],
                          ),
                          onPressed: () async {
                            final rslt = await _pickColor(
                              bgColor.value ??
                                  Theme.of(context)
                                      .textTheme
                                      .headline5
                                      ?.color ??
                                  Colors.white,
                            );
                            if (rslt != null) bgColor.value = rslt;
                          },
                        ),
                        IconButton(
                          iconSize: (IconTheme.of(context).size ?? 20) + 5,
                          padding: EdgeInsets.zero,
                          icon: DecoratedIcon(
                            Icons.format_size,
                            color: Colors.white,
                            shadows: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius:
                                    ((IconTheme.of(context).size ?? 20) / 4) +
                                        1,
                              ),
                            ],
                          ),
                          onPressed: _editOrAddItem,
                        ),
                        IconButton(
                          iconSize: (IconTheme.of(context).size ?? 20) + 5,
                          padding: EdgeInsets.zero,
                          icon: DecoratedIcon(
                            Icons.add_photo_alternate,
                            color: Colors.white,
                            shadows: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius:
                                    ((IconTheme.of(context).size ?? 20) / 4) +
                                        1,
                              ),
                            ],
                          ),
                          onPressed: () async {
                            if (!(await Permission.storage.request())
                                .isGranted) {
                              return;
                            }

                            final selectedImage = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            if (selectedImage == null) return;

                            setState(
                              () => stackData.add(EditableItem(
                                type: ItemType.Image,
                                value: selectedImage.path,
                                position:
                                    Alignment.center.alongSize(stackSize!),
                              )),
                            );
                          },
                        ),
                        IconButton(
                          iconSize: (IconTheme.of(context).size ?? 20) + 5,
                          padding: EdgeInsets.zero,
                          icon: DecoratedIcon(
                            Icons.camera,
                            color: Colors.white,
                            shadows: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius:
                                    ((IconTheme.of(context).size ?? 20) / 4) +
                                        1,
                              ),
                            ],
                          ),
                          onPressed: () async {
                            if (!(await Permission.camera.request())
                                .isGranted) {
                              return;
                            }

                            final selectedImage = await ImagePicker()
                                .pickImage(source: ImageSource.camera);
                            if (selectedImage == null) return;

                            setState(
                              () => stackData.add(EditableItem(
                                  type: ItemType.Image,
                                  value: selectedImage.path,
                                  position:
                                      Alignment.center.alongSize(stackSize!))),
                            );
                          },
                        ),
                        if (widget.showGIFPicker)
                          IconButton(
                            iconSize: (IconTheme.of(context).size ?? 20) + 5,
                            padding: EdgeInsets.zero,
                            icon: DecoratedIcon(
                              Icons.gif,
                              color: Colors.white,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius:
                                      ((IconTheme.of(context).size ?? 20) / 4) +
                                          1,
                                ),
                              ],
                            ),
                            onPressed: () async {
                              final item = await widget.onAddGIF?.call(context);
                              if (item != null) {
                                setState(() => stackData.add(item));
                              }
                            },
                          ),
                      ],
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

                          final RenderRepaintBoundary boundary =
                              previewContainer.currentContext!
                                  .findRenderObject() as RenderRepaintBoundary;

                          final ui.Image image = await boundary.toImage(
                            pixelRatio: 2.0,
                          );

                          final directory =
                              (await getTemporaryDirectory()).path;

                          final ByteData? byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png,
                          );

                          final Uint8List pngBytes =
                              byteData!.buffer.asUint8List();

                          final storyResult = Story(
                            image: await File(
                              '$directory/' +
                                  DateTime.now().toString() +
                                  '.png',
                            ).writeAsBytes(pngBytes),
                            gifs: stackData
                                .where((i) => i.type == ItemType.GIF)
                                .map(
                                  (gif) => GIFProperties._fromEditableItem(gif),
                                )
                                .toList(),
                          );

                          // done: return imgFile
                          Navigator.of(context).pop(storyResult);
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
                    child: Align(
                      alignment: Alignment(0, 0.95),
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
          );
        },
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
    final item = activeItem?.copy() ??
        EditableItem(
          type: ItemType.Text,
          position: Alignment.center.alongSize(stackSize!),
        );
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
                                        ? Colors.black
                                        : Colors.white,
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
              color: e.textStyle.value == 1 ? Colors.black : Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(4),
              ),
            ),
            child: widget,
          );
        }
        break;
      case ItemType.Image:
        widget = Image(
          image: this.widget.fileImageProvider(e.value.value!),
        );
        break;
      case ItemType.GIF:
        widget = Image(
          image: this.widget.gifImageProvider(e.value.value!),
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
              onTap: e.type != ItemType.GIF ? () => _editOrAddItem(e) : null,
              child: Listener(
                onPointerDown: (details) {
                  _activeItem.value = e;

                  initialPosition = details.position;
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
                onPointerMove: (details) {
                  final double centerX = (stackSize! / 2).width;
                  final double centerY = (stackSize! / 2).height;

                  final Alignment relativePosition = Alignment(
                      (e.position.value.dx - centerX) / centerX,
                      (e.position.value.dy - centerY) / centerY);

                  if (relativePosition.y >= 0.73 &&
                      relativePosition.x >= -0.33 &&
                      relativePosition.x <= 0.33) {
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
        return Positioned(
          top: position.dy,
          left: position.dx,
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

enum ItemType { Image, GIF, Text }

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
    required Offset position,
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

class GIFProperties {
  String url;
  Offset position;
  double scale;
  double rotation;

  GIFProperties({
    required this.url,
    this.position = const Offset(0.5, 0.5),
    this.scale = 1,
    this.rotation = 0,
  });

  factory GIFProperties._fromEditableItem(EditableItem item) {
    return GIFProperties(
      url: item.value.value!,
      position: item.position.value,
      rotation: item.rotation.value,
      scale: item.scale.value,
    );
  }
}

class Story {
  /// The combined photo of all static text and images
  File image;

  /// List of gifs and their position, rotation and scale
  List<GIFProperties> gifs;

  Story({required this.image, required this.gifs});
}
