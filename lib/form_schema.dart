// form_schema.dart
//
// Questo file contiene TUTTI i "mattoncini" (building blocks) disponibili per
// costruire un form, PIÙ le liste che elencano i campi/grafici di ogni
// pagina. Il file è diviso in due parti:
//
// - Sezioni 1-6 (in cima): le classi/enum "motore" — cosa E' un campo
//   (DynamicFormField) e cosa E' un grafico (DynamicChartField) — più i
//   blocchi di esempio da copiare. Queste NON cambiano quasi mai.
// - Sezione 7 (in fondo al file): gli SCHEMI DI PAGINA veri e propri, cioè
//   le liste che elencano i campi/grafici mostrati da ciascuna pagina
//   dell'app (7.1 pagina statica, 7.2 pagina live, 7.3 pagina Listener).
//   Questa è la parte che si modifica quasi sempre: per aggiungere/togliere
//   un campo o un grafico da una pagina, basta editare la lista giusta qui.
//
// Per aggiungere un nuovo campo a una pagina basta COPIARE uno degli esempi
// di sezione 5 e INCOLLARLO nella lista di pagina giusta (sezione 7),
// cambiando id/label/opzioni. Non serve altro: il rendering del widget
// giusto è già gestito automaticamente da `dynamic_field_builder.dart`
// (per i campi) e da `chart_builder.dart` (per i grafici).
//
// Non è necessario conoscere Flutter per aggiungere un campo o un grafico:
// basta seguire gli esempi.
//
// Campi e grafici vivono di proposito nello stesso file, perché sono la
// stessa filosofia "mattoncino" applicata a due "motori di disegno" diversi
// (dynamic_field_builder.dart / chart_builder.dart).

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

// ---- 1. I TIPI DI CAMPO DISPONIBILI ---------------------------------------
/// Tutti i tipi di campo disponibili. Ogni tipo ha un widget dedicato in
/// `dynamic_field_builder.dart`.
enum FormFieldType {
  text,
  email,
  password,
  url,
  phone,
  number,
  multiline,
  checkbox,
  switchField,
  radio,
  toggleButtons,
  dropdown,
  slider,
  numberSlider,
  counter,
  stepper,
  rating,
  colorPicker,
  filePicker,
  date,
  time,
  timeRange,
  range,
  xyPad, // pad 2D (X/Y), utile per controlli spaziali via OSC
  momentaryButton, // pulsante "a pressione" (invia 1 mentre premuto, 0 al rilascio)
  label, // non è un campo dati: è solo un titolo/sezione per organizzare il form
}

// ---- 2. QUANDO INVIARE (solo pagina Live) ---------------------------------
/// Quando deve "partire" l'invio/salvataggio del valore di un campo.
///
/// - [onChange]: ad ogni singola modifica (es. ogni trascinamento dello slider,
///   ogni carattere digitato). Usalo per controlli "discreti" tipo switch,
///   checkbox, dropdown, dove ogni click è già una scelta definitiva.
/// - [onSubmit]: solo quando l'utente conferma (Invio/tastiera "Fatto") in un
///   campo di testo.
/// - [onFocusLost]: solo quando l'utente esce dal campo (es. rilascia lo
///   slider, o clicca altrove dopo aver scritto in un campo testo). È il modo
///   più "leggero" per campi che cambiano continuamente (slider) senza
///   inondare la rete di messaggi OSC ad ogni pixel di trascinamento.
/// - [onButton]: il valore NON viene inviato automaticamente: comparirà una
///   piccola icona di invio accanto al campo, da premere manualmente.
enum FieldTrigger { onChange, onSubmit, onFocusLost, onButton }

enum SelectionMode { single, multiple }

