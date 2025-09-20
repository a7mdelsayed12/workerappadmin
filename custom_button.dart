import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              textColor ?? Colors.white,
            ),
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }
}