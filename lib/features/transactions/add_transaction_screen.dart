import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';

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
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _wzCtrl;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<Category> _categories = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _titleCtrl = TextEditingController(text: widget.prefillTitle ?? '');
    _amountCtrl = TextEditingController(
        text: widget.prefillAmount != null
            ? widget.prefillAmount!.toStringAsFixed(2)
            : '');
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
    _amountCtrl.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wybierz kategorię')));
      return;
    }
    setState(() => _saving = true);
    final transactionId = await widget.db.transactionsDao.insertTransaction(
      TransactionsCompanion.insert(
        title: _titleCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
        type: _type,
        category: _selectedCategory!,
        notes: Value(_notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
        wzNumber: Value(_wzCtrl.text.trim().isEmpty ? null : _wzCtrl.text.trim()),
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
    final dateFormatter = DateFormat('dd.MM.yyyy', 'pl_PL');

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Dodaj przychód' : 'Dodaj wydatek'),
        backgroundColor: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
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
              // Kwota
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kwota (zł) *',
                  prefixIcon: Icon(Icons.payments),
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Podaj kwotę';
                  final val = double.tryParse(v.replaceAll(',', '.'));
                  if (val == null || val <= 0) return 'Nieprawidłowa kwota';
                  return null;
                },
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
                  backgroundColor:
                      isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
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
