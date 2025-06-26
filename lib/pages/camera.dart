import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

const int modelInputSize = 256;
const double confidenceThreshold = 0.4;

class CameraComponent extends StatefulWidget {
  const CameraComponent({super.key});

  @override
  State<CameraComponent> createState() => _CameraComponentState();
}

class _CameraComponentState extends State<CameraComponent> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Interpreter? _interpreter;
  List<String> _labels = [];

  bool _isDetecting = false;
  bool _isDetectionRunning = false;
  List<dynamic>? _recognitions;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _setupCameraAndModel();
  }

  Future<void> _setupCameraAndModel() async {
    await _loadModel();
    await _loadLabels();

    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No cameras found");

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    if (!mounted) return;

    _controller!.startImageStream((CameraImage image) {
      if (!_isDetectionRunning || _isDetecting || _interpreter == null) return;

      _isDetecting = true;
      _runModelOnFrame(image).then((recognitions) {
        if (mounted) {
          setState(() {
            _recognitions = recognitions;
          });
        }
        _isDetecting = false;
      });
    });

    setState(() {});
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model/best_float32.tflite',
      );
      debugPrint('Model loaded');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final data = await rootBundle.loadString('assets/model/labels.txt');
      _labels = data
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error loading labels: $e');
    }
  }

  Future<List<dynamic>?> _runModelOnFrame(CameraImage image) async {
    if (_interpreter == null) return null;

    final img.Image rgbImage = _convertYUV420ToImage(image);
    final img.Image resizedImage = img.copyResize(
      rgbImage,
      width: modelInputSize,
      height: modelInputSize,
    );

    final input = [
      List.generate(
        modelInputSize,
        (y) => List.generate(modelInputSize, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    ];

    var output = {
      0: List.generate(10, (_) => List.filled(4, 0.0)), // boxes
      1: List.filled(10, 0.0), // classes
      2: List.filled(10, 0.0), // scores
      3: [0.0], // number of detections
    };

    _interpreter!.runForMultipleInputs([input], output);

    final List<dynamic> recognitions = [];
    final int numDetections = (output[3] as List)[0].toInt();

    for (int i = 0; i < numDetections; i++) {
      final double score = (output[2] as List)[i];
      if (score > confidenceThreshold) {
        final int classId = (output[1] as List)[i].toInt();
        final List box = (output[0] as List)[i];
        recognitions.add({
          "rect": Rect.fromLTRB(box[1], box[0], box[3], box[2]),
          "detectedClass": _labels[classId],
          "confidenceInClass": score,
        });
      }
    }

    return recognitions;
  }

  img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image rgbImage = img.Image(width: width, height: height);

    final Plane planeY = image.planes[0];
    final Plane planeU = image.planes[1];
    final Plane planeV = image.planes[2];

    final int uvRowStride = planeU.bytesPerRow;
    final int uvPixelStride = planeU.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * planeY.bytesPerRow + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final int yVal = planeY.bytes[yIndex];
        final int uVal = planeU.bytes[uvIndex];
        final int vVal = planeV.bytes[uvIndex];

        int r = (yVal + 1.370705 * (vVal - 128)).toInt();
        int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
            .toInt();
        int b = (yVal + 1.732446 * (uVal - 128)).toInt();

        rgbImage.setPixelRgb(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }

    return rgbImage;
  }

  List<Widget> _buildBoxes() {
    if (_recognitions == null || _recognitions!.isEmpty || !_isDetectionRunning) {
      return [];  x
    }

    final size = MediaQuery.of(context).size;
    final previewSize = _controller!.value.previewSize!;
    final scaleX = size.width / previewSize.height;
    final scaleY = size.height / previewSize.width;

    return _recognitions!.map((re) {
      final Rect rect = re["rect"];
      final String label = re["detectedClass"];
      final double conf = re["confidenceInClass"];

      return Positioned(
        left: rect.left * scaleX,
        top: rect.top * scaleY,
        width: (rect.right - rect.left) * scaleX,
        height: (rect.bottom - rect.top) * scaleY,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
          child: Text(
            "$label ${(conf * 100).toStringAsFixed(0)}%",
            style: const TextStyle(
              backgroundColor: Colors.blue,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildResultsCard() {
    if (!_isDetectionRunning ||
        _recognitions == null ||
        _recognitions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: _recognitions!.map((rec) {
            return Text(
              '${rec["detectedClass"]} (${(rec["confidenceInClass"] * 100).toStringAsFixed(1)}%)',
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FilSign Detection")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isDetectionRunning = !_isDetectionRunning;
            if (!_isDetectionRunning) _recognitions = [];
          });
        },
        child: Icon(_isDetectionRunning ? Icons.stop : Icons.play_arrow),
      ),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller?.value.isInitialized == true) {
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [CameraPreview(_controller!), ..._buildBoxes()],
                  ),
                ),
                _buildResultsCard(),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
