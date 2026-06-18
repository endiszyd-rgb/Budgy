import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/database/database.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/scanner/wz_scanner_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/documents/documents_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL', null);
  await ThemeController.load();
  final db = AppDatabase();
  runApp(BudzetWarsztatuApp(db: db));
}

class BudzetWarsztatuApp extends StatelessWidget {
  final AppDatabase db;
  const BudzetWarsztatuApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Budżet Warsztatu',
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pl', 'PL'), Locale('en', 'US')],
        home: MainScaffold(db: db),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final AppDatabase db;
  const MainScaffold({super.key, required this.db});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(db: widget.db),
      TransactionsScreen(db: widget.db),
      DocumentsScreen(db: widget.db),
      ReportsScreen(db: widget.db),
    ];
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  void _openAddTransaction(TransactionType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(db: widget.db, initialType: type),
      ),
    );
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WzScannerScreen(db: widget.db)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      // Dolna nawigacja
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Historia'),
          NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Dokumenty'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Raporty'),
        ],
      ),
      // FAB z menu szybkich akcji
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _ActionTile(
                icon: Icons.arrow_upward,
                color: AppTheme.incomeColor,
                title: 'Dodaj przychód',
                subtitle: 'Usługi, sprzedaż, inne wpływy',
                onTap: () {
                  Navigator.pop(context);
                  _openAddTransaction(TransactionType.income);
                },
              ),
              _ActionTile(
                icon: Icons.arrow_downward,
                color: AppTheme.expenseColor,
                title: 'Dodaj wydatek',
                subtitle: 'Materiały, narzędzia, paliwo...',
                onTap: () {
                  Navigator.pop(context);
                  _openAddTransaction(TransactionType.expense);
                },
              ),
              _ActionTile(
                icon: Icons.document_scanner,
                color: Colors.indigo,
                title: 'Skanuj dokument WZ',
                subtitle: 'OCR z aparatu lub galerii',
                onTap: () {
                  Navigator.pop(context);
                  _openScanner();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        radius: 26,
        child: Icon(icon, color: color, size: 26),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }
}
