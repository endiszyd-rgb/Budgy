import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart';
import '../../../core/database/database.dart';
import '../../../core/transitions.dart';
import '../add_appointment_screen.dart';
import 'appointment_calendar_event.dart';
import 'appointment_tile.dart';
import 'calendar_breakpoints.dart';
import 'calendar_create_overlay.dart';

/// Google-Calendar-style weekly drag-and-drop replacement for the old
/// list-based "Terminarz" screen.
///
/// Drop-in usage: `CalendarScreen(db: widget.db)` — same constructor shape
/// as the legacy `ScheduleScreen`.
class CalendarScreen extends StatefulWidget {
  final AppDatabase db;

  const CalendarScreen({super.key, required this.db});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final EventsController eventsController = DefaultEventsController();
  late final CalendarController calendarController = CalendarController();
  late final DoubleTapToCreateDetector _createDetector =
      DoubleTapToCreateDetector(
        onDoubleTap: (slot) => Navigator.push(
          context,
          premiumRoute(AddAppointmentScreen(db: widget.db, initialScheduledAt: slot)),
        ),
      );

  /// Generous navigation bounds for the calendar, mirroring the package's
  /// own example (now +/- 1 year) — also used as the bounded range for the
  /// DB watch so we never load the entire appointment history at once.
  late final DateTimeRange _displayRange = () {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year - 1, now.month, now.day),
      end: DateTime(now.year + 1, now.month, now.day),
    );
  }();

  /// Mirrors what's currently loaded into [eventsController], keyed by
  /// `Appointment.id.toString()`, so each new stream emission can be diffed
  /// into add/remove/update calls instead of clearing and re-adding
  /// everything (which would discard in-progress drag state and cause a
  /// visible flicker on every keystroke-driven rebuild elsewhere in the app).
  final Map<String, Appointment> _known = {};
  late final StreamSubscription<List<Appointment>> _subscription;

  @override
  void initState() {
    super.initState();
    // A raw subscription (not StreamBuilder) on purpose: CalendarView already
    // listens to eventsController directly, so this screen's own build()
    // doesn't need to depend on appointment data at all. Driving this through
    // StreamBuilder would call eventsController.addEvent/notifyListeners as a
    // side effect from inside this widget's build() — a known Flutter hazard
    // when a build-in-progress triggers another ChangeNotifier synchronously.
    _subscription = widget.db.appointmentsDao
        .watchAppointmentsInRange(_displayRange.start, _displayRange.end)
        .listen(_syncEvents);
  }

  @override
  void dispose() {
    _subscription.cancel();
    eventsController.dispose();
    calendarController.dispose();
    super.dispose();
  }

  void _syncEvents(List<Appointment> appointments) {
    final incoming = {for (final a in appointments) a.id.toString(): a};

    // Removed: known ids that are no longer in the latest snapshot.
    for (final id in _known.keys.toList()) {
      if (!incoming.containsKey(id)) {
        eventsController.removeById(id);
        _known.remove(id);
      }
    }

    // Added or changed.
    for (final entry in incoming.entries) {
      final id = entry.key;
      final appointment = entry.value;
      final previous = _known[id];
      if (previous == null) {
        eventsController.addEvent(AppointmentCalendarEvent(appointment: appointment));
        _known[id] = appointment;
      } else if (previous != appointment) {
        final oldEvent = eventsController.byId(id);
        if (oldEvent != null) {
          eventsController.updateEvent(
            event: oldEvent,
            updatedEvent: AppointmentCalendarEvent(appointment: appointment),
          );
        }
        _known[id] = appointment;
      }
    }
  }

  void _onEventTapped(CalendarEvent event, RenderBox renderBox) {
    final appointmentEvent = event as AppointmentCalendarEvent;
    Navigator.push(
      context,
      premiumRoute(
        AddAppointmentScreen(db: widget.db, existing: appointmentEvent.appointment),
      ),
    );
  }

  void _onEventChanged(CalendarEvent event, CalendarEvent updatedEvent) {
    // Instant visual feedback first.
    eventsController.updateEvent(event: event, updatedEvent: updatedEvent);

    final updated = updatedEvent as AppointmentCalendarEvent;
    _known[updated.id] = updated.appointment;
    widget.db.appointmentsDao.updateSchedule(
      updated.appointment.id,
      updated.appointment.scheduledAt,
      updated.appointment.durationMinutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileComponents = appointmentTileComponents(
      context,
      onToggleDone: (event) => widget.db.appointmentsDao.setDone(
        event.appointment.id,
        !event.appointment.isDone,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Terminarz')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewConfiguration = breakpointViewConfiguration(
            constraints.maxWidth,
            _displayRange,
          );

          return CalendarView(
            eventsController: eventsController,
            calendarController: calendarController,
            viewConfiguration: viewConfiguration,
            callbacks: CalendarCallbacks(
              onEventTapped: _onEventTapped,
              onEventChanged: _onEventChanged,
              onTappedWithDetail: _createDetector.handleTap,
            ),
            header: Material(
              color: Theme.of(context).colorScheme.surface,
              child: CalendarHeader(multiDayTileComponents: tileComponents),
            ),
            body: CalendarBody(
              multiDayTileComponents: tileComponents,
              interaction: CalendarInteraction(allowEventCreation: false),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          premiumRoute(AddAppointmentScreen(db: widget.db)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj wizytę'),
      ),
    );
  }
}
