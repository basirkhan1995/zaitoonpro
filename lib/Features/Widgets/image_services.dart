import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ImagePickerService {

  // For multiple images (recommended for product images)
  static Future<List<Uint8List>> pickMultipleImages({int maxCount = 5}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<Uint8List> images = [];
        for (var file in result.files) {
          if (images.length >= maxCount) break;

          if (file.bytes != null) {
            images.add(file.bytes!);
          } else if (file.path != null) {
            // Fix: Use File class to read bytes
            final fileObj = File(file.path!);
            final bytes = await fileObj.readAsBytes();
            images.add(bytes);
          }
        }
        return images;
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
    return [];
  }

  // For single image (alternative approach)
  static Future<Uint8List?> pickSingleImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          return file.bytes!;
        } else if (file.path != null) {
          // Fix: Use File class to read bytes
          final fileObj = File(file.path!);
          return await fileObj.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Error picking single image: $e');
    }
    return null;
  }
}