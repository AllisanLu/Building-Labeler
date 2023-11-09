import 'package:camera/camera.dart';
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

  @override
  void initState() {
    super.initState();
    FlutterCompass.events!.listen((event) {
      setState(() {
        heading = event.heading;
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

  void takePicture() async{
      if(!_controller.value.isInitialized){
        return null;
      }
      if(_controller.value.isTakingPicture){
        return null;
      }
      try {
        await _controller.setFlashMode(FlashMode.off);
        XFile picture = await _controller.takePicture();
        Navigator.push(context, MaterialPageRoute(builder: (context)=> ImagePreview(picture)));
      } on CameraException catch (e) {
        debugPrint("Error occured while taking picture : $e");
        return null;
      }
  }

  Future<String> labelBuilding(XFile picture) async{
    Position pos = await _determinePosition();
    double? bearing = heading;
    //do something with position orientation and picture
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.grey.shade900,
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
            ButtonTheme(
                minWidth: 200.0,
                height: 100.0,
                child: ElevatedButton(
                    onPressed: _updatePosition,
                    child: const Text("Check Location"))),
            Container(
              height: 500,
              child: CameraPreview(_controller),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    margin:EdgeInsets.all(20.0),
                    child: MaterialButton(
                      onPressed: takePicture,
                      color: Colors.white54,
                      child: const Text("Label Building"),
                    )
                  )
                )
              ],
            )
          ]),
    );
  }
}
