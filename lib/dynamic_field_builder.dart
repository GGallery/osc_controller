// dynamic_field_builder.dart
//
// Trasforma una singola `DynamicFormField` (vedi form_schema.dart) nel widget
// Flutter corrispondente. Le pagine (form_page.dart, live_change_page.dart)
// non devono sapere COME è fatto ogni campo: chiamano semplicemente
// `buildDynamicField(...)` per ogni campo dello schema.
//
// Due callback distinte vengono passate dal chiamante:
//  - onValueChanged: aggiorna lo stato locale/UI ad ogni variazione (serve
//    solo per far vedere il valore che cambia, es. mentre si trascina uno
//    slider). Non deve salvare né inviare nulla.
//  - onValueCommitted: viene chiamata quando il valore va effettivamente
//    salvato/inviato, nel momento indicato da `field.trigger`
//    (onChange / onSubmit / onFocusLost / onButton). Se non specificata,
//    equivale a onValueChanged (comportamento "invia sempre").

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'form_schema.dart';
import 'app_theme.dart';
import 'package:intl/intl.dart';

dynamic convertValueForType(FormFieldType type, dynamic rawValue) {
  switch (type) {
    case FormFieldType.number:
    case FormFieldType.counter:
    case FormFieldType.stepper:
    case FormFieldType.rating:
      return _toInt(rawValue);
    case FormFieldType.slider:
    case FormFieldType.numberSlider:
      return _toDouble(rawValue);
    case FormFieldType.range:
      if (rawValue is String && rawValue.contains('-')) {
        final parts = rawValue.split('-');
        final start = double.tryParse(parts[0]) ?? 0.0;
        final end = double.tryParse(parts[1]) ?? 0.0;
        return RangeValues(start, end);
      }
      return RangeValues(0.0, 0.0);
    case FormFieldType.switchField:
    case FormFieldType.checkbox:
    case FormFieldType.momentaryButton:
      return _toBool(rawValue);
    case FormFieldType.colorPicker:
      if (rawValue is String && rawValue.startsWith('#')) {
        final colorInt = int.tryParse(rawValue.substring(1), radix: 16) ?? 0;
        return Color(colorInt);
      }
      return rawValue;
    case FormFieldType.xyPad:
      if (rawValue is String && rawValue.contains(',')) {
        final parts = rawValue.split(',');
        final x = double.tryParse(parts[0]) ?? 0.5;
        final y = double.tryParse(parts.length > 1 ? parts[1] : '0.5') ?? 0.5;
        return Offset(x, y);
      }
      if (rawValue is Offset) return rawValue;
      return const Offset(0.5, 0.5);
    default:
      return rawValue;
  }
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _toDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return (v.toLowerCase() == 'true' || v == '1');
  return false;
}

