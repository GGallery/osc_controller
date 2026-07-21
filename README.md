# OSC Controller

App **Flutter** multipiattaforma (iOS, Android, macOS, Windows) per costruire pannelli di controllo che inviano e ricevono dati in tempo reale via **OSC** (Open Sound Control) su rete locale, tramite **UDP** — pensata per pilotare visori VR, installazioni interattive o qualunque dispositivo/software che parli OSC.

Il progetto è costruito con un'architettura a "mattoncini": ogni campo di un form (slider, switch, dropdown, pad XY, ecc.) e ogni grafico sono descritti da un semplice oggetto dati, disegnato automaticamente da un motore comune. Aggiungere un nuovo campo, una nuova pagina o un nuovo grafico non richiede di scrivere widget da zero: basta copiare un esempio esistente. Per questo il manuale utente è scritto pensando anche a chi non programma abitualmente in Flutter/Dart.

## Funzionalità principali

- **Init Settings** — pagina statica: si compila con calma e si salva/invia con un pulsante esplicito.
- **Live Change** — pagina "in tempo reale": ogni controllo invia il proprio valore via OSC appena viene toccato, secondo un trigger configurabile per campo.
- **Ricevi OSC (Listener)** — ascolta la porta UDP 9000 e mostra in tempo reale i campi e i grafici collegati ai dati in arrivo, più un registro di tutti i messaggi ricevuti.
- **Impostazioni** — IP, porta e indirizzo OSC del dispositivo di destinazione, con esportazione/importazione dell'intera configurazione in JSON.
- **Grafici live** (tramite [`fl_chart`](https://pub.dev/packages/fl_chart)) — andamento nel tempo dei valori ricevuti (linea, barre, torta).
- Oltre 20 tipi di campo pronti all'uso: testo, numero, password, slider, range, rating, contatore, color picker, file picker, data/ora, pad XY, pulsante momentaneo e altri.
- Persistenza locale su database SQLite (via [`drift`](https://pub.dev/packages/drift)).

## Documentazione completa

Tutte le istruzioni dettagliate — compilazione per piattaforma, catalogo dei campi disponibili, tutorial per creare nuove pagine, come funziona l'invio/ricezione OSC, risoluzione dei problemi comuni — sono nel **manuale utente**, disponibile in due formati equivalenti:

- [`MANUALE_UTENTE.md`](./MANUALE_UTENTE.md)
- [`MANUALE_UTENTE.docx`](./MANUALE_UTENTE.docx)

## Avvio rapido

Requisiti: [Flutter SDK](https://flutter.dev) installato e verificato con `flutter doctor`.

```bash
git clone <url-del-repository>
cd osc_controller
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # genera lib/db.g.dart
flutter run -d macos   # oppure: windows, ios, android, chrome...
```

Per le istruzioni specifiche di ogni piattaforma (cosa installare, permessi di rete da configurare, come eseguire su emulatore/simulatore o su dispositivo fisico, comandi di debug) vedi la **sezione 1** del manuale utente.

## Struttura del progetto

| Percorso | Contenuto |
|---|---|
| `lib/form_schema.dart` | Elenco dei tipi di campo disponibili e schema dei campi di ogni pagina — il file da modificare per aggiungere/togliere campi. |
| `lib/dynamic_field_builder.dart` | Motore che trasforma ogni campo dello schema nel widget Flutter corrispondente. |
| `lib/chart_schema.dart` / `lib/chart_builder.dart` | Stessa idea, per i grafici. |
| `lib/form_page.dart`, `lib/live_change_page.dart`, `lib/receiver_osc_page.dart`, `lib/settings_page.dart` | Le 4 pagine dell'app. |
| `lib/osc_sender.dart` / `lib/osc_decoder.dart` | Costruzione/invio e decodifica dei pacchetti OSC via UDP. |
| `lib/db.dart` | Database locale (SQLite via `drift`). |
| `tools/test_osc_sender.py` | Script Python per inviare dati OSC finti e testare l'app senza un dispositivo esterno. |
| `test/` | Test automatici (`flutter test`). |

Il dettaglio completo, file per file, è nella **sezione 2** del manuale utente.

## Test

```bash
flutter test                              # tutti i test automatici
python3 tools/test_osc_sender.py          # test manuale in tempo reale (vedi sezione 14 del manuale)
```

## Stack tecnico

Flutter/Dart · [`drift`](https://pub.dev/packages/drift) (database locale) · [`osc`](https://pub.dev/packages/osc) (protocollo OSC) · [`fl_chart`](https://pub.dev/packages/fl_chart) (grafici) · [`shared_preferences`](https://pub.dev/packages/shared_preferences), [`file_picker`](https://pub.dev/packages/file_picker), [`flutter_colorpicker`](https://pub.dev/packages/flutter_colorpicker), [`flutter_rating_bar`](https://pub.dev/packages/flutter_rating_bar), [`intl`](https://pub.dev/packages/intl).
