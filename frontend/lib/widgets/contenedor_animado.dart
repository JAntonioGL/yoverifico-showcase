import 'package:flutter/material.dart';

import 'textos_animado.dart';

class ContenedorAnimadoAuth extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color background;

  const ContenedorAnimadoAuth({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 300),
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 16,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedWidgetWrapper(
      delay: delay,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
