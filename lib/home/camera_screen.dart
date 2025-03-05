import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pass_scanner/home/scan_frame_painter.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final Function(File, bool) onImageCaptured;

  const CameraScreen({
    super.key,
    required this.camera,
    required this.onImageCaptured,
  });

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool showInstruction = true;
  bool isFrontSide = true;
  bool showCheckmark = false;
  bool showProcessing = false;
  File? frontImage;
  File? backImage;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.ultraHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirmPressed() {
    setState(() {
      showInstruction = false;
    });

    Future.delayed(Duration(seconds: 3), _takePicture);
  }

  void _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      File imageFile = File(image.path);

      setState(() {
        showCheckmark = true;
      });

      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          showCheckmark = false;
        });

        if (isFrontSide) {
          frontImage = imageFile;
          setState(() {
            isFrontSide = false;
            showInstruction = true;
          });
        } else {
          backImage = imageFile;
          _showProcessingDialog();
        }
      });
    } catch (e) {
      print("Ошибка при съёмке: $e");
    }
  }

  void _showProcessingDialog() {
    setState(() {
      showProcessing = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        showProcessing = false;
      });

      Navigator.of(context).pop();
      widget.onImageCaptured(frontImage!, true);
      widget.onImageCaptured(backImage!, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller)),
                Positioned.fill(
                  child: CustomPaint(painter: ScanFramePainter()),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                if (showInstruction)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card, size: 32),
                          SizedBox(height: 16),
                          Text(
                            isFrontSide
                                ? "Поместите в рамку\nлицевую часть паспорта"
                                : "Теперь поместите в рамку\nобратную часть паспорта",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Мы автоматически считаем\nданные паспорта",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _onConfirmPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('Хорошо'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showCheckmark)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xff34C759),
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(17),
                      child: Icon(Icons.check, color: Colors.white, size: 50),
                    ),
                  ),
                if (showProcessing)
                  Positioned.fill(
                    child: Center(
                      child: AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 24),
                            Text(
                              'Отлично!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Минуту, мы обрабатываем\nпаспортные данные',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
