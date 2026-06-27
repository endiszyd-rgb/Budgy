import 'package:drift/drift.dart';
import '../database.dart';

part 'appointments_dao.g.dart';

@DriftAccessor(tables: [Appointments])
class AppointmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AppointmentsDaoMixin {
  AppointmentsDao(super.db);

  Stream<List<Appointment>> watchAllAppointments() => (select(
    appointments,
  )..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)])).watch();

  Future<int> insertAppointment(AppointmentsCompanion entry) =>
      into(appointments).insert(entry);

  Future<bool> updateAppointment(Appointment entry) =>
      update(appointments).replace(entry);

  Future<int> deleteAppointment(int id) =>
      (delete(appointments)..where((a) => a.id.equals(id))).go();

  Future<void> setDone(int id, bool isDone) =>
      (update(appointments)..where((a) => a.id.equals(id))).write(
        AppointmentsCompanion(isDone: Value(isDone)),
      );

  /// Granular reschedule used by calendar drag-to-move and drag-to-resize —
  /// mirrors [setDone]'s partial-write pattern so only these two columns
  /// are touched.
  Future<void> updateSchedule(
    int id,
    DateTime newScheduledAt,
    int newDurationMinutes,
  ) => (update(appointments)..where((a) => a.id.equals(id))).write(
    AppointmentsCompanion(
      scheduledAt: Value(newScheduledAt),
      durationMinutes: Value(newDurationMinutes),
    ),
  );

  /// Bounded-range watch for the calendar view, so it doesn't re-query the
  /// full table as appointment history grows. [watchAllAppointments] is
  /// left untouched for any other callers.
  Stream<List<Appointment>> watchAppointmentsInRange(
    DateTime start,
    DateTime end,
  ) =>
      (select(appointments)
            ..where(
              (a) =>
                  a.scheduledAt.isBiggerOrEqualValue(start) &
                  a.scheduledAt.isSmallerThanValue(end),
            )
            ..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)]))
          .watch();
}
