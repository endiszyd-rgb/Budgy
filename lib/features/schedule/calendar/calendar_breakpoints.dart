import 'package:flutter/material.dart' show DateTimeRange;
import 'package:kalender/kalender.dart';

/// Width thresholds (logical pixels) used to pick how many days the weekly
/// calendar shows at once — mirrors the breakpoints used elsewhere in the
/// app's responsive layouts (desktop / tablet / phone).
const double kCalendarDesktopBreakpoint = 1100;
const double kCalendarTabletBreakpoint = 600;

/// Picks a [ViewConfiguration] for [CalendarView] based on the available
/// [width] of the calendar's layout area.
///
/// - `width >= 1100`: full 7-day week (desktop).
/// - `600 <= width < 1100`: 4-day rolling view (tablet).
/// - `width < 600`: single day, swipeable (phone).
///
/// [displayRange] bounds how far back/forward the user can navigate and is
/// forwarded unchanged to whichever [MultiDayViewConfiguration] is chosen.
ViewConfiguration breakpointViewConfiguration(
  double width,
  DateTimeRange displayRange,
) {
  if (width >= kCalendarDesktopBreakpoint) {
    return MultiDayViewConfiguration.week(
      displayRange: displayRange,
      firstDayOfWeek: DateTime.monday,
    );
  }
  if (width >= kCalendarTabletBreakpoint) {
    return MultiDayViewConfiguration.custom(
      numberOfDays: 4,
      displayRange: displayRange,
    );
  }
  return MultiDayViewConfiguration.singleDay(displayRange: displayRange);
}
