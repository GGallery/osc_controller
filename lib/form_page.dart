// ============================================================================
// form_page.dart — Pagina "Init Settings" (form STATICO)
//
// Questo file è pensato per essere COPIATO quando vuoi creare una nuova
// pagina statica (che si compila e si invia con un pulsante, senza invio
// automatico in tempo reale). Vedi il manuale, sezione 5, per la procedura
// passo-passo. Le parti da cambiare quando lo copi sono segnalate con
// "COPIA-INCOLLA: ..." nei commenti qui sotto.
// ============================================================================

// ---- 1. IMPORT: i pacchetti/file di cui questa pagina ha bisogno ----------
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // per firstWhereOrNull
import 'package:osc_controller/widgets/custom_app_bar.dart';

import 'db.dart'; // salvataggio/lettura dal database locale
import 'form_serializer.dart'; // conversione valori <-> testo
import 'form_schema.dart'; // qui vive la lista dei campi (formPageSchema)
import 'device_settings.dart'; // IP/porta/indirizzo OSC salvati dall'utente
import 'osc_sender.dart'; // invio dei messaggi OSC via UDP
import 'dynamic_field_builder.dart'; // trasforma un campo nel widget giusto
import 'config_service.dart'; // notifica quando una configurazione viene importata
import 'app_theme.dart'; // colori centralizzati dell'app

/// Pagina di impostazione iniziale: mostra tutti i campi di `formPageSchema`,
/// li salva nel database locale e/o li invia via OSC solo quando l'utente
/// preme uno dei due pulsanti in fondo (non c'è invio "in tempo reale" qui:
/// per quello vedi LiveChangePage).
class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  // ---- 2. STATO INTERNO DELLA PAGINA ---------------------------------------
  // Un "controller" per ogni campo di testo, necessario per poter leggere e
  // aggiornare quello che l'utente digita. Viene riempito automaticamente da
  // buildDynamicField: non serve toccarlo a mano.
  final Map<String, TextEditingController> _textControllers = {};

  // ---- 3. CICLO DI VITA: cosa succede all'apertura e alla chiusura --------
  @override
  void initState() {
    super.initState();
    _loadFromDb(); // appena la pagina si apre, ricarica gli ultimi valori salvati
    // Se i dati vengono sovrascritti da un import (in SettingsPage), ricarica.
    configRevision.addListener(_loadFromDb);
  }

  @override
  void dispose() {
    // Quando la pagina viene chiusa, "ripuliamo" per evitare fughe di memoria:
    // smettiamo di ascoltare gli import e liberiamo i controller di testo.
    configRevision.removeListener(_loadFromDb);
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- 4. CARICAMENTO DAL DATABASE -----------------------------------------
  // Legge dal database tutti i valori salvati in precedenza e li riassegna
  // ai campi dello schema (formPageSchema), così l'utente ritrova i dati
  // che aveva inserito l'ultima volta.
  Future<void> _loadFromDb() async {
    final rows = await DbService.instance.loadForm();

    for (final row in rows) {
      final field = formPageSchema.firstWhereOrNull((f) => f.id == row.fieldId);
      if (field == null) continue;

      final raw = FormSerializer.deserializeByType(
        field.type,
        row.value,
        selectionMode: field.selectionMode,
      );
      field.value = convertValueForType(field.type, raw);

      // Se esiste già un controller di testo per questo campo (es. dopo un
      // import mentre la pagina era aperta), aggiorna anche il suo testo:
      // altrimenti resterebbe visualizzato il vecchio valore.
      _textControllers[field.id]?.text = field.value?.toString() ?? '';
    }

    if (!mounted) return;
    setState(() {});
  }

  // ---- 5. PULSANTE "Salva nel DB" ------------------------------------------
  // Scrive nel database il valore attuale di ogni campo (tranne i campi
  // "sezione", che non contengono un dato). Non invia nulla via OSC.
  Future<void> _saveToDatabase() async {
    for (final f in formPageSchema) {
      if (!isDataField(f.type)) continue; // salta i campi "sezione"
      await DbService.instance.saveValue(
        fieldId: f.id,
        value: FormSerializer.serialize(f.value),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Valori salvati nel database'),
      ),
    );
  }

  // ---- 6. PULSANTE "Invia via OSC" ------------------------------------------
  // Legge IP/porta/indirizzo dalle Impostazioni e invia TUTTI i campi in un
  // colpo solo, via rete, al dispositivo/visore configurato.
  Future<void> _sendViaOsc() async {
    try {
      final settings = await DeviceSettings().load();
      final formValues = {
        for (final f in formPageSchema)
          if (isDataField(f.type)) f.id: f.value,
      };

      await OscSender.sendForm(
        baseAddress: settings['address'] as String,
        formValues: formValues,
        targetIp: settings['ip'] as String,
        targetPort: settings['port'] as int,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Dati inviati via OSC!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Errore invio OSC: $e'),
        ),
      );
    }
  }

  // ---- 7. COSTRUZIONE DI UN SINGOLO CAMPO -----------------------------------
  // Per ogni campo dello schema, chiede a dynamic_field_builder.dart di
  // disegnare il widget giusto (slider, switch, casella di testo, ecc.).
  // Qui non serve MAI aggiungere casi nuovi: quello si fa in
  // dynamic_field_builder.dart, non qui.
  Widget buildField(DynamicFormField field, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: buildDynamicField(
        field,
        context: context,
        textControllers: _textControllers,
        onValueChanged: (value) => setState(() {
          field.value = value; // aggiorna solo lo stato in memoria/UI
        }),
        isMobile: isMobile,
      ),
    );
  }

  // ---- 8. LAYOUT DELLA PAGINA ------------------------------------------------
  // Disegna la barra in alto, poi TUTTI i campi di formPageSchema uno sotto
  // l'altro (generati automaticamente dal punto 7), e infine i due pulsanti
  // "Salva nel DB" / "Invia via OSC".
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final buttonWidth = isMobile ? double.infinity : 200.0;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // COPIA-INCOLLA: se rinomini lo schema (es. audioPageSchema),
              // cambia anche qui il nome usato.
              ...formPageSchema.map((f) => buildField(f, isMobile)),

              const SizedBox(height: 32),

              // Riga con i due pulsanti principali della pagina.
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton(
                      onPressed: _saveToDatabase,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Salva nel DB'),
                    ),
                  ),
                  SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                  SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton(
                      onPressed: _sendViaOsc,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Invia via OSC'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