// ---- 3. LA CLASSE "MATTONCINO": un campo del form -------------------------
// Ogni riga degli schemi di pagina (sezione 7, in fondo al file) è
// un'istanza di questa classe. Le proprietà sono tutte facoltative tranne
// id/label/type.
class DynamicFormField {
  final String id;
  final String label;
  final FormFieldType type;
  final List<String>? options;
  dynamic value;
  final double min;
  final double max;
  final double step;
  final FieldTrigger trigger;

  /// Formato di visualizzazione per date/time (es. 'yyyy-MM-dd', 'HH:mm').
  final String? formatDatePattern;

  /// Per i dropdown: selezione singola o multipla.
  final SelectionMode selectionMode;

  /// Se `true`, mostra SEMPRE un'iconcina "Invia" accanto al campo (in più
  /// rispetto a quanto già previsto dal `trigger`), da premere per
  /// confermare manualmente il valore corrente.
  ///
  /// Utile per:
  /// - i campi `multiline`: il tasto Invio va a capo, non può anche
  ///   confermare, quindi senza questo pulsante non ci sarebbe alcun modo
  ///   per inviare il testo scritto;
  /// - qualunque altro campo di testo/slider/pad dove preferisci un
  ///   pulsante esplicito invece di affidarti solo al trigger automatico.
  ///
  /// Si applica ai campi che hanno un valore "in sospeso" prima dell'invio:
  /// text, email, url, phone, password, number, multiline, slider,
  /// numberSlider, range, xyPad. Sui controlli "a scelta secca" (switch,
  /// checkbox, radio, dropdown, ecc.) non ha effetto, perché quei controlli
  /// inviano già ad ogni interazione.
  final bool showSendButton;

  DynamicFormField({
    required this.id,
    required this.label,
    required this.type,
    this.options,
    this.value,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.trigger = FieldTrigger.onSubmit,
    this.formatDatePattern,
    this.selectionMode = SelectionMode.single,
    this.showSendButton = false,
  });
}

// ---- 4. FUNZIONI DI SUPPORTO -----------------------------------------------
/// I campi di tipo [FormFieldType.label] sono solo intestazioni visive: non
/// hanno un valore, non vanno salvati nel DB e non vanno inviati via OSC.
bool isDataField(FormFieldType type) => type != FormFieldType.label;

/// Cerca un campo per id in una lista di schema (helper di comodo).
DynamicFormField? findFieldById(List<DynamicFormField> schema, String id) =>
    schema.firstWhereOrNull((f) => f.id == id);

// ============================================================================
// ESEMPI DI CAMPO — copia il blocco che ti serve, incollalo nella lista dello
// schema di pagina (sezione 7, in fondo al file) e personalizza id/label/
// opzioni.
// ============================================================================
//
// Testo semplice:
//   DynamicFormField(id: 'mioTesto', label: 'Etichetta', type: FormFieldType.text),
//
// Sezione/titolo (solo organizzativo, non invia nulla):
//   DynamicFormField(id: 'sezioneAudio', label: 'Sezione Audio', type: FormFieldType.label),
//
// Interruttore (switch):
//   DynamicFormField(id: 'mioSwitch', label: 'Attiva', type: FormFieldType.switchField, value: false),
//
// Scelta singola tra opzioni (radio):
//   DynamicFormField(id: 'scelta', label: 'Modalità', type: FormFieldType.radio, options: ['A', 'B', 'C']),
//
// Scelta singola tra opzioni (pulsanti a gruppo):
//   DynamicFormField(id: 'gruppo', label: 'Vista', type: FormFieldType.toggleButtons, options: ['Mappa', '3D', 'Lista']),
//
// Pad XY (controllo bidimensionale, es. joystick virtuale):
//   DynamicFormField(id: 'padPosizione', label: 'Posizione', type: FormFieldType.xyPad, trigger: FieldTrigger.onChange),
//
// Pulsante "a pressione" (invia 1 mentre è premuto, 0 al rilascio):
//   DynamicFormField(id: 'pulsanteFuoco', label: 'Fuoco', type: FormFieldType.momentaryButton),
//
// ============================================================================

