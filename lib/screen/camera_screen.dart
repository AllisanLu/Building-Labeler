import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ImagePreview extends StatefulWidget {
  ImagePreview(this.file, this.buildingName, {super.key});
  XFile file;
  String buildingName;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    File picture = File(widget.file.path);
    String name = widget.buildingName;

    return Scaffold(
        appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 234, 234, 234),
            centerTitle: true,
            title: Text(name)),
        body: Center(
          child: Image.file(picture),
        ));
  }
}
