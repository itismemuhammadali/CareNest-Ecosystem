import 'package:flutter/material.dart';

class CustomPageRoute<T> extends MaterialPageRoute<T> {
  CustomPageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Use a fade transition instead of the default slide transition
    // This prevents the flash effect
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