// ---- 6. I GRAFICI: TIPI E CLASSE "MATTONCINO" ------------------------------
// Stessa filosofia "mattoncino" delle sezioni precedenti, applicata ai
// grafici: una classe che descrive UN grafico (tipo, colore, quanti punti
// tenere in memoria) e delle liste (sezione 7.3, in fondo al file) che
// elencano i grafici di una pagina. Il disegno vero e proprio è delegato a
// chart_builder.dart (buildDynamicChart), esattamente come
// dynamic_field_builder.dart fa per i campi del form.
//
// Per aggiungere un nuovo grafico a una pagina:
//   1. Aggiungi una riga DynamicChartField a una lista di sezione 7.3 (o
//      creane una nuova, se il grafico serve in un'altra pagina).
//   2. Ogni volta che arriva un valore nuovo, chiama `campo.addValue(x)`
//      dentro un setState(() {...}): il grafico si ridisegna da solo.
// Nessuna modifica serve a chart_builder.dart, a meno di voler cambiare
// COME viene disegnato un tipo di grafico già esistente.

// I tipi di grafico disponibili.
enum ChartType { line, bar, pie }

/// Usata solo dai grafici di tipo [ChartType.pie]: etichetta, valore e
/// colore di una singola fetta.
class ChartSlice {
  final String label;
  final double value;
  final Color color;
  ChartSlice({required this.label, required this.value, required this.color});
}

/// LA CLASSE "MATTONCINO": un grafico.
/// Descrive UN grafico (tipo, aspetto, quanti punti tenere in memoria) e ne
/// contiene i dati correnti.
///
/// Per i grafici a serie temporale ([ChartType.line], [ChartType.bar]): i
/// dati vivono in [values], una lista che si allunga ad ogni chiamata di
/// [addValue] e si accorcia da sola oltre [maxPoints] — una "finestra
/// scorrevole" pensata per dati che arrivano in continuazione (es. via OSC):
/// tiene solo gli ultimi N valori, invece di crescere all'infinito.
///
/// Per i grafici a torta ([ChartType.pie]): i dati vivono in [slices], da
/// riassegnare per intero quando cambiano (non c'è uno storico da scorrere,
/// solo l'ultima "fotografia" delle proporzioni).
class DynamicChartField {
  final String id;
  final String label;
  final ChartType type;
  final Color color;

  /// Estremi dell'asse Y (grafici line/bar). Ignorati per i grafici a torta.
  final double min;
  final double max;

  /// Quanti punti tenere in memoria per i grafici line/bar (finestra
  /// scorrevole). Ignorato per i grafici a torta.
  final int maxPoints;

  List<double> values;
  List<ChartSlice>? slices;

  DynamicChartField({
    required this.id,
    required this.label,
    required this.type,
    this.color = AppColors.primary,
    this.min = 0,
    this.max = 100,
    this.maxPoints = 30,
    List<double>? values,
    this.slices,
  }) : values = values ?? [];

  /// Aggiunge un nuovo valore alla serie (grafici line/bar), scartando il
  /// valore più vecchio se si supera [maxPoints]. Non chiama `setState` da
  /// sola: va richiamata dentro un `setState(() {...})` nella pagina che usa
  /// questo grafico, altrimenti il valore viene aggiornato ma lo schermo non
  /// si aggiorna.
  void addValue(double v) {
    values.add(v);
    if (values.length > maxPoints) {
      values.removeAt(0);
    }
  }

  /// Sostituisce interamente le fette di un grafico a torta con [newSlices].
  /// Come per [addValue], va richiamata dentro un `setState(() {...})`.
  void setSlices(List<ChartSlice> newSlices) {
    slices = newSlices;
  }
}

