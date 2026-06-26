import 'package:flutter/material.dart';

/// Lifts [child] with a soft shadow and slight upward translation on mouse
/// hover (desktop/web only — touch devices never trigger [MouseRegion]).
class HoverLift extends StatefulWidget {
  final Widget child;
  final double liftPx;
  final BorderRadius borderRadius;

  const HoverLift({
    super.key,
    required this.child,
    this.liftPx = 4,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _hovering ? -widget.liftPx : 0,
          0,
        ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
