import 'package:flutter/material.dart';

class ViewProfileButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final double fontSize;
  final double height;
  final double borderRadius;
  final double iconSize;

  const ViewProfileButton({
    super.key,
    required this.onPressed,
    this.buttonText = 'View Full Profile',
    this.borderColor = const Color(0xFFA8D8EA),
    this.textColor = const Color(0xFFA8D8EA),
    this.iconColor = const Color(0xFFA8D8EA),
    this.fontSize = 14,
    this.height = 44,
    this.borderRadius = 12,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              color: iconColor,
              size: iconSize,
            ),
          ],
        ),
      ),
    );
  }
}
