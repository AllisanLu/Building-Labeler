import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ImagePreview extends StatefulWidget {
  ImagePreview(this.file, this.buildingName, this.heading, this.lat, this.long, {super.key});
  XFile file;
  String buildingName;
  double? heading;
  double? lat;
  double? long;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    File picture = File(widget.file.path);
    double? heading = widget.heading;
    double? lat = widget.lat;
    double? long = widget.long;
    String name = widget.buildingName;

    var size = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 37, 37, 37),
            centerTitle: true,
            title: Text(name)),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Compass reading: ${heading!.ceil()}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold)),
            Text("Latitude: $lat",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold)),
            Text('Longitude: $long',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold)),
            Container(
                width: size,
                height: size,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Container(
                        width: size,
                        child: Image.file(picture),
                      ),
                    ),
                  ),
                )),
          ]
        ));
  }
}
