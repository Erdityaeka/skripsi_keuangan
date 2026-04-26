import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final io.File? file;
  final Uint8List? bytes;

  PickedImage({this.file, this.bytes});
}

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  bool _isPicking = false;

  // ================== PICK GALLERY ==================
  Future<PickedImage?> pickImage() async {
    if (_isPicking) return null;

    _isPicking = true;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();

        return PickedImage(bytes: bytes);
      } else {
        return PickedImage(file: io.File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Gallery picker error: $e');
      return null;
    } finally {
      _isPicking = false;
    }
  }

  // ================== PICK CAMERA ==================
  Future<PickedImage?> pickImageFromCamera() async {
    if (_isPicking) return null;

    _isPicking = true;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();

        return PickedImage(bytes: bytes);
      } else {
        return PickedImage(file: io.File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Camera picker error: $e');
      return null;
    } finally {
      _isPicking = false;
    }
  }
}
