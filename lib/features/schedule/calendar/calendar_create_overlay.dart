import 'dart:ui' show Offset;
import 'package:kalender/kalender.dart';

/// Detects a double-tap on empty calendar space from kalender's
/// [OnTappedWithDetails] callback, since the package only supports
/// single-tap/long-press for its own (disabled) native create gesture.
///
/// The package's `CalendarInteraction(allowEventCreation: false)` turns off
/// its built-in "tap empty space to create an event" behaviour, but its
/// [CalendarCallbacks.onTappedWithDetail] still fires on every single tap on
/// empty space, already carrying the correctly-computed [DateTime] for the
/// tapped slot (via [DayDetail]/[MultiDayDetail]) — no pixel-to-time math is
/// reimplemented here, we just detect when two of those taps land close
/// together in time and position and treat that as "double-tap to create".
class DoubleTapToCreateDetector {
  DoubleTapToCreateDetector({
    required this.onDoubleTap,
    this.maxInterval = const Duration(milliseconds: 400),
    this.maxDistance = 40,
  });

  final void Function(DateTime slot) onDoubleTap;
  final Duration maxInterval;
  final double maxDistance;

  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  void handleTap(TapDetail detail) {
    final now = DateTime.now();
    final position = detail.localOffset;

    final lastTime = _lastTapTime;
    final lastPosition = _lastTapPosition;

    final isDoubleTap =
        lastTime != null &&
        lastPosition != null &&
        now.difference(lastTime) <= maxInterval &&
        (position - lastPosition).distance <= maxDistance;

    if (isDoubleTap) {
      final DateTime? slot = switch (detail) {
        DayDetail d => d.date,
        MultiDayDetail d => d.dateTimeRange.start,
        _ => null,
      };
      _lastTapTime = null;
      _lastTapPosition = null;
      if (slot != null) onDoubleTap(slot);
      return;
    }

    _lastTapTime = now;
    _lastTapPosition = position;
  }
}
