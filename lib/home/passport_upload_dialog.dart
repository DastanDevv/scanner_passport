import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PassportUploadDialog extends StatefulWidget {
  final File? initialFaceImage;
  final File? initialBackImage;
  final Function(File?, bool) onImagePicked;
  final VoidCallback onProcessingComplete;

  const PassportUploadDialog({
    super.key,
    required this.initialFaceImage,
    required this.initialBackImage,
    required this.onImagePicked,
    required this.onProcessingComplete,
  });

  @override
  State<PassportUploadDialog> createState() => _PassportUploadDialogState();
}

class _PassportUploadDialogState extends State<PassportUploadDialog> {
  File? _faceImage;
  File? _backImage;

  @override
  void initState() {
    super.initState();
    _faceImage = widget.initialFaceImage;
    _backImage = widget.initialBackImage;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImageUploadSection(
                image: _faceImage,
                label: "Лицевая часть паспорта",
                isFaceSide: true,
              ),
              const SizedBox(height: 14),
              _buildImageUploadSection(
                image: _backImage,
                label: "Оборотная часть паспорта",
                isFaceSide: false,
              ),
              // if (_faceImage != null && _backImage != null)
              //   _buildProcessingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection({
    required File? image,
    required String label,
    required bool isFaceSide,
  }) {
    return GestureDetector(
      onTap: () => _handleImagePick(isFaceSide),
      child: Container(
        width: double.infinity,
        height: 214,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            image != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(image, fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_upload_outlined,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 10),
                    Text(label, style: const TextStyle(fontSize: 16)),
                  ],
                ),
      ),
    );
  }

  Future<void> _handleImagePick(bool isFaceSide) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      setState(() {
        if (isFaceSide) {
          _faceImage = image;
        } else {
          _backImage = image;
        }
      });

      widget.onImagePicked(image, isFaceSide);

      if (_faceImage != null && _backImage != null) {
        Future.delayed(const Duration(seconds: 2), () {
          widget.onProcessingComplete();
          Navigator.pop(context);
        });
      }
    }
  }
}
