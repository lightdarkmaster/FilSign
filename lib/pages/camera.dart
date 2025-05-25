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
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _controller?.value.isInitialized == true) {
          return Column(
            children: [
              Expanded(child: CameraPreview(_controller!)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isRecording ? null : _startVideoRecording,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Start Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isRecording ? _stopVideoRecording : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
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
    );
  }
}
