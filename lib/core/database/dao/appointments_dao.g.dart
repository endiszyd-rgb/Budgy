// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointments_dao.dart';

// ignore_for_file: type=lint
mixin _$AppointmentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppointmentsTable get appointments => attachedDatabase.appointments;
  AppointmentsDaoManager get managers => AppointmentsDaoManager(this);
}

class AppointmentsDaoManager {
  final _$AppointmentsDaoMixin _db;
  AppointmentsDaoManager(this._db);
  $$AppointmentsTableTableManager get appointments =>
      $$AppointmentsTableTableManager(_db.attachedDatabase, _db.appointments);
}
