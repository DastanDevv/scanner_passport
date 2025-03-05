import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:pass_scanner/home/camera_screen.dart';
import 'package:pass_scanner/home/passport_upload_dialog.dart';

class PassportScannerScreen extends StatefulWidget {
  const PassportScannerScreen({super.key});

  @override
  PassportScannerScreenState createState() => PassportScannerScreenState();
}

class PassportScannerScreenState extends State<PassportScannerScreen> {
  File? faceImage;
  File? backImage;
  String faceSideText = "";
  String backSideText = "";
  bool isLoading = false;
  bool showResult = false;
  bool faceScanned = false;

  void openCameraScanner() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Камера недоступна')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CameraScreen(
              camera: cameras.first,
              onImageCaptured: (image, isFaceSide) {
                setState(() {
                  if (isFaceSide) {
                    faceImage = image;
                  } else {
                    backImage = image;
                  }

                  if (faceImage != null && backImage != null) {
                    showResult = true;
                  }
                });

                scanText(image, isFaceSide);
              },
            ),
      ),
    );
  }

  Future<void> scanText(File imageFile, bool isFaceSide) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textDetector.processImage(
      inputImage,
    );
    textDetector.close();

    String extractedText = recognizedText.text;
    extractPassportData(extractedText, isFaceSide);
  }

  /// Извлекаем данные с паспорта
  void extractPassportData(String text, bool isFaceSide) {
    String surname = "";
    String name = "";
    String birthDate = "";
    String iin = "";

    List<String> lines = text.split("\n");

    if (isFaceSide) {
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim().toLowerCase();

        if (line.contains("surname") && i + 1 < lines.length) {
          surname = lines[i + 1].trim();
        }

        if (line.contains("name") && i + 1 < lines.length) {
          name = lines[i + 1].trim();
        }

        if (line.contains("date of birth") && i + 1 < lines.length) {
          RegExp datePattern = RegExp(r'\d{2}\.\d{2}\.\d{4}');
          Match? dateMatch = datePattern.firstMatch(lines[i + 1]);
          if (dateMatch != null) {
            birthDate = dateMatch.group(0)!;
          }
        }
      }

      setState(() {
        faceSideText =
            "Фамилия: $surname\nИмя: $name\nДата рождения: $birthDate";
      });
    } else {
      RegExp iinPattern = RegExp(r'\b\d{14}\b');
      Match? iinMatch = iinPattern.firstMatch(text);
      if (iinMatch != null) {
        iin = iinMatch.group(0)!;
      }

      setState(() {
        backSideText = "ИИН: $iin";
      });
    }
  }

  void _resetState() {
    setState(() {
      faceImage = backImage = null;
      faceSideText = backSideText = '';
      showResult = faceScanned = false;
    });
  }

  Widget _buildScanButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: text.contains("камерой") ? Colors.blue : null,
          foregroundColor: text.contains("камерой") ? Colors.white : null,
        ),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Сканер паспорта Кыргызстана")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildScanButton("📸 Загрузить паспорт", showPassportDialog),
                const SizedBox(width: 10),
                _buildScanButton("📷 Сканировать камерой", () {
                  _resetState();
                  openCameraScanner();
                }),
              ],
            ),
            if (showResult) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Данные паспорта:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "$faceSideText\n$backSideText",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void showPassportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => PassportUploadDialog(
            initialFaceImage: faceImage,
            initialBackImage: backImage,
            onImagePicked: (image, isFaceSide) {
              setState(() {
                if (isFaceSide) {
                  faceImage = image;
                } else {
                  backImage = image;
                }
              });
              if (image != null) scanText(image, isFaceSide);
            },
            onProcessingComplete: () {
              setState(() => showResult = true);
            },
          ),
    );
  }

  Future<void> pickImage(
    ImageSource source, {
    required bool isFaceSide,
    required StateSetter dialogSetState,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    setState(() {
      if (isFaceSide) {
        faceImage = imageFile;
      } else {
        backImage = imageFile;
      }
    });

    dialogSetState(() {});

    scanText(imageFile, isFaceSide);

    if (faceImage != null && backImage != null) {
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
        setState(() {
          showResult = true;
        });
      });
    }
  }
}
