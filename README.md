# Budgy — Budżet Warsztatu

Aplikacja Android (zoptymalizowana pod 12" tablet Huawei) do zarządzania budżetem warsztatu samochodowego: szybkie księgowanie przychodów i wydatków, skanowanie dokumentów WZ z hurtowni przez OCR, raporty miesięczne i backup danych na Dysku Google.

## Stack technologiczny

| Warstwa | Technologia |
|---|---|
| UI | Flutter (Dart) |
| Baza danych | Drift (SQLite), lokalnie na urządzeniu |
| OCR | Google ML Kit (`google_mlkit_text_recognition`) — działa offline |
| Wykresy | fl_chart |
| Eksport raportów | pdf, printing, excel |
| Backup | Google Sign-In + Google Drive API (`googleapis`) |
| Pakowanie backupu | archive (zip) |

## Funkcje

### 1. Dashboard
- Bilans miesięczny (przychody − wydatki) z nawigacją między miesiącami
- Karty przychodów i wydatków
- Wykres kołowy struktury wydatków wg kategorii
- Lista ostatnich transakcji z możliwością podglądu zeskanowanego dokumentu (ikona 🖼️, jeśli transakcja powstała ze skanu WZ) i usuwania (przytrzymanie)

### 2. Szybkie dodawanie transakcji
- Pływający przycisk **+** → menu: Dodaj przychód / Dodaj wydatek / Skanuj dokument WZ
- Formularz: tytuł, kwota, kategoria, data, opcjonalny numer WZ i notatki

### 3. Skaner dokumentów WZ (OCR)
- Zdjęcie z aparatu lub wybór z galerii
- Automatyczne rozpoznanie: numeru WZ, dostawcy, kwoty, daty (Google ML Kit, offline)
- Zeskanowane zdjęcie zapisywane trwale w archiwum dokumentów aplikacji
- Przejście do formularza transakcji z wypełnionymi danymi

### 4. Archiwum dokumentów ("Dokumenty")
- Wszystkie zeskanowane dokumenty WZ pogrupowane wg daty skanowania
- Miniatury w siatce, znacznik ✓ jeśli dokument jest powiązany z transakcją
- Pełnoekranowy podgląd z zoomem (pinch-to-zoom) i możliwością usunięcia

### 5. Historia transakcji
- Lista wszystkich transakcji pogrupowana wg dnia
- Filtrowanie: wszystkie / przychody / wydatki
- Wyszukiwanie po tytule, kategorii lub numerze WZ

### 6. Raporty
- Wybór miesiąca, podsumowanie przychodów/wydatków/bilansu
- Wykres słupkowy przychody vs wydatki wg tygodni miesiąca
- Podział wydatków i przychodów wg kategorii (z udziałem procentowym)
- Eksport do **PDF** (do druku/wysłania) i **Excel** (do dalszej analizy)

### 7. Kategorie
- Domyślne kategorie: Materiały, Narzędzia, Paliwo, Wynajem, Inne wydatki / Usługi, Sprzedaż części, Inne przychody
- Zarządzanie (Ustawienia → Kategorie): zmiana nazwy i koloru, dodawanie nowych, usuwanie
- Usunięcie kategorii nie wpływa na istniejące transakcje (zachowują nazwę w historii)
- Nie można usunąć ostatniej kategorii danego typu (przychód/wydatek musi mieć z czego wybierać)

### 8. Backup na Dysku Google
- Logowanie kontem Google (OAuth, scope `drive.file` — dostęp tylko do plików utworzonych przez aplikację)
- **Backup teraz**: pakuje bazę danych + wszystkie zeskanowane dokumenty w jeden plik `budgy_backup.zip` i wysyła do folderu „Budgy Backups” na Dysku
- **Przywróć**: pobiera ostatni backup i nadpisuje lokalne dane (z potwierdzeniem), następnie wymaga zamknięcia i ponownego otwarcia aplikacji
- Wymaga jednorazowej konfiguracji projektu w Google Cloud Console (OAuth Client ID dla Androida)

## Struktura projektu

```
lib/
├── main.dart                          # Nawigacja, FAB menu szybkich akcji
├── core/
│   ├── database/
│   │   ├── database.dart              # Definicje tabel Drift (Transactions, Categories, ScannedDocuments)
│   │   └── dao/
│   │       ├── transactions_dao.dart  # Zapytania do transakcji i kategorii
│   │       └── documents_dao.dart     # Zapytania do zeskanowanych dokumentów
│   ├── backup/
│   │   └── drive_backup_service.dart  # Logowanie Google, backup/restore na Dysku
│   └── theme.dart                     # Motyw kolorystyczny aplikacji
├── features/
│   ├── dashboard/                     # Ekran główny z bilansem i wykresem
│   ├── transactions/                  # Formularz dodawania + historia transakcji
│   ├── scanner/                       # Skaner WZ z OCR
│   ├── documents/                     # Archiwum zeskanowanych dokumentów + podgląd
│   ├── reports/                       # Raporty miesięczne + eksport PDF/Excel
│   ├── categories/                    # Zarządzanie kategoriami
│   └── settings/                      # Ustawienia, backup Google Drive
└── shared/widgets/                    # Komponenty wspólne (karty, kafelki transakcji)
```

## Baza danych

Trzy tabele SQLite (Drift), plik `budzet_warsztatu.sqlite` w katalogu dokumentów aplikacji:

- **Transactions** — tytuł, kwota, typ (przychód/wydatek), kategoria, notatki, numer WZ, data
- **Categories** — nazwa, typ, ikona, kolor
- **ScannedDocuments** — ścieżka do zdjęcia, numer WZ, dostawca, kwota, surowy tekst OCR, powiązana transakcja, data skanu

Zeskanowane zdjęcia są przechowywane w `wz_documents/` w katalogu dokumentów aplikacji.

## Budowanie projektu

```powershell
flutter pub get
dart run build_runner build          # generuje kod Drift (*.g.dart)
flutter build apk --debug            # APK w build/app/outputs/flutter-apk/
```

### Wymagana konfiguracja Google Cloud (dla backupu)

1. Utwórz projekt w [Google Cloud Console](https://console.cloud.google.com/projectcreate)
2. Włącz **Google Drive API**
3. Skonfiguruj **OAuth consent screen** (External, scope `drive.file`, dodaj siebie jako test user)
4. Utwórz **OAuth Client ID** typu Android:
   - Package name: `com.warsztat.budzet_warsztatu`
   - SHA-1: pobierz przez `cd android && ./gradlew signingReport`

## Repozytorium

https://github.com/endiszyd-rgb/Budgy
