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
}
