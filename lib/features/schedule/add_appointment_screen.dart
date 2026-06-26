import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../shared/widgets/responsive_page.dart';

class AddAppointmentScreen extends StatefulWidget {
  final AppDatabase db;

  /// Gdy podana, ekran działa w trybie edycji tej wizyty (zamiast tworzenia nowej).
  final Appointment? existing;

  const AddAppointmentScreen({super.key, required this.db, this.existing});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _clientCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _vehicleCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _date;
  late TimeOfDay _time;
  bool _isDone = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _clientCtrl = TextEditingController(text: existing?.clientName ?? '');
    _phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    _vehicleCtrl = TextEditingController(text: existing?.vehicle ?? '');
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final scheduledAt = existing?.scheduledAt ?? DateTime.now();
    _date = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    _time = TimeOfDay(hour: scheduledAt.hour, minute: scheduledAt.minute);
    _isDone = existing?.isDone ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clientCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pl', 'PL'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final notes = Value(
      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    final clientName = Value(
      _clientCtrl.text.trim().isEmpty ? null : _clientCtrl.text.trim(),
    );
    final phone = Value(
      _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    final vehicle = Value(
      _vehicleCtrl.text.trim().isEmpty ? null : _vehicleCtrl.text.trim(),
    );

    final existing = widget.existing;
    if (existing == null) {
      await widget.db.appointmentsDao.insertAppointment(
        AppointmentsCompanion.insert(
          title: _titleCtrl.text.trim(),
          clientName: clientName,
          phone: phone,
          vehicle: vehicle,
          notes: notes,
          scheduledAt: scheduledAt,
          isDone: Value(_isDone),
        ),
      );
    } else {
      await widget.db.appointmentsDao.updateAppointment(
        existing.copyWith(
          title: _titleCtrl.text.trim(),
          clientName: clientName,
          phone: phone,
          vehicle: vehicle,
          notes: notes,
          scheduledAt: scheduledAt,
          isDone: _isDone,
        ),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    const accentColor = AppTheme.primary;
    final dateFormatter = DateFormat('dd.MM.yyyy', 'pl_PL');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edytuj wizytę' : 'Umów pracę'),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: ResponsivePage(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Zakres pracy *',
                    hintText: 'np. Wymiana klocków hamulcowych',
                    prefixIcon: Icon(Icons.build_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Podaj zakres pracy'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clientCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Klient (opcjonalnie)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefon (opcjonalnie)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pojazd (opcjonalnie)',
                    hintText: 'np. Skoda Octavia, WA 12345',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            dateFormatter.format(_date),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Godzina',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(
                            _time.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    value: _isDone,
                    onChanged: (v) => setState(() => _isDone = v),
                    activeThumbColor: AppTheme.incomeColor,
                    title: Text(_isDone ? 'Zrealizowane' : 'Zaplanowane'),
                    secondary: Icon(
                      _isDone ? Icons.check_circle_outline : Icons.schedule,
                      color: _isDone
                          ? AppTheme.incomeColor
                          : AppTheme.pendingColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notatki (opcjonalnie)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _saving
                        ? 'Zapisywanie...'
                        : (isEditing ? 'Zapisz zmiany' : 'Zapisz'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