// ============================================================================
// ESEMPI DI GRAFICO — copia il blocco che ti serve, incollalo nella lista di
// schema della pagina (sezione 7.3, in fondo al file) e personalizza id/
// label/colore.
// ============================================================================
//
// Grafico a linea (andamento nel tempo di un valore, es. uno slider ricevuto):
//   DynamicChartField(id: 'temperaturaChart', label: 'Temperatura', type: ChartType.line, min: -20, max: 50),
//
// Grafico a barre (stessa idea del grafico a linea, ma a barre):
//   DynamicChartField(id: 'livelloChart', label: 'Livello', type: ChartType.bar, color: AppColors.success),
//
// Grafico a torta (proporzioni tra categorie, valori assegnati "in blocco" con setSlices):
//   DynamicChartField(id: 'distribuzioneChart', label: 'Distribuzione risposte', type: ChartType.pie),
//
// ============================================================================

// ============================================================================
// ---- 7. SCHEMI DI PAGINA ----------------------------------------------------
// Da qui in poi: le liste vere e proprie che ELENCANO i campi/grafici
// mostrati da ciascuna pagina dell'app, una sottosezione per pagina. Per
// aggiungere/rimuovere/riordinare un campo o un grafico di una pagina, è
// QUESTA la parte del file da modificare: le pagine stesse
// (form_page.dart, live_change_page.dart, receiver_osc_page.dart) non
// vanno toccate.
// ============================================================================

