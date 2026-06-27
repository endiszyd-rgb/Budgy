import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart';
import '../../../core/database/database.dart';
import '../../../core/theme.dart';

/// Wraps an [Appointment] row as a [kalender] CalendarEvent, without
/// duplicating its data. The event id is always derived from
/// [Appointment.id] (`id.toString()`) so that re-wrapping a fresh row from
/// the DB stream keeps the same identity — required for the calendar
/// controller to recognise "this is the same appointment, just updated"
/// rather than removing and re-adding a tile.
class AppointmentCalendarEvent extends CalendarEvent {
  AppointmentCalendarEvent({required this.appointment})
    : super(
        id: appointment.id.toString(),
        dateTimeRange: DateTimeRange(
          start: appointment.scheduledAt,
          end: appointment.scheduledAt.add(
            Duration(minutes: appointment.durationMinutes),
          ),
        ),
        interaction: EventInteraction.allowAll(),
      );

  final Appointment appointment;

  /// Same rule as the legacy list view: not done, and the scheduled time
  /// has already passed.
  bool get isOverdue =>
      !appointment.isDone &&
      appointment.scheduledAt.isBefore(DateTime.now());

  /// Single place that maps appointment status to a colour — reuses the
  /// app's existing palette, no new colours introduced. Extending this to
  /// "colour by mechanic" later only requires changing this getter.
  Color get displayColor {
    if (appointment.isDone) return AppTheme.incomeColor;
    if (isOverdue) return AppTheme.expenseColor;
    return AppTheme.pendingColor;
  }

  @override
  AppointmentCalendarEvent copyWith({
    DateTimeRange? dateTimeRange,
    EventInteraction? interaction,
  }) {
    final range = dateTimeRange ?? this.dateTimeRange;
    // [CalendarEvent] stores start/end as UTC internally, but every other
    // DateTime in this app (TimeOfDay pickers, DateFormat calls) is local —
    // convert back on the way out or displayed times shift by the UTC
    // offset after a drag/resize.
    final localStart = range.start.toLocal();
    final updated = AppointmentCalendarEvent(
      appointment: appointment.copyWith(
        scheduledAt: localStart,
        durationMinutes: range.duration.inMinutes,
      ),
    );
    updated.id = id;
    return updated;
  }

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is AppointmentCalendarEvent &&
      other.appointment == appointment;

  @override
  int get hashCode => Object.hash(super.hashCode, appointment);
}
