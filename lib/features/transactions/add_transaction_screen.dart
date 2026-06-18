import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../shared/widgets/numeric_keypad_dialog.dart';

class AddTransactionScreen extends StatefulWidget {
  final AppDatabase db;
  final TransactionType initialType;
  final String? prefillTitle;
  final double? prefillAmount;
  final String? prefillWzNumber;
  final int? sourceDocumentId;

  const AddTransactionScreen({
    super.key,
    required this.db,
    this.initialType = TransactionType.expense,
    this.prefillTitle,
    this.prefillAmount,
    this.prefillWzNumber,
    this.sourceDocumentId,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _titleCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _wzCtrl;
  double? _amount;
  bool _amountTouched = false;
  bool _isPaid = true;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<Category> _categories = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _titleCtrl = TextEditingController(text: widget.prefillTitle ?? '');
    _amount = widget.prefillAmount;
    _notesCtrl = TextEditingController();
    _wzCtrl = TextEditingController(text: widget.prefillWzNumber ?? '');
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await widget.db.transactionsDao.getCategoriesByType(_type);
    setState(() {
      _categories = cats;
      _selectedCategory = cats.isNotEmpty ? cats.first.name : null;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _wzCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('pl', 'PL'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _openKeypad() async {
    final isIncome = _type == TransactionType.income;
    final result = await showNumericKeypad(
      context,
      initialValue: _amount,
      accentColor: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
    );
    if (result != null) {
      setState(() {
        _amount = result;
        _amountTouched = true;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _amountTouched = true);
    if (!_formKey.currentState!.validate()) return;
    if (_amount == null || _amount! <= 0) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wybierz kategorię')));
      return;
    }
    setState(() => _saving = true);
    final transactionId = await widget.db.transactionsDao.insertTransaction(
      TransactionsCompanion.insert(
        title: _titleCtrl.text.trim(),
        amount: _amount!,
        type: _type,
        category: _selectedCategory!,
        notes: Value(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
        wzNumber: Value(_wzCtrl.text.trim().isEmpty ? null : _wzCtrl.text.trim()),
        isPaid: Value(_isPaid),
        date: _selectedDate,
      ),
    );
    if (widget.sourceDocumentId != null) {
      await widget.db.documentsDao
          .linkTransaction(widget.sourceDocumentId!, transactionId);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == TransactionType.income;
    final accentColor = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final dateFormatter = DateFormat('dd.MM.yyyy', 'pl_PL');
    final moneyFormatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final amountError = _amountTouched && (_amount == null || _amount! <= 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Dodaj przychód' : 'Dodaj wydatek'),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Przełącznik typ
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Przychód'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Wydatek'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() => _type = s.first);
                  _loadCategories();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
                    }
                    return null;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return null;
                  }),
                ),
              ),
              const SizedBox(height: 20),
              // Tytuł
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tytuł / opis *',
                  prefixIcon: Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Podaj tytuł' : null,
              ),
              const SizedBox(height: 16),
              // Kwota — duży własny numpad
              InkWell(
                onTap: _openKeypad,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Kwota *',
                    prefixIcon: const Icon(Icons.payments),
                    suffixIcon: const Icon(Icons.dialpad),
                    errorText: amountError ? 'Podaj kwotę' : null,
                  ),
                  child: Text(
                    _amount != null ? moneyFormatter.format(_amount) : 'Dotknij, aby wprowadzić',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _amount != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Kategoria
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategoria *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Wybierz kategorię' : null,
              ),
              const SizedBox(height: 16),
              // Data
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormatter.format(_selectedDate),
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              // Status płatności
              Card(
                margin: EdgeInsets.zero,
                color: _isPaid ? null : Colors.orange.shade50,
                child: SwitchListTile(
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v),
                  activeThumbColor: AppTheme.incomeColor,
                  title: Text(_isPaid ? 'Zapłacone' : 'Niezapłacone'),
                  subtitle: Text(
                    isIncome
                        ? (_isPaid
                            ? 'Klient zapłacił'
                            : 'Należność — klient jeszcze nie zapłacił')
                        : (_isPaid
                            ? 'Zapłacono hurtowni/dostawcy'
                            : 'Zobowiązanie — termin płatności odroczony'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  secondary: Icon(
                    _isPaid ? Icons.check_circle_outline : Icons.schedule,
                    color: _isPaid ? AppTheme.incomeColor : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Numer WZ (opcjonalny)
              TextFormField(
                controller: _wzCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numer WZ (opcjonalnie)',
                  prefixIcon: Icon(Icons.receipt),
                  hintText: 'np. WZ/2026/001',
                ),
              ),
              const SizedBox(height: 16),
              // Notatki
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
              // Przycisk zapisz
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'Zapisywanie...' : 'Zapisz',
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
    );
  }
}
