// app_theme.dart
//
// TUTTI i colori dell'app sono definiti QUI. Per cambiare l'aspetto
// dell'app (es. il colore della barra in alto, dei pulsanti, dei messaggi
// di conferma/errore) basta modificare i valori in questa classe: non serve
// cercare "Colors.blue" sparso nei vari file.
//
// Come cambiare un colore:
//   1. Apri questo file.
//   2. Sostituisci il valore, es. `static const Color primary = Colors.blue;`
//      con `static const Color primary = Color(0xFF1565C0);` (un blu più scuro)
//      oppure semplicemente `Colors.purple`, `Colors.teal`, ecc.
//   3. Salva e riavvia l'app (hot reload con il tasto "r" nel terminale, o
//      il pulsante di reload nel tuo editor, di solito bastano).
//
// Per usare un colore "personalizzato" che non è tra quelli con nome
// (Colors.blue, Colors.red, ecc.) puoi scrivere Color(0xFFRRGGBB), dove
// RRGGBB è il colore in esadecimale (lo stesso formato usato nei programmi
// di grafica, es. il "verde brillante" è 0xFF00FF66).

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Colore principale dell'app: barra in alto (AppBar) e pulsante "Fuoco"/
  /// pad quando premuto.
  static const Color primary = Colors.blue;

  /// Colore di sfondo della barra di navigazione in basso.
  static const Color navBarBackground = Colors.black;

  /// Colore dell'icona/etichetta selezionata nella barra di navigazione.
  static const Color navBarSelected = Colors.white;

  /// Colore delle icone/etichette NON selezionate nella barra di navigazione.
  static const Color navBarUnselected = Colors.white70;

  /// Colore di sfondo della splash screen iniziale (quella col solo logo).
  static const Color splashBackground = Colors.white;

  /// Colore dei messaggi (SnackBar) di conferma, es. "Dati inviati via OSC!".
  static const Color success = Colors.green;

  /// Colore dei messaggi (SnackBar) di errore.
  static const Color error = Colors.red;
}
