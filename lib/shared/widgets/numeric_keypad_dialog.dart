import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pokazuje duży, dotykowy panel numeryczny do wprowadzania kwoty.
/// Wygodny w rękawicach lub z brudnymi palcami — bez systemowej klawiatury.
Future<double?> showNumericKeypad(
  BuildContext context, {
  double? initialValue,
  required Color accentColor,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _NumericKeypadDialog(
      initialValue: initialValue,
      accentColor: accentColor,
    ),
  );
}

class _NumericKeypadDialog extends StatefulWidget {
  final double? initialValue;
  final Color accentColor;

  const _NumericKeypadDialog({this.initialValue, required this.accentColor});

  @override
  State<_NumericKeypadDialog> createState() => _NumericKeypadDialogState();
}

class _NumericKeypadDialogState extends State<_NumericKeypadDialog> {
  static const _maxDigits = 8;
  late String _digits;

  @override
  void initState() {
    super.initState();
    final cents = ((widget.initialValue ?? 0) * 100).round();
    _digits = cents > 0 ? cents.toString() : '';
  }

  double get _amount =>
      (int.tryParse(_digits.isEmpty ? '0' : _digits) ?? 0) / 100;

  String get _display {
    final formatter = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    return formatter.format(_amount);
  }

  void _tapDigit(String digit) {
    if (_digits.length >= _maxDigits) return;
    setState(() => _digits += digit);
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _clear() => setState(() => _digits = '');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wprowadź kwotę',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _display,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildRow(context, ['1', '2', '3']),
              const SizedBox(height: 10),
              _buildRow(context, ['4', '5', '6']),
              const SizedBox(height: 10),
              _buildRow(context, ['7', '8', '9']),
              const SizedBox(height: 10),
              Row(
                children: [
                  _keyButton(context, label: 'C', onTap: _clear),
                  const SizedBox(width: 10),
                  _keyButton(context, label: '0', onTap: () => _tapDigit('0')),
                  const SizedBox(width: 10),
                  _keyButton(
                    context,
                    icon: Icons.backspace_outlined,
                    onTap: _backspace,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Anuluj',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _amount > 0
                          ? () => Navigator.pop(context, _amount)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Gotowe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      children:
          digits
              .map(
                (d) => _keyButton(context, label: d, onTap: () => _tapDigit(d)),
              )
              .expand((w) => [w, const SizedBox(width: 10)])
              .toList()
            ..removeLast(),
    );
  }

  Widget _keyButton(
    BuildContext context, {
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    Color? background,
    Color? foreground,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: background ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 26, color: foreground ?? scheme.onSurface)
                  : Text(
                      label!,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: foreground ?? scheme.onSurface,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
