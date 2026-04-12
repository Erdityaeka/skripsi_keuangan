import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final io.File? file;
  final Uint8List? bytes;

  PickedImage({this.file, this.bytes});
}

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<PickedImage?> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        return PickedImage(bytes: bytes);
      } else {
        return PickedImage(file: io.File(pickedFile.path));
      }
    }
    return null;
  }

  Future<PickedImage?> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        return PickedImage(bytes: bytes);
      } else {
        return PickedImage(file: io.File(pickedFile.path));
      }
    }
    return null;
  }
}
