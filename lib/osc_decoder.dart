// osc_decoder.dart
//
// Fa l'operazione INVERSA di osc_sender.dart: prende i byte grezzi di un
// pacchetto OSC arrivato via UDP e li trasforma in qualcosa di leggibile
// (indirizzo + valori), invece di mostrare a schermo i byte grezzi.
//
// Usato dalla pagina "Listener" (receiver_osc_page.dart) per mostrare in
// tempo reale, in modo comprensibile, i dati che arrivano da una sorgente
// OSC esterna (per esempio uno script di test, o un altro dispositivo).
//
// Non serve modificare questo file per usare l'app normalmente: è
// "infrastruttura". Se in futuro serve leggere anche altri tipi OSC oltre a
// intero/decimale/stringa, è qui che va aggiunto il nuovo case nello switch.

import 'dart:convert';
import 'dart:typed_data';

/// Un messaggio OSC già decodificato, pronto per essere mostrato in UI.
class OscDecodedMessage {
  final String address; // es. "/vr/sliderLive"
  final String typeTags; // es. ",sf"  (',' + un carattere per argomento)
  final List<Object> args; // valori nell'ordine in cui sono stati inviati

  OscDecodedMessage(this.address, this.typeTags, this.args);

  /// Rappresentazione leggibile per la pagina Listener, tipo:
  /// "/vr/sliderLive  →  sliderLive = 42.5"
  String toDisplayString() {
    if (args.isEmpty) return address;
    // Convenzione usata da OscSender: il primo argomento è sempre il
    // fieldId (nome del campo), gli argomenti successivi sono i valori.
    final fieldId = args.first;
    final values = args.skip(1).toList();
    final valuesText = values.isEmpty
        ? '(nessun valore)'
        : values.map((v) => v.toString()).join(', ');
    return '$address  →  $fieldId = $valuesText';
  }
}

/// Legge una stringa "padded" secondo lo standard OSC: terminata da almeno
/// un byte 0x00 e allineata a multipli di 4 byte.
///
/// Ritorna sia la stringa letta sia la posizione da cui continuare a
/// leggere (è un "record" di Dart 3: una coppia di valori senza bisogno di
/// creare una classe apposta).
(String, int) _readPaddedString(List<int> bytes, int offset) {
  final end = bytes.indexOf(0, offset);
  if (end == -1) {
    // Pacchetto malformato: niente terminatore trovato. Evita un crash e
    // ritorna quello che resta come stringa "grezza".
    return (utf8.decode(bytes.sublist(offset), allowMalformed: true), bytes.length);
  }
  final str = utf8.decode(bytes.sublist(offset, end), allowMalformed: true);
  final totalLen = end - offset + 1; // +1 per il terminatore
  final padded = ((totalLen + 3) ~/ 4) * 4;
  return (str, offset + padded);
}

/// Prova a decodificare [bytes] come un pacchetto OSC valido (lo stesso
/// formato prodotto da OscSender: indirizzo, type-tags, argomenti).
///
/// Ritorna `null` se i byte non sembrano un pacchetto OSC valido (per
/// esempio perché arrivano da un'altra sorgente): in quel caso la pagina
/// Listener può comunque mostrare il testo grezzo come fallback.
OscDecodedMessage? tryDecodeOscMessage(List<int> bytes) {
  try {
    if (bytes.isEmpty || bytes[0] != 0x2F /* '/' */) return null;

    var offset = 0;
    final String address;
    (address, offset) = _readPaddedString(bytes, offset);

    if (offset >= bytes.length || bytes[offset] != 0x2C /* ',' */) {
      return null; // niente type-tag string dove ce la aspettiamo
    }

    final String typeTags;
    (typeTags, offset) = _readPaddedString(bytes, offset);

    final args = <Object>[];
    // typeTags inizia sempre con ',': i tipi veri partono dal carattere 1.
    for (var i = 1; i < typeTags.length; i++) {
      if (offset > bytes.length) return null;
      switch (typeTags[i]) {
        case 'i':
          if (offset + 4 > bytes.length) return null;
          final data = ByteData.sublistView(
            Uint8List.fromList(bytes),
            offset,
            offset + 4,
          );
          args.add(data.getInt32(0, Endian.big));
          offset += 4;
          break;
        case 'f':
          if (offset + 4 > bytes.length) return null;
          final data = ByteData.sublistView(
            Uint8List.fromList(bytes),
            offset,
            offset + 4,
          );
          // Arrotondato per una lettura più pulita in UI (es. 42.5 invece
          // di 42.500001 per via della precisione a 32 bit).
          final f = data.getFloat32(0, Endian.big);
          args.add(double.parse(f.toStringAsFixed(4)));
          offset += 4;
          break;
        case 's':
          final String s;
          (s, offset) = _readPaddedString(bytes, offset);
          args.add(s);
          break;
        default:
          return null; // type-tag sconosciuto: non rischiamo di decodificare male
      }
    }

    return OscDecodedMessage(address, typeTags, args);
  } catch (_) {
    // Qualsiasi problema di parsing (indice fuori range, ecc.) -> niente
    // decodifica, mostreremo il fallback grezzo.
    return null;
  }
}
