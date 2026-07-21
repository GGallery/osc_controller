// chart_schema.dart
//
// Stessa filosofia "mattoncino" di form_schema.dart, applicata ai grafici:
// una classe che descrive UN grafico (tipo, colore, quanti punti tenere in
// memoria) e delle liste che elencano i grafici di una pagina. Il disegno
// vero e proprio è delegato a chart_builder.dart (buildDynamicChart),
// esattamente come dynamic_field_builder.dart fa per i campi del form.
//
// Per aggiungere un nuovo grafico a una pagina:
//   1. Aggiungi una riga DynamicChartField a una lista qui sotto (o creane
//      una nuova, come receiverChartSchema).
//   2. Ogni volta che arriva un valore nuovo, chiama `campo.addValue(x)`
//      dentro un setState(() {...}): il grafico si ridisegna da solo.
// Nessuna modifica serve a chart_builder.dart, a meno di voler cambiare
// COME viene disegnato un tipo di grafico già esistente.

import 'package:flutter/material.dart';
import 'app_theme.dart';

// ---- 1. I TIPI DI GRAFICO DISPONIBILI --------------------------------------
enum ChartType { line, bar, pie }

// ---- 2. UNA "FETTA" DI GRAFICO A TORTA -------------------------------------
/// Usata solo dai grafici di tipo [ChartType.pie]: etichetta, valore e
/// colore di una singola fetta.
class ChartSlice {
  final String label;
  final double value;
  final Color color;
  ChartSlice({required this.label, required this.value, required this.color});
}

// ---- 3. LA CLASSE "MATTONCINO": un grafico ---------------------------------
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
// schema della pagina e personalizza id/label/colore.
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

// ---- 4. GRAFICI DELLA PAGINA LISTENER --------------------------------------
// Grafici mostrati da lib/receiver_osc_page.dart, collegati per `id` agli
// stessi campi di receiverPageSchema (in lib/form_schema.dart, sezione 7):
// ogni volta che arriva un pacchetto OSC per un campo che ha anche un
// grafico con lo stesso id, il valore viene aggiunto alla serie storica del
// grafico oltre che allo slider "in sola lettura".
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
