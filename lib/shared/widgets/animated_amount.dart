import 'package:flutter/material.dart';

/// Animates numeric changes to [amount] with a count-up/down tween instead
/// of snapping the text directly — used for money figures across the app.
class AnimatedAmount extends StatelessWidget {
  final double amount;
  final String Function(double value) format;
  final TextStyle? style;

  const AnimatedAmount({
    super.key,
    required this.amount,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(format(value), style: style),
    );
  }
}
