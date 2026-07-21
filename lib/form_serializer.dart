// form_serializer.dart
//
// Converte i valori dei campi (double, bool, Color, Offset, ecc.) in stringhe
// da salvare nel database / nei file di export JSON, e viceversa. Tutta la
// logica di conversione vive QUI: le pagine non devono mai fare conversioni
// "a mano" per un tipo di campo specifico.

import 'package:flutter/material.dart';
import 'form_schema.dart';

/// Separatore usato per le liste di valori (es. dropdown a selezione multipla).
/// Si usa '|' invece di ',' perché alcune etichette/opzioni possono contenere
/// una virgola.
const String _listSeparator = '|';

class FormSerializer {
  static String serialize(dynamic value) {
    if (value == null) return '';

    if (value is RangeValues) {
      return '${value.start}-${value.end}';
    }

    if (value is Color) {
      return '#${value.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }

    if (value is Offset) {
      return '${value.dx},${value.dy}';
    }

    if (value is bool) return value ? 'true' : 'false';

    if (value is List<String>) {
      return value.join(_listSeparator);
    }
    if (value is List<bool>) {
      return value.map((b) => b ? 'true' : 'false').join(_listSeparator);
    }

    if (value is DateTime) return value.toIso8601String();

    if (value is TimeOfDay) {
      return _formatTimeOfDay(value);
    }

    if (value is Map && value.containsKey('start') && value.containsKey('end')) {
      final start = value['start'] as TimeOfDay;
      final end = value['end'] as TimeOfDay;
      return '${_formatTimeOfDay(start)}-${_formatTimeOfDay(end)}';
    }

    return value.toString();
  }

  static String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static TimeOfDay? _parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Ricostruisce il valore tipizzato a partire dalla stringa salvata.
  ///
  /// [selectionMode] è rilevante solo per i dropdown: se `multiple`, il
  /// risultato è una `List<String>` invece di una singola `String`.
  static dynamic deserializeByType(
    FormFieldType type,
    String value, {
    SelectionMode selectionMode = SelectionMode.single,
  }) {
    if (value.isEmpty) {
      // I dropdown a selezione multipla devono comunque restituire una lista
      // vuota (non null), altrimenti la UI non sa come renderizzarli.
      if (type == FormFieldType.dropdown && selectionMode == SelectionMode.multiple) {
        return <String>[];
      }
      return null;
    }

    switch (type) {
      case FormFieldType.text:
      case FormFieldType.email:
      case FormFieldType.url:
      case FormFieldType.phone:
      case FormFieldType.password:
      case FormFieldType.multiline:
        return value;

      case FormFieldType.range:
        return value; // convertito in RangeValues da convertValueForType

      case FormFieldType.number:
      case FormFieldType.numberSlider:
      case FormFieldType.slider:
        return double.tryParse(value) ?? 0.0;

      case FormFieldType.counter:
      case FormFieldType.stepper:
      case FormFieldType.rating:
        return int.tryParse(value) ?? 0;

      case FormFieldType.checkbox:
      case FormFieldType.switchField:
      case FormFieldType.momentaryButton:
        return value.toLowerCase() == 'true';

      case FormFieldType.colorPicker:
        if (value.startsWith('#')) {
          final hex = value.substring(1);
          final intColor = int.tryParse(hex, radix: 16) ?? 0;
          return Color(intColor);
        }
        return null;

      case FormFieldType.xyPad:
        return value; // convertito in Offset da convertValueForType

      case FormFieldType.date:
        return DateTime.tryParse(value);

      case FormFieldType.time:
        return _parseTimeOfDay(value);

      case FormFieldType.timeRange:
        final parts = value.split('-');
        if (parts.length == 2) {
          final start = _parseTimeOfDay(parts[0]);
          final end = _parseTimeOfDay(parts[1]);
          if (start != null && end != null) {
            return {'start': start, 'end': end};
          }
        }
        return null;

      case FormFieldType.dropdown:
        if (selectionMode == SelectionMode.multiple) {
          return value.split(_listSeparator).where((s) => s.isNotEmpty).toList();
        }
        return value;

      case FormFieldType.radio:
      case FormFieldType.toggleButtons:
      case FormFieldType.filePicker:
        return value;

      case FormFieldType.label:
        return null; // i campi "sezione" non hanno un valore da ripristinare
    }
  }
}
