// ============================================================================
// live_change_page.dart — Pagina "Live Change" (form IN TEMPO REALE)
//
// Questo file è pensato per essere COPIATO quando vuoi creare una nuova
// pagina "live" (dove ogni campo invia da solo via OSC, senza bisogno di un
// pulsante). Vedi il manuale, sezione 6, per la procedura passo-passo.
// ============================================================================

// ---- 1. IMPORT: i pacchetti/file di cui questa pagina ha bisogno ----------
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // per firstWhereOrNull
import 'package:osc_controller/widgets/custom_app_bar.dart';
import 'db.dart'; // salvataggio/lettura dal database locale
import 'form_serializer.dart'; // conversione valori <-> testo
import 'form_schema.dart'; // qui vive la lista dei campi (livePageSchema)
import 'device_settings.dart'; // IP/porta/indirizzo OSC salvati dall'utente
import 'osc_sender.dart'; // invio dei messaggi OSC via UDP
import 'dynamic_field_builder.dart'; // trasforma un campo nel widget giusto
import 'config_service.dart'; // notifica quando una configurazione viene importata
import 'app_theme.dart'; // colori centralizzati dell'app

/// Pagina "in tempo reale": ogni campo di `livePageSchema` invia il proprio
/// valore via OSC nel momento indicato dal suo `trigger` (vedi form_schema.dart
/// per il significato di onChange / onSubmit / onFocusLost / onButton).
class LiveChangePage extends StatefulWidget {
  const LiveChangePage({super.key});

  @override
  State<LiveChangePage> createState() => _LiveChangePageState();
}

class _LiveChangePageState extends State<LiveChangePage> {
  // ---- 2. STATO INTERNO DELLA PAGINA ---------------------------------------
  // Un "controller" per ogni campo di testo (riempito automaticamente da
  // buildDynamicField: non serve toccarlo a mano).
  final Map<String, TextEditingController> _textControllers = {};

  // ---- 3. CICLO DI VITA: cosa succede all'apertura e alla chiusura --------
  @override
  void initState() {
    super.initState();
    _loadFromDb(); // appena la pagina si apre, ricarica gli ultimi valori salvati
    configRevision.addListener(_loadFromDb); // ricarica se arriva un import
  }

  @override
  void dispose() {
    // "Pulizia" quando la pagina si chiude: evita fughe di memoria.
    configRevision.removeListener(_loadFromDb);
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- 4. CARICAMENTO DAL DATABASE -----------------------------------------
  // Legge dal database gli ultimi valori salvati e li riassegna ai campi
  // dello schema (livePageSchema).
  Future<void> _loadFromDb() async {
    final rows = await DbService.instance.loadForm();

    for (final row in rows) {
      final field = livePageSchema.firstWhereOrNull((f) => f.id == row.fieldId);
      if (field == null) continue;

      final raw = FormSerializer.deserializeByType(
        field.type,
        row.value,
        selectionMode: field.selectionMode,
      );
      field.value = convertValueForType(field.type, raw);
      _textControllers[field.id]?.text = field.value?.toString() ?? '';
    }

    if (!mounted) return;
    setState(() {});
  }

  // ---- 5. SALVA + INVIA UN SINGOLO CAMPO ------------------------------------
  // Questa è la funzione "chiave" della pagina live: scrive il valore nel
  // database E lo invia via OSC, nel momento deciso dal `trigger` del campo
  // (vedi il punto 7 qui sotto: onValueCommitted chiama proprio questa).
  Future<void> _saveAndSend(String fieldId, dynamic value) async {
    await DbService.instance.saveValue(
      fieldId: fieldId,
      value: FormSerializer.serialize(value),
    );

    try {
      final settings = await DeviceSettings().load();
      await OscSender.sendForm(
        baseAddress: settings['address'] as String,
        formValues: {fieldId: value},
        targetIp: settings['ip'] as String,
        targetPort: settings['port'] as int,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore OSC: $e')));
    }
  }

  // ---- 6. COSTRUZIONE DI UN SINGOLO CAMPO -----------------------------------
  // Per ogni campo dello schema, chiede a dynamic_field_builder.dart di
  // disegnare il widget giusto, passando DUE callback distinte:
  //  - onValueChanged: aggiorna solo la UI (nessun invio), es. mentre trascini
  //    uno slider vedi il numero cambiare ma non parte ancora nulla in rete;
  //  - onValueCommitted: salva nel DB e invia via OSC, chiamata nel momento
  //    esatto deciso dal `trigger` del campo (onChange/onSubmit/onFocusLost/
  //    onButton — vedi form_schema.dart).
  Widget buildField(DynamicFormField field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: buildDynamicField(
        field,
        context: context,
        textControllers: _textControllers,
        // Aggiornamento immediato solo a livello di interfaccia (nessun invio).
        onValueChanged: (value) => setState(() => field.value = value),
        // Salvataggio + invio OSC, secondo il trigger configurato sul campo.
        onValueCommitted: (value) => _saveAndSend(field.id, value),
      ),
    );
  }

  // ---- 7. LAYOUT DELLA PAGINA ------------------------------------------------
  // Disegna la barra in alto, poi TUTTI i campi di livePageSchema uno sotto
  // l'altro (punto 6), e infine il pulsante "Invia Tutti" (utile come rete di
  // sicurezza per rimandare manualmente ogni valore, es. dopo aver riconnesso
  // il visore).
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final buttonWidth = isMobile ? screenWidth * 0.5 : 80.0;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // COPIA-INCOLLA: se rinomini lo schema (es. audioLivePageSchema),
              // cambia anche qui il nome usato.
              ...livePageSchema.map((f) => buildField(f)),

              const SizedBox(height: 24),

              // Bottone "Invia Tutti" (solo immagine, responsivo): manda di
              // nuovo, uno per uno, tutti i valori correnti via OSC.
              Center(
                child: InkWell(
                  onTap: () async {
                    for (final f in livePageSchema) {
                      if (isDataField(f.type)) {
                        _saveAndSend(f.id, f.value);
                      }
                    }
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tutti i valori inviati!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: buttonWidth,
                    height: buttonWidth,
                    child: Image.asset(
                      'assets/images/invia_tutti_icona.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
