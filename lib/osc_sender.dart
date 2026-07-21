// osc_sender.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'form_serializer.dart';

class OscSender {
  static Future<void> sendForm({
    required String baseAddress,
    required Map<String, dynamic> formValues,
    required String targetIp,
    required int targetPort,
    int retryCount = 3,
    Duration retryDelay = const Duration(milliseconds: 200),
    Duration bindTimeout = const Duration(seconds: 2),
  }) async {
    if (!baseAddress.startsWith('/')) {
      throw ArgumentError('OSC base address must start with "/"');
    }
    if (targetIp.isEmpty) {
      throw ArgumentError(
        'IP di destinazione non impostato: vai in "Impostazioni" e configuralo.',
      );
    }
    final ipAddr = InternetAddress(targetIp);

    // Rimuove un eventuale "/" finale per evitare indirizzi con "//" quando
    // viene concatenato il fieldId (es. baseAddress "/vr/" + "slider" -> "/vr//slider").
    final normalizedBase = baseAddress.endsWith('/')
        ? baseAddress.substring(0, baseAddress.length - 1)
        : baseAddress;

    print('📡 [OSC] Sending OSC messages to $targetIp:$targetPort');
    print('📡 [OSC] Base address: $normalizedBase');

    for (final entry in formValues.entries) {
      final fieldId = entry.key;
      final value = entry.value;

      final address = '$normalizedBase/$fieldId';
      final args = _buildArgs(fieldId, value);

      // Log leggibile prima dell’invio
      print('');
      print('➡️ [OSC] Preparing message');
      print('   • OSC Address: $address');
      print('   • fieldId     : $fieldId');
      print('   • value       : $value');
      print('   • serialized  : ${FormSerializer.serialize(value)}');
      print('   • typeTags    : ${_getTypeTags(args)}');

      final bytes = _buildOscMessageBytes(address, args);

      await _sendBytesWithRetry(
        bytes,
        ipAddr,
        targetPort,
        retryCount,
        retryDelay,
        bindTimeout,
      );
    }
  }

  static List<Object> _buildArgs(String id, dynamic val) {
    final args = <Object>[];
    args.add(id); // sempre il fieldId come primo argomento

    if (val is int) {
      args.add(val);
    } else if (val is double) {
      args.add(val);
    } else if (val is bool) {
      // bool come int (1/0)
      args.add(val ? 1 : 0);
    } else if (val is Offset) {
      // pad XY: due valori float separati, x e y
      args.add(val.dx);
      args.add(val.dy);
    } else {
      // tutti gli altri (stringhe, date/time, ecc.)
      final serialized = FormSerializer.serialize(val);
      args.add(serialized);
    }

    return args;
  }

  static String _getTypeTags(List<Object> args) {
    final sb = StringBuffer(',');
    for (var arg in args) {
      if (arg is int) {
        sb.write('i');
      } else if (arg is double) {
        sb.write('f');
      } else {
        sb.write('s');
      }
    }
    return sb.toString();
  }

  static Future<void> _sendBytesWithRetry(
    List<int> bytes,
    InternetAddress ipAddr,
    int port,
    int retryCount,
    Duration retryDelay,
    Duration bindTimeout,
  ) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      ).timeout(bindTimeout);

      print(
        '🔹 [OSC] UDP socket bound to ${socket.address.address}:${socket.port}',
      );
      print('🔹 [OSC] Byte length to send: ${bytes.length}');

      int attempts = 0;
      int sentBytes = 0;

      while (attempts < retryCount) {
        attempts++;
        try {
          sentBytes = socket.send(bytes, ipAddr, port);
          print('   Attempt #$attempts → sentBytes = $sentBytes');
        } catch (e) {
          sentBytes = 0;
          print('❗ [OSC] Attempt #$attempts error: $e');
        }

        if (sentBytes > 0) {
          print('✅ [OSC] Sent on attempt #$attempts');
          break;
        } else if (attempts < retryCount) {
          print('⏱ [OSC] Retry in ${retryDelay.inMilliseconds}ms...');
          await Future.delayed(retryDelay);
        }
      }

      if (sentBytes == 0) {
        print('❌ [OSC] Failed to send after $retryCount attempts.');
      }
    } catch (e) {
      print('❗ [OSC] Socket bind error: $e');
    } finally {
      socket?.close();
      print('🔹 [OSC] Socket closed\n');
    }
  }

  static List<int> _buildOscMessageBytes(String address, List<Object> args) {
    final builder = BytesBuilder();

    _writePaddedString(builder, address);

    final typeTags = _getTypeTags(args);
    _writePaddedString(builder, typeTags);

    for (final arg in args) {
      if (arg is int) {
        final data = ByteData(4)..setInt32(0, arg, Endian.big);
        builder.add(data.buffer.asUint8List());
      } else if (arg is double) {
        final data = ByteData(4)..setFloat32(0, arg, Endian.big);
        builder.add(data.buffer.asUint8List());
      } else if (arg is String) {
        _writePaddedString(builder, arg);
      }
    }

    return builder.toBytes();
  }

  static void _writePaddedString(BytesBuilder builder, String str) {
    final utf8Bytes = utf8.encode(str);
    builder.add(utf8Bytes);
    builder.addByte(0); // null terminator
    int pad = (4 - ((utf8Bytes.length + 1) % 4)) % 4;
    for (int i = 0; i < pad; i++) {
      builder.addByte(0);
    }
  }
}
