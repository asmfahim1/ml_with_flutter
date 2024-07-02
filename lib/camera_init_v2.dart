import 'dart:async'; // Ensure you have the right ML Kit package

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fresh_face_detect/ML/Recognizer.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraInitV2Screen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraInitV2Screen({super.key, required this.cameras});

  @override
  _CameraInitV2ScreenState createState() => _CameraInitV2ScreenState();
}

class _CameraInitV2ScreenState extends State<CameraInitV2Screen> {
  late Timer _timer;
  late CameraController _controller;
  late Future<void> initializeControllerFuture;
  bool _isStreaming = false;
  int currentCameraIndex = 1;
  List<XFile> capturedImages = [];
  late String _cascadeFilePath;
  final FaceDetector _faceDetector =
  FaceDetector(options: FaceDetectorOptions());
  bool isFaceDetected = false;

  //final FaceDetector _faceDetector = FaceDetector();

  //late FaceDetector faceDetector;

  // TODO declare face recognizer
  late Recognizer recognizer;

  @override
  void initState() {
    super.initState();

    //faceDetector = FaceDetector(options: options);
    // TODO initialize face recognizer
    //recognizer = Recognizer();

    _initializeCamera();
  }

  void _initializeCamera() async {
    _controller = CameraController(
      widget.cameras[currentCameraIndex],
      ResolutionPreset.high,
      imageFormatGroup:
      ImageFormatGroup.nv21, // Use YUV format for raw image data
    );


    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {

      initializeControllerFuture = _controller.initialize().then((_) {
        if (!mounted) return;

        _initializeCamera2();

        setState(() {}); // Refresh the UI once the controller is initialized
      });
    });
  }

  void _startFrameExtraction() {
    int i = 0;
    print('Calling ${i + 1} time');
    // _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
    //   _initializeCamera2();
    // });
  }

  Future<void> _initializeCamera2() async {
    print('-----------1');

    try {
      // Timer(Duration(seconds: 3), () {
      print("${_controller.value.isInitialized} checking");
      // });

      print('------3');

      if (!_isStreaming) {
        _controller.startImageStream((CameraImage image) async {
          try {
            //await saveImageToGallery(image);

            print("Ulala ${image.width} ${image.width}");

            InputImage? inImg = await _convertCameraImageToInputImage(image);

            //print("Check InputImage ok ${inImg?.bytes}");
            await _detectFaces(inImg!);
            //await _saveImage(image);
            //await _captureAndSaveFrame(image);
          } catch (err) {
            print('error in stream: $err');
          }

          _isStreaming = true;

          setState(() {});
        });
      }

      if (_isStreaming) {
        _isStreaming = false;
        await _controller.stopImageStream();
      }

      print('------5');
      //_startFrameExtraction();
      // setState(() {
      //   print('------6');
      // });
      //}
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _detectFaces(InputImage inputImage) async {
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      print("found face");
    } else {
      print("Not found face");
    }

    setState(() {
      isFaceDetected = faces.isNotEmpty;
    });

    // for (Face face in faces) {
    //   final Rect boundingBox = face.boundingBox;
    //   print('Found face at ${boundingBox.left}, ${boundingBox.top}');
    // }
  }

  InputImage _convertCameraImageToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final Uint8List bytes = allBytes.done().buffer.asUint8List();

    final InputImageData inputImageData = InputImageData(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      imageRotation: _rotationIntToImageRotation(
          _controller.description.sensorOrientation),
      inputImageFormat: InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21,
      planeData: image.planes.map(
            (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList(),
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  // Future<void> _saveImage(CameraImage image) async {
  //   try {
  //     final img.Image convertedImage = _convertYUV420ToImage(image);
  //
  //     // Request storage permission
  //     if (await Permission.storage.request().isGranted) {
  //       // Get temporary directory
  //       final directory = await getTemporaryDirectory();
  //       final imgPath = '${directory.path}/image.jpg';
  //
  //       // Save the image to a file
  //       final File imgFile = File(imgPath);
  //       await imgFile
  //           .writeAsBytes(Uint8List.fromList(img.encodeJpg(convertedImage)));
  //
  //       // Save the image to the gallery
  //       final result = await ImageGallerySaver.saveFile(imgFile.path);
  //
  //       // Show a notification after the image is saved
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: result['isSuccess'] == true
  //               ? Text('Image saved to gallery')
  //               : Text('Failed to save image'),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error saving image: $e');
  //   }
  // }
  //
  // img.Image _convertYUV420ToImage(CameraImage image) {
  //   final int width = image.width;
  //   final int height = image.height;
  //   final img.Image img1 = img.Image(width: width, height: height);
  //   final Plane yPlane = image.planes[0];
  //   final Plane uPlane = image.planes[1];
  //   final Plane vPlane = image.planes[2];
  //   final int yRowStride = yPlane.bytesPerRow;
  //   final int uvRowStride = uPlane.bytesPerRow;
  //   final int uvPixelStride = uPlane.bytesPerPixel!;
  //
  //   for (int h = 0; h < height; h++) {
  //     for (int w = 0; w < width; w++) {
  //       final int yIndex = h * yRowStride + w;
  //       final int uvIndex = (h >> 1) * uvRowStride + (w >> 1) * uvPixelStride;
  //
  //       final int y = yPlane.bytes[yIndex];
  //       final int u = uPlane.bytes[uvIndex];
  //       final int v = vPlane.bytes[uvIndex];
  //
  //       // Convert YUV to RGB
  //       final int r = (y + (1.370705 * (v - 128))).clamp(0, 255).toInt();
  //       final int g = (y - (0.337633 * (u - 128)) - (0.698001 * (v - 128)))
  //           .clamp(0, 255)
  //           .toInt();
  //       final int b = (y + (1.732446 * (u - 128))).clamp(0, 255).toInt();
  //
  //       img1.setPixel(w, h, img.ColorInt8.rgba(r, g, b, 255));
  //     }
  //   }
  //
  //   return img1;
  // }

  void _switchCamera() async {
    currentCameraIndex = (currentCameraIndex + 1) % widget.cameras.length;
    await _controller.dispose();
    _initializeCamera();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: Column(
        children: [
          if (_controller.value.isInitialized)
            Expanded(
              child: Stack(
                children: [
                  CameraPreview(_controller),
                  if (isFaceDetected)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        color: Colors.black54,
                        child: Text(
                          'Face Detected!',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: _switchCamera,
            child: Text('Switch Camera'),
          ),
        ],
      ),
    );
  }
}
