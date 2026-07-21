#!/usr/bin/env python3
# test_osc_receiver.py
#
# Script di TEST manuale: fa l'OPPOSTO di test_osc_sender.py. Invece di
# mandare dati finti ALL'APP (per provare la pagina Listener), questo
# script si mette in ascolto e riceve i dati che l'APP INVIA verso l'esterno
# — cioe' simula il "visore VR" (o qualunque altro dispositivo/software OSC)
# che normalmente riceverebbe i pacchetti mandati dalla pagina "Init
# Settings" (pulsante "Invia via OSC") o dalla pagina "Live Change" (ogni
# campo, in automatico, secondo il suo trigger).
#
# Non richiede nulla di speciale: solo Python 3 (nessuna libreria esterna).
#
# COME USARLO
# -----------
# 1. In un terminale, lancia questo script PRIMA di inviare qualunque dato
#    dall'app:
#       python3 tools/test_osc_receiver.py
#    Per default resta in ascolto su 0.0.0.0:9002 (tutte le interfacce di
#    rete di questo computer, porta 9002 — diversa dalla 9000 usata dalla
#    pagina Listener dell'app stessa, cosi' i due non entrano in conflitto
#    se li fai girare insieme sullo stesso computer).
# 2. Avvia l'app osc_controller (es. "flutter run -d macos") e vai in
#    "Impostazioni": imposta come IP l'indirizzo di QUESTO computer (se lo
#    script gira sullo stesso computer dell'app, va bene "127.0.0.1") e come
#    Porta 9002 (o quella che hai scelto con --port). Salva.
# 3. Vai in "Init Settings", cambia qualche campo e premi "Invia via OSC"
#    (oppure vai in "Live Change" e muovi/tocca un campo): nel terminale
#    dello script vedrai comparire una riga per ogni messaggio ricevuto, con
#    indirizzo OSC, id del campo e valore decodificato.
# 4. Premi Ctrl+C nel terminale per fermare l'ascolto.
#
# OPZIONI (facoltative):
#   python3 tools/test_osc_receiver.py --port 9002 --raw
#
#   --ip    indirizzo su cui restare in ascolto (default: 0.0.0.0, cioe'
#           "tutte le interfacce di rete" - va bene quasi sempre, anche se
#           l'app gira su un altro dispositivo della stessa rete Wi-Fi)
#   --port  porta UDP su cui restare in ascolto (default: 9002; deve
#           combaciare con la Porta impostata in "Impostazioni" nell'app)
#   --raw   mostra anche i byte grezzi di ogni pacchetto ricevuto (utile
#           solo per debug avanzato del formato OSC)

import argparse
import socket
import struct
import sys
from datetime import datetime

# ---------------------------------------------------------------------------
# 1. DECODIFICA DEL PACCHETTO OSC (operazione inversa di test_osc_sender.py
#    e di lib/osc_sender.dart: qui leggiamo i byte invece di scriverli)
# ---------------------------------------------------------------------------
# Un messaggio OSC e' fatto cosi':
#   - l'indirizzo (es. "/vr/sliderLive"), come stringa terminata da almeno
#     un byte 0x00 e allineata a multipli di 4 byte
#   - i "type tags": una stringa che inizia con "," e ha una lettera per
#     ogni argomento che segue (i = intero, f = decimale, s = testo),
#     anch'essa allineata a multipli di 4 byte
#   - gli argomenti veri e propri, nell'ordine dichiarato dai type tags
#
# Nota: come fa anche l'app, il PRIMO argomento e' sempre il nome del campo
# (fieldId) come stringa, seguito dal valore vero e proprio (o due valori,
# per il pad XY). Questo permette di stampare "campo = valore" in modo
# leggibile anche se stiamo guardando solo l'indirizzo OSC dall'esterno.


class OscDecodeError(Exception):
    pass


def _read_padded_string(data: bytes, offset: int) -> tuple[str, int]:
    """Legge una stringa OSC (terminata da 0x00, allineata a 4 byte) a
    partire da `offset`. Ritorna (stringa, nuovo_offset)."""
    end = data.index(b"\x00", offset)
    s = data[offset:end].decode("utf-8", errors="replace")
    # Lo zero-terminatore + padding portano sempre a un multiplo di 4 byte
    # a partire da `offset`.
    total_len = end - offset + 1
    pad_len = (4 - (total_len % 4)) % 4
    new_offset = end + 1 + pad_len
    return s, new_offset


