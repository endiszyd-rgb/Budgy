import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/database/database.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'core/transitions.dart';
import 'shared/widgets/staggered_fade_in.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/transactions/unpaid_payments_screen.dart';
import 'features/scanner/wz_scanner_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/documents/documents_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/schedule/calendar/calendar_screen.dart';
import 'features/schedule/add_appointment_screen.dart';

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

typedef NavDestination = ({IconData icon, IconData selectedIcon, String label});

const _destinations = <NavDestination>[
  (
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  (
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    label: 'Terminarz',
  ),
  (
    icon: Icons.list_alt_outlined,
    selectedIcon: Icons.list_alt,
    label: 'Historia',
  ),
  (icon: Icons.folder_outlined, selectedIcon: Icons.folder, label: 'Dokumenty'),
  (
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    label: 'Raporty',
  ),
  (
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Ustawienia',
  ),
];

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
      CalendarScreen(db: widget.db),
      TransactionsScreen(db: widget.db),
      DocumentsScreen(db: widget.db),
      ReportsScreen(db: widget.db),
      SettingsScreen(db: widget.db),
    ];
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  void _openAddTransaction(TransactionType type) {
    Navigator.push(
      context,
      premiumRoute(AddTransactionScreen(db: widget.db, initialType: type)),
    );
  }

  void _openScanner() {
    Navigator.push(context, premiumRoute(WzScannerScreen(db: widget.db)));
  }

  void _openUnpaidPayments() {
    Navigator.push(context, premiumRoute(UnpaidPaymentsScreen(db: widget.db)));
  }

  void _openAddAppointment() {
    Navigator.push(context, premiumRoute(AddAppointmentScreen(db: widget.db)));
  }

  void _toggleTheme() {
    final current = ThemeController.themeMode.value;
    final isDark =
        current == ThemeMode.dark ||
        (current == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    ThemeController.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedIndex,
            onSelect: _onNavTap,
            onAddTap: () => _showActionMenu(context),
            onThemeToggle: _toggleTheme,
          ),
          VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              StaggeredFadeIn(
                index: 0,
                child: _ActionTile(
                  icon: Icons.arrow_upward,
                  color: AppTheme.incomeColor,
                  title: 'Dodaj przychód',
                  subtitle: 'Usługi, sprzedaż, inne wpływy',
                  onTap: () {
                    Navigator.pop(context);
                    _openAddTransaction(TransactionType.income);
                  },
                ),
              ),
              StaggeredFadeIn(
                index: 1,
                child: _ActionTile(
                  icon: Icons.arrow_downward,
                  color: AppTheme.expenseColor,
                  title: 'Dodaj wydatek',
                  subtitle: 'Materiały, narzędzia, paliwo...',
                  onTap: () {
                    Navigator.pop(context);
                    _openAddTransaction(TransactionType.expense);
                  },
                ),
              ),
              StaggeredFadeIn(
                index: 2,
                child: _ActionTile(
                  icon: Icons.document_scanner,
                  color: AppTheme.primary,
                  title: 'Skanuj dokument WZ',
                  subtitle: 'OCR z aparatu lub galerii',
                  onTap: () {
                    Navigator.pop(context);
                    _openScanner();
                  },
                ),
              ),
              StaggeredFadeIn(
                index: 3,
                child: _ActionTile(
                  icon: Icons.calendar_month_outlined,
                  color: AppTheme.primary,
                  title: 'Umów pracę',
                  subtitle: 'Zaplanuj wizytę klienta w terminarzu',
                  onTap: () {
                    Navigator.pop(context);
                    _openAddAppointment();
                  },
                ),
              ),
              StaggeredFadeIn(
                index: 4,
                child: _ActionTile(
                  icon: Icons.payments_outlined,
                  color: AppTheme.pendingColor,
                  title: 'Spłać / rozlicz',
                  subtitle: 'Częściowa spłata należności lub zobowiązania',
                  onTap: () {
                    Navigator.pop(context);
                    _openUnpaidPayments();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddTap;
  final VoidCallback onThemeToggle;

  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddTap,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.handyman_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Budżet Warsztatu',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _destinations.length,
                itemBuilder: (context, i) {
                  return _NavItem(
                    destination: _destinations[i],
                    selected: i == selectedIndex,
                    isDark: isDark,
                    onTap: () => onSelect(i),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: onThemeToggle,
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
                label: Text(isDark ? 'Jasny motyw' : 'Ciemny motyw'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final NavDestination destination;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final d = widget.destination;

    Color background;
    if (selected) {
      background = AppTheme.primary.withOpacity(widget.isDark ? 0.18 : 0.1);
    } else if (_hovering) {
      background = colorScheme.onSurface.withOpacity(
        widget.isDark ? 0.06 : 0.04,
      );
    } else {
      background = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      selected ? d.selectedIcon : d.icon,
                      key: ValueKey(selected),
                      size: 22,
                      color: selected
                          ? AppTheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppTheme.primary
                          : colorScheme.onSurface,
                    ),
                    child: Text(d.label),
                  ),
                ],
              ),
            ),
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
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }
}
