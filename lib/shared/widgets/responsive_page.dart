import 'package:flutter/material.dart';

/// Centruje treść ekranu i ogranicza jej szerokość na dużych ekranach
/// (tablet), żeby karty/listy nie rozciągały się brzeg-do-brzegu.
class ResponsivePage extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth = 1400,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
