# Projekt: BudgetApp — aplikacja do zarządzania budżetem (Flutter)

## Stack
- Flutter (stable), Dart
- State management: BLoC (sealed events/states)
- Nawigacja: GoRouter
- Lokalna baza: [drift / sqflite / Isar]
- Testy: flutter_test + bloc_test + mocktail

## Zasady kodowania
- **PIENIĄDZE**: int w groszach, NIGDY double
- RED-GREEN-REFACTOR: test najpierw
- Waluta/data: intl package, nie hardkoduj

## Design System (Material 3)
- Success (wpływy): #4CAF50
- Warning (limit): #FFC107
- Danger (przekrocz): #F44336
- Spacing: wielokrotności 8px
- Komponenty: TransactionCard, BudgetProgressIndicator, CategoryChip