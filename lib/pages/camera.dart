import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraComponent extends StatefulWidget {
  const CameraComponent({super.key});

  @override
  State<CameraComponent> createState() => _CameraComponentState();
}

class _CameraComponentState extends State<CameraComponent> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras found on device.");
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {}); // Rebuild after controller is initialized
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller?.value.isInitialized == true &&
        !_controller!.value.isRecordingVideo) {
      try {
        await _controller!.startVideoRecording();
        if (mounted) {
          setState(() {
            _isRecording = true;
          });
        }
      } catch (e) {
        debugPrint('Error starting video recording: $e');
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller?.value.isRecordingVideo == true) {
      try {
        await _controller!.stopVideoRecording();
        if (mounted) {
          setState(() {
            _isRecording = false;
          });
        }
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
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
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller?.value.isInitialized == true) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                // Floating button at the bottom center
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isRecording
                          ? _stopVideoRecording
                          : _startVideoRecording,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 160, 58, 183),
                              Color.fromARGB(255, 253, 78, 224),
                              Color.fromARGB(255, 237, 77, 255),
                            ],
                          ),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.videocam,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Camera error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
