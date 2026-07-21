// config_service.dart
//
// Punto unico per esportare/importare la configurazione completa
// dell'app (impostazioni dispositivo + dati dei form) come file JSON.
// Prima questa logica era duplicata/sparsa dentro settings_page.dart;
// ora vive tutta qui, così le pagine restano semplici "view".

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'db.dart';
import 'device_settings.dart';
import 'utils/string_utils.dart';

/// Cambia ogni volta che una configurazione viene importata da file: le
/// pagine che mostrano dati persistenti (FormPage, LiveChangePage,
/// SettingsPage) ci sono in ascolto e si ricaricano da sole, così non serve
/// più chiudere e riaprire l'app dopo un import.
final ValueNotifier<int> configRevision = ValueNotifier<int>(0);

class ConfigService {
  const ConfigService._();

  /// Esporta impostazioni dispositivo + dati dei form in un file JSON scelto
  /// dall'utente. Ritorna il percorso del file salvato, oppure null se
  /// l'utente ha annullato l'operazione.
  static Future<String?> exportToFile() async {
    final settings = await DeviceSettings().load();
    final formRows = await DbService.instance.loadForm();
    final formData = <String, dynamic>{
      for (final row in formRows) row.fieldId: row.value,
    };

    final exportJson = {'settings': settings, 'formData': formData};
    final jsonString = jsonEncode(exportJson);
    final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));

    return FilePicker.saveFile(
      dialogTitle: 'Scegli dove salvare il file JSON',
      fileName: 'config_export_${generateDynamicFileName()}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
  }

  /// Importa impostazioni dispositivo + dati dei form da un file JSON scelto
  /// dall'utente. Ritorna `true` se l'import è avvenuto, `false` se
  /// l'utente ha annullato la selezione del file.
  static Future<bool> importFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    final settingsData = data['settings'];
    if (settingsData is Map) {
      final s = Map<String, dynamic>.from(settingsData);
      await DeviceSettings().save(
        ip: s['ip']?.toString() ?? '',
        port: s['port'] is int
            ? s['port'] as int
            : int.tryParse(s['port']?.toString() ?? '') ?? 0,
        address: s['address']?.toString() ?? '',
      );
    }

    final formData = data['formData'];
    if (formData is Map) {
      final formMap = Map<String, dynamic>.from(formData);
      await DbService.instance.clearForm();
      for (final entry in formMap.entries) {
        await DbService.instance.saveValue(
          fieldId: entry.key,
          value: entry.value.toString(),
        );
      }
    }

    // Avvisa le pagine aperte: devono ricaricare i propri dati dal DB.
    configRevision.value++;
    return true;
  }
}
