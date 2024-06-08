// import 'dart:async'; // Ensure you have the right ML Kit package
// import 'dart:io';
//
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fresh_face_detect/ML/Recognition.dart';
// import 'package:fresh_face_detect/ML/Recognizer.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:image/image.dart' as img;
// import 'package:permission_handler/permission_handler.dart';
//
// class CameraScreen extends StatefulWidget {
//   final List<CameraDescription> cameras;
//
//   CameraScreen({required this.cameras});
//
//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }
//
// class _CameraScreenState extends State<CameraScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   CameraLensDirection camDirec = CameraLensDirection.front;
//   int currentCameraIndex = 1;
//   List<XFile> capturedImages = [];
//   bool isCapturing = false;
//
//   late List<Recognition> recognitions = [];
//
//   // TODO declare face detector
//   late FaceDetector faceDetector;
//
//   // TODO declare face recognizer
//   late Recognizer recognizer;
//
//   Future<void> _requestPermissions() async {
//     var status = await Permission.camera.status;
//     if (!status.isGranted) {
//       await Permission.camera.request();
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     // TODO initialize face detector
//     var options = FaceDetectorOptions(
//       enableContours: true,
//       enableClassification: true,
//     );
//     faceDetector = FaceDetector(options: options);
//     // TODO initialize face recognizer
//     recognizer = Recognizer();
//     _requestPermissions();
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     print('-----------1');
//
//     _controller = CameraController(
//       widget.cameras[currentCameraIndex],
//       ResolutionPreset.medium,
//       imageFormatGroup:
//           ImageFormatGroup.yuv420, // Use YUV format for raw image data
//     );
//     print('-----------212');
//     _initializeControllerFuture = _controller.initialize();
//
//     setState(() {});
//     print('-----------2');
//
//     try {
//       await _initializeControllerFuture;
//
//       //if (!mounted) return;
//
//       while (true) {
//         print("${_controller.value.isInitialized} checking");
//         //Future.delayed(const Duration(milliseconds: 3000), () {
//         print('------3');
//
//         // _controller.startImageStream((CameraImage image) {
//         //   print("Ulala ${image.width} ${image.width}");
//         //   // setState(() {
//         //   //   print('------4');
//         //   //   frame = image;
//         //   // });
//         // });
//         // Refresh the UI once the controller is initialized
//         //});
//
//         print('------5');
//         //_startFrameExtraction();
//         // setState(() {
//         //   print('------6');
//         // });
//       }
//     } catch (e) {
//       print('Error initializing camera: $e');
//     }
//   }
//
//   // void _startFrameExtraction() {
//   //   Timer(Duration(seconds: 3), _captureAndSaveFrame);
//   // }
//
//   CameraImage? frame;
//   dynamic _scanResults;
//   Future<void> _captureAndSaveFrame(InputImage frame) async {
//     if (isCapturing) return; // Prevent multiple captures
//     isCapturing = true;
//
//     try {
//       // await _initializeControllerFuture;
//       //
//       // if (!_controller.value.isInitialized || frame == null) {
//       //   return;
//       // }
//
//       // Capture the frame
//       // final XFile file = await _controller.takePicture();
//       //
//       // // If you want to convert to InputImage for ML Kit processing:
//       // final inputImage = InputImage.fromFilePath(file.path);
//
//       // TODO pass InputImage to face detection model and detect faces
//       //List<Face> faces = await faceDetector.processImage(inputImage);
//
//       List<Face> faces = await faceDetector.processImage(frame);
//       if (faces.isNotEmpty) {
//         print("face found");
//         // setState(() {
//         //   capturedImages.add(file);
//         // });
//
//         // performFaceRecognition(faces);
//       } else {
//         print("Face not found");
//       }
//     } catch (e) {
//       print('Error capturing and saving frame: $e');
//     } finally {
//       //isCapturing = false;
//       //_startFrameExtraction(); // Schedule the next frame capture
//     }
//   }
//
//   InputImage getInputImageFromCameraImage(CameraImage cameraImage) {
//     final WriteBuffer allBytes = WriteBuffer();
//     for (final Plane plane in cameraImage.planes) {
//       allBytes.putUint8List(plane.bytes);
//     }
//     final bytes = allBytes.done().buffer.asUint8List();
//
//     final Size imageSize =
//         Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
//
//     final camera = widget.cameras[currentCameraIndex];
//     final imageRotation = getInputImageRotation(camera.sensorOrientation);
//
//     final inputImageData = InputImageData(
//       size: imageSize,
//       imageRotation: imageRotation,
//       inputImageFormat: InputImageFormat.yuv420,
//       planeData: cameraImage.planes.map((Plane plane) {
//         return InputImagePlaneMetadata(
//           bytesPerRow: plane.bytesPerRow,
//           height: plane.height,
//           width: plane.width,
//         );
//       }).toList(),
//     );
//
//     return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
//   }
//
//   InputImageRotation getInputImageRotation(int sensorOrientation) {
//     switch (sensorOrientation) {
//       case 90:
//         return InputImageRotation.rotation90deg;
//       case 180:
//         return InputImageRotation.rotation180deg;
//       case 270:
//         return InputImageRotation.rotation270deg;
//       case 0:
//       default:
//         return InputImageRotation.rotation0deg;
//     }
//   }
//
//   void _switchCamera() async {
//     currentCameraIndex = (currentCameraIndex + 1) % widget.cameras.length;
//     await _controller.stopImageStream();
//     await _controller.dispose();
//     _initializeCamera();
//   }
//
//   img.Image? image;
//   bool register = false;
//
//   // TODO perform Face Recognition
//   performFaceRecognition(List<Face> faces) async {
//     recognitions.clear();
//
//     // TODO convert CameraImage to Image and rotate it so that our frame will be in a portrait
//     image = convertYUV420ToImage(frame!);
//     image = img.copyRotate(image!,
//         angle: camDirec == CameraLensDirection.front ? 270 : 90);
//
//     for (Face face in faces) {
//       Rect faceRect = face.boundingBox;
//       // TODO crop face
//       img.Image croppedFace = img.copyCrop(image!,
//           x: faceRect.left.toInt(),
//           y: faceRect.top.toInt(),
//           width: faceRect.width.toInt(),
//           height: faceRect.height.toInt());
//
//       // TODO pass cropped face to face recognition model
//       Recognition recognition = recognizer.recognize(croppedFace, faceRect);
//       if (recognition.distance > 1) {
//         recognition.name = "Unknown";
//       }
//       recognitions.add(recognition);
//
//       // TODO show face registration dialogue
//       if (register) {
//         showFaceRegistrationDialogue(croppedFace, recognition);
//         register = false;
//       }
//     }
//
//     setState(() {
//       _scanResults = recognitions;
//     });
//   }
//
//   // TODO Face Registration Dialogue
//   TextEditingController textEditingController = TextEditingController();
//   showFaceRegistrationDialogue(img.Image croppedFace, Recognition recognition) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Face Registration", textAlign: TextAlign.center),
//         alignment: Alignment.center,
//         content: SizedBox(
//           height: 340,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(
//                 height: 20,
//               ),
//               Image.memory(
//                 Uint8List.fromList(img.encodeBmp(croppedFace!)),
//                 width: 200,
//                 height: 200,
//               ),
//               SizedBox(
//                 width: 200,
//                 child: TextField(
//                     controller: textEditingController,
//                     decoration: const InputDecoration(
//                         fillColor: Colors.white,
//                         filled: true,
//                         hintText: "Enter Name")),
//               ),
//               const SizedBox(
//                 height: 10,
//               ),
//               ElevatedButton(
//                   onPressed: () {
//                     recognizer.registerFaceInDB(
//                         textEditingController.text, recognition.embeddings);
//                     textEditingController.text = "";
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       content: Text("Face Registered"),
//                     ));
//                   },
//                   style: ElevatedButton.styleFrom(
//                       primary: Colors.blue, minimumSize: const Size(200, 40)),
//                   child: const Text("Register"))
//             ],
//           ),
//         ),
//         contentPadding: EdgeInsets.zero,
//       ),
//     );
//   }
//
//   // TODO method to convert CameraImage to Image
//   img.Image convertYUV420ToImage(CameraImage cameraImage) {
//     final width = cameraImage.width;
//     final height = cameraImage.height;
//
//     final yRowStride = cameraImage.planes[0].bytesPerRow;
//     final uvRowStride = cameraImage.planes[1].bytesPerRow;
//     final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;
//
//     final image = img.Image(width: width, height: height);
//
//     for (var w = 0; w < width; w++) {
//       for (var h = 0; h < height; h++) {
//         final uvIndex =
//             uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
//         final index = h * width + w;
//         final yIndex = h * yRowStride + w;
//
//         final y = cameraImage.planes[0].bytes[yIndex];
//         final u = cameraImage.planes[1].bytes[uvIndex];
//         final v = cameraImage.planes[2].bytes[uvIndex];
//
//         image.data!.setPixelR(w, h, yuv2rgb(y, u, v)); //= yuv2rgb(y, u, v);
//       }
//     }
//     return image;
//   }
//
//   int yuv2rgb(int y, int u, int v) {
//     // Convert yuv pixel to rgb
//     var r = (y + v * 1436 / 1024 - 179).round();
//     var g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
//     var b = (y + u * 1814 / 1024 - 227).round();
//
//     // Clipping RGB values to be inside boundaries [ 0 , 255 ]
//     r = r.clamp(0, 255);
//     g = g.clamp(0, 255);
//     b = b.clamp(0, 255);
//
//     return 0xff000000 |
//         ((b << 16) & 0xff0000) |
//         ((g << 8) & 0xff00) |
//         (r & 0xff);
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final List<XFile> reversedCapturedImages = capturedImages.reversed.toList();
//     return Scaffold(
//       appBar: AppBar(title: Text('Camera')),
//       body: Column(
//         children: [
//           if (_controller.value.isInitialized)
//             Expanded(child: CameraPreview(_controller)),
//           ElevatedButton(
//             onPressed: _switchCamera,
//             child: Text('Switch Camera'),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: reversedCapturedImages.length,
//               itemBuilder: (context, index) {
//                 return Image.file(File(reversedCapturedImages[index].path));
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
