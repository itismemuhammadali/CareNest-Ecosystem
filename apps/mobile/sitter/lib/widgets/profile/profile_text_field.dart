import 'package:flutter/material.dart';

class ProfileTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final String? hintText;
  final int maxLines;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool readOnly;

  const ProfileTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
          decoration: InputDecoration(
            hintText: hintText ?? initialValue,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0x99FFFFFF),
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1AA8D8EA), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1AA8D8EA), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0x4DA8D8EA), width: 1.09),
            ),
          ),
        ),
      ],
    );
  }
}
