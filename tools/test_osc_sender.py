#!/usr/bin/env python3
# test_osc_sender.py
#
# Script di TEST manuale: invia pacchetti OSC finti verso osc_controller,
# in continuazione, uno ogni pochi secondi, cosi puoi tenere aperta la
# pagina "Listener" dell'app e vedere i dati arrivare in tempo reale, senza
# dover usare davvero un visore VR o un'altra pagina del form.
#
# Non richiede nulla di speciale: solo Python 3 (nessuna libreria esterna).
#
# COME USARLO
# -----------
# 1. Avvia l'app osc_controller sul computer (es. "flutter run -d macos")
#    e apri la pagina "Listener": li vedrai il messaggio
#    "In ascolto sulla porta 9000 (UDP)".
# 2. In un terminale separato, lancia questo script:
#       python3 tools/test_osc_sender.py
# 3. Guarda la pagina Listener dell'app: ogni paio di secondi comparira'
#    una nuova riga con un campo finto e il suo valore.
# 4. Premi Ctrl+C nel terminale per fermare l'invio.
#
# OPZIONI (facoltative):
#   python3 tools/test_osc_sender.py --ip 127.0.0.1 --port 9000 --interval 2
#
#   --ip        indirizzo del computer che esegue l'app (default: 127.0.0.1,
#               cioe' "questo stesso computer" - va bene per i test locali)
#   --port      porta UDP su cui l'app e' in ascolto (default: 9000, deve
#               combaciare con quella mostrata nella pagina Listener)
#   --interval  secondi di pausa tra un invio e il successivo (default: 2)
#   --once      invia un solo giro di messaggi e poi esce, invece di
#               continuare all'infinito

import argparse
import random
import socket
import struct
import time

# ---------------------------------------------------------------------------
# 1. COSTRUZIONE DEL PACCHETTO OSC (stesso formato usato da lib/osc_sender.dart)
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
# (fieldId) come stringa, seguito dal valore vero e proprio. Questo permette
# alla pagina Listener di mostrare "campo = valore" in modo leggibile.


def _pad_string(s: str) -> bytes:
    """Codifica una stringa in byte OSC: UTF-8 + terminatore 0x00 + padding
    a multiplo di 4 byte."""
    data = s.encode("utf-8") + b"\x00"
    pad_len = (4 - (len(data) % 4)) % 4
    return data + (b"\x00" * pad_len)


def build_osc_message(address: str, field_id: str, *values) -> bytes:
    """Costruisce un pacchetto OSC completo: indirizzo + fieldId + valori.

    Ogni elemento di [values] deve essere un int, un float o una str.
    """
    args = [field_id, *values]

    type_tags = ","
    arg_bytes = b""
    for v in args:
        if isinstance(v, bool):
            # bool trattato come intero 0/1, esattamente come in Dart
            type_tags += "i"
            arg_bytes += struct.pack(">i", 1 if v else 0)
        elif isinstance(v, int):
            type_tags += "i"
            arg_bytes += struct.pack(">i", v)
        elif isinstance(v, float):
            type_tags += "f"
            arg_bytes += struct.pack(">f", v)
        else:
            type_tags += "s"
            arg_bytes += _pad_string(str(v))

    return _pad_string(address) + _pad_string(type_tags) + arg_bytes


# ---------------------------------------------------------------------------
# 2. CAMPI FINTI DI ESEMPIO
# ---------------------------------------------------------------------------
# Un piccolo set di campi rappresentativi dei tipi principali del form
# (numero decimale, intero/switch, testo, coppia di coordinate xyPad).
# Ogni volta che lo script gira, sceglie un valore leggermente diverso, cosi'
# si vede chiaramente che i dati cambiano "in tempo reale".


def make_messages(base_address: str):
    slider_val = round(random.uniform(0, 100), 1)
    # Slider "a step": arrotonda a multipli di 5, come fa il grafico a barre
    # numberSliderRx (step: 5) nella pagina Listener (receiverChartSchema).
    number_slider_val = float(random.choice(range(0, 101, 5)))
    switch_val = random.choice([0, 1])
    pad_x = round(random.uniform(0, 1), 2)
    pad_y = round(random.uniform(0, 1), 2)
    nome = random.choice(["Mario", "Luca", "Giulia", "Anna"])
    # Frase finta per l'area di testo "in sola lettura" (textAreaRx): cambia
    # ad ogni giro, cosi' si vede chiaramente che il testo si aggiorna da solo.
    frase = random.choice(
        [
            "Tutto ok, in ascolto...",
            "Livello batteria: 87%",
            "Connessione stabile",
            "Ultimo aggiornamento ricevuto correttamente",
            "In attesa di nuovi comandi",
        ]
    )

    return [
        # Questi due aggiornano dal vivo lo slider e l'area di testo "in sola
        # lettura" mostrati in cima alla pagina Listener (receiverPageSchema
        # in form_schema.dart).
        build_osc_message(f"{base_address}/sliderRx", "sliderRx", slider_val),
        build_osc_message(f"{base_address}/textAreaRx", "textAreaRx", frase),
        # Questo aggiorna dal vivo il grafico a barre nella pagina Listener
        # (receiverChartSchema in chart_schema.dart).
        build_osc_message(f"{base_address}/numberSliderRx", "numberSliderRx", number_slider_val),
        # Questi restano solo nel registro messaggi in fondo alla pagina
        # (non corrispondono a nessun campo/grafico, solo testo).
        build_osc_message(f"{base_address}/switchLive", "switchLive", switch_val),
        build_osc_message(f"{base_address}/padLive", "padLive", pad_x, pad_y),
        build_osc_message(f"{base_address}/nomeUtente", "nomeUtente", nome),
    ]


# ---------------------------------------------------------------------------
# 3. INVIO VIA UDP
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Invia pacchetti OSC di test verso osc_controller, in tempo reale."
    )
    parser.add_argument("--ip", default="127.0.0.1", help="IP del computer con l'app (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=9000, help="Porta UDP (default: 9000)")
    parser.add_argument("--interval", type=float, default=2.0, help="Secondi tra un invio e il successivo")
    parser.add_argument("--base-address", default="/vr", help="Prefisso indirizzo OSC (default: /vr)")
    parser.add_argument("--once", action="store_true", help="Invia un solo giro e poi esce")
    args = parser.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    print(f"Invio pacchetti OSC a {args.ip}:{args.port} (indirizzo base '{args.base_address}')")
    print("Tieni aperta la pagina 'Listener' dell'app per vedere i dati arrivare.")
    print("Premi Ctrl+C per fermare.\n")

    try:
        giro = 0
        while True:
            giro += 1
            msgs = make_messages(args.base_address)
            for msg in msgs:
                sock.sendto(msg, (args.ip, args.port))
            print(f"[giro {giro}] inviati {len(msgs)} messaggi di test")

            if args.once:
                break
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nInterrotto dall'utente. Chiusura.")
    finally:
        sock.close()


if __name__ == "__main__":
    main()