Widget buildDynamicField(
  DynamicFormField field, {
  required BuildContext context,
  required Map<String, TextEditingController> textControllers,
  required ValueChanged<dynamic> onValueChanged,
  ValueChanged<dynamic>? onValueCommitted,
  bool isMobile = false,
  // Se true, il campo NON risponde più al tocco/trascinamento/digitazione
  // dell'utente: mostra solo il valore corrente (utile per "leggere" un dato
  // che arriva da fuori, es. via OSC, invece di inviarlo). Si applica a
  // slider, numberSlider e multiline (vedi receiver_osc_page.dart per un
  // esempio d'uso: uno slider e un'area di testo "in sola lettura" che si
  // aggiornano da soli quando arrivano i dati OSC).
  bool readOnly = false,
}) {
  // Valore "da salvare/inviare", secondo il trigger del campo.
  final commit = onValueCommitted ?? onValueChanged;

  // Avvolge un campo testuale/numerico in modo che rispetti field.trigger.
  Widget wrapTextLike({
    required TextEditingController controller,
    required Widget Function({
      required ValueChanged<String> onChanged,
      required ValueChanged<String> onSubmitted,
    })
    builder,
  }) {
    Widget child = builder(
      onChanged: (v) {
        onValueChanged(v);
        if (field.trigger == FieldTrigger.onChange) commit(v);
      },
      onSubmitted: (v) {
        if (field.trigger == FieldTrigger.onSubmit) commit(v);
      },
    );

    if (field.trigger == FieldTrigger.onFocusLost) {
      child = Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) commit(controller.text);
        },
        child: child,
      );
    }

    // Iconcina "Invia" manuale: sempre presente se il trigger è onButton,
    // oppure se il campo ha esplicitamente `showSendButton: true` (utile per
    // i campi multilinea, dove il tasto Invio va a capo e non può inviare).
    if (field.trigger == FieldTrigger.onButton || field.showSendButton) {
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: child),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: 'Invia',
            onPressed: () => commit(controller.text),
          ),
        ],
      );
    }

    return child;
  }

  switch (field.type) {
    // --- SEZIONE / TITOLO (non è un campo dati) ---
    case FormFieldType.label:
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
          ],
        ),
      );

    // --- TESTO ---
    case FormFieldType.text:
    case FormFieldType.email:
    case FormFieldType.url:
    case FormFieldType.phone:
      final controller = textControllers.putIfAbsent(
        field.id,
        () => TextEditingController(text: field.value?.toString() ?? ''),
      );
      return wrapTextLike(
        controller: controller,
        builder: ({required onChanged, required onSubmitted}) => TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: field.label),
          keyboardType: field.type == FormFieldType.phone
              ? TextInputType.phone
              : field.type == FormFieldType.email
              ? TextInputType.emailAddress
              : field.type == FormFieldType.url
              ? TextInputType.url
              : TextInputType.text,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
        ),
      );

    // TESTO MULTILINEA
    // Nota: in un campo multilinea il tasto Invio va semplicemente a capo,
    // non può anche confermare il valore. Se vuoi un modo per inviarlo,
    // ricorda di impostare `showSendButton: true` su questo campo nello
    // schema (vedi form_schema.dart) per mostrare un'iconcina "Invia".
    case FormFieldType.multiline:
      final controller = textControllers.putIfAbsent(
        field.id,
        () => TextEditingController(text: field.value?.toString() ?? ''),
      );

      if (readOnly) {
        // In sola lettura: il testo arriva da fuori (es. un messaggio OSC
        // ricevuto) e va risincronizzato nel controller ad ogni
        // ricostruzione. Questo va fatto SOLO qui: nel campo normale
        // (sotto) sovrascriverebbe quello che l'utente sta scrivendo.
        final incomingText = field.value?.toString() ?? '';
        if (controller.text != incomingText) {
          controller.text = incomingText;
        }
        return TextFormField(
          controller: controller,
          readOnly: true,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: field.label,
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        );
      }

      return wrapTextLike(
        controller: controller,
        builder: ({required onChanged, required onSubmitted}) => TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: field.label),
          maxLines: 4,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
        ),
      );

    // --- NUMERO ---
    case FormFieldType.number:
      final controller = textControllers.putIfAbsent(
        field.id,
        () => TextEditingController(text: field.value?.toString() ?? ''),
      );
      return wrapTextLike(
        controller: controller,
        builder: ({required onChanged, required onSubmitted}) => TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: field.label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          onChanged: (v) => onChanged(v),
          onFieldSubmitted: (v) => onSubmitted(v),
        ),
      );

    // --- BOOLEANI ---
    case FormFieldType.checkbox:
      return CheckboxListTile(
        title: Text(field.label),
        value: field.value as bool? ?? false,
        onChanged: (v) {
          onValueChanged(v);
          commit(v);
        },
      );

    case FormFieldType.switchField:
      return SwitchListTile(
        title: Text(field.label),
        value: field.value as bool? ?? false,
        onChanged: (v) {
          onValueChanged(v);
          commit(v);
        },
      );

    // --- SLIDER & RANGE ---
    case FormFieldType.slider:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${field.label}: ${_toDouble(field.value).toStringAsFixed(1)}'),
          Slider(
            value: _toDouble(field.value),
            min: field.min,
            max: field.max,
            // In sola lettura: onChanged null disabilita il trascinamento,
            // ma lo slider continua a mostrare graficamente field.value
            // (che qui viene aggiornato da fuori, es. da un messaggio OSC
            // ricevuto, non dal tocco dell'utente).
            onChanged: readOnly
                ? null
                : (v) {
                    onValueChanged(v);
                    if (field.trigger == FieldTrigger.onChange) commit(v);
                  },
            onChangeEnd: readOnly
                ? null
                : (v) {
                    if (field.trigger != FieldTrigger.onChange &&
                        field.trigger != FieldTrigger.onButton) {
                      commit(v);
                    }
                  },
          ),
          if (!readOnly &&
              (field.trigger == FieldTrigger.onButton || field.showSendButton))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Invia'),
                onPressed: () => commit(_toDouble(field.value)),
              ),
            ),
        ],
      );

    // SLIDER NUMERICO (con step -> divisioni)
    case FormFieldType.numberSlider:
      final rawDivisions = field.step > 0
          ? ((field.max - field.min) / field.step).round()
          : 0;
      final divisions = rawDivisions > 0 ? rawDivisions : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${field.label}: ${_toDouble(field.value).toStringAsFixed(1)}'),
          Slider(
            value: _toDouble(field.value),
            min: field.min,
            max: field.max,
            divisions: divisions,
            onChanged: readOnly
                ? null
                : (v) {
                    onValueChanged(v);
                    if (field.trigger == FieldTrigger.onChange) commit(v);
                  },
            onChangeEnd: readOnly
                ? null
                : (v) {
                    if (field.trigger != FieldTrigger.onChange &&
                        field.trigger != FieldTrigger.onButton) {
                      commit(v);
                    }
                  },
          ),
          if (!readOnly &&
              (field.trigger == FieldTrigger.onButton || field.showSendButton))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Invia'),
                onPressed: () => commit(_toDouble(field.value)),
              ),
            ),
        ],
      );

    // RANGE
    case FormFieldType.range:
      final currentRange = field.value is RangeValues
          ? field.value as RangeValues
          : RangeValues(field.min.toDouble(), field.max.toDouble());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${field.label}: ${currentRange.start.toStringAsFixed(1)} – ${currentRange.end.toStringAsFixed(1)}',
          ),
          RangeSlider(
            values: currentRange,
            min: field.min.toDouble(),
            max: field.max.toDouble(),
            divisions: (field.max - field.min) > 0
                ? (field.max - field.min).toInt()
                : null,
            labels: RangeLabels(
              currentRange.start.toStringAsFixed(1),
              currentRange.end.toStringAsFixed(1),
            ),
            onChanged: (values) {
              onValueChanged(values);
              if (field.trigger == FieldTrigger.onChange) commit(values);
            },
            onChangeEnd: (values) {
              if (field.trigger != FieldTrigger.onChange &&
                  field.trigger != FieldTrigger.onButton) {
                commit(values);
              }
            },
          ),
          if (field.trigger == FieldTrigger.onButton || field.showSendButton)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Invia'),
                onPressed: () => commit(currentRange),
              ),
            ),
        ],
      );

    // --- CONTATORI ---
    case FormFieldType.counter:
      final cur = _toInt(field.value);
      return Row(
        children: [
          Text(field.label),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              onValueChanged(cur - 1);
              commit(cur - 1);
            },
          ),
          Text('$cur'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              onValueChanged(cur + 1);
              commit(cur + 1);
            },
          ),
        ],
      );

    // STEPPER
    case FormFieldType.stepper:
      final cur = _toInt(field.value);
      return Row(
        children: [
          Text(field.label),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              final next = cur - field.step.toInt();
              onValueChanged(next);
              commit(next);
            },
          ),
          Text('$cur'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final next = cur + field.step.toInt();
              onValueChanged(next);
              commit(next);
            },
          ),
        ],
      );

    // --- RATING ---
    case FormFieldType.rating:
      final cur = _toInt(field.value);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label),
          // KeyedSubtree con il valore corrente: forza il ridisegno quando il
          // valore cambia da fuori (es. dopo il caricamento dal DB),
          // altrimenti RatingBar mostrerebbe sempre il rating iniziale.
          // (RatingBar.builder non espone un parametro `key` proprio, quindi
          // la key va messa sul widget che lo avvolge.)
          KeyedSubtree(
            key: ValueKey('${field.id}_$cur'),
            child: RatingBar.builder(
              initialRating: cur.toDouble(),
              minRating: field.min,
              maxRating: field.max,
              itemCount: field.max.toInt(),
              itemBuilder: (_, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                onValueChanged(rating.toInt());
                commit(rating.toInt());
              },
            ),
          ),
        ],
      );

    // --- COLOR PICKER ---
    case FormFieldType.colorPicker:
      Color currentColor = field.value is Color
          ? field.value as Color
          : Colors.transparent;

      return StatefulBuilder(
        builder: (context, setStateLocal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.label),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      Color picked = currentColor;
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Seleziona colore'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: picked,
                              onColorChanged: (col) {
                                picked = col;
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                setStateLocal(() {
                                  currentColor = picked;
                                });
                                onValueChanged(picked);
                                commit(picked);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: currentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '#${currentColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

    // --- FILE PICKER ---
    case FormFieldType.filePicker:
      return ElevatedButton(
        onPressed: () async {
          final result = await FilePicker.pickFiles();
          if (result != null) {
            onValueChanged(result.files.first.path);
            commit(result.files.first.path);
          }
        },
        child: Text(field.label),
      );

    // --- DATE & TIME ---
    case FormFieldType.date:
      final displayText = field.value != null
          ? (field.formatDatePattern != null
                ? DateFormat(field.formatDatePattern).format(field.value)
                : DateFormat.yMd().format(field.value))
          : 'Seleziona ${field.label}';

      return ElevatedButton(
        onPressed: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: field.value ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            builder: (ctx, child) {
              if (!isMobile) {
                final maxWidth = MediaQuery.of(ctx).size.width * 0.5;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child,
                  ),
                );
              }
              return child!;
            },
          );

          if (pickedDate != null) {
            onValueChanged(pickedDate);
            commit(pickedDate);
          }
        },
        child: Text(displayText),
      );

    case FormFieldType.time:
      final displayText = field.value != null
          ? (field.formatDatePattern != null
                ? DateFormat(field.formatDatePattern).format(
                    DateTime(
                      0,
                      1,
                      1,
                      (field.value as TimeOfDay).hour,
                      (field.value as TimeOfDay).minute,
                    ),
                  )
                : DateFormat('HH:mm').format(
                    DateTime(
                      0,
                      1,
                      1,
                      (field.value as TimeOfDay).hour,
                      (field.value as TimeOfDay).minute,
                    ),
                  ))
          : 'Seleziona ${field.label}';

      return ElevatedButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: field.value ?? TimeOfDay.now(),
            builder: (ctx, child) {
              if (!isMobile) {
                final maxWidth = MediaQuery.of(ctx).size.width * 0.5;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child!,
                  ),
                );
              }
              return child!;
            },
          );

          if (picked != null) {
            onValueChanged(picked);
            commit(picked);
          }
        },
        child: Text(displayText),
      );

    case FormFieldType.timeRange:
      final currentRange = field.value is Map ? field.value as Map : null;
      final displayText = currentRange == null
          ? 'Seleziona ${field.label}'
          : '${(currentRange['start'] as TimeOfDay).format(context)} - '
                '${(currentRange['end'] as TimeOfDay).format(context)}';

      return ElevatedButton(
        onPressed: () async {
          final start = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (start == null || !context.mounted) return;

          final end = await showTimePicker(context: context, initialTime: start);
          if (end != null) {
            final value = {'start': start, 'end': end};
            onValueChanged(value);
            commit(value);
          }
        },
        child: Text(displayText),
      );

    // --- SCELTA SINGOLA (RADIO) ---
    case FormFieldType.radio:
      final options = field.options ?? const [];
      return RadioGroup<String>(
        groupValue: field.value as String?,
        onChanged: (val) {
          if (val == null) return;
          onValueChanged(val);
          commit(val);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label),
            ...options.map(
              (opt) => RadioListTile<String>(title: Text(opt), value: opt),
            ),
          ],
        ),
      );

    // --- SCELTA SINGOLA (PULSANTI A GRUPPO) ---
    case FormFieldType.toggleButtons:
      final options = field.options ?? const [];
      final selected = field.value as String?;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ToggleButtons(
              isSelected: options.map((opt) => opt == selected).toList(),
              onPressed: (index) {
                final val = options[index];
                onValueChanged(val);
                commit(val);
              },
              children: options
                  .map((opt) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(opt),
                      ))
                  .toList(),
            ),
          ),
        ],
      );

    case FormFieldType.dropdown:
      if (field.selectionMode == SelectionMode.single) {
        return DropdownButtonFormField<String>(
          initialValue: field.value as String?,
          decoration: InputDecoration(labelText: field.label),
          items: field.options
              ?.map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              onValueChanged(val);
              commit(val);
            }
          },
        );
      } else {
        // Multi-select
        final selectedList = (field.value as List<String>? ?? <String>[]);
        return ListTile(
          title: Text(field.label),
          subtitle: Text(
            selectedList.isEmpty ? 'Seleziona' : selectedList.join(', '),
          ),
          onTap: () async {
            final List<String> tempSelected = [...selectedList];
            await showDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: Text('Seleziona ${field.label}'),
                  content: StatefulBuilder(
                    builder: (ctx2, setStateDialog) {
                      return SingleChildScrollView(
                        child: Column(
                          children: field.options!
                              .map(
                                (opt) => CheckboxListTile(
                                  value: tempSelected.contains(opt),
                                  title: Text(opt),
                                  onChanged: (bool? checked) {
                                    if (checked == true) {
                                      setStateDialog(() {
                                        tempSelected.add(opt);
                                      });
                                    } else {
                                      setStateDialog(() {
                                        tempSelected.remove(opt);
                                      });
                                    }
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('ANNULLA'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onValueChanged(tempSelected);
                        commit(tempSelected);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
        );
      }

    // --- PAD XY (controllo bidimensionale) ---
    case FormFieldType.xyPad:
      final current = field.value is Offset
          ? field.value as Offset
          : const Offset(0.5, 0.5);

      void handleDrag(Offset localPos, Size size) {
        final dx = (localPos.dx / size.width).clamp(0.0, 1.0);
        final dy = (localPos.dy / size.height).clamp(0.0, 1.0);
        final value = Offset(dx, dy);
        onValueChanged(value);
        if (field.trigger == FieldTrigger.onChange) commit(value);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${field.label}: (${current.dx.toStringAsFixed(2)}, ${current.dy.toStringAsFixed(2)})',
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                constraints.maxWidth * 0.6,
              );
              return GestureDetector(
                onPanUpdate: (details) => handleDrag(details.localPosition, size),
                onPanEnd: (_) {
                  if (field.trigger != FieldTrigger.onChange &&
                      field.trigger != FieldTrigger.onButton) {
                    commit(field.value);
                  }
                },
                onTapDown: (details) => handleDrag(details.localPosition, size),
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: current.dx * size.width - 10,
                        top: current.dy * size.height - 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (field.trigger == FieldTrigger.onButton || field.showSendButton)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Invia'),
                onPressed: () => commit(current),
              ),
            ),
        ],
      );

    // --- PULSANTE MOMENTANEO (invia 1 alla pressione, 0 al rilascio) ---
    case FormFieldType.momentaryButton:
      final pressed = field.value as bool? ?? false;
      return GestureDetector(
        onTapDown: (_) {
          onValueChanged(true);
          commit(true);
        },
        onTapUp: (_) {
          onValueChanged(false);
          commit(false);
        },
        onTapCancel: () {
          onValueChanged(false);
          commit(false);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? AppColors.primary : AppColors.primary.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            field.label,
            style: TextStyle(
              color: pressed ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

    case FormFieldType.password:
      final controller = textControllers.putIfAbsent(
        field.id,
        () => TextEditingController(text: field.value?.toString() ?? ''),
      );
      return wrapTextLike(
        controller: controller,
        builder: ({required onChanged, required onSubmitted}) => TextFormField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: field.label),
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
        ),
      );
  }
}
