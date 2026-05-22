import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable, modular search bar widget with SVG icon support
/// 
/// Features:
/// - Customizable hint text
/// - SVG search icon from assets
/// - Optional text controller
/// - Callbacks for text changes and tap events
/// - Customizable styling (border radius, colors, padding)
/// - Focus management
class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color fillColor;
  final Color hintColor;
  final Color textColor;
  final EdgeInsets contentPadding;
  final String? suffixIconPath;
  final VoidCallback? onSuffixIconTap;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search',
    this.controller,
    this.onChanged,
    this.onTap,
    this.borderRadius = 12,
    this.borderColor = const Color(0x26FFFFFF),
    this.focusedBorderColor = const Color(0x66FFFFFF),
    this.fillColor = Colors.transparent,
    this.hintColor = const Color(0x61FFFFFF),
    this.textColor = Colors.white,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.suffixIconPath,
    this.onSuffixIconTap,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      style: TextStyle(color: widget.textColor),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: widget.hintColor),
        filled: true,
        fillColor: widget.fillColor,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: SvgPicture.asset(
            'assets/search.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFFFFF),
              BlendMode.srcIn,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
        suffixIcon: widget.suffixIconPath != null
            ? GestureDetector(
                onTap: widget.onSuffixIconTap,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, left: 8),
                  child: SvgPicture.asset(
                    widget.suffixIconPath!,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFFFFFFF),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
        contentPadding: widget.contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: widget.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: widget.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: widget.focusedBorderColor),
        ),
      ),
    );
  }
}