// ---- 7.1 Pagina statica ("Init Settings") ----------------------------------
// Questa è la lista che ELENCA i campi mostrati da FormPage
// (lib/form_page.dart). Per aggiungere/rimuovere/riordinare un campo di
// quella pagina, modifica QUESTA lista: FormPage non va toccata.
final List<DynamicFormField> formPageSchema = [
  DynamicFormField(
    id: 'sezioneTesto',
    label: 'Campi di testo',
    type: FormFieldType.label,
  ),
  DynamicFormField(id: 'textInput', label: 'Testo', type: FormFieldType.text),
  DynamicFormField(
    id: 'multilineInput',
    label: 'Testo Multilinea',
    type: FormFieldType.multiline,
    // Il tasto Invio in un campo multilinea va a capo, non conferma: senza
    // questa opzione non ci sarebbe modo di inviare il testo scritto.
    showSendButton: true,
  ),
  DynamicFormField(id: 'emailInput', label: 'Email', type: FormFieldType.email),
  DynamicFormField(id: 'urlInput', label: 'URL', type: FormFieldType.url),
  DynamicFormField(
    id: 'phoneInput',
    label: 'Telefono',
    type: FormFieldType.phone,
  ),
  DynamicFormField(
    id: 'numberInput',
    label: 'Numero',
    type: FormFieldType.number,
  ),
  DynamicFormField(
    id: 'passwordInput',
    label: 'Password',
    type: FormFieldType.password,
  ),

  DynamicFormField(
    id: 'sezioneNumeriche',
    label: 'Selezioni numeriche',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'sliderValue',
    label: 'Slider',
    type: FormFieldType.slider,
    value: 50.0,
    min: 0,
    max: 100,
  ),
  DynamicFormField(
    id: 'numberSliderValue',
    label: 'Slider con Step',
    type: FormFieldType.numberSlider,
    value: 20.0,
    min: 0,
    max: 100,
    step: 5,
  ),
  DynamicFormField(
    id: 'rangeValue',
    label: 'Intervallo',
    type: FormFieldType.range,
    value: RangeValues(20.0, 80.0),
    min: 0,
    max: 100,
  ),
  DynamicFormField(
    id: 'stepperValue',
    label: 'Stepper',
    type: FormFieldType.stepper,
    value: 10,
    step: 1,
  ),
  DynamicFormField(
    id: 'ratingValue',
    label: 'Valutazione',
    type: FormFieldType.rating,
    value: 3,
    min: 0,
    max: 5,
  ),
  DynamicFormField(
    id: 'counterValue',
    label: 'Contatore',
    type: FormFieldType.counter,
    value: 0,
  ),

  DynamicFormField(
    id: 'sezioneScelte',
    label: 'Scelte e opzioni',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'switchValue',
    label: 'Switch',
    type: FormFieldType.switchField,
    value: false,
  ),
  DynamicFormField(
    id: 'checkboxValue',
    label: 'Checkbox',
    type: FormFieldType.checkbox,
    value: false,
  ),
  DynamicFormField(
    id: 'radioGroup',
    label: 'Radio',
    type: FormFieldType.radio,
    options: ['Opzione A', 'Opzione B', 'Opzione C'],
  ),
  DynamicFormField(
    id: 'toggleGroup',
    label: 'Vista',
    type: FormFieldType.toggleButtons,
    options: ['Mappa', '3D', 'Lista'],
  ),
  DynamicFormField(
    id: 'dropdown',
    label: 'Dropdown',
    type: FormFieldType.dropdown,
    options: ['Italia', 'Francia', 'Spagna'],
    selectionMode: SelectionMode.single,
  ),
  DynamicFormField(
    id: 'dropdownMultiple',
    label: 'Dropdown multiplo',
    type: FormFieldType.dropdown,
    options: ['Rosso', 'Verde', 'Giallo'],
    selectionMode: SelectionMode.multiple,
    value: <String>[],
  ),
  DynamicFormField(
    id: 'colorValue',
    label: 'Colore',
    type: FormFieldType.colorPicker,
  ),
  DynamicFormField(
    id: 'fileValue',
    label: 'Carica File',
    type: FormFieldType.filePicker,
  ),

  DynamicFormField(
    id: 'sezioneDataOra',
    label: 'Data e ora',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'dateValue',
    label: 'Data',
    type: FormFieldType.date,
    formatDatePattern: 'yyyy-MM-dd',
  ),
  DynamicFormField(
    id: 'timeValue',
    label: 'Ora',
    type: FormFieldType.time,
    formatDatePattern: 'HH:mm',
  ),
  DynamicFormField(
    id: 'timeRangeValue',
    label: 'Intervallo Ora',
    type: FormFieldType.timeRange,
  ),

  DynamicFormField(
    id: 'sezioneVR',
    label: 'Controlli spaziali (VR)',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'padPosizione',
    label: 'Pad Posizione (X/Y)',
    type: FormFieldType.xyPad,
    value: const Offset(0.5, 0.5),
  ),
  DynamicFormField(
    id: 'pulsanteMomentaneoInput',
    label: 'Pulsante Momentaneo - Premuto true',
    type: FormFieldType.momentaryButton,
    value: false,
  ),
];

