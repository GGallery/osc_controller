// form_serializer_test.dart
//
// Test automatici per FormSerializer (lib/form_serializer.dart), il
// "traduttore" che converte i valori dei campi in testo (per salvarli nel
// database / esportarli in JSON / inviarli via OSC) e viceversa.
//
// Come si lanciano questi test:
//   flutter test test/form_serializer_test.dart
// oppure, per lanciare TUTTI i test del progetto:
//   flutter test
//
// Non serve un dispositivo/emulatore collegato: sono test "puri" (nessuna
// UI, nessuna rete, nessun database vero), quindi girano in pochi secondi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osc_controller/form_schema.dart';
import 'package:osc_controller/form_serializer.dart';

void main() {
  group('FormSerializer.serialize — conversione valore -> testo', () {
    test('valori semplici', () {
      expect(FormSerializer.serialize(null), '');
      expect(FormSerializer.serialize('ciao'), 'ciao');
      expect(FormSerializer.serialize(42), '42');
      expect(FormSerializer.serialize(3.14), '3.14');
    });

    test('booleani', () {
      expect(FormSerializer.serialize(true), 'true');
      expect(FormSerializer.serialize(false), 'false');
    });

    test('RangeValues (campo "range")', () {
      expect(FormSerializer.serialize(const RangeValues(20.0, 80.0)), '20.0-80.0');
    });

    test('Offset (campo "xyPad")', () {
      expect(FormSerializer.serialize(const Offset(0.5, 0.75)), '0.5,0.75');
    });

    test('Color (campo "colorPicker") -> formato #AARRGGBB', () {
      // Colors.red pieno (alpha FF) = 0xFFFF0000
      expect(FormSerializer.serialize(const Color(0xFFFF0000)), '#FFFF0000');
    });

    test('lista di stringhe (dropdown multiplo) -> separate da "|"', () {
      expect(FormSerializer.serialize(<String>['Rosso', 'Verde']), 'Rosso|Verde');
      expect(FormSerializer.serialize(<String>[]), '');
    });

    test('DateTime -> ISO8601', () {
      final d = DateTime(2026, 7, 15);
      expect(FormSerializer.serialize(d), d.toIso8601String());
    });

    test('TimeOfDay -> HH:mm con zero iniziale', () {
      expect(FormSerializer.serialize(const TimeOfDay(hour: 9, minute: 5)), '09:05');
      expect(FormSerializer.serialize(const TimeOfDay(hour: 14, minute: 30)), '14:30');
    });

    test('intervallo orario (timeRange) -> HH:mm-HH:mm', () {
      final value = {
        'start': const TimeOfDay(hour: 14, minute: 30),
        'end': const TimeOfDay(hour: 15, minute: 45),
      };
      expect(FormSerializer.serialize(value), '14:30-15:45');
    });
  });

  group('FormSerializer.deserializeByType — conversione testo -> valore', () {
    test('stringa vuota -> null (tranne dropdown multiplo)', () {
      expect(FormSerializer.deserializeByType(FormFieldType.text, ''), null);
      expect(
        FormSerializer.deserializeByType(
          FormFieldType.dropdown,
          '',
          selectionMode: SelectionMode.multiple,
        ),
        <String>[],
      );
    });

    test('numeri', () {
      expect(FormSerializer.deserializeByType(FormFieldType.number, '3.5'), 3.5);
      expect(FormSerializer.deserializeByType(FormFieldType.counter, '7'), 7);
      // testo non numerico -> valore di default (0 / 0.0), non deve esplodere
      expect(FormSerializer.deserializeByType(FormFieldType.number, 'abc'), 0.0);
    });

    test('booleani (case-insensitive)', () {
      expect(FormSerializer.deserializeByType(FormFieldType.checkbox, 'true'), true);
      expect(FormSerializer.deserializeByType(FormFieldType.checkbox, 'TRUE'), true);
      expect(FormSerializer.deserializeByType(FormFieldType.checkbox, 'false'), false);
    });

    test('colore: round-trip serialize -> deserialize', () {
      const original = Color(0xFF1565C0);
      final asText = FormSerializer.serialize(original);
      final back = FormSerializer.deserializeByType(FormFieldType.colorPicker, asText);
      expect(back, isA<Color>());
      expect((back as Color).toARGB32(), original.toARGB32());
    });

    test('ora (time): round-trip', () {
      const original = TimeOfDay(hour: 8, minute: 45);
      final asText = FormSerializer.serialize(original);
      final back = FormSerializer.deserializeByType(FormFieldType.time, asText);
      expect(back, isA<TimeOfDay>());
      expect((back as TimeOfDay).hour, 8);
      expect(back.minute, 45);
    });

    test('intervallo orario (timeRange): round-trip', () {
      final original = {
        'start': const TimeOfDay(hour: 9, minute: 0),
        'end': const TimeOfDay(hour: 10, minute: 15),
      };
      final asText = FormSerializer.serialize(original);
      final back = FormSerializer.deserializeByType(FormFieldType.timeRange, asText);
      expect(back, isA<Map>());
      expect((back as Map)['start'], const TimeOfDay(hour: 9, minute: 0));
      expect(back['end'], const TimeOfDay(hour: 10, minute: 15));
    });

    test('dropdown a selezione multipla: round-trip lista', () {
      final original = <String>['Rosso', 'Verde', 'Giallo'];
      final asText = FormSerializer.serialize(original);
      final back = FormSerializer.deserializeByType(
        FormFieldType.dropdown,
        asText,
        selectionMode: SelectionMode.multiple,
      );
      expect(back, original);
    });

    test('campo "label" non ha mai un valore da ripristinare', () {
      expect(FormSerializer.deserializeByType(FormFieldType.label, 'qualsiasi cosa'), null);
    });
  });
}
