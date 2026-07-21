// receiver_osc_page.dart
//
// Pagina "Listener": si mette in ascolto sulla porta UDP 9000 e mostra in
// tempo reale ogni pacchetto OSC che arriva (da OscSender di questa stessa
// app, o da qualunque altra sorgente esterna, come lo script di test in
// tools/test_osc_sender.py).
//
// Ogni pacchetto viene prima decodificato con osc_decoder.dart (per
// mostrare "indirizzo -> campo = valore" invece dei byte grezzi); se la
// decodifica fallisce (pacchetto non-OSC), viene mostrato comunque il
// contenuto grezzo come testo, così nulla va perso.
//
// In cima, la pagina mostra:
// - un paio di CAMPI in sola lettura (receiverPageSchema, in form_schema.dart
//   sezione 7.3: uno slider e un'area di testo) — stessa "classe mattoncino"
//   e stesso motore di disegno (DynamicFormField + buildDynamicField) usati
//   per INVIARE dati via OSC nelle pagine statica/live, ma qui usati con
//   readOnly: true, così mostrano solo l'ULTIMO valore ricevuto per il loro
//   id, senza poter essere toccati/modificati dall'utente;
// - un paio di GRAFICI (receiverChartSchema, anch'essa in form_schema.dart
//   sezione 7.3, subito sotto receiverPageSchema) collegati per `id` ai
//   dati in arrivo: stessa filosofia "mattoncino", ma con la classe
//   DynamicChartField (definita in sezione 6) + motore di disegno
//   buildDynamicChart (vedi chart_builder.dart), che mostrano lo storico
//   degli ultimi valori ricevuti, non solo l'ultimo.
//
// Campi e grafici sono entrambi DEFINITI in form_schema.dart (stesso file,
// sezione 7.3, uno di seguito all'altro) e vengono qui INTERPRETATI/disegnati
// insieme, con lo stesso meccanismo: una lista di "mattoncini" mappata sul
// motore di disegno giusto (buildDynamicField per i campi, buildDynamicChart
// per i grafici).
//
// NOTA SUL LAYOUT (vedi manuale, sezione "Errori di layout: RenderFlex
// overflow"): l'area dei campi/grafici e il registro messaggi sotto sono
// avvolti ciascuno in un proprio Expanded + area scorrevole
// (SingleChildScrollView / ListView). Questo è voluto: se si mettessero
// campi/grafici direttamente in una Column senza Expanded/scroll, appena il
// loro contenuto supera lo spazio disponibile su schermo Flutter genera un
// errore "BOTTOM OVERFLOWED BY N PIXELS" invece di adattarsi. Aggiungendo un
// campo o un grafico in più a receiverPageSchema/receiverChartSchema, questa
// struttura continua a reggere da sola.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:osc_controller/chart_builder.dart';
import 'package:osc_controller/dynamic_field_builder.dart';
import 'package:osc_controller/form_schema.dart';
import 'package:osc_controller/osc_decoder.dart';
import 'package:osc_controller/widgets/custom_app_bar.dart';

class ReceiverOscPage extends StatefulWidget {
  const ReceiverOscPage({super.key});

  @override
  State<ReceiverOscPage> createState() => _ReceiverOscPageState();
}

class _ReceiverOscPageState extends State<ReceiverOscPage> {
  final List<String> _messages = [];
  RawDatagramSocket? _socket;

