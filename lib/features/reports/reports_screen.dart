import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/database.dart';
import '../../core/theme.dart';

class ReportsScreen extends StatefulWidget {
  final AppDatabase db;
  const ReportsScreen({super.key, required this.db});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _selectedMonth;
  List<Transaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await widget.db.transactionsDao
        .getTransactionsByMonth(_selectedMonth.year, _selectedMonth.month);
    setState(() {
      _transactions = data;
      _loading = false;
    });
  }

  double get _income => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get _expense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final dateFmt = DateFormat('dd.MM.yyyy', 'pl_PL');
    final monthLabel =
        DateFormat('MMMM yyyy', 'pl_PL').format(_selectedMonth);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Header(
          level: 0,
          child: pw.Text('Raport: $monthLabel',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _pdfSummaryBox('Przychody', moneyFmt.format(_income), PdfColors.green800),
            _pdfSummaryBox('Wydatki', moneyFmt.format(_expense), PdfColors.red800),
            _pdfSummaryBox(
                'Bilans',
                moneyFmt.format(_income - _expense),
                (_income - _expense) >= 0 ? PdfColors.green800 : PdfColors.red800),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text('Lista transakcji',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Data', 'Tytuł', 'Kategoria', 'Typ', 'Kwota'],
          data: _transactions.map((t) => [
                dateFmt.format(t.date),
                t.title,
                t.category,
                t.type == TransactionType.income ? 'Przychód' : 'Wydatek',
                moneyFmt.format(t.amount),
              ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {4: pw.Alignment.centerRight},
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _pdfSummaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Future<void> _exportExcel() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Transakcje'];
    final moneyFmt = NumberFormat('#,##0.00', 'pl_PL');
    final dateFmt = DateFormat('dd.MM.yyyy', 'pl_PL');

    // Nagłówki
    sheet.appendRow([
      xl.TextCellValue('Data'),
      xl.TextCellValue('Tytuł'),
      xl.TextCellValue('Kategoria'),
      xl.TextCellValue('Typ'),
      xl.TextCellValue('Kwota (zł)'),
      xl.TextCellValue('Numer WZ'),
      xl.TextCellValue('Notatki'),
    ]);

    for (final t in _transactions) {
      sheet.appendRow([
        xl.TextCellValue(dateFmt.format(t.date)),
        xl.TextCellValue(t.title),
        xl.TextCellValue(t.category),
        xl.TextCellValue(
            t.type == TransactionType.income ? 'Przychód' : 'Wydatek'),
        xl.TextCellValue(moneyFmt.format(t.amount)),
        xl.TextCellValue(t.wzNumber ?? ''),
        xl.TextCellValue(t.notes ?? ''),
      ]);
    }

    // Podsumowanie
    sheet.appendRow([xl.TextCellValue('')]);
    sheet.appendRow([
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Przychody:'),
      xl.TextCellValue(moneyFmt.format(_income)),
    ]);
    sheet.appendRow([
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Wydatki:'),
      xl.TextCellValue(moneyFmt.format(_expense)),
    ]);
    sheet.appendRow([
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue('Bilans:'),
      xl.TextCellValue(moneyFmt.format(_income - _expense)),
    ]);

    final bytes = excel.save();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final monthLabel =
        DateFormat('yyyy_MM', 'pl_PL').format(_selectedMonth);
    final file = File('${dir.path}/raport_$monthLabel.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Raport warsztatu $monthLabel',
    );
  }

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporty'),
        actions: [
          IconButton(
            onPressed: _transactions.isEmpty ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Eksport PDF',
          ),
          IconButton(
            onPressed: _transactions.isEmpty ? null : _exportExcel,
            icon: const Icon(Icons.table_chart),
            tooltip: 'Eksport Excel',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nawigacja miesiąca
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          onPressed: () {
                            setState(() => _selectedMonth = DateTime(
                                _selectedMonth.year, _selectedMonth.month - 1));
                            _loadData();
                          },
                          icon: const Icon(Icons.chevron_left, size: 32)),
                      Text(
                        DateFormat('MMMM yyyy', 'pl_PL').format(_selectedMonth),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                          onPressed: () {
                            setState(() => _selectedMonth = DateTime(
                                _selectedMonth.year, _selectedMonth.month + 1));
                            _loadData();
                          },
                          icon: const Icon(Icons.chevron_right, size: 32)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Karty podsumowania
                  Row(
                    children: [
                      _SummaryCard(
                          label: 'Przychody',
                          value: moneyFmt.format(_income),
                          color: AppTheme.incomeColor),
                      const SizedBox(width: 8),
                      _SummaryCard(
                          label: 'Wydatki',
                          value: moneyFmt.format(_expense),
                          color: AppTheme.expenseColor),
                      const SizedBox(width: 8),
                      _SummaryCard(
                          label: 'Bilans',
                          value: moneyFmt.format(_income - _expense),
                          color: (_income - _expense) >= 0
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Brak transakcji w tym miesiącu',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                    )
                  else ...[
                    // Wykres słupkowy tygodnie
                    Text('Przychody vs Wydatki',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    SizedBox(height: 200, child: _buildBarChart()),
                    const SizedBox(height: 24),
                    // Top kategorie wydatków
                    Text('Wydatki wg kategorii',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _buildCategoryList(TransactionType.expense),
                    const SizedBox(height: 24),
                    Text('Przychody wg kategorii',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _buildCategoryList(TransactionType.income),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBarChart() {
    // Grupowanie wg tygodnia miesiąca
    final Map<int, double> incomeByWeek = {};
    final Map<int, double> expenseByWeek = {};
    for (final t in _transactions) {
      final week = ((t.date.day - 1) ~/ 7) + 1;
      if (t.type == TransactionType.income) {
        incomeByWeek[week] = (incomeByWeek[week] ?? 0) + t.amount;
      } else {
        expenseByWeek[week] = (expenseByWeek[week] ?? 0) + t.amount;
      }
    }
    final weeks = {
      ...incomeByWeek.keys,
      ...expenseByWeek.keys
    }.toList()..sort();

    return BarChart(BarChartData(
      barGroups: weeks.map((w) {
        return BarChartGroupData(x: w, barRods: [
          BarChartRodData(
              toY: incomeByWeek[w] ?? 0,
              color: AppTheme.incomeColor,
              width: 16,
              borderRadius: BorderRadius.circular(4)),
          BarChartRodData(
              toY: expenseByWeek[w] ?? 0,
              color: AppTheme.expenseColor,
              width: 16,
              borderRadius: BorderRadius.circular(4)),
        ]);
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) =>
                Text('Tydz. ${v.toInt()}', style: const TextStyle(fontSize: 11)),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (v, _) => Text(
              NumberFormat.compact(locale: 'pl_PL').format(v),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildCategoryList(TransactionType type) {
    final filtered = _transactions.where((t) => t.type == type).toList();
    final Map<String, double> byCategory = {};
    for (final t in filtered) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = filtered.fold(0.0, (s, t) => s + t.amount);
    final moneyFmt = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final color =
        type == TransactionType.income ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Column(
      children: sorted.map((e) {
        final pct = total > 0 ? (e.value / total) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(moneyFmt.format(e.value),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: pct,
                color: color,
                backgroundColor: color.withOpacity(0.15),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
