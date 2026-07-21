// Test "smoke" di base: verifica che l'app parta correttamente mostrando la
// splash screen, senza toccare database o plugin nativi (drift,
// shared_preferences, ecc. non sono disponibili nell'ambiente di test).
//
// NB: il vecchio test qui presente testava un contatore che non esiste in
// questa app (era il template di default di `flutter create`) e importava
// `App` da `main.dart`, dove quella classe non è mai stata definita: non
// avrebbe nemmeno compilato.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osc_controller/main.dart';
import 'package:osc_controller/widgets/splash_page.dart';

void main() {
  testWidgets('L\'app si avvia e mostra la splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyRoot());

    // Subito dopo l'avvio deve essere visibile la splash screen (prima che
    // scatti il timer di 2 secondi che porta alla navigazione principale).
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    // Rimuove l'albero dei widget prima della fine del test: questo forza
    // dispose() su SplashPage, che annulla il Timer da 2 secondi ancora in
    // attesa (altrimenti il test fallirebbe per "timer pendente").
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
