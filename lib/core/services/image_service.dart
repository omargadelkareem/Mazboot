import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickBase64({ImageSource source = ImageSource.gallery}) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 55,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > AppConfig.maxBase64ImageBytes) {
      throw const ImageTooLargeException();
    }
    return base64Encode(bytes);
  }

  Uint8List? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}

class ImageTooLargeException implements Exception {
  const ImageTooLargeException();
}
