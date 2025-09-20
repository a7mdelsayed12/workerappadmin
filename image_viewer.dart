import 'package:flutter/material.dart';
import 'dart:io';

class ImageViewer extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ImageViewer({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // التحقق من نوع المسار
    if (imagePath.startsWith('http')) {
      // صورة من الانترنت
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
      );
    } else {
      // صورة محلية
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[400],
        size: 40,
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: _buildImage(),
            ),
          ),
        ),
      ),
    );
  }
}