import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../shared/widgets/hover_lift.dart';
import '../../shared/widgets/responsive_page.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import 'add_appointment_screen.dart';

class ScheduleScreen extends StatelessWidget {
  final AppDatabase db;
  const ScheduleScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terminarz')),
      body: StreamBuilder<List<Appointment>>(
        stream: db.appointmentsDao.watchAllAppointments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final appointments = snapshot.data!;
          if (appointments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Brak umówionych prac.\nUżyj przycisku "Dodaj wizytę", aby zaplanować pierwszą.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          final dayFmt = DateFormat('EEEE, dd MMMM yyyy', 'pl_PL');
          final grouped = <String, List<Appointment>>{};
          for (final a in appointments) {
            final key = dayFmt.format(a.scheduledAt);
            grouped.putIfAbsent(key, () => []).add(a);
          }

          var globalIndex = 0;
          return SingleChildScrollView(
            child: ResponsivePage(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grouped.keys.map((key) {
                  final items = grouped[key]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                        child: Text(
                          key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...items.map(
                        (a) => StaggeredFadeIn(
                          index: globalIndex++,
                          child: _AppointmentTile(db: db, appointment: a),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.push(context, premiumRoute(AddAppointmentScreen(db: db))),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj wizytę'),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppDatabase db;
  final Appointment appointment;

  const _AppointmentTile({required this.db, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm', 'pl_PL');
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final isOverdue =
        !appointment.isDone && appointment.scheduledAt.isBefore(DateTime.now());

    final subtitleParts = [
      if (appointment.clientName != null) appointment.clientName!,
      if (appointment.vehicle != null) appointment.vehicle!,
    ].join(' • ');

    return HoverLift(
      liftPx: 2,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: IconButton(
            icon: Icon(
              appointment.isDone
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: appointment.isDone ? AppTheme.incomeColor : muted,
              size: 28,
            ),
            tooltip: appointment.isDone
                ? 'Oznacz jako zaplanowane'
                : 'Oznacz jako zrealizowane',
            onPressed: () =>
                db.appointmentsDao.setDone(appointment.id, !appointment.isDone),
          ),
          title: Text(
            appointment.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration: appointment.isDone
                  ? TextDecoration.lineThrough
                  : null,
              color: appointment.isDone ? muted : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitleParts.isNotEmpty)
                Text(
                  subtitleParts,
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              if (appointment.phone != null)
                Text(
                  'Tel: ${appointment.phone}',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              if (isOverdue)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: AppTheme.expenseColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Zaległe',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.expenseColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: Text(
            timeFmt.format(appointment.scheduledAt),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onTap: () => Navigator.push(
            context,
            premiumRoute(AddAppointmentScreen(db: db, existing: appointment)),
          ),
          onLongPress: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Usunąć wizytę?'),
              content: Text('Czy usunąć "${appointment.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anuluj'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    db.appointmentsDao.deleteAppointment(appointment.id);
                  },
                  child: const Text(
                    'Usuń',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