// ---- 7.2 Pagina Live ("Live Change") ---------------------------------------
// Questa è la lista che ELENCA i campi mostrati da LiveChangePage
// (lib/live_change_page.dart). Per aggiungere/rimuovere un campo di quella
// pagina, modifica QUESTA lista: LiveChangePage non va toccata.
//
// Qui sotto sono elencati TUTTI i tipi di campo disponibili (vedi enum
// FormFieldType, sezione 1), uno per uno, così questa pagina funziona anche
// da "catalogo dal vivo": puoi aprire l'app, andare su "Live Change" e
// provare ogni singolo controllo per vedere come si comporta e quando invia
// il dato via OSC (guarda il campo `trigger` di ciascuno).
//
// NB: gli id qui finiscono tutti con "Live" per non confondersi con quelli,
// diversi, usati in formPageSchema: ogni campo, in tutta l'app, deve avere
// un id UNICO perché è la chiave con cui viene salvato nel database.
final List<DynamicFormField> livePageSchema = [
  DynamicFormField(
    id: 'sezioneTestoLive',
    label: 'Campi di testo',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'textLive',
    label: 'Testo',
    type: FormFieldType.text,
    // onSubmit: invia quando l'utente preme "Invio"/"Fatto" sulla tastiera.
    trigger: FieldTrigger.onSubmit,
  ),
  DynamicFormField(
    id: 'multilineLive',
    label: 'Testo Multilinea',
    type: FormFieldType.multiline,
    // onFocusLost: invia anche quando l'utente clicca fuori dal campo, MA
    // aggiungiamo comunque il pulsante esplicito: il tasto Invio qui va a
    // capo e non basta da solo per confermare.
    trigger: FieldTrigger.onFocusLost,
    showSendButton: true,
  ),
  DynamicFormField(
    id: 'emailLive',
    label: 'Email',
    type: FormFieldType.email,
    trigger: FieldTrigger.onFocusLost,
  ),
  DynamicFormField(
    id: 'urlLive',
    label: 'URL',
    type: FormFieldType.url,
    // onButton: NON invia da solo, compare un'iconcina di invio da premere.
    trigger: FieldTrigger.onButton,
  ),
  DynamicFormField(
    id: 'phoneLive',
    label: 'Telefono',
    type: FormFieldType.phone,
    trigger: FieldTrigger.onFocusLost,
  ),
  DynamicFormField(
    id: 'passwordLive',
    label: 'Password',
    type: FormFieldType.password,
    trigger: FieldTrigger.onSubmit,
  ),
  DynamicFormField(
    id: 'numberLive',
    label: 'Numero',
    type: FormFieldType.number,
    trigger: FieldTrigger.onFocusLost,
  ),

  DynamicFormField(
    id: 'sezioneNumericheLive',
    label: 'Selezioni numeriche',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'sliderLive',
    label: 'Slider Live',
    type: FormFieldType.slider,
    value: 50.0,
    min: 0,
    max: 100,
    // onFocusLost: invia solo al rilascio dello slider, non ad ogni pixel.
    trigger: FieldTrigger.onFocusLost,
  ),
  DynamicFormField(
    id: 'numberSliderLive',
    label: 'Slider con Step',
    type: FormFieldType.numberSlider,
    value: 20.0,
    min: 0,
    max: 100,
    step: 5,
    // onChange: invia in tempo reale ad ogni scatto dello slider.
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'rangeLive',
    label: 'Intervallo',
    type: FormFieldType.range,
    value: const RangeValues(20.0, 80.0),
    min: 0,
    max: 100,
    trigger: FieldTrigger.onFocusLost,
  ),
  DynamicFormField(
    id: 'stepperLive',
    label: 'Stepper',
    type: FormFieldType.stepper,
    value: 10,
    step: 1,
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'ratingLive',
    label: 'Valutazione',
    type: FormFieldType.rating,
    value: 3,
    min: 0,
    max: 5,
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'counterLive',
    label: 'Contatore Live',
    type: FormFieldType.counter,
    value: 0,
    trigger: FieldTrigger.onChange,
  ),

  DynamicFormField(
    id: 'sezioneScelteLive',
    label: 'Scelte e opzioni',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'switchLive',
    label: 'Switch Live',
    type: FormFieldType.switchField,
    value: false,
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'checkboxLive',
    label: 'Checkbox',
    type: FormFieldType.checkbox,
    value: false,
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'radioLive',
    label: 'Radio',
    type: FormFieldType.radio,
    options: const ['Opzione A', 'Opzione B', 'Opzione C'],
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'toggleLive',
    label: 'Vista',
    type: FormFieldType.toggleButtons,
    options: const ['Mappa', '3D', 'Lista'],
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'dropdownLive',
    label: 'Dropdown',
    type: FormFieldType.dropdown,
    options: const ['Italia', 'Francia', 'Spagna'],
    selectionMode: SelectionMode.single,
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'dropdownMultipleLive',
    label: 'Dropdown multiplo',
    type: FormFieldType.dropdown,
    options: const ['Rosso', 'Verde', 'Giallo'],
    selectionMode: SelectionMode.multiple,
    value: <String>[],
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'colorLive',
    label: 'Colore',
    type: FormFieldType.colorPicker,
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'fileLive',
    label: 'Carica File',
    type: FormFieldType.filePicker,
    trigger: FieldTrigger.onChange,
  ),

  DynamicFormField(
    id: 'sezioneDataOraLive',
    label: 'Data e ora',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'dateLive',
    label: 'Data',
    type: FormFieldType.date,
    formatDatePattern: 'yyyy-MM-dd',
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'timeLive',
    label: 'Ora',
    type: FormFieldType.time,
    formatDatePattern: 'HH:mm',
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'timeRangeLive',
    label: 'Intervallo Ora',
    type: FormFieldType.timeRange,
    trigger: FieldTrigger.onChange,
  ),

  DynamicFormField(
    id: 'sezioneVRLive',
    label: 'Controlli spaziali (VR)',
    type: FormFieldType.label,
  ),
  DynamicFormField(
    id: 'padLive',
    label: 'Pad Posizione Live',
    type: FormFieldType.xyPad,
    value: const Offset(0.5, 0.5),
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'pulsanteMomentaneo',
    label: 'Tieni premuto per true',
    type: FormFieldType.momentaryButton,
    value: false,
    trigger: FieldTrigger.onChange,
  ),
];

