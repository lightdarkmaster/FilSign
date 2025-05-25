import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras found on device.");
      }

      final firstCamera = cameras.first;

      _cameraController = CameraController(firstCamera, ResolutionPreset.high);

      _initializeControllerFuture = _cameraController.initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera initialization failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FilSign'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.fromARGB(255, 160, 58, 183),
                Color.fromARGB(255, 253, 78, 224),
                Color.fromARGB(255, 237, 77, 255),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FilSign Mobile Camera',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color.fromARGB(255, 160, 58, 183),
                    Color.fromARGB(255, 253, 78, 224),
                    Color.fromARGB(255, 237, 77, 255),
                  ],
                ),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CameraPage(cameraController: _cameraController),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening camera: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Open Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraPage extends StatelessWidget {
  final CameraController cameraController;

  const CameraPage({super.key, required this.cameraController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera View'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.fromARGB(255, 237, 77, 255),
                Color.fromARGB(255, 253, 78, 224),
                Color.fromARGB(255, 237, 77, 255),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: CameraPreview(cameraController),
    );
  }
}
