import 'dart:async'; // Ensure you have the right ML Kit package

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fresh_face_detect/ML/Recognizer.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import 'ML/Recognition.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraScreen({required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late Timer _timer;
  late CameraController _controller;
  late Future<void> initializeControllerFuture;
  bool _isStreaming = false;
  int currentCameraIndex = 1;
  List<XFile> capturedImages = [];
  late String _cascadeFilePath;
  late FaceDetector _faceDetector;
  CameraLensDirection camDirec = CameraLensDirection.front;
  bool isFaceDetected = false;

  // Declare face recognizer
  late Recognizer recognizer;
  late List<Recognition> recognitions = [];

  img.Image? image;
  bool register = false;
  dynamic _scanResults;

  @override
  void initState() {
    super.initState();
    var options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    );
    _faceDetector = FaceDetector(options: options);

    // Initialize face recognizer
    recognizer =
        Recognizer(); // Make sure to initialize the recognizer properly

    _initializeCamera();
  }

  void _initializeCamera() async {
    _controller = CameraController(
      widget.cameras[currentCameraIndex],
      ResolutionPreset.high,
      imageFormatGroup:
          ImageFormatGroup.nv21, // Use YUV format for raw image data
    );

    initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) return;

      _startFrameExtraction();
      setState(() {}); // Refresh the UI once the controller is initialized
    });
  }

  void _startFrameExtraction() {
    int i = 0;
    print('Calling ${i + 1} time');
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _initializeCamera2();
    });
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
            await _detectFaces(inImg!, image);
            //await _saveImage(image);
            //await _captureAndSaveFrame(image);
          } catch (err) {
            print('error in stream: ${err}');
          }

          _isStreaming = true;

          setState(() {});
        });
      }

      if (_isStreaming) {
        _isStreaming = false;
        await _controller.stopImageStream();
        if (_isStreaming) {}
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

  Future<void> _detectFaces(
      InputImage inputImage, CameraImage cameraImage) async {
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      print("found face");

      performFaceRecognition(faces, cameraImage);
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

  // TODO perform Face Recognition
  Future<void> performFaceRecognition(
      List<Face> faces, CameraImage cameraImage) async {
    recognitions.clear();
    print('===================performance in=====================');
    try {
      // Convert CameraImage to Image and rotate it so that our frame will be in portrait
      img.Image image = await convertCameraImageToImage(cameraImage);

      print('===================converted image=====================');

      image = img.copyRotate(image,
          angle: camDirec == CameraLensDirection.front ? 270 : 90);

      for (Face face in faces) {
        Rect faceRect = face.boundingBox;

        print('===================face Looping=====================');

        // Crop face
        img.Image croppedFace = img.copyCrop(image,
            x: faceRect.left.toInt(),
            y: faceRect.top.toInt(),
            width: faceRect.width.toInt(),
            height: faceRect.height.toInt());

        // Pass cropped face to face recognition model
        Recognition recognition = recognizer.recognize(croppedFace, faceRect);
        if (recognition.distance > 1) {
          recognition.name = "Unknown";
        }
        recognitions.add(recognition);

        print(
            '===================Recognition process Done=====================');

        // Show face registration dialogue
        if (register) {
          showFaceRegistrationDialogue(
              Uint8List.fromList(img.encodeBmp(croppedFace)), recognition);
          register = false;
        }
      }

      setState(() {
        _scanResults = recognitions;
      });
    } catch (e) {
      print('Error performing face recognition: $e');
    }
  }

  img.Image convertCameraImageToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      final int uvRowStride = cameraImage.planes[1].bytesPerRow;
      final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

      final img.Image image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        final int uvRow = uvRowStride * (y >> 1);
        for (int x = 0; x < width; x++) {
          final int uvOffset = uvRow + (x >> 1) * uvPixelStride;

          final int yp = y * width + x;
          final int up = uvOffset;
          final int vp = uvOffset;

          if (yp >= cameraImage.planes[0].bytes.length ||
              up >= cameraImage.planes[1].bytes.length ||
              vp >= cameraImage.planes[2].bytes.length) {
            continue;
          }

          final int yValue = cameraImage.planes[0].bytes[yp];
          final int uValue = cameraImage.planes[1].bytes[up];
          final int vValue = cameraImage.planes[2].bytes[vp];

          int r = (yValue + (1.370705 * (vValue - 128))).toInt();
          int g = (yValue -
                  (0.337633 * (uValue - 128)) -
                  (0.698001 * (vValue - 128)))
              .toInt();
          int b = (yValue + (1.732446 * (uValue - 128))).toInt();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          image.setPixel(x, y, img.ColorInt8.rgba(r, g, b, 255));
        }
      }

      return image;
    } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
      // Handle NV21 format
      final img.Image image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yp = y * width + x;
          final int uvIndex = width * (height + (y >> 1)) + (x & ~1);

          if (yp >= cameraImage.planes[0].bytes.length ||
              uvIndex + 1 >= cameraImage.planes[1].bytes.length) {
            continue;
          }

          final int yValue = cameraImage.planes[0].bytes[yp];
          final int uValue = cameraImage.planes[1].bytes[uvIndex];
          final int vValue = cameraImage.planes[1].bytes[uvIndex + 1];

          int r = (yValue + (1.370705 * (vValue - 128))).toInt();
          int g = (yValue -
                  (0.337633 * (uValue - 128)) -
                  (0.698001 * (vValue - 128)))
              .toInt();
          int b = (yValue + (1.732446 * (uValue - 128))).toInt();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          image.setPixel(x, y, img.ColorInt8.rgba(r, g, b, 255));
        }
      }

      return image;
    } else {
      throw UnsupportedError(
          'Unsupported image format: ${cameraImage.format.group}');
    }
  }

  /* Future<img.Image> convertCameraImageToImage(CameraImage cameraImage) async {
    // Assuming the image format is YUV420, which is typical for camera images
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    // Convert YUV420 to RGB
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int? uvPixelStride = cameraImage.planes[1].bytesPerPixel;

    final img.Image image = img.Image(width,  height);

    for (int y = 0; y < height; y++) {
      final int uvRow = uvRowStride * (y >> 1);
      for (int x = 0; x < width; x++) {
        final int uvOffset = uvRow + (x >> 1) * uvPixelStride!;

        final int yp = y * width + x;
        final int up = uvOffset;
        final int vp = uvOffset;

        final int yValue = cameraImage.planes[0].bytes[yp];
        final int uValue = cameraImage.planes[1].bytes[up];
        final int vValue = cameraImage.planes[2].bytes[vp];

        int r = (yValue + (1.370705 * (vValue - 128))).toInt();
        int g = (yValue - (0.337633 * (uValue - 128)) - (0.698001 * (vValue - 128))).toInt();
        int b = (yValue + (1.732446 * (uValue - 128))).toInt();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        image.setPixel(x, y, img.getColor(r, g, b));
      }
    }

    return image;
  }*/

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

  //TODO Face Registration Dialogue
  TextEditingController textEditingController = TextEditingController();
  showFaceRegistrationDialogue(Uint8List cropedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Image.memory(
                cropedFace,
                width: 200,
                height: 200,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: textEditingController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Enter Name")),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    recognizer.registerFaceInDB(
                        textEditingController.text, recognition.embeddings);
                    textEditingController.text = "";
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Face Registered"),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(200, 40)),
                  child: const Text("Register"))
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

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
      appBar: AppBar(title: const Text('Camera')),
      body: Column(
        children: [
          if (_controller.value.isInitialized)
            Expanded(child: CameraPreview(_controller)),
          Column(
            children: [
              ElevatedButton(
                onPressed: _switchCamera,
                child: const Text('Switch Camera'),
              ),
              if (isFaceDetected)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black54,
                    child: const Text(
                      'Face Detected!',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