// ---- 7.3 Pagina Listener (Ricezione) ---------------------------------------
// Stessa "classe mattoncino" (DynamicFormField) e stesso motore di
// disegno (buildDynamicField) usati per INVIARE dati via OSC, ma qui usati
// al contrario: la pagina Listener (lib/receiver_osc_page.dart) li mostra in
// modalità "sola lettura" (readOnly: true in buildDynamicField) e aggiorna
// `value` ogni volta che arriva un pacchetto OSC con lo stesso `id`.
// L'utente non può interagire con loro (né trascinare lo slider, né
// scrivere nell'area di testo): si aggiornano da soli quando arrivano dati.
//
// Per collegare un nuovo campo "ricevente": aggiungi qui una riga con lo
// stesso id che ti aspetti nel pacchetto OSC in arrivo (il primo argomento
// del messaggio, il "fieldId" — vedi osc_decoder.dart). Nessun'altra
// modifica necessaria: receiver_osc_page.dart itera su questa lista da sola.
//
// readOnly è supportato per i tipi: slider, numberSlider, multiline.
final List<DynamicFormField> receiverPageSchema = [
  DynamicFormField(
    id: 'sliderRx',
    label: 'Slider ricevuto',
    type: FormFieldType.slider,
    value: 0.0,
    min: 0,
    max: 100,
  ),
  DynamicFormField(
    id: 'textAreaRx',
    label: 'Testo ricevuto',
    type: FormFieldType.multiline,
    value: '',
  ),
];

// I grafici mostrati dalla stessa pagina Listener (lib/receiver_osc_page.dart),
// collegati per `id` ai campi di receiverPageSchema qui sopra: ogni volta
// che arriva un pacchetto OSC per un campo che ha anche un grafico con lo
// stesso id, il valore viene aggiunto alla serie storica del grafico oltre
// che allo slider "in sola lettura". Vedi la classe DynamicChartField e gli
// esempi in sezione 6, più sopra.
final List<DynamicChartField> receiverChartSchema = [
  DynamicChartField(
    id: 'sliderRx',
    label: 'Andamento nel tempo — Slider ricevuto',
    type: ChartType.line,
    color: AppColors.primary,
    min: 0,
    max: 100,
    maxPoints: 30,
  ),
  DynamicChartField(
    id: 'numberSliderRx',
    label: 'Andamento nel tempo — Slider con Step ricevuto',
    type: ChartType.bar,
    color: AppColors.success,
    min: 0,
    max: 100,
    maxPoints: 20,
  ),
];
