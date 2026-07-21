// chart_builder.dart
//
// Trasforma un DynamicChartField (vedi chart_schema.dart) nel widget
// grafico giusto, usando il pacchetto fl_chart. Stessa idea di
// dynamic_field_builder.dart per i campi del form: le pagine non devono
// sapere COME è fatto un grafico, chiamano semplicemente
// `buildDynamicChart(...)` per ogni grafico dello schema.
//
// Non serve modificare questo file per aggiungere un nuovo grafico a una
// pagina (vedi chart_schema.dart per quello): va toccato solo se serve un
// tipo di grafico NUOVO che non esiste già (es. scatter, radar — fl_chart li
// supporta entrambi, basta aggiungere un case allo switch qui sotto seguendo
// lo stesso schema dei tipi già presenti).

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'chart_schema.dart';

Widget buildDynamicChart(DynamicChartField field, {double height = 180}) {
  switch (field.type) {
    case ChartType.line:
      return _buildLineChart(field, height);
    case ChartType.bar:
      return _buildBarChart(field, height);
    case ChartType.pie:
      return _buildPieChart(field, height);
  }
}

// Involucro comune a tutti i grafici: etichetta sopra, grafico sotto con
// altezza fissa (i grafici di fl_chart hanno bisogno di un'altezza precisa,
// non si adattano da soli al contenuto).
Widget _wrapWithLabel(DynamicChartField field, double height, Widget chart) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(field.label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SizedBox(height: height, child: chart),
    ],
  );
}

// --- GRAFICO A LINEA (andamento nel tempo) ---
Widget _buildLineChart(DynamicChartField field, double height) {
  final spots = [
    for (var i = 0; i < field.values.length; i++)
      FlSpot(i.toDouble(), field.values[i]),
  ];

  return _wrapWithLabel(
    field,
    height,
    LineChart(
      LineChartData(
        minY: field.min,
        maxY: field.max,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            // Se non c'è ancora nessun dato, disegna un singolo punto a 0
            // invece di lasciare il grafico completamente vuoto/rotto.
            spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
            isCurved: true,
            color: field.color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: field.color.withAlpha(40),
            ),
          ),
        ],
      ),
    ),
  );
}

// --- GRAFICO A BARRE (stessa idea del grafico a linea, ma a barre) ---
Widget _buildBarChart(DynamicChartField field, double height) {
  final bars = [
    for (var i = 0; i < field.values.length; i++)
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: field.values[i], color: field.color, width: 6),
        ],
      ),
  ];

  return _wrapWithLabel(
    field,
    height,
    BarChart(
      BarChartData(
        minY: field.min,
        maxY: field.max,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barGroups: bars,
      ),
    ),
  );
}

// --- GRAFICO A TORTA (proporzioni tra categorie) ---
Widget _buildPieChart(DynamicChartField field, double height) {
  final slices = field.slices ?? const <ChartSlice>[];

  return _wrapWithLabel(
    field,
    height,
    PieChart(
      PieChartData(
        sections: slices.isEmpty
            // Nessun dato ancora: una "ciambella" grigia vuota invece di un
            // grafico rotto.
            ? [
                PieChartSectionData(
                  value: 1,
                  color: Colors.grey.shade300,
                  title: '',
                ),
              ]
            : [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.value,
                    color: s.color,
                    title: s.label,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    ),
  );
}
