import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:pass_scanner/home/camera_screen.dart';

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

  /// Распознаём текст с изображения
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Сканер паспорта Кыргызстана")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (showResult) {
                          faceImage = null;
                          backImage = null;
                          faceSideText = "";
                          backSideText = "";
                          showResult = false;
                          faceScanned = false;
                        }
                      });
                      showPassportDialog();
                    },
                    child: Text("📸 Загрузить паспорт"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        faceImage = null;
                        backImage = null;
                        faceSideText = "";
                        backSideText = "";
                        showResult = false;
                        faceScanned = false;
                      });
                      openCameraScanner();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("📷 Сканировать камерой"),
                  ),
                ),
              ],
            ),

            if (showResult)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        "Данные паспорта:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "$faceSideText\n$backSideText",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showPassportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Color(0xFFFFFFFF),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Лицевая часть паспорта
                    GestureDetector(
                      onTap: () async {
                        if (faceImage == null) {
                          await pickImage(
                            ImageSource.gallery,
                            isFaceSide: true,
                            dialogSetState: setState,
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 214,
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            faceImage != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    faceImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.file_upload_outlined,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Лицевая часть паспорта",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    SizedBox(height: 14),
                    GestureDetector(
                      onTap: () async {
                        if (backImage == null) {
                          await pickImage(
                            ImageSource.gallery,
                            isFaceSide: false,
                            dialogSetState: setState,
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 214,
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            backImage != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    backImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.file_upload_outlined,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Оборотная часть паспорта",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    if (faceImage != null && backImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Отлично! Минуту, мы обрабатываем данные...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
