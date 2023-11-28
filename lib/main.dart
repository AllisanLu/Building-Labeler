import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import './screen/camera_screen.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
// // Obtain a list of the available cameras on the device.
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController _controller;

  double? heading = 0;
  double? lat = 0;
  double? long = 0;

  bool _isLoading = false;
  bool updateHeading = true;

  @override
  void initState() {
    super.initState();
    FlutterCompass.events!.listen((event) {
      setState(() {
        if (updateHeading) {
          if (event.heading! < 0) {
            heading = event.heading! + 360;
          } else {
            heading = event.heading;
          }
        }
      });
    });
    _controller = CameraController(cameras[0], ResolutionPreset.max);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print("Camera access denied");
            break;
          default:
            print(e.description);
            break;
        }
      }
    });
  }

  Future<void> _updatePosition() async {
    Position pos = await _determinePosition();
    setState(() {
      lat = pos.latitude;
      long = pos.longitude;
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are diabled.");
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permissions are permenantly denied D:");
    }

    return await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        desiredAccuracy: LocationAccuracy.best);
  }

  void takePicture() async {
    updateHeading = false;
    _isLoading = true;
    if (!_controller.value.isInitialized) {
      return null;
    }
    if (_controller.value.isTakingPicture) {
      return null;
    }
    try {
      await _controller.setFlashMode(FlashMode.off);
      XFile picture = await _controller.takePicture();
      // picture = XFile(await resizePhoto(picture.path));
      String buildingName = await labelBuilding(picture);
      print(buildingName);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ImagePreview(picture, buildingName, heading, lat, long)));
    } on CameraException catch (e) {
      debugPrint("Error occured while taking picture : $e");
      _isLoading = false;
      return null;
    }
  }

  Future<String> labelBuilding(XFile picture) async {
    Position pos = await _determinePosition();
    setState(() {
      lat = pos.latitude;
      long = pos.longitude;
    });
    double? bearing = heading;

    //POST request
    final dio = Dio();
    dio.options.contentType = "multipart/form-data";
    final image = await MultipartFile.fromFile(
      picture.path,
      filename: picture.path.split('/').last,
    );
    FormData formData = FormData.fromMap(
        {"image": image, "bearing": bearing, "lat": lat, "long": long});
    final response = await dio.post(
      'http://98.62.207.19:5000/api/get-building',
      data: formData,
    );

    updateHeading = true;
    if (response.statusCode == 200) {
      // final data = jsonDecode(response.data) as Map<String, dynamic>;
      final data = response.data['buildings'] as List<dynamic>;
      _isLoading = false;
      return data[0];
    } else {
      _isLoading = false;
      throw Exception('Failed to load building name');
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 37, 37, 37),
          centerTitle: true,
          title: const Text("Take a picture of a building!")),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Compass reading: ${heading!.ceil()}",
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
                        child: CameraPreview(_controller),
                      ),
                    ),
                  ),
                )),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                    child: Container(
                        margin: const EdgeInsets.all(20.0),
                        child: ButtonTheme(
                            minWidth: 200.0,
                            height: 100.0,
                            child: ElevatedButton(
                                onPressed: _isLoading ? null : () => takePicture(),
                                child: const Text("Label Building")))))
              ],
            )
          ]),
    );
  }
}
