// osc_sender_test.dart
//
// Test automatici per OscSender (lib/osc_sender.dart), la parte che
// costruisce e invia i pacchetti OSC via UDP.
//
// Le funzioni che costruiscono i byte del pacchetto (_buildArgs,
// _buildOscMessageBytes, ecc.) sono "private" (iniziano con _): non sono
// richiamabili direttamente da qui. Per questo i test qui sotto lavorano
// come farebbe il visore VR: aprono un vero socket UDP in ascolto su
// 127.0.0.1 (il computer stesso), fanno inviare un messaggio a OscSender, e
// controllano i byte ricevuti — decodificandoli "a mano" secondo lo standard
// OSC, per verificare che il pacchetto sia fatto correttamente.
//
// Come si lanciano questi test:
//   flutter test test/osc_sender_test.dart
//
// Nota: servono permessi di rete locale (localhost); non serve internet né
// un visore vero collegato.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osc_controller/osc_sender.dart';

/// Un messaggio OSC decodificato, per poterlo controllare comodamente nei test.
class DecodedOscMessage {
  final String address;
  final String typeTags; // es. ",sif"
  final List<Object> args;
  DecodedOscMessage(this.address, this.typeTags, this.args);
}

/// Legge una stringa "padded" (terminata da almeno un byte 0x00, allineata a
/// multipli di 4 byte) a partire da [offset]. Ritorna la stringa e la
/// posizione da cui continuare a leggere.
(String, int) _readPaddedString(List<int> bytes, int offset) {
  final end = bytes.indexOf(0, offset);
  final str = utf8.decode(bytes.sublist(offset, end));
  final totalLen = end - offset + 1; // +1 per il terminatore
  final padded = ((totalLen + 3) ~/ 4) * 4;
  return (str, offset + padded);
}

/// Decodifica un pacchetto OSC grezzo (indirizzo + type-tags + argomenti),
/// esattamente come farebbe un visore/software OSC ricevente.
DecodedOscMessage decodeOscMessage(List<int> bytes) {
  var offset = 0;
  final String address;
  (address, offset) = _readPaddedString(bytes, offset);

  final String typeTags;
  (typeTags, offset) = _readPaddedString(bytes, offset);

  final args = <Object>[];
  // typeTags inizia sempre con ',': i tipi veri partono dal carattere 1.
  for (var i = 1; i < typeTags.length; i++) {
    switch (typeTags[i]) {
      case 'i':
        final data = ByteData.sublistView(Uint8List.fromList(bytes), offset, offset + 4);
        args.add(data.getInt32(0, Endian.big));
        offset += 4;
        break;
      case 'f':
        final data = ByteData.sublistView(Uint8List.fromList(bytes), offset, offset + 4);
        args.add(data.getFloat32(0, Endian.big));
        offset += 4;
        break;
      case 's':
        final String s;
        (s, offset) = _readPaddedString(bytes, offset);
        args.add(s);
        break;
    }
  }

  return DecodedOscMessage(address, typeTags, args);
}

void main() {
  group('OscSender.sendForm — validazioni prima dell\'invio', () {
    test('lancia un errore se baseAddress non inizia con "/"', () {
      expect(
        () => OscSender.sendForm(
          baseAddress: 'vr', // manca la barra iniziale
          formValues: const {'campo': 1},
          targetIp: '127.0.0.1',
          targetPort: 9000,
        ),
        throwsArgumentError,
      );
    });

    test('lancia un errore se l\'IP di destinazione è vuoto', () {
      expect(
        () => OscSender.sendForm(
          baseAddress: '/vr',
          formValues: const {'campo': 1},
          targetIp: '',
          targetPort: 9000,
        ),
        throwsArgumentError,
      );
    });
  });

  group('OscSender.sendForm — formato dei pacchetti OSC inviati', () {
    late RawDatagramSocket receiver;
    late StreamSubscription sub;
    late List<DecodedOscMessage> received;

    setUp(() async {
      // Apre un socket UDP "finto ricevitore" su una porta libera del
      // computer stesso (127.0.0.1), esattamente come farebbe un visore VR
      // in ascolto sulla propria rete.
      receiver = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      received = [];
      sub = receiver.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = receiver.receive();
          if (datagram != null) {
            received.add(decodeOscMessage(datagram.data));
          }
        }
      });
    });

    tearDown(() async {
      await sub.cancel();
      receiver.close();
    });

    test('un campo intero (switch/checkbox) -> indirizzo corretto + tipo "i"', () async {
      await OscSender.sendForm(
        baseAddress: '/vr',
        formValues: const {'switchLive': 1},
        targetIp: '127.0.0.1',
        targetPort: receiver.port,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      expect(received, hasLength(1));
      final msg = received.first;
      expect(msg.address, '/vr/switchLive');
      // Il primo argomento è SEMPRE il fieldId (stringa), poi il valore.
      expect(msg.args[0], 'switchLive');
      expect(msg.args[1], 1);
      expect(msg.typeTags, ',si');
    });

    test('un campo decimale (slider) -> tipo "f"', () async {
      await OscSender.sendForm(
        baseAddress: '/vr',
        formValues: const {'sliderLive': 42.5},
        targetIp: '127.0.0.1',
        targetPort: receiver.port,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      final msg = received.first;
      expect(msg.address, '/vr/sliderLive');
      expect(msg.typeTags, ',sf');
      expect((msg.args[1] as double), closeTo(42.5, 0.001));
    });

    test('un campo di testo -> tipo "s"', () async {
      await OscSender.sendForm(
        baseAddress: '/vr',
        formValues: const {'nomeUtente': 'Mario'},
        targetIp: '127.0.0.1',
        targetPort: receiver.port,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      final msg = received.first;
      expect(msg.typeTags, ',ss');
      expect(msg.args[1], 'Mario');
    });

    test('un campo xyPad (Offset) -> due argomenti float consecutivi', () async {
      await OscSender.sendForm(
        baseAddress: '/vr',
        formValues: const {'padLive': Offset(0.25, 0.75)},
        targetIp: '127.0.0.1',
        targetPort: receiver.port,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      final msg = received.first;
      expect(msg.typeTags, ',sff'); // fieldId + x + y
      expect((msg.args[1] as double), closeTo(0.25, 0.001));
      expect((msg.args[2] as double), closeTo(0.75, 0.001));
    });

    test('un booleano viene inviato come intero 0/1, non come testo', () async {
      await OscSender.sendForm(
        baseAddress: '/vr',
        formValues: const {'flag': true},
        targetIp: '127.0.0.1',
        targetPort: receiver.port,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      final msg = received.first;
      expect(msg.typeTags, ',si');
      expect(msg.args[1], 1);
    });

    test('un indirizzo base che finisce con "/" non produce doppie barre', () async {
      await OscSender.sendForm(
        baseAddress: '/vr/', // barra finale voluta, per testare la normalizzazione
        formValues: const {'test': 1},
        targetIp: '127.0.0.1',
        targetPort: receiver.port,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      expect(received.first.address, '/vr/test'); // non "/vr//test"
    });

    test('più campi -> più messaggi separati, uno per campo, in ordine', () async {
      await OscSender.sendForm(
        baseAddress: '/vr',
        formValues: const {'campoA': 1, 'campoB': 2, 'campoC': 3},
        targetIp: '127.0.0.1',
        targetPort: receiver.port,
      );
      await Future.delayed(const Duration(milliseconds: 300));

      expect(received, hasLength(3));
      expect(received.map((m) => m.address).toList(), [
        '/vr/campoA',
        '/vr/campoB',
        '/vr/campoC',
      ]);
    });
  });
}
