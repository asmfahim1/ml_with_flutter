import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fresh_face_detect/camera_init_v2.dart';
import 'package:fresh_face_detect/home_screen.dart';
//import 'home_screen.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(cameras: cameras,)
        //home: CameraInitV2Screen(cameras: cameras,)
    );
  }
}
