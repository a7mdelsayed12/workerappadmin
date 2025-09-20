import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  // اختيار صورة من المعرض
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('خطأ في اختيار الصورة: $e');
      return null;
    }
  }

  // التقاط صورة بالكاميرا
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('خطأ في التقاط الصورة: $e');
      return null;
    }
  }

  // اختيار عدة صور
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      print('خطأ في اختيار الصور: $e');
      return [];
    }
  }

  // عرض خيارات الصورة
  Future<File?> showImagePicker(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('التقاط صورة'),
                onTap: () async {
                  final image = await takePhoto();
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('اختيار من المعرض'),
                onTap: () async {
                  final image = await pickImageFromGallery();
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}