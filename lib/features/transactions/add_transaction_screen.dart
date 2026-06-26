import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';
import '../../shared/widgets/numeric_keypad_dialog.dart';
import '../../shared/widgets/responsive_page.dart';

class AddTransactionScreen extends StatefulWidget {
  final AppDatabase db;
  final TransactionType initialType;
  final String? prefillTitle;
  final double? prefillAmount;
  final String? prefillWzNumber;
  final int? sourceDocumentId;

  /// Gdy podana, ekran działa w trybie edycji tej transakcji
  /// (zamiast tworzenia nowej).
  final Transaction? existing;

  const AddTransactionScreen({
    super.key,
    required this.db,
    this.initialType = TransactionType.expense,
    this.prefillTitle,
    this.prefillAmount,
    this.prefillWzNumber,
    this.sourceDocumentId,
    this.existing,
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
    final existing = widget.existing;
    _type = existing?.type ?? widget.initialType;
    _titleCtrl = TextEditingController(
      text: existing?.title ?? widget.prefillTitle ?? '',
    );
    _amount = existing?.amount ?? widget.prefillAmount;
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
    _wzCtrl = TextEditingController(
      text: existing?.wzNumber ?? widget.prefillWzNumber ?? '',
    );
    _isPaid = existing?.isPaid ?? true;
    _selectedDate = existing?.date ?? DateTime.now();
    _selectedCategory = existing?.category;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await widget.db.transactionsDao.getCategoriesByType(_type);
    setState(() {
      _categories = cats;
      final keepCurrent =
          _selectedCategory != null &&
          cats.any((c) => c.name == _selectedCategory);
      if (!keepCurrent) {
        _selectedCategory = cats.isNotEmpty ? cats.first.name : null;
      }
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

  /// Dodaje lub odejmuje kwotę od bieżącej wartości pola — wygodne przy
  /// dopisywaniu dodatkowych kosztów (np. części) do istniejącej pozycji.
  Future<void> _adjustAmount({required bool add}) async {
    final isIncome = _type == TransactionType.income;
    final delta = await showNumericKeypad(
      context,
      accentColor: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
    );
    if (delta == null || delta <= 0) return;
    setState(() {
      final newAmount = (_amount ?? 0) + (add ? delta : -delta);
      _amount = newAmount < 0 ? 0 : newAmount;
      _amountTouched = true;
    });
  }

  Future<void> _save() async {
    setState(() => _amountTouched = true);
    if (!_formKey.currentState!.validate()) return;
    if (_amount == null || _amount! <= 0) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wybierz kategorię')));
      return;
    }
    setState(() => _saving = true);

    final existing = widget.existing;
    final double paidAmount;
    if (_isPaid) {
      paidAmount = _amount!;
    } else if (existing != null && existing.isPaid == _isPaid) {
      // Status niezapłacone bez zmian — zachowujemy dotychczasową częściową spłatę.
      paidAmount = existing.paidAmount.clamp(0, _amount!);
    } else {
      paidAmount = 0;
    }

    final notes = Value(
      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    final wzNumber = Value(
      _wzCtrl.text.trim().isEmpty ? null : _wzCtrl.text.trim(),
    );

    if (existing == null) {
      final transactionId = await widget.db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          title: _titleCtrl.text.trim(),
          amount: _amount!,
          type: _type,
          category: _selectedCategory!,
          notes: notes,
          wzNumber: wzNumber,
          isPaid: Value(_isPaid),
          paidAmount: Value(paidAmount),
          date: _selectedDate,
        ),
      );
      if (widget.sourceDocumentId != null) {
        await widget.db.documentsDao.linkTransaction(
          widget.sourceDocumentId!,
          transactionId,
        );
      }
    } else {
      await widget.db.transactionsDao.updateTransaction(
        existing.copyWith(
          title: _titleCtrl.text.trim(),
          amount: _amount!,
          type: _type,
          category: _selectedCategory!,
          notes: notes,
          wzNumber: wzNumber,
          isPaid: _isPaid,
          paidAmount: paidAmount,
          date: _selectedDate,
        ),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final isIncome = _type == TransactionType.income;
    final accentColor = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final dateFormatter = DateFormat('dd.MM.yyyy', 'pl_PL');
    final moneyFormatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final amountError = _amountTouched && (_amount == null || _amount! <= 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? (isIncome ? 'Edytuj przychód' : 'Edytuj wydatek')
              : (isIncome ? 'Dodaj przychód' : 'Dodaj wydatek'),
        ),
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
                        return isIncome
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor;
                      }
                      return null;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected))
                        return Colors.white;
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
                      _amount != null
                          ? moneyFormatter.format(_amount)
                          : 'Dotknij, aby wprowadzić',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _amount != null
                            ? null
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _adjustAmount(add: true),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Dodaj kwotę'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(color: accentColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _adjustAmount(add: false),
                          icon: const Icon(Icons.remove, size: 18),
                          label: const Text('Odejmij kwotę'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(color: accentColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Kategoria
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategoria *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name),
                        ),
                      )
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
                    child: Text(
                      dateFormatter.format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Status płatności
                Card(
                  margin: EdgeInsets.zero,
                  color: _isPaid
                      ? null
                      : AppTheme.pendingColor.withOpacity(
                          Theme.of(context).brightness == Brightness.dark
                              ? 0.16
                              : 0.08,
                        ),
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
                      color: _isPaid
                          ? AppTheme.incomeColor
                          : AppTheme.pendingColor,
                    ),
                  ),
                ),
                if (!_isPaid &&
                    widget.existing != null &&
                    widget.existing!.isPaid == false &&
                    widget.existing!.paidAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Spłacono już częściowo: ${moneyFormatter.format(widget.existing!.paidAmount)}. '
                      'Zostanie zachowane, jeśli nie zmienisz tego przełącznika.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