  // Controller di testo per i campi in sola lettura di receiverPageSchema
  // (qui serve solo per il campo multiline "textAreaRx"): stessa mappa che
  // userebbe una pagina normale (form_page.dart/live_change_page.dart),
  // richiesta da buildDynamicField.
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _log('🔍 Initializing socket listener...');
    _startListening();
  }

  @override
  void dispose() {
    _log('🛑 Closing socket...');
    _socket?.close();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _startListening({int port = 9000}) async {
    try {
      _log('🎧 Binding UDP socket to port $port...');
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _log('✅ Socket bound to ${_socket!.address.address}:${_socket!.port}');
      _socket!.listen((RawSocketEvent event) {
        _log('📡 Socket event: $event');
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            final addr = datagram.address.address;
            final rport = datagram.port;
            final rawData = datagram.data;

            // Prova prima a leggerlo come un vero pacchetto OSC (indirizzo +
            // campo + valore/i): è il formato inviato da OscSender e dallo
            // script di test tools/test_osc_sender.py.
            final decoded = tryDecodeOscMessage(rawData);
            final String debugMsg;
            if (decoded != null) {
              debugMsg = 'From $addr:$rport -> ${decoded.toDisplayString()}';
              _updateLiveChart(decoded);
              _updateReceiverFields(decoded);
            } else {
              // Fallback: non era un pacchetto OSC valido, mostra il testo
              // grezzo così come arriva (nulla viene nascosto).
              final msg = String.fromCharCodes(rawData);
              debugMsg = 'From $addr:$rport -> $msg (bytes: ${rawData.length})';
            }
            _log('📥 Received datagram: $debugMsg');
            setState(() {
              _messages.insert(0, debugMsg);
            });
          }
        }
      });
    } catch (e) {
      _log('❗ Failed to bind socket or listen: $e');
      setState(() {
        _messages.insert(0, 'Error starting socket: $e');
      });
    }
  }

  // Se il messaggio OSC decodificato riguarda uno dei grafici di
  // receiverChartSchema (stesso id come primo argomento del messaggio),
  // aggiunge il valore alla sua serie storica: il grafico corrispondente si
  // aggiorna da solo, in tempo reale, nella build successiva.
  void _updateLiveChart(OscDecodedMessage decoded) {
    if (decoded.args.length < 2) return;
    final fieldId = decoded.args.first;
    final value = decoded.args[1];
    if (value is! num) return;

    for (final chart in receiverChartSchema) {
      if (chart.id == fieldId) {
        chart.addValue(value.toDouble());
        break;
      }
    }
  }

  // Se il messaggio OSC decodificato riguarda uno dei campi "in sola
  // lettura" di receiverPageSchema (stesso id come primo argomento del
  // messaggio), aggiorna il suo `value`: il campo corrispondente (slider o
  // area di testo) si aggiorna da solo, in tempo reale, nella build
  // successiva (stesso setState del registro messaggi, poco sotto).
  void _updateReceiverFields(OscDecodedMessage decoded) {
    if (decoded.args.length < 2) return;
    final fieldId = decoded.args.first;
    final value = decoded.args[1];

    for (final field in receiverPageSchema) {
      if (field.id == fieldId) {
        field.value = convertValueForType(field.type, value);
        break;
      }
    }
  }

  void _log(String text) {
    print('ReceiverOscPage: $text');
    setState(() {
      _messages.insert(0, text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('In ascolto sulla porta 9000 (UDP)'),
            const SizedBox(height: 12),

            // Campi "in sola lettura" + grafici collegati ai dati in arrivo
            // (vedi receiverPageSchema e receiverChartSchema, entrambe in
            // form_schema.dart, sezione 7.3). Per provarli:
            // lancia "python3 tools/test_osc_sender.py" mentre questa pagina
            // è aperta. Expanded + SingleChildScrollView: se in futuro si
            // aggiungono altri campi/grafici, quest'area scorre invece di
            // andare in overflow.
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...receiverPageSchema.map(
                      (field) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: buildDynamicField(
                          field,
                          context: context,
                          textControllers: _textControllers,
                          // Nessuna azione: i campi sono readOnly, il valore
                          // arriva solo da _updateReceiverFields (via OSC),
                          // mai dal tocco dell'utente.
                          onValueChanged: (_) {},
                          readOnly: true,
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    ...receiverChartSchema.map(
                      (chart) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: buildDynamicChart(chart),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            const Text(
              'Registro messaggi ricevuti',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Anche il registro ha il suo Expanded dedicato: cresce/si
            // restringe nello spazio rimasto, e scorre da solo con
            // ListView.builder se i messaggi sono tanti.
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(_messages[index]));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