def decode_osc_message(data: bytes) -> dict:
    """Decodifica un pacchetto OSC grezzo in
    {"address": str, "args": [valori]}. Solleva OscDecodeError se i byte
    non sembrano un messaggio OSC valido (es. un pacchetto mandato da
    un'altra fonte, per errore, sulla stessa porta)."""
    offset = 0
    address, offset = _read_padded_string(data, offset)
    if not address.startswith("/"):
        raise OscDecodeError(f"indirizzo non valido: {address!r}")

    type_tags, offset = _read_padded_string(data, offset)
    if not type_tags.startswith(","):
        raise OscDecodeError(f"type tags non validi: {type_tags!r}")

    args = []
    for tag in type_tags[1:]:
        if tag == "i":
            (val,) = struct.unpack_from(">i", data, offset)
            args.append(val)
            offset += 4
        elif tag == "f":
            (val,) = struct.unpack_from(">f", data, offset)
            args.append(round(val, 4))
            offset += 4
        elif tag == "s":
            val, offset = _read_padded_string(data, offset)
            args.append(val)
        else:
            raise OscDecodeError(f"tipo di argomento non supportato: {tag!r}")

    return {"address": address, "args": args}


def format_decoded(decoded: dict) -> str:
    address = decoded["address"]
    args = decoded["args"]
    if not args:
        return f"{address} (nessun argomento)"

    field_id = args[0]
    values = args[1:]
    if len(values) == 1:
        valore = values[0]
    elif len(values) == 2:
        # Caso xyPad: due argomenti float consecutivi (x, y).
        valore = f"x={values[0]}, y={values[1]}"
    else:
        valore = ", ".join(str(v) for v in values)

    return f"{address} -> {field_id} = {valore}"


# ---------------------------------------------------------------------------
# 2. ASCOLTO VIA UDP
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Simula il dispositivo (es. visore VR) che riceve i dati OSC "
            "inviati da osc_controller. Fa l'opposto di test_osc_sender.py."
        )
    )
    parser.add_argument(
        "--ip",
        default="0.0.0.0",
        help="Indirizzo su cui restare in ascolto (default: 0.0.0.0, tutte le interfacce)",
    )
    parser.add_argument("--port", type=int, default=9002, help="Porta UDP di ascolto (default: 9002)")
    parser.add_argument(
        "--raw",
        action="store_true",
        help="Mostra anche i byte grezzi di ogni pacchetto ricevuto (debug avanzato)",
    )
    args = parser.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.bind((args.ip, args.port))
    except OSError as e:
        print(f"Errore: impossibile mettersi in ascolto su {args.ip}:{args.port} ({e})")
        print("La porta e' forse gia' occupata da un altro processo (es. l'app stessa, se")
        print("hai usato per sbaglio la stessa porta della pagina Listener)? Prova --port 9003.")
        sys.exit(1)

    print(f"In ascolto su {args.ip}:{args.port} — simula il dispositivo che riceve da osc_controller.")
    print("Configura IP/Porta corrispondenti nella pagina 'Impostazioni' dell'app, poi premi")
    print("'Invia via OSC' (Init Settings) o modifica un campo (Live Change).")
    print("Premi Ctrl+C per fermare.\n")

    contatore = 0
    try:
        while True:
            data, (src_ip, src_port) = sock.recvfrom(4096)
            timestamp = datetime.now().strftime("%H:%M:%S")
            contatore += 1
            try:
                decoded = decode_osc_message(data)
                print(f"[{timestamp}] #{contatore} da {src_ip}:{src_port} — {format_decoded(decoded)}")
            except OscDecodeError as e:
                print(f"[{timestamp}] #{contatore} da {src_ip}:{src_port} — pacchetto non OSC valido ({e})")
            if args.raw:
                print(f"           bytes ({len(data)}): {data!r}")
    except KeyboardInterrupt:
        print("\nInterrotto dall'utente. Chiusura.")
    finally:
        sock.close()


if __name__ == "__main__":
    main()
