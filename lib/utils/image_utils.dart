import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  // Function to get the app's documents directory for image storage
  static Future<String> getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/media_images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir.path;
  }

  // Function to copy image to app's documents directory
  static Future<String> saveImageToAppDirectory(File imageFile, String originalName) async {
    try {
      final imagesDir = await getImagesDirectory();
      final String fileName = originalName; // Keep original name with extension
      final String newPath = '$imagesDir/$fileName';

      await imageFile.copy(newPath);
      return newPath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  // Function to get image file from app's documents directory
  static Future<File?> getImageFile(String imageName) async {
    try {
      final imagesDir = await getImagesDirectory();
      final String imagePath = '$imagesDir/$imageName';
      final File imageFile = File(imagePath);

      if (await imageFile.exists()) {
        return imageFile;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Function to delete image from app's documents directory
  static Future<void> deleteImage(String imageName) async {
    try {
      final imagesDir = await getImagesDirectory();
      final String imagePath = '$imagesDir/$imageName';
      final File imageFile = File(imagePath);

      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete image: $e');
      }
    }
  }

  // Function to extract name with extension from path
  static String getImageNameWithExtension(String imagePath) {
    return imagePath.split('/').last;
  }

  // Function to extract name without extension from path
  static String getImageNameWithoutExtension(String imagePath) {
    String fileName = getImageNameWithExtension(imagePath);
    return fileName.split('.').first;
  }
}