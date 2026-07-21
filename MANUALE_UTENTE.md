# Manuale utente — OSC Controller

Questo manuale è scritto per chi **non programma in Flutter**. Non serve capire il linguaggio Dart: basta seguire gli esempi "copia e incolla" indicati.

L'app serve a costruire pannelli di controllo (form) che inviano dati via **OSC** (un protocollo di rete usato per comunicare in tempo reale con un visore VR o altri dispositivi) tramite **UDP**.

L'app ha 4 schermate, accessibili dalla barra in basso:

1. **Init Settings** (pagina statica) — un form completo che si compila e poi si invia/salva con un pulsante.
2. **Live Change** (pagina "in tempo reale") — ogni controllo invia il proprio valore via OSC da solo, appena lo tocchi.
3. **Ricevi OSC** — mostra i messaggi OSC/UDP ricevuti sulla porta 9000, utile per verificare che il visore risponda.
4. **Impostazioni** — IP, porta e indirizzo OSC del dispositivo di destinazione, più i pulsanti per esportare/importare la configurazione.

---

## Indice

1. [Come compilare il progetto su ogni piattaforma](#1-come-compilare-il-progetto-su-ogni-piattaforma)
2. [Struttura del progetto: a cosa serve ogni file](#2-struttura-del-progetto-a-cosa-serve-ogni-file)
3. [Concetti base: come funziona un campo del form](#3-concetti-base-come-funziona-un-campo-del-form)
4. [Catalogo completo di tutti gli elementi disponibili](#4-catalogo-completo-di-tutti-gli-elementi-disponibili)
5. [Tutorial: creare una pagina statica da zero](#5-tutorial-creare-una-pagina-statica-da-zero)
6. [Tutorial: creare una pagina "live" da zero](#6-tutorial-creare-una-pagina-live-da-zero)
7. [Personalizzare il logo](#7-personalizzare-il-logo)
8. [Personalizzare i colori](#8-personalizzare-i-colori)
9. [Esportare e importare una configurazione](#9-esportare-e-importare-una-configurazione)
10. [Problemi comuni e soluzioni](#10-problemi-comuni-e-soluzioni)
11. [Approfondimento: come funziona l'invio dei dati via OSC](#11-approfondimento-come-funziona-linvio-dei-dati-via-osc)
12. [La pagina Listener attiva: ricevere dati in tempo reale](#12-la-pagina-listener-attiva-ricevere-dati-in-tempo-reale)
13. [I grafici: visualizzare i dati con fl_chart](#13-i-grafici-visualizzare-i-dati-con-fl_chart)
14. [Come eseguire i test](#14-come-eseguire-i-test)
15. [Piccolo glossario](#15-piccolo-glossario)

---

## 1. Come compilare il progetto su ogni piattaforma

### 1.0 Cosa serve prima di iniziare (una volta sola)

- **Flutter SDK**: scaricalo da flutter.dev oppure, su Mac, con `brew install --cask flutter`.
- Un editor: **Visual Studio Code** (gratuito, consigliato per chi non programma) con l'estensione "Flutter".
- Verifica che tutto sia a posto lanciando nel Terminale, dentro la cartella del progetto:
  ```bash
  flutter doctor
  ```
  Questo comando controlla cosa manca (Xcode, Android Studio, licenze, ecc.) e te lo segnala con una ❌. Vanno risolte una per una prima di continuare.

- La prima volta (e ogni volta che si aggiunge un nuovo "pacchetto" nel `pubspec.yaml`), dentro la cartella del progetto:
  ```bash
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  ```
  Il secondo comando rigenera il file `lib/db.g.dart` (il "motore" del database): va rilanciato ogni volta che si modifica `lib/db.dart`.

- **Rigenerare la cartella di una piattaforma, se manca o va rifatta:** ogni piattaforma (iOS, Android, macOS, Windows, Linux, web) ha una propria cartella nel progetto (`ios/`, `android/`, `macos/`, `windows/`, `linux/`, `web/`) generata da Flutter, con i file nativi necessari per compilare su quella piattaforma. In questo progetto sono già tutte presenti, ma se in futuro una dovesse mancare (es. su una copia del progetto scaricata senza quella cartella, o dopo averla cancellata per errore), si rigenera con `flutter create --platforms=<piattaforma> .` (il punto finale è importante: significa "genera solo i file mancanti in questa cartella", senza toccare il codice Dart già scritto):
  ```bash
  flutter create --platforms=ios .
  flutter create --platforms=android .
  flutter create --platforms=macos .
  flutter create --platforms=windows .
  flutter create --platforms=linux .
  flutter create --platforms=web .
  ```
  Si può anche rigenerare più piattaforme insieme in un solo comando, separandole con la virgola: `flutter create --platforms=ios,android .`.

### 1.1 Windows (PC Windows, app nativa)

Va eseguito **da un PC Windows** (non da Mac): Flutter compila le app desktop native per il sistema operativo su cui gira il comando, non esiste "cross-compilazione" da Mac/Linux a Windows.

**Cosa serve installato:**
1. **Flutter SDK per Windows** (istruzioni su flutter.dev, versione Windows).
2. **Visual Studio 2022** — attenzione: è **Visual Studio** (l'IDE completo Microsoft), non "Visual Studio Code". Durante l'installazione va selezionato il carico di lavoro **"Sviluppo di applicazioni desktop con C++"**: è richiesto da Flutter per compilare la parte nativa Windows dell'app. Verifica che tutto sia a posto con `flutter doctor`.

**Esempio — eseguire l'app in locale:**
```powershell
cd percorso\della\cartella\osc_controller
flutter pub get
flutter run -d windows
```
Output atteso quando l'app si avvia correttamente (i tempi variano, la prima compilazione è la più lenta):
```
Launching lib\main.dart on Windows in debug mode...
Building Windows application...
√ Built build\windows\x64\runner\Debug\osc_controller.exe
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
q Quit (terminate the application on the device).
```

**Esempio — generare l'eseguibile da distribuire:**
```powershell
flutter build windows
```
Il risultato si trova in `build\windows\x64\runner\Release\`: va copiata/distribuita **l'intera cartella**, non solo il file `.exe` (contiene anche le DLL necessarie a farlo funzionare su un altro PC).

**Cosa va configurato:** al primo avvio, **Windows Defender Firewall** mostrerà quasi certamente un popup per l'app (o per `dart.exe`/`flutter_tools` durante lo sviluppo), chiedendo di autorizzare l'accesso a reti private/pubbliche: va concesso, altrimenti l'invio/ricezione OSC via UDP non funziona. Se il popup non compare o è stato chiuso per errore, si può autorizzare manualmente da Pannello di controllo → Sistema e sicurezza → Windows Defender Firewall → "Consenti app tramite Windows Defender Firewall".

**Tips & tricks:**
- **`flutter` non riconosciuto in PowerShell/Prompt dei comandi** (`'flutter' non è riconosciuto come comando interno...`) → la cartella `flutter\bin` non è stata aggiunta alla variabile d'ambiente `PATH` di Windows, oppure il terminale è rimasto aperto da prima di averla aggiunta. Aggiungila da Pannello di controllo → Sistema → Impostazioni di sistema avanzate → Variabili d'ambiente, poi **chiudi e riapri** il terminale (o riavvia VS Code) perché la modifica abbia effetto.
- **La build fallisce con errori legati a MSVC/CMake/Ninja** → quasi sempre manca (o è incompleto) il carico di lavoro "Sviluppo di applicazioni desktop con C++" di Visual Studio: riapri "Visual Studio Installer" → "Modifica" → verifica che sia selezionato, poi rilancia `flutter doctor` per confermare che sia rilevato.
- **L'app parte ma non manda/riceve nulla via OSC, senza nessun errore visibile** → è quasi sempre il firewall (vedi sopra "Cosa va configurato"): apri Windows Defender Firewall → "Consenti un'app tramite Windows Defender Firewall" e controlla che l'app (o `flutter_tools.exe`/`dart.exe` durante lo sviluppo con `flutter run`) sia spuntata **sia per "Privata" sia per "Pubblica"** — molte reti Wi-Fi/hotspot vengono classificate come "Pubblica" ed è la casella che più spesso resta disabilitata per errore.
- **Hot reload per iterare velocemente**: con `flutter run -d windows` attivo, premi `r` nel terminale per applicare le modifiche al codice senza riavviare l'app (utile mentre personalizzi campi/colori, vedi sezioni 5–8); usa `R` maiuscola (hot **restart**) se il hot reload non basta, ad esempio dopo aver aggiunto/rimosso un campo da uno schema.
- **Attenzione ai percorsi**: su Windows i percorsi usano il backslash `\` (es. `build\windows\x64\runner\Release\`), mentre questo manuale per le altre piattaforme usa `/`: se copi un comando scritto per macOS/Linux, ricordati di adattare i separatori di percorso.
- **Antivirus di terze parti**: se oltre a Windows Defender è attivo un altro antivirus (es. Avast, Norton, McAfee), potrebbe bloccare il traffico UDP indipendentemente dalle regole di Windows Defender: va autorizzato anche lì, con lo stesso principio (consenti l'app sulle reti private).

### 1.2 Android (telefono/tablet Android)

**Cosa serve installato:**
- **Android Studio** (include l'SDK Android necessario). Al primo avvio, la procedura guidata scarica anche l'"Android SDK Platform-Tools" (contiene `adb`, usato per parlare con telefono/emulatore) e almeno una "System Image" per l'emulatore.
- Le **licenze SDK** accettate: se `flutter doctor` segnala licenze mancanti, lancia `flutter doctor --android-licenses` e accetta tutto (`y`).

**Cosa va configurato nel progetto:** i permessi di rete (necessari per l'OSC via UDP) sono dichiarati in `android/app/src/main/AndroidManifest.xml`. Verifica che siano presenti queste righe (sono già incluse in questo progetto):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>
```
A cosa serve ciascuna:
- `INTERNET` — il permesso base, indispensabile per aprire socket di rete (senza questo l'invio/ricezione OSC fallisce silenziosamente: nessun dato parte o arriva, senza un errore chiaro in schermo).
- `ACCESS_NETWORK_STATE` — permette all'app di controllare se il dispositivo è connesso a una rete (es. per capire se il Wi-Fi è disponibile prima di provare a inviare).
- `ACCESS_WIFI_STATE` — permette di leggere informazioni sulla connessione Wi-Fi attiva (es. l'indirizzo IP del dispositivo sulla rete locale).
- `CHANGE_WIFI_MULTICAST_STATE` — necessario per ricevere pacchetti UDP broadcast/multicast sulla rete locale in alcune condizioni (alcuni dispositivi Android, per risparmio energetico, filtrano il traffico multicast/broadcast in arrivo a meno che l'app non richieda esplicitamente questo permesso); rilevante per la pagina "Ricevi OSC".

**Su un telefono/tablet fisico** (metodo consigliato per i test reali con un visore VR: il telefono è già un dispositivo di rete "normale" sulla Wi-Fi, senza le particolarità di rete di un emulatore — vedi la nota su `10.0.2.2` più sotto):

1. **Attiva le Opzioni sviluppatore sul telefono** (va fatto una sola volta per telefono):
   - Apri Impostazioni → Info telefono (su alcuni modelli: "Informazioni sul telefono" o "Informazioni sul software").
   - Cerca la voce **"Numero build"**.
   - Toccala **7 volte di seguito**, rapidamente: dopo qualche tocco il telefono avvisa quanti tocchi mancano, poi conferma "Ora sei uno sviluppatore!" (può chiedere il PIN/la sequenza di sblocco).
   - Torna alla schermata principale di Impostazioni: è comparsa una nuova voce **"Opzioni sviluppatore"** (di solito sotto "Sistema", o in fondo alla lista).

2. **Attiva il debug USB:**
   - Apri Impostazioni → Opzioni sviluppatore.
   - Se presente, attiva l'interruttore in alto "Usa opzioni sviluppatore".
   - Scorri fino a **"Debug USB"** e attivalo.
   - Se disponibile, attiva anche "Installa tramite USB" (su alcuni produttori serve per poter installare app da computer).

3. **Collega il telefono al computer con un cavo USB dati** (non tutti i cavi "solo ricarica" trasmettono anche dati: se il telefono non viene rilevato al passo 4, prova un altro cavo/porta).
   - Sul telefono comparirà un popup **"Consenti debug USB su questo computer?"**, con l'impronta di sicurezza del computer: spunta "Consenti sempre da questo computer" (per non doverlo riconfermare ogni volta) e conferma. Se il popup non compare, scollega e ricollega il cavo, oppure controlla di aver davvero attivato il debug USB al passo 2.

4. **Verifica dal terminale che il telefono sia visto a livello di sistema:**
   ```bash
   adb devices
   ```
   Output atteso (il telefono compare con un id e lo stato `device`):
   ```
   List of devices attached
   R58N30ABCDE     device
   ```
   - Se lo stato è **`unauthorized`** invece di `device`: il popup di autorizzazione USB sul telefono non è stato ancora confermato — guarda lo schermo del telefono e conferma (potrebbe essere nascosto dietro la schermata di blocco: sblocca il telefono e riprova).
   - Se la lista è **vuota**: il telefono non è rilevato a livello di sistema operativo. Prova un altro cavo/porta USB; su **Windows** potrebbero servire i driver USB specifici del produttore del telefono (Samsung, Google, ecc. — cercali sul sito del produttore); su **macOS/Linux** di solito non serve installare nulla.

5. **Verifica che anche Flutter lo veda come dispositivo disponibile:**
   ```bash
   flutter devices
   ```
   Output atteso:
   ```
   1 connected device:

   Pixel 7 (mobile) • R58N30ABCDE • android-arm64 • Android 14 (API 34)
   ```

6. **Avvia l'app sul telefono:**
   ```bash
   flutter run -d <nome-dispositivo>
   ```
   dove `<nome-dispositivo>` è l'id mostrato da `flutter devices` (nell'esempio sopra: `R58N30ABCDE`); se è collegato un solo dispositivo, basta `flutter run` senza specificare nulla. La prima compilazione può richiedere un paio di minuti (installa anche l'app sul telefono); le volte successive, con hot reload (`r`) o hot restart (`R`), sono molto più veloci.

7. **Configura l'OSC per un dispositivo fisico:** a differenza dell'emulatore (vedi sotto), un telefono fisico è un dispositivo di rete "normale": in "Impostazioni" dell'app, l'IP da usare non è `127.0.0.1` né `10.0.2.2`, ma l'**indirizzo IP reale** del computer/visore sulla rete Wi-Fi locale (es. `192.168.1.23` — lo trovi in Impostazioni → Wi-Fi → dettagli della rete connessa, sia sul telefono sia sul computer/visore). **Telefono e destinazione devono essere sulla stessa rete Wi-Fi**: non funziona se il telefono usa la connessione dati mobile invece del Wi-Fi.

**Su un emulatore (AVD — Android Virtual Device), senza telefono fisico:**
1. In Android Studio: Device Manager → "Create Device" → scegli un modello di telefono → scegli una "System Image" (consigliata una versione recente con Play Store, se serve) → scarica e completa la creazione.
2. Requisito importante per le prestazioni: serve la **virtualizzazione hardware attiva** (su Mac con chip Apple Silicon è automatica; su Mac Intel serve "Hypervisor.Framework", incluso in macOS; su Windows/Linux serve "Intel HAXM" o virtualizzazione Hyper-V/KVM abilitata nel BIOS) — senza, l'emulatore parte ma è lentissimo o non parte affatto.
3. Comandi da terminale per avviarlo e usarlo:
   ```bash
   flutter emulators                  # elenca gli emulatori configurati in Android Studio
   flutter emulators --launch <id>    # avvia l'emulatore scelto (es. "Pixel_7_API_34")
   flutter devices                    # verifica che compaia come dispositivo disponibile
   flutter run                        # compila e avvia l'app (basta se c'è un solo dispositivo attivo)
   ```
   In alternativa all'ultimo passo, per scegliere esplicitamente l'emulatore quando ce n'è più di uno attivo: `flutter run -d emulator-5554` (l'id esatto lo mostra `flutter devices`).

   Esempio di output di `flutter emulators` (l'"id" nella prima colonna è quello da passare a `--launch`):
   ```
   2 available emulators:

   Pixel_7_API_34       • Pixel 7 API 34       • Google • android
   Pixel_Tablet_API_33  • Pixel Tablet API 33  • Google • android

   To run an emulator, run 'flutter emulators --launch <emulator id>'.
   ```
   Esempio di output di `flutter devices`, una volta che l'emulatore è avviato (l'id `emulator-5554` è quello da passare a `flutter run -d ...`):
   ```
   1 connected device:

   sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64 • Android 14 (API 34) (emulator)
   ```

⚠️ **Nota importante per l'OSC sull'emulatore Android**: a differenza del Simulatore iOS, l'emulatore Android **non condivide la rete del computer host**: gira in una rete virtuale isolata. Da dentro l'emulatore, `127.0.0.1`/`localhost` punta all'emulatore stesso, **non** al Mac/PC che lo ospita. Per raggiungere un servizio in esecuzione sul computer host (es. lo script di test `tools/test_osc_sender.py`, o un'altra istanza dell'app in ascolto sullo stesso computer), usa l'indirizzo speciale **`10.0.2.2`** al posto di `127.0.0.1` nel campo IP di "Impostazioni". Per raggiungere invece un visore VR vero sulla stessa rete Wi-Fi, usa il suo indirizzo IP reale (es. `192.168.1.50`), esattamente come per un dispositivo fisico.

**Debug:** con `flutter run` attivo, il terminale mostra in tempo reale tutti i `print()` dell'app (compresi i log `📡 [OSC] ...`); premi `r` per hot reload, `R` per hot restart. Se il terminale si è disconnesso ma l'app è ancora aperta, puoi ricollegarti ai log con:
```bash
flutter logs
```
Per un'ispezione più visuale (log, rete, memoria), Android Studio offre anche il pannello "Logcat" e, per le app Flutter, **Flutter DevTools** (si apre automaticamente all'avvio da `flutter run`, con un link cliccabile stampato in terminale).

Per generare un file `.apk` da installare manualmente su altri telefoni:
```bash
flutter build apk --release
```
Il file si trova in `build/app/outputs/flutter-apk/app-release.apk`.

### 1.3 macOS (Mac, app nativa)

```bash
cd percorso/della/cartella/osc_controller
flutter pub get
flutter run -d macos
```
Al primo avvio, macOS potrebbe chiedere di autorizzare l'app ad accedere alla rete (necessario per inviare/ricevere OSC via UDP): va sempre concesso.

**Cosa deve essere configurato:** macOS "sandboxa" le app per default, quindi l'accesso alla rete va dichiarato esplicitamente nei file `macos/Runner/*.entitlements` (`DebugProfile.entitlements` e `Release.entitlements`), con le due righe:
```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```
`network.client` serve per inviare dati (OscSender), `network.server` per ricevere (la pagina Listener, che apre un socket in ascolto). Il template generato da Flutter di solito include già `network.client`; se la pagina Listener non riceve nulla pur essendo tutto corretto lato codice, controlla che ci sia anche `network.server`.

Per creare un file `.app` da distribuire (senza dover restare aperti nel terminale):
```bash
flutter build macos
```
Il file risultante si trova in `build/macos/Build/Products/Release/`.

### 1.4 iOS (iPhone / iPad)

**Cosa serve installato sul Mac:**
- **Xcode** (da App Store) — non basta avere solo Xcode Command Line Tools.
- I **Command Line Tools** di Xcode selezionati: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`.
- **CocoaPods** (gestisce le dipendenze native iOS): `sudo gem install cocoapods` (o `brew install cocoapods`). Senza CocoaPods, `flutter run -d ios` si ferma con un errore su `pod install`.
- Il **runtime del Simulatore iOS**, se vuoi usare il simulatore invece di un dispositivo fisico: Xcode → Settings → Platforms → scarica "iOS" (può richiedere diversi GB e qualche minuto).

**Cosa va configurato nel progetto (una volta sola):**
1. Per un iPhone/iPad fisico serve un **Apple ID** registrato come sviluppatore in Xcode (Xcode → Settings → Accounts → aggiungi il tuo Apple ID). Per i test personali non serve un account a pagamento.
2. Apri il progetto in Xcode per impostare il "Team" di firma:
   ```bash
   open ios/Runner.xcworkspace
   ```
   Nel pannello a sinistra seleziona "Runner" → scheda "Signing & Capabilities" → scegli il tuo Team dal menu a tendina.
3. ⚠️ **Permesso di rete locale (essenziale per l'OSC)**: a partire da iOS 14, un'app che comunica sulla rete locale (esattamente il caso di questa app: invia/riceve OSC via UDP verso un visore sulla stessa Wi-Fi) deve dichiararlo esplicitamente in `ios/Runner/Info.plist`, altrimenti iOS blocca silenziosamente il traffico senza errori chiari. Aggiungi queste chiavi (con Xcode: apri `Info.plist` → tasto destro → "Add Row"; oppure modifica il file XML a mano):
   ```xml
   <key>NSLocalNetworkUsageDescription</key>
   <string>L'app invia e riceve dati OSC dal visore sulla stessa rete Wi-Fi.</string>
   <key>NSBonjourServices</key>
   <array>
     <string>_osc._udp</string>
   </array>
   ```
   Al primo avvio, iOS mostrerà un popup per autorizzare l'accesso alla rete locale: va sempre concesso, altrimenti l'invio/ricezione OSC non funziona pur senza errori visibili in app.

**Avviare sul Simulatore (non serve un iPhone fisico):**
```bash
open -a Simulator               # avvia l'app Simulatore (oppure aprilo da Xcode: Xcode → Open Developer Tool → Simulator)
flutter devices                 # verifica che il simulatore compaia come dispositivo disponibile
```
Dal comando `flutter devices` ottieni la lista dei device disponibili, con nome e identificativo (UDID). Esempio di riga restituita per un simulatore già avviato:
```
iPhone 17 (mobile) • 85383303-8E95-43BB-85A9-4EA7CC3D1E31 • ios • iOS 18.0 (simulator)
```
A quel punto avvia l'app passando **uno dei due** (nome tra virgolette, oppure l'UDID):
```bash
flutter run -d "iPhone 17"                                  # compila e avvia l'app sul simulatore, usando il nome
# oppure, equivalente:
flutter run -d 85383303-8E95-43BB-85A9-4EA7CC3D1E31          # compila e avvia l'app sul simulatore, usando l'UDID
```
Nota: il nome del simulatore va sempre tra virgolette se contiene spazi (es. `"iPhone 17"`), altrimenti `flutter run` lo interpreta come più argomenti separati e non trova il dispositivo. Se non è già stato avviato nessun simulatore, apri prima Simulator (o usa `flutter emulators --launch <id>`, con `<id>` preso da `flutter emulators`) e solo dopo lancia `flutter devices`/`flutter run -d ...`.

Nota comoda per l'OSC: sul **Simulatore** `127.0.0.1`/`localhost` punta al Mac stesso (non serve nessun indirizzo speciale), quindi puoi testare l'invio/ricezione OSC impostando in "Impostazioni" l'IP `127.0.0.1` esattamente come fai su macOS.

**Avviare su un iPhone/iPad fisico:**
```bash
flutter run -d ios
```
Sul primo avvio su un dispositivo fisico, sull'iPhone: Impostazioni → Generali → VPN e gestione dispositivi → autorizza il tuo Apple ID come sviluppatore fidato. In questo caso, per l'OSC, l'IP da inserire in "Impostazioni" non è `127.0.0.1` ma l'indirizzo IP reale del computer/visore sulla rete Wi-Fi locale (es. `192.168.1.23`), perché il telefono è un dispositivo di rete separato.

**Debug:** con l'app in esecuzione da `flutter run`, il terminale resta collegato e mostra in tempo reale tutti i `print()` (compresi i log `📡 [OSC] ...` di `osc_sender.dart`); premi `r` per hot reload, `R` per hot restart, `q` per uscire (vedi anche sezione 10). In alternativa, con Xcode aperto su `ios/Runner.xcworkspace`, la finestra "Console" in basso mostra lo stesso output.

Per generare un file da distribuire (richiede un account Apple Developer a pagamento se lo si vuole installare su altri dispositivi senza passare da Xcode):
```bash
flutter build ipa
```

---

## 2. Struttura del progetto: a cosa serve ogni file

Tutti i file "operativi" (quelli che contengono davvero la logica dell'app) sono dentro `lib/`. Ecco a cosa serve ciascuno:

| File | A cosa serve |
|---|---|
| `lib/main.dart` | Punto di partenza dell'app: avvia la Splash screen. **Di solito non va mai toccato.** |
| `lib/app_main.dart` | Definisce la barra di navigazione in basso e le 4 pagine (`HomeNavigation`). Qui si aggiunge una pagina nuova alla barra in basso. |
| `lib/app_theme.dart` | **Tutti i colori dell'app in un unico posto.** Vedi [sezione 8](#8-personalizzare-i-colori). |
| `lib/form_schema.dart` | **Il file più importante per chi non programma.** In cima contiene l'elenco di tutti i tipi di campo disponibili (`FormFieldType`) e la classe `DynamicChartField` per i grafici; in fondo al file (sezione 7, suddivisa in 7.1/7.2/7.3, una sottosezione per pagina) ci sono le liste vere e proprie: `formPageSchema` (statica), `livePageSchema` (live, invia) e `receiverPageSchema`/`receiverChartSchema` (Listener, riceve campi e grafici insieme — vedi [sezione 12](#12-la-pagina-listener-attiva-ricevere-dati-in-tempo-reale)). Qui si aggiungono/tolgono/modificano i campi e i grafici dei form, copiando gli esempi. |
| `lib/audio_page.dart.example`, `lib/audio_live_page.dart.example`, `lib/sensor_receiver_page.dart.example` | Pagine di esempio già pronte, usate nei tutorial delle sezioni [5](#5-tutorial-creare-una-pagina-statica-da-zero), [6](#6-tutorial-creare-una-pagina-live-da-zero) e [12.6](#126-esempio-creare-una-seconda-pagina-di-ricezione-dedicata). L'estensione `.dart.example` (invece di `.dart`) fa sì che Flutter le ignori completamente finché restano così: basta rinominarle togliendo `.example` per attivarle davvero. |
| `lib/dynamic_field_builder.dart` | Il "motore grafico": trasforma ogni campo dello schema nel widget giusto (slider, switch, ecc.). Va toccato solo se si vuole creare un tipo di campo **nuovo** che non esiste già. |
| `lib/form_page.dart` | La pagina "Init Settings" (statica): mostra `formPageSchema` e i due pulsanti "Salva nel DB" / "Invia via OSC". |
| `lib/live_change_page.dart` | La pagina "Live Change": mostra `livePageSchema`, invia via OSC automaticamente secondo il `trigger` di ogni campo. |
| `lib/settings_page.dart` | La pagina "Impostazioni": IP/porta/indirizzo OSC del dispositivo, ed export/import della configurazione. |
| `lib/receiver_osc_page.dart` | La pagina "Ricevi OSC" (Listener): ascolta la porta UDP 9000, mostra in cima i campi "in sola lettura" di `receiverPageSchema` (uno slider, un'area di testo) e i grafici di `receiverChartSchema`, tutti collegati per id ai dati in arrivo, e sotto il registro di tutti i messaggi ricevuti (utile per il debug). |
| `lib/osc_decoder.dart` | Fa l'operazione inversa di `osc_sender.dart`: decodifica i byte grezzi di un pacchetto OSC in arrivo (indirizzo + valori), usato dalla pagina Listener. |
| `lib/chart_builder.dart` | Il "motore grafico" dei grafici: trasforma un `DynamicChartField` nel widget `fl_chart` giusto (linea, barre, torta). Va toccato solo per aggiungere un tipo di grafico nuovo. |
| `lib/form_serializer.dart` | Converte i valori dei campi (numeri, colori, date, ecc.) in testo da salvare nel database/JSON, e viceversa. Non richiede modifiche a meno di aggiungere un tipo di campo nuovo. |
| `lib/osc_sender.dart` | Costruisce e invia i pacchetti OSC via UDP. Non richiede modifiche in condizioni normali. |
| `lib/db.dart` / `lib/db.g.dart` | Il database locale (SQLite, tramite il pacchetto `drift`) dove vengono salvati i valori dei campi. `db.g.dart` è **generato automaticamente**: non va mai modificato a mano (si rigenera con `dart run build_runner build`). |
| `lib/device_settings.dart` | Legge/scrive IP, porta e indirizzo OSC (salvati nelle preferenze del dispositivo). |
| `lib/config_service.dart` | Esporta/importa l'intera configurazione (impostazioni + dati dei form) come file `.json`. |
| `lib/utils/string_utils.dart` | Piccola funzione di supporto per generare nomi di file univoci per l'export. |
| `lib/widgets/custom_app_bar.dart` | La barra in alto (logo + colore), usata da tutte le pagine. |
| `lib/widgets/splash_page.dart` | La schermata iniziale con il logo, mostrata per 2 secondi all'avvio. |

Altri file e cartelle importanti (fuori da `lib/`):

| Percorso | A cosa serve |
|---|---|
| `pubspec.yaml` | "Carta d'identità" del progetto: nome, versione, elenco dei pacchetti esterni usati, ed elenco degli **assets** (immagini incluse nell'app, es. il logo). |
| `assets/images/` | Le immagini usate dall'app (logo, icona del pulsante "Invia Tutti"). |
| `android/`, `ios/`, `macos/`, `windows/`, `web/`, `linux/` | Progetti nativi generati automaticamente da Flutter per ciascuna piattaforma. Normalmente non vanno toccati a mano. |
| `test/widget_test.dart` | Un test automatico di base che verifica che l'app si avvii correttamente. |
| `test/form_serializer_test.dart` | Test automatici della conversione valore ↔ testo. Vedi [sezione 14](#14-come-eseguire-i-test). |
| `test/osc_sender_test.dart` | Test automatici del formato dei pacchetti OSC inviati. Vedi [sezione 14](#14-come-eseguire-i-test). |
| `tools/test_osc_sender.py` | Script Python di test **manuale**: invia dati OSC finti in continuazione, utile per vedere la pagina Listener "in azione" senza un visore vero. Vedi [sezione 14](#14-come-eseguire-i-test). |

---

## 3. Concetti base: come funziona un campo del form

Ogni campo del form (una casella di testo, uno slider, un interruttore...) è descritto da un oggetto `DynamicFormField` dentro `lib/form_schema.dart`. Esempio:

```dart
DynamicFormField(
  id: 'volumeMusica',       // nome univoco del campo (usato per salvarlo e per l'indirizzo OSC)
  label: 'Volume Musica',   // testo mostrato all'utente
  type: FormFieldType.slider, // che TIPO di controllo mostrare
  value: 50.0,               // valore iniziale
  min: 0,
  max: 100,
),
```

Le proprietà principali:

- **`id`** — deve essere **unico in tutta l'app** (sia nella pagina statica sia in quella live): è la chiave con cui il valore viene salvato nel database e con cui viene costruito l'indirizzo OSC (es. `/vr/volumeMusica`).
- **`label`** — il testo mostrato accanto al controllo.
- **`type`** — uno dei 26 tipi disponibili, vedi il [catalogo completo](#4-catalogo-completo-di-tutti-gli-elementi-disponibili).
- **`value`** — il valore di partenza (facoltativo per molti tipi).
- **`min` / `max` / `step`** — usati solo dai controlli numerici (slider, stepper, rating...).
- **`options`** — l'elenco delle scelte, usato da radio / toggle a gruppo / dropdown.
- **`trigger`** — **solo per la pagina Live**, decide QUANDO il valore viene inviato via OSC (vedi sotto).

### Il `trigger`: quando viene inviato il valore (solo pagina Live)

Nella pagina statica ("Init Settings") l'invio avviene solo premendo il pulsante "Invia via OSC": il `trigger` non ha effetto pratico lì.

Nella pagina "Live Change", invece, ogni campo invia il proprio valore automaticamente, e il `trigger` decide **il momento esatto**:

| Trigger | Quando invia | Quando usarlo |
|---|---|---|
| `FieldTrigger.onChange` | Ad ogni singola modifica (ogni tap, ogni scatto) | Controlli "a scelta secca": switch, checkbox, radio, dropdown, contatore |
| `FieldTrigger.onSubmit` | Solo quando si preme Invio/"Fatto" sulla tastiera | Campi di testo dove non vuoi inviare mentre l'utente sta ancora scrivendo |
| `FieldTrigger.onFocusLost` | Solo quando l'utente esce dal campo (rilascia lo slider, clicca altrove) | Slider e testo: eviti di "inondare" la rete di messaggi ad ogni pixel/carattere |
| `FieldTrigger.onButton` | Mai da solo: compare un'iconcina ✉️ da premere manualmente | Valori "delicati" che non vuoi inviare per sbaglio |

Esempio pratico — uno slider che invia SOLO al rilascio (non ad ogni trascinamento):
```dart
DynamicFormField(
  id: 'sliderLuci',
  label: 'Intensità Luci',
  type: FormFieldType.slider,
  value: 50.0,
  trigger: FieldTrigger.onFocusLost,
),
```

Puoi aprire l'app, andare su **Live Change** e provare dal vivo tutti i 26 tipi di campo con esempi di ogni trigger: quella pagina è stata popolata apposta come "catalogo dimostrativo".

### Il pulsante "Invia" manuale (`showSendButton`) — anche nella pagina statica

Oltre al `trigger` (che riguarda solo la pagina Live), ogni campo ha una proprietà `showSendButton` che funziona **sia nella pagina statica sia in quella live**: se impostata a `true`, mostra sempre un'iconcina ✉️ accanto al campo, da premere per confermare/inviare manualmente il valore corrente.

```dart
DynamicFormField(
  id: 'noteOperatore',
  label: 'Note',
  type: FormFieldType.multiline,
  showSendButton: true, // aggiunge l'iconcina "Invia"
),
```

Si applica a: `text`, `email`, `url`, `phone`, `password`, `number`, `multiline`, `slider`, `numberSlider`, `range`, `xyPad` — cioè tutti i campi che hanno un valore "in sospeso" prima dell'invio. Non ha alcun effetto sui controlli "a scelta secca" (switch, checkbox, radio, dropdown, date, rating, ecc.), che inviano già ad ogni interazione.

⚠️ **Importante per i campi `multiline` (testo su più righe)**: il tasto Invio in una casella di testo multilinea va semplicemente **a capo**, non può anche confermare il valore (è una limitazione della tastiera, non un bug). Per questo motivo, se usi un campo `multiline`, **ricordati sempre di impostare `showSendButton: true`**, altrimenti non ci sarà alcun modo per l'utente di inviare quel testo (né nella pagina statica né in quella live). Gli esempi già presenti in `form_schema.dart` (`multilineInput` e `multilineLive`) lo hanno già impostato: usali come riferimento quando ne aggiungi uno nuovo.

---

## 4. Catalogo completo di tutti gli elementi disponibili

Per ogni tipo: cosa mostra, e **due esempi pronti da copiare** — uno per la pagina statica (`formPageSchema`, l'utente compila e poi preme "Invia via OSC") e uno per la pagina live (`livePageSchema`, il campo invia da solo secondo il suo `trigger` — vedi [sezione 3](#3-concetti-base-come-funziona-un-campo-del-form) per il significato di `onChange`/`onSubmit`/`onFocusLost`/`onButton`). Sono gli esempi realmente usati in questo progetto: puoi trovarli identici in `lib/form_schema.dart`. I grafici, invece, non sono campi del form: vivono nella pagina Listener (vedi in fondo a questa sezione e la [sezione 13](#13-i-grafici-visualizzare-i-dati-con-fl_chart)).

### Testo e numeri

**`text`** — casella di testo su una riga.

Pagina statica:
```dart
DynamicFormField(id: 'textInput', label: 'Testo', type: FormFieldType.text),
```
Pagina live (`onSubmit`: invia quando l'utente preme "Invio"/"Fatto" sulla tastiera):
```dart
DynamicFormField(
  id: 'textLive',
  label: 'Testo',
  type: FormFieldType.text,
  trigger: FieldTrigger.onSubmit,
),
```

**`multiline`** — casella di testo su più righe (note, descrizioni). ⚠️ Ricorda sempre `showSendButton: true` (vedi sopra), altrimenti non c'è modo di inviare il testo scritto: il tasto Invio qui va a capo, non conferma.

Pagina statica:
```dart
DynamicFormField(
  id: 'multilineInput',
  label: 'Testo Multilinea',
  type: FormFieldType.multiline,
  showSendButton: true,
),
```
Pagina live (`onFocusLost` + `showSendButton`: invia anche uscendo dal campo, ma il pulsante resta comunque necessario per chi non cambia focus):
```dart
DynamicFormField(
  id: 'multilineLive',
  label: 'Testo Multilinea',
  type: FormFieldType.multiline,
  trigger: FieldTrigger.onFocusLost,
  showSendButton: true,
),
```

**`email`** — come `text`, ma con tastiera ottimizzata per indirizzi email.

Pagina statica:
```dart
DynamicFormField(id: 'emailInput', label: 'Email', type: FormFieldType.email),
```
Pagina live (`onFocusLost`: invia quando l'utente esce dal campo):
```dart
DynamicFormField(
  id: 'emailLive',
  label: 'Email',
  type: FormFieldType.email,
  trigger: FieldTrigger.onFocusLost,
),
```

**`url`** — come `text`, ma con tastiera ottimizzata per indirizzi web.

Pagina statica:
```dart
DynamicFormField(id: 'urlInput', label: 'URL', type: FormFieldType.url),
```
Pagina live (`onButton`: non invia mai da solo, compare un'iconcina di invio da premere manualmente):
```dart
DynamicFormField(
  id: 'urlLive',
  label: 'URL',
  type: FormFieldType.url,
  trigger: FieldTrigger.onButton,
),
```

**`phone`** — come `text`, ma con tastiera numerica da telefono.

Pagina statica:
```dart
DynamicFormField(id: 'phoneInput', label: 'Telefono', type: FormFieldType.phone),
```
Pagina live (`onFocusLost`):
```dart
DynamicFormField(
  id: 'phoneLive',
  label: 'Telefono',
  type: FormFieldType.phone,
  trigger: FieldTrigger.onFocusLost,
),
```

**`password`** — come `text`, ma nasconde i caratteri digitati (pallini).

Pagina statica:
```dart
DynamicFormField(id: 'passwordInput', label: 'Password', type: FormFieldType.password),
```
Pagina live (`onSubmit`):
```dart
DynamicFormField(
  id: 'passwordLive',
  label: 'Password',
  type: FormFieldType.password,
  trigger: FieldTrigger.onSubmit,
),
```

**`number`** — casella numerica (accetta solo cifre e punto decimale).

Pagina statica:
```dart
DynamicFormField(id: 'numberInput', label: 'Numero', type: FormFieldType.number),
```
Pagina live (`onFocusLost`):
```dart
DynamicFormField(
  id: 'numberLive',
  label: 'Numero',
  type: FormFieldType.number,
  trigger: FieldTrigger.onFocusLost,
),
```

### Controlli a scelta booleana

I controlli "a scelta secca" (switch, checkbox, momentaryButton) inviano già ad ogni interazione: nella pagina live si usa quasi sempre `trigger: FieldTrigger.onChange`, non c'è un "valore in sospeso" da confermare dopo.

**`checkbox`** — casella con segno di spunta.

Pagina statica:
```dart
DynamicFormField(id: 'checkboxValue', label: 'Checkbox', type: FormFieldType.checkbox, value: false),
```
Pagina live:
```dart
DynamicFormField(
  id: 'checkboxLive',
  label: 'Checkbox',
  type: FormFieldType.checkbox,
  value: false,
  trigger: FieldTrigger.onChange,
),
```

**`switchField`** — interruttore on/off in stile moderno.

Pagina statica:
```dart
DynamicFormField(id: 'switchValue', label: 'Switch', type: FormFieldType.switchField, value: false),
```
Pagina live:
```dart
DynamicFormField(
  id: 'switchLive',
  label: 'Switch Live',
  type: FormFieldType.switchField,
  value: false,
  trigger: FieldTrigger.onChange,
),
```

**`momentaryButton`** — pulsante "a pressione": manda `1` finché lo tieni premuto, `0` al rilascio. Utile per un trigger "spara ora" o per simulare un pulsante fisico.

Pagina statica:
```dart
DynamicFormField(id: 'pulsanteMomentaneoInput', label: 'Pulsante Momentaneo - Premuto true', type: FormFieldType.momentaryButton, value: false),
```
Pagina live:
```dart
DynamicFormField(
  id: 'pulsanteMomentaneo',
  label: 'Tieni premuto per true',
  type: FormFieldType.momentaryButton,
  value: false,
  trigger: FieldTrigger.onChange,
),
```

### Selezione tra opzioni

**`radio`** — elenco di opzioni, se ne può scegliere una sola (pallini).

Pagina statica:
```dart
DynamicFormField(
  id: 'radioGroup',
  label: 'Radio',
  type: FormFieldType.radio,
  options: ['Opzione A', 'Opzione B', 'Opzione C'],
),
```
Pagina live:
```dart
DynamicFormField(
  id: 'radioLive',
  label: 'Radio',
  type: FormFieldType.radio,
  options: const ['Opzione A', 'Opzione B', 'Opzione C'],
  trigger: FieldTrigger.onChange,
),
```

**`toggleButtons`** — come `radio`, ma mostrato come pulsanti affiancati (più compatto).

Pagina statica:
```dart
DynamicFormField(
  id: 'toggleGroup',
  label: 'Vista',
  type: FormFieldType.toggleButtons,
  options: ['Mappa', '3D', 'Lista'],
),
```
Pagina live:
```dart
DynamicFormField(
  id: 'toggleLive',
  label: 'Vista',
  type: FormFieldType.toggleButtons,
  options: const ['Mappa', '3D', 'Lista'],
  trigger: FieldTrigger.onChange,
),
```

**`dropdown`** (scelta singola) — menu a tendina.

Pagina statica:
```dart
DynamicFormField(
  id: 'dropdown',
  label: 'Dropdown',
  type: FormFieldType.dropdown,
  options: ['Italia', 'Francia', 'Spagna'],
  selectionMode: SelectionMode.single,
),
```
Pagina live:
```dart
DynamicFormField(
  id: 'dropdownLive',
  label: 'Dropdown',
  type: FormFieldType.dropdown,
  options: const ['Italia', 'Francia', 'Spagna'],
  selectionMode: SelectionMode.single,
  trigger: FieldTrigger.onChange,
),
```

**`dropdown`** (scelta multipla) — stesso menu, ma si possono selezionare più voci insieme.

Pagina statica:
```dart
DynamicFormField(
  id: 'dropdownMultiple',
  label: 'Dropdown multiplo',
  type: FormFieldType.dropdown,
  options: ['Rosso', 'Verde', 'Giallo'],
  selectionMode: SelectionMode.multiple,
  value: <String>[],
),
```
Pagina live:
```dart
DynamicFormField(
  id: 'dropdownMultipleLive',
  label: 'Dropdown multiplo',
  type: FormFieldType.dropdown,
  options: const ['Rosso', 'Verde', 'Giallo'],
  selectionMode: SelectionMode.multiple,
  value: <String>[],
  trigger: FieldTrigger.onChange,
),
```

### Numeri con range

**`slider`** — cursore continuo tra un minimo e un massimo.

Pagina statica:
```dart
DynamicFormField(id: 'sliderValue', label: 'Slider', type: FormFieldType.slider, value: 50.0, min: 0, max: 100),
```
Pagina live (`onFocusLost`: invia solo al rilascio, non ad ogni pixel trascinato):
```dart
DynamicFormField(
  id: 'sliderLive',
  label: 'Slider Live',
  type: FormFieldType.slider,
  value: 50.0,
  min: 0,
  max: 100,
  trigger: FieldTrigger.onFocusLost,
),
```

**`numberSlider`** — come `slider`, ma "scatta" a intervalli fissi (`step`).

Pagina statica:
```dart
DynamicFormField(id: 'numberSliderValue', label: 'Slider con Step', type: FormFieldType.numberSlider, value: 20.0, min: 0, max: 100, step: 5),
```
Pagina live (`onChange`: qui invia in tempo reale ad ogni scatto, invece che al rilascio):
```dart
DynamicFormField(
  id: 'numberSliderLive',
  label: 'Slider con Step',
  type: FormFieldType.numberSlider,
  value: 20.0,
  min: 0,
  max: 100,
  step: 5,
  trigger: FieldTrigger.onChange,
),
```

**`range`** — cursore doppio per scegliere un intervallo min-max.

Pagina statica:
```dart
DynamicFormField(id: 'rangeValue', label: 'Intervallo', type: FormFieldType.range, value: RangeValues(20.0, 80.0), min: 0, max: 100),
```
Pagina live (`onFocusLost`):
```dart
DynamicFormField(
  id: 'rangeLive',
  label: 'Intervallo',
  type: FormFieldType.range,
  value: const RangeValues(20.0, 80.0),
  min: 0,
  max: 100,
  trigger: FieldTrigger.onFocusLost,
),
```

**`counter`** — numero con pulsanti `−` / `+` (passo di 1).

Pagina statica:
```dart
DynamicFormField(id: 'counterValue', label: 'Contatore', type: FormFieldType.counter, value: 0),
```
Pagina live:
```dart
DynamicFormField(
  id: 'counterLive',
  label: 'Contatore Live',
  type: FormFieldType.counter,
  value: 0,
  trigger: FieldTrigger.onChange,
),
```

**`stepper`** — come `counter`, ma con passo personalizzabile tramite `step`.

Pagina statica:
```dart
DynamicFormField(id: 'stepperValue', label: 'Stepper', type: FormFieldType.stepper, value: 10, step: 1),
```
Pagina live:
```dart
DynamicFormField(
  id: 'stepperLive',
  label: 'Stepper',
  type: FormFieldType.stepper,
  value: 10,
  step: 1,
  trigger: FieldTrigger.onChange,
),
```

**`rating`** — stelline (da 0 a `max`).

Pagina statica:
```dart
DynamicFormField(id: 'ratingValue', label: 'Valutazione', type: FormFieldType.rating, value: 3, min: 0, max: 5),
```
Pagina live:
```dart
DynamicFormField(
  id: 'ratingLive',
  label: 'Valutazione',
  type: FormFieldType.rating,
  value: 3,
  min: 0,
  max: 5,
  trigger: FieldTrigger.onChange,
),
```

### Altri tipi speciali

**`colorPicker`** — apre una tavolozza colori.

Pagina statica:
```dart
DynamicFormField(id: 'colorValue', label: 'Colore', type: FormFieldType.colorPicker),
```
Pagina live:
```dart
DynamicFormField(
  id: 'colorLive',
  label: 'Colore',
  type: FormFieldType.colorPicker,
  trigger: FieldTrigger.onChange,
),
```

**`filePicker`** — apre la finestra di selezione file del sistema operativo, salva il percorso scelto.

Pagina statica:
```dart
DynamicFormField(id: 'fileValue', label: 'Carica File', type: FormFieldType.filePicker),
```
Pagina live:
```dart
DynamicFormField(
  id: 'fileLive',
  label: 'Carica File',
  type: FormFieldType.filePicker,
  trigger: FieldTrigger.onChange,
),
```

**`date`** — apre il calendario per scegliere una data.

Pagina statica:
```dart
DynamicFormField(id: 'dateValue', label: 'Data', type: FormFieldType.date, formatDatePattern: 'yyyy-MM-dd'),
```
Pagina live:
```dart
DynamicFormField(
  id: 'dateLive',
  label: 'Data',
  type: FormFieldType.date,
  formatDatePattern: 'yyyy-MM-dd',
  trigger: FieldTrigger.onChange,
),
```

**`time`** — apre l'orologio per scegliere un orario.

Pagina statica:
```dart
DynamicFormField(id: 'timeValue', label: 'Ora', type: FormFieldType.time, formatDatePattern: 'HH:mm'),
```
Pagina live:
```dart
DynamicFormField(
  id: 'timeLive',
  label: 'Ora',
  type: FormFieldType.time,
  formatDatePattern: 'HH:mm',
  trigger: FieldTrigger.onChange,
),
```

**`timeRange`** — chiede due orari (inizio e fine) uno dopo l'altro.

Pagina statica:
```dart
DynamicFormField(id: 'timeRangeValue', label: 'Intervallo Ora', type: FormFieldType.timeRange),
```
Pagina live:
```dart
DynamicFormField(
  id: 'timeRangeLive',
  label: 'Intervallo Ora',
  type: FormFieldType.timeRange,
  trigger: FieldTrigger.onChange,
),
```

**`xyPad`** — pad bidimensionale (come un piccolo joystick): invia due valori X/Y insieme, pensato per il controllo spaziale nel visore VR.

Pagina statica:
```dart
DynamicFormField(id: 'padPosizione', label: 'Pad Posizione (X/Y)', type: FormFieldType.xyPad, value: const Offset(0.5, 0.5)),
```
Pagina live (`onChange`: qui ha senso inviare ad ogni trascinamento, per un controllo spaziale fluido nel visore):
```dart
DynamicFormField(
  id: 'padLive',
  label: 'Pad Posizione Live',
  type: FormFieldType.xyPad,
  value: const Offset(0.5, 0.5),
  trigger: FieldTrigger.onChange,
),
```

**`label`** — **non è un campo dati**: è solo un titolo/sezione per organizzare visivamente un form lungo (non viene salvato né inviato via OSC, quindi non ha un `trigger`).

Pagina statica:
```dart
DynamicFormField(id: 'sezioneTesto', label: 'Campi di testo', type: FormFieldType.label),
```
Pagina live:
```dart
DynamicFormField(id: 'sezioneTestoLive', label: 'Campi di testo', type: FormFieldType.label),
```

### Grafici

A differenza dei tipi sopra, i grafici **non sono campi del form**: non si inviano via OSC, servono a **visualizzare** dei dati (tipicamente quelli ricevuti nella pagina Listener). Usano una classe diversa, `DynamicChartField` (invece di `DynamicFormField`), definita **nello stesso file** dei campi, `lib/form_schema.dart` (sezione 6); il disegno è gestito da `buildDynamicChart(...)` in `lib/chart_builder.dart`, con lo stesso pacchetto esterno `fl_chart`. Dettagli completi ed esempi di collegamento ai dati OSC nella [sezione 13](#13-i-grafici-visualizzare-i-dati-con-fl_chart).

**`ChartType.line`** — grafico a linea, ideale per mostrare l'andamento nel tempo di un valore che cambia in continuazione (es. uno slider ricevuto via OSC).
```dart
DynamicChartField(
  id: 'temperaturaChart',
  label: 'Temperatura',
  type: ChartType.line,
  color: AppColors.primary,
  min: -20,
  max: 50,
  maxPoints: 30,
),
```

**`ChartType.bar`** — stessa idea del grafico a linea (storico degli ultimi valori), ma disegnato a barre.
```dart
DynamicChartField(
  id: 'livelloChart',
  label: 'Livello',
  type: ChartType.bar,
  color: AppColors.success,
  min: 0,
  max: 100,
  maxPoints: 20,
),
```

**`ChartType.pie`** — grafico a torta: mostra le proporzioni tra categorie in un dato momento (non uno storico). I dati si assegnano "in blocco" con `setSlices(...)`, non con `addValue(...)`.
```dart
final distribuzioneChart = DynamicChartField(
  id: 'distribuzioneChart',
  label: 'Distribuzione risposte',
  type: ChartType.pie,
);

// altrove, dentro un setState:
distribuzioneChart.setSlices([
  ChartSlice(label: 'Sì', value: 70, color: AppColors.success),
  ChartSlice(label: 'No', value: 30, color: AppColors.error),
]);
```

---

## 5. Tutorial: creare una pagina statica da zero

### Quando creare una pagina statica ("init") invece di una live (e viceversa)

Prima di iniziare, vale la pena chiarire quando conviene usare l'una o l'altra tecnica — usano esattamente gli stessi "mattoncini" (`DynamicFormField` + `buildDynamicField`), cambia solo **quando** il valore di un campo viene salvato/inviato:

| | Pagina statica ("Init Settings") | Pagina live ("Live Change") |
|---|---|---|
| Quando invia/salva | Solo quando l'utente preme un pulsante esplicito ("Salva nel DB" / "Invia via OSC") | Automaticamente, campo per campo, secondo il `trigger` di ciascuno (vedi [sezione 3](#3-concetti-base-come-funziona-un-campo-del-form)) — anche mentre l'utente sta ancora interagendo |
| Scenario tipico | Impostazioni "di partenza" di una scena/sessione: configurazione iniziale del visore, un preset da richiamare, dati che cambiano raramente e vanno confermati con calma prima di essere inviati tutti insieme | Controllo "dal vivo" durante una sessione: manopole/slider/interruttori che l'utente muove in tempo reale e il cui effetto deve arrivare subito al visore (es. regolare un volume, spostare una luce, un joystick) |
| Rischio di "troppi" messaggi OSC | Nessuno: un solo invio, quando l'utente lo decide | Va scelto con cura il `trigger` di ogni campo (`onChange` per la reattività massima ma più traffico, `onFocusLost` per inviare solo al rilascio e ridurre il traffico su slider/testo, `onButton` per un invio sempre manuale) |
| Il valore resta salvato anche ad app chiusa? | Sì, appena premuto "Salva nel DB" | Sì, ma solo dopo che `onValueCommitted` è scattato (dipende dal `trigger` — vedi sopra) |

In pratica: se non sei sicuro di quale usare, parti da una pagina **statica** (più semplice: un solo momento di invio, facile da capire e da debuggare) e passa a una pagina **live** solo se ti serve davvero che il visore reagisca mentre l'utente sta ancora muovendo un controllo, senza dover premere nulla. Le due tecniche convivono già in questo progetto ("Init Settings" è statica, "Live Change" è live) e si possono anche mescolare nella stessa pagina, campo per campo, se un giorno ti serve.

Immaginiamo ora di voler creare una nuova pagina "Controllo Audio" con qualche campo, che si compila e si invia con un pulsante (come "Init Settings").

> **Scorciatoia:** l'esempio di questo tutorial esiste già, pronto all'uso, in `lib/audio_page.dart.example`. Basta rinominarlo in `lib/audio_page.dart` (togliendo `.example`), spostare la lista `audioPageSchema` che contiene dentro `lib/form_schema.dart` (sezione 7.1) e fare il Passo 3 qui sotto — non serve ricopiare a mano il codice dei Passi 1-2. I due passi che seguono restano comunque utili per capire COSA fa quel file e replicare la stessa idea con una pagina diversa dalla tua.

**Passo 1 — Aggiungi lo schema dei campi**

Apri `lib/form_schema.dart` e, in fondo al file (sezione 7.1, vicino a `formPageSchema`), aggiungi una nuova lista copiando lo stile di `formPageSchema`:

```dart
// ※ Schema per la pagina "Controllo Audio"
final List<DynamicFormField> audioPageSchema = [
  DynamicFormField(id: 'sezioneAudio', label: 'Impostazioni Audio', type: FormFieldType.label),
  DynamicFormField(id: 'volumeMaster', label: 'Volume Master', type: FormFieldType.slider, value: 70.0, min: 0, max: 100),
  DynamicFormField(id: 'muto', label: 'Muto', type: FormFieldType.switchField, value: false),
  DynamicFormField(
    id: 'sorgenteAudio',
    label: 'Sorgente',
    type: FormFieldType.dropdown,
    options: ['Microfono', 'Musica', 'Effetti'],
  ),
];
```

**Passo 2 — Crea il file della pagina**

Crea un nuovo file `lib/audio_page.dart` **copiando interamente** `lib/form_page.dart` e cambiando solo 3 cose:
1. Il nome della classe: `FormPage` → `AudioPage` (e `_FormPageState` → `_AudioPageState`).
2. Lo schema usato: `formPageSchema` → `audioPageSchema`.
3. I testi dei messaggi, se vuoi renderli più specifici (facoltativo).

Ecco il file pronto all'uso (basta incollarlo):

```dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:osc_controller/widgets/custom_app_bar.dart';

// Gli stessi 4 "motori" usati da ogni altra pagina statica: schema dei
// campi, database, invio OSC e disegno dei widget. Nessuno di questi file
// va modificato per creare una pagina nuova: bastano import + riuso.
import 'db.dart';
import 'form_serializer.dart';
import 'form_schema.dart';
import 'device_settings.dart';
import 'osc_sender.dart';
import 'dynamic_field_builder.dart';
import 'config_service.dart';
import 'app_theme.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  // Un TextEditingController per ogni campo di testo/numero della pagina
  // (slider, switch, ecc. non lo usano). buildDynamicField lo crea/riusa da
  // solo la prima volta che disegna un campo: qui serve solo la mappa vuota.
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    // Al primo apparire della pagina, ricarica gli eventuali valori salvati
    // in precedenza (altrimenti la pagina si aprirebbe sempre "vuota", con
    // i valori di default dello schema).
    _loadFromDb();
    // Se un'altra pagina cambia i dati "sotto ai piedi" di questa (es. una
    // importazione JSON dalla pagina Impostazioni, vedi sezione 9),
    // configRevision lo segnala e questa pagina si ricarica da sola.
    configRevision.addListener(_loadFromDb);
  }

  @override
  void dispose() {
    // Va sempre rimosso il listener aggiunto in initState, altrimenti
    // resterebbe agganciato anche dopo che la pagina è stata chiusa
    // (memory leak) e potrebbe causare errori chiamando setState() su un
    // widget non più presente a schermo.
    configRevision.removeListener(_loadFromDb);
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Legge dal database (tabella comune a tutte le pagine, vedi lib/db.dart)
  // tutte le righe salvate finora, e per ognuna cerca il campo con lo
  // stesso id in audioPageSchema: se lo trova, converte il testo salvato
  // nel tipo giusto (FormSerializer fa il percorso inverso di "serialize",
  // usato invece in _saveToDatabase) e aggiorna sia field.value sia
  // l'eventuale controller di testo già creato.
  Future<void> _loadFromDb() async {
    final rows = await DbService.instance.loadForm();
    for (final row in rows) {
      final field = audioPageSchema.firstWhereOrNull((f) => f.id == row.fieldId);
      if (field == null) continue;
      final raw = FormSerializer.deserializeByType(field.type, row.value, selectionMode: field.selectionMode);
      field.value = convertValueForType(field.type, raw);
      _textControllers[field.id]?.text = field.value?.toString() ?? '';
    }
    if (!mounted) return;
    setState(() {});
  }

  // Collegata al pulsante "Salva nel DB": scorre TUTTI i campi con un
  // valore vero e proprio (isDataField esclude i FormFieldType.label, che
  // sono solo titoli) e salva ciascuno nel database, uno per uno. Non
  // invia nulla via OSC: è solo persistenza locale sul dispositivo.
  Future<void> _saveToDatabase() async {
    for (final f in audioPageSchema) {
      if (!isDataField(f.type)) continue;
      await DbService.instance.saveValue(fieldId: f.id, value: FormSerializer.serialize(f.value));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: AppColors.success, content: Text('Valori salvati nel database')),
    );
  }

  // Collegata al pulsante "Invia via OSC": legge IP/porta/indirizzo da
  // "Impostazioni" (DeviceSettings), raccoglie tutti i valori correnti dei
  // campi in una mappa {id: valore} e li passa a OscSender.sendForm, che si
  // occupa di costruire e spedire un messaggio OSC per ciascun campo (vedi
  // sezione 11 per i dettagli). Il try/catch mostra un messaggio di errore
  // leggibile invece di far "sparire" un problema di rete senza spiegazioni.
  Future<void> _sendViaOsc() async {
    try {
      final settings = await DeviceSettings().load();
      final formValues = {for (final f in audioPageSchema) if (isDataField(f.type)) f.id: f.value};
      await OscSender.sendForm(
        baseAddress: settings['address'] as String,
        formValues: formValues,
        targetIp: settings['ip'] as String,
        targetPort: settings['port'] as int,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.success, content: Text('Dati inviati via OSC!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text('Errore invio OSC: $e')),
      );
    }
  }

  // Disegna UN campo, delegando tutto il lavoro vero a buildDynamicField
  // (lib/dynamic_field_builder.dart): qui c'è solo un po' di spaziatura
  // (Padding) e il collegamento a onValueChanged, che aggiorna field.value
  // e ridisegna la pagina (setState) ogni volta che l'utente tocca il
  // campo — ma NON salva né invia nulla da sola: per una pagina statica
  // questo avviene solo premendo i pulsanti, non ad ogni interazione.
  Widget buildField(DynamicFormField field, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: buildDynamicField(
        field,
        context: context,
        textControllers: _textControllers,
        onValueChanged: (value) => setState(() => field.value = value),
        isMobile: isMobile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sotto i 600px di larghezza consideriamo il layout "mobile" (usato da
    // alcuni tipi di campo, es. date/time picker, per adattare la propria
    // larghezza — vedi dynamic_field_builder.dart).
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Un widget per ogni campo dello schema, nell'ordine in cui
              // compare in audioPageSchema: per riordinare i campi a
              // schermo basta riordinare le righe nello schema, non serve
              // toccare questo file.
              ...audioPageSchema.map((f) => buildField(f, isMobile)),
              const SizedBox(height: 32),
              // I due pulsanti espliciti: è la differenza chiave rispetto
              // a una pagina "live" (sezione 6), dove non ce n'è bisogno
              // perché ogni campo invia/salva già da solo.
              ElevatedButton(onPressed: _saveToDatabase, child: const Text('Salva nel DB')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _sendViaOsc, child: const Text('Invia via OSC')),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Passo 3 — Aggiungi la pagina alla barra di navigazione**

Apri `lib/app_main.dart` e:
1. Aggiungi l'import in cima: `import 'audio_page.dart';`
2. Aggiungi `const AudioPage()` alla lista `_pages`.
3. Aggiungi una voce corrispondente alla lista `items` della `BottomNavigationBar` (stessa posizione nell'elenco):
```dart
BottomNavigationBarItem(icon: Icon(Icons.volume_up), label: 'Audio'),
```

Fatto: riavvia l'app e la nuova scheda "Audio" comparirà nella barra in basso, già funzionante (salvataggio, invio OSC, export/import inclusi automaticamente perché passano dal database condiviso).

---

## 6. Tutorial: creare una pagina "live" da zero

(Se non hai ancora letto ["Quando creare una pagina statica invece di una live"](#5-tutorial-creare-una-pagina-statica-da-zero) all'inizio della sezione 5, vale la pena tornarci: qui diamo per scontato che tu abbia già deciso che ti serve una pagina **live**, cioè che ogni campo debba salvare/inviare **da solo**, senza un pulsante esplicito.)

Stessa idea del tutorial precedente (stesso schema `DynamicFormField`, stesso motore `buildDynamicField`), ma copiando `lib/live_change_page.dart` invece di `form_page.dart`. La differenza chiave sta in **quando** parte il salvataggio/invio: invece di due pulsanti, ogni campo passa a `buildDynamicField` **due** callback distinte:

> **Scorciatoia:** anche per questo tutorial esiste già un esempio pronto all'uso in `lib/audio_live_page.dart.example`. Basta rinominarlo in `lib/audio_live_page.dart`, spostare la lista `audioLivePageSchema` che contiene dentro `lib/form_schema.dart` (sezione 7.2) e fare il Passo 3 qui sotto.

```dart
buildDynamicField(
  field,
  context: context,
  textControllers: _textControllers,
  // onValueChanged: chiamata ad OGNI variazione del campo (anche solo
  // "in corso", es. mentre si trascina uno slider). Serve solo per
  // aggiornare la UI (setState) così il numero/il cursore seguono il
  // dito dell'utente: NON deve salvare né inviare nulla da sola,
  // altrimenti si rischia di mandare un messaggio OSC per ogni singolo
  // pixel di trascinamento.
  onValueChanged: (value) => setState(() => field.value = value),
  // onValueCommitted: chiamata solo quando il valore va davvero
  // salvato/inviato. IL MOMENTO in cui scatta dipende dal `trigger` del
  // campo (onChange / onSubmit / onFocusLost / onButton — vedi sezione 3):
  // buildDynamicField decide da solo quando richiamarla, in base al
  // trigger che hai scritto nello schema.
  onValueCommitted: (value) => _saveAndSend(field.id, value),
),
```

**Passo 1 — Aggiungi lo schema dei campi**

Come per la pagina statica, ma scegliendo con attenzione il `trigger` di ogni campo (vedi la tabella in [sezione 3](#3-concetti-base-come-funziona-un-campo-del-form)) — è questo che definisce COME si comporta la pagina live, campo per campo:

```dart
// ※ Schema per la pagina "Controllo Audio" (live)
// Nota: gli id finiscono con "Live" per restare diversi da quelli, anche
// se simili, usati in audioPageSchema (sezione 5): ogni campo dell'app,
// in qualunque pagina, deve avere un id UNICO.
final List<DynamicFormField> audioLivePageSchema = [
  DynamicFormField(id: 'sezioneAudioLive', label: 'Impostazioni Audio', type: FormFieldType.label),
  DynamicFormField(
    id: 'volumeMasterLive',
    label: 'Volume Master',
    type: FormFieldType.slider,
    value: 70.0,
    min: 0,
    max: 100,
    // onFocusLost: invia solo al rilascio dello slider, non ad ogni pixel
    // trascinato — un buon compromesso tra reattività e traffico di rete.
    trigger: FieldTrigger.onFocusLost,
  ),
  DynamicFormField(
    id: 'mutoLive',
    label: 'Muto',
    type: FormFieldType.switchField,
    value: false,
    // onChange: uno switch è una scelta "secca" (acceso/spento), quindi ha
    // senso inviarla subito ad ogni tocco, senza aspettare altro.
    trigger: FieldTrigger.onChange,
  ),
  DynamicFormField(
    id: 'sorgenteAudioLive',
    label: 'Sorgente',
    type: FormFieldType.dropdown,
    options: ['Microfono', 'Musica', 'Effetti'],
    // onChange: come per lo switch, un dropdown è una scelta a elenco:
    // appena l'utente seleziona un'opzione è già una decisione definitiva,
    // ha senso inviarla subito.
    trigger: FieldTrigger.onChange,
  ),
];
```

**Passo 2 — Crea il file della pagina**

Crea un nuovo file `lib/audio_live_page.dart` **copiando interamente** `lib/live_change_page.dart` e cambiando gli stessi 3 elementi del tutorial precedente (nome della classe, schema usato, testi dei messaggi). La struttura interna è molto simile a `AudioPage` (sezione 5): stesso `_textControllers`, stesso `initState`/`dispose` con `configRevision`, stesso `_loadFromDb` — cambiano solo la funzione di salvataggio/invio e come viene collegata ai campi:

```dart
// Funzione unica per "committare" un campo: salva il nuovo valore nel
// database E lo invia via OSC nello stesso momento, così i due restano
// sempre allineati (a differenza della pagina statica, qui non ha senso
// separare "Salva" e "Invia" in due pulsanti distinti).
Future<void> _saveAndSend(String fieldId, dynamic value) async {
  final field = audioLivePageSchema.firstWhereOrNull((f) => f.id == fieldId);
  if (field == null) return;

  // 1. Salva nel database (stesso meccanismo della pagina statica).
  await DbService.instance.saveValue(fieldId: fieldId, value: FormSerializer.serialize(value));

  // 2. Invia subito via OSC il singolo campo appena cambiato (non l'intero
  //    form: è la differenza pratica più importante rispetto a
  //    _sendViaOsc() della pagina statica, che invece manda tutti i campi
  //    insieme, in un colpo solo, quando si preme "Invia via OSC").
  final settings = await DeviceSettings().load();
  await OscSender.sendForm(
    baseAddress: settings['address'] as String,
    formValues: {fieldId: value},
    targetIp: settings['ip'] as String,
    targetPort: settings['port'] as int,
  );
}

// Disegna UN campo passando ENTRAMBE le callback (vedi il blocco commentato
// più sopra): a differenza di AudioPage (sezione 5), qui non compaiono
// pulsanti "Salva"/"Invia" nella build() della pagina, perché non servono.
Widget buildField(DynamicFormField field, bool isMobile) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: buildDynamicField(
      field,
      context: context,
      textControllers: _textControllers,
      onValueChanged: (value) => setState(() => field.value = value),
      onValueCommitted: (value) => _saveAndSend(field.id, value),
      isMobile: isMobile,
    ),
  );
}
```

**Passo 3 — Aggiungi la pagina alla barra di navigazione**

Esattamente come nel tutorial precedente: import in `lib/app_main.dart`, riga in `_pages`, voce corrispondente in `items` della `BottomNavigationBar`.

---

## 7. Personalizzare il logo

Il logo è usato in due punti: la barra in alto (`lib/widgets/custom_app_bar.dart`) e la splash screen (`lib/widgets/splash_page.dart`). Entrambi puntano allo stesso file immagine: `assets/images/logo.png`.

**Per cambiarlo:**
1. Prepara la tua nuova immagine (consigliato: PNG con sfondo trasparente, quadrata, almeno 512×512 px).
2. Sostituisci il file `assets/images/logo.png` con il tuo (stesso nome, stesso percorso).
3. Riavvia l'app (un semplice hot-reload potrebbe non bastare per le immagini: meglio fermare e rilanciare `flutter run`).

Se invece vuoi usare un **nome file diverso**, devi anche aggiornare `pubspec.yaml` nella sezione `assets:`:
```yaml
flutter:
  assets:
    - assets/images/logo.png
    - assets/images/invia_tutti_icona.png
```
e i riferimenti `'assets/images/logo.png'` dentro `custom_app_bar.dart` e `splash_page.dart`.

L'icona del pulsante "Invia Tutti" nella pagina Live (`assets/images/invia_tutti_icona.png`) si personalizza allo stesso modo.

---

## 8. Personalizzare i colori

Tutti i colori dell'app sono raccolti in **un unico file**: `lib/app_theme.dart`. Non serve cercare altrove.

```dart
class AppColors {
  static const Color primary = Colors.blue;            // barra in alto, pulsante "Fuoco"/pad
  static const Color navBarBackground = Colors.black;   // sfondo barra di navigazione in basso
  static const Color navBarSelected = Colors.white;     // icona selezionata in basso
  static const Color navBarUnselected = Colors.white70; // icone non selezionate in basso
  static const Color splashBackground = Colors.white;   // sfondo della schermata iniziale
  static const Color success = Colors.green;            // messaggi di conferma
  static const Color error = Colors.red;                // messaggi di errore
}
```

Per cambiare un colore, sostituisci il valore. Puoi usare:
- Un nome di colore predefinito: `Colors.purple`, `Colors.teal`, `Colors.orange`, ecc.
- Una sfumatura: `Colors.blue.shade700` (più scuro), `Colors.blue.shade200` (più chiaro).
- Un colore esatto in esadecimale (lo stesso formato di Photoshop/Figma): `Color(0xFF1565C0)` — le prime due cifre (`FF`) sono l'opacità (lascia sempre `FF` = opaco), le 6 seguenti sono RRGGBB.

Dopo la modifica, riavvia l'app.

---

## 9. Esportare e importare una configurazione

Nella pagina **Impostazioni**:
- **Esporta JSON** → salva un file `.json` con IP/porta/indirizzo OSC **e** tutti i valori attualmente salvati nel database (di tutte le pagine). Utile per creare un "preset" da distribuire ad altri dispositivi/colleghi.
- **Importa JSON** → scegli un file `.json` esportato in precedenza: sovrascrive impostazioni e dati. Le pagine aperte si aggiornano da sole, non serve riavviare l'app.

Il file JSON è testo semplice, quindi è anche ispezionabile/modificabile a mano con un editor di testo se necessario (con cautela).

---

## 10. Problemi comuni e soluzioni

**"Errore invio OSC: IP di destinazione non impostato"**
→ Vai in Impostazioni e compila IP, porta e indirizzo OSC del visore prima di inviare.

**"Errore OSC: Invalid argument(s): OSC base address must start with "/""**
→ Il campo **Indirizzo OSC** in Impostazioni è vuoto oppure non inizia con `/` (es. hai scritto `vr` invece di `/vr`). Capita spesso al primo avvio su un'installazione "pulita" (es. un simulatore/emulatore appena creato, o dopo aver disinstallato e reinstallato l'app): tutte le impostazioni ripartono vuote finché non le salvi almeno una volta. Vai in Impostazioni, scrivi un indirizzo che inizi con `/` (es. `/vr`) insieme a IP e porta, e premi "Salva". Il campo ora segnala subito l'errore al salvataggio (invece di farlo scoprire solo più tardi inviando un dato), grazie a un controllo aggiunto in `lib/settings_page.dart`.

**L'app non invia nulla e non dà errori nella pagina Live**
→ Controlla il `trigger` del campo: se è `onButton`, serve premere l'iconcina ✉️ accanto al campo; se è `onFocusLost`, serve uscire dal campo (o rilasciare lo slider).

**Il visore non riceve nulla pur non avendo errori**
→ Verifica che PC/Mac/telefono e visore siano sulla **stessa rete Wi-Fi**, che l'IP inserito sia corretto, e che il firewall del computer non stia bloccando il traffico UDP in uscita (su macOS potrebbe comparire un popup di autorizzazione al primo avvio: va accettato).

**Errore di compilazione `FilePicker.platform` / `Member not found: platform`**
→ È un problema noto delle versioni 10.3.9 del pacchetto `file_picker` (bug risolto nelle versioni successive). Questo progetto usa già l'API corretta (`FilePicker.pickFiles()` diretto); se l'errore ricompare dopo un `flutter pub upgrade`, verifica la versione di `file_picker` in `pubspec.yaml`.

**Dopo aver modificato `lib/db.dart` l'app non compila più / dà errori strani sul database**
→ Vanno rigenerati i file automatici:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**`flutter run -d ios` non trova nessun dispositivo iOS**
→ Se manca la cartella `ios/` (es. su una copia del progetto che non la include), va rigenerata con `flutter create --platforms=ios .` (vedi [sezione 1.0](#1-come-compilare-il-progetto-su-ogni-piattaforma)).

**Ho aggiunto un campo nuovo ma la pagina Live non lo invia mai**
→ Controlla di aver assegnato un `id` diverso da tutti gli altri campi (statici e live insieme): id duplicati confondono il salvataggio nel database.

**Su un emulatore Android, `python3 tools/test_osc_sender.py` non fa arrivare nulla nella pagina Listener**
→ Questo è normale ed è diverso dal caso "l'app invia verso il computer" spiegato nella [sezione 1.3](#13-android-telefonotablet-android): qui la direzione è opposta. Lo script gira sul computer (host) e prova a **mandare** pacchetti UDP verso l'app che gira **dentro** l'emulatore, in ascolto sulla pagina Listener. Ma l'emulatore Android è isolato in una rete virtuale propria: il computer host non può raggiungere direttamente l'IP interno dell'emulatore, e a differenza del caso opposto (dall'emulatore verso il host, dove basta usare `10.0.2.2`) qui non esiste un indirizzo speciale equivalente da usare con `--ip`. Inoltre `adb forward`, il comando normalmente usato per "aprire un varco" verso l'emulatore, supporta solo TCP e non UDP, quindi non è utilizzabile per l'OSC.

Due modi per risolvere:

1. **Consigliato — prova su un telefono/tablet fisico invece che sull'emulatore** (vedi ["Su un telefono/tablet fisico"](#12-android-telefonotablet-android) nella sezione 1.2): un dispositivo reale è sulla stessa rete Wi-Fi del computer, quindi basta lanciare lo script con `--ip <indirizzo IP del telefono>` (lo trovi in Impostazioni → Wi-Fi → dettagli rete sul telefono), esattamente come si farebbe con un visore VR vero.
2. **Solo se devi per forza restare sull'emulatore** — puoi aprire un inoltro UDP manuale verso l'emulatore tramite la sua console di controllo (funzionalità avanzata degli emulatori Android, non specifica di questa app):
   ```bash
   telnet localhost 5554
   ```
   (`5554` è la porta console del primo emulatore avviato; `flutter devices`/`adb devices` mostra l'id, es. `emulator-5554` → porta console `5554`). Al primo collegamento ti verrà chiesto un token di autenticazione, che trovi nel file `~/.emulator_console_auth_token` (per Windows: `%USERPROFILE%\.emulator_console_auth_token`):
   ```
   auth <token-dal-file>
   redir add udp:9000:9000
   ```
   Dopo questo comando, i pacchetti UDP inviati dallo script con `--ip 127.0.0.1 --port 9000` verranno inoltrati al Listener in ascolto dentro l'emulatore.

---

## 11. Approfondimento: come funziona l'invio dei dati via OSC

Questa sezione è più tecnica delle altre: è utile se in futuro tu (o un altro sviluppatore) vorrete cambiare **come** i dati vengono inviati al visore, non **cosa** viene mostrato nel form. Per usare l'app normalmente non serve leggerla.

### 11.1 Un messaggio per ogni campo

Quando premi "Invia via OSC" (pagina statica) o quando un campo scatta nella pagina Live, l'app **non** manda un unico pacchetto con tutti i dati: manda **un messaggio OSC separato per ogni campo**, uno dopo l'altro, in sequenza. Tutta questa logica sta in `lib/osc_sender.dart`, dentro `OscSender.sendForm`.

Per ogni campo, l'indirizzo OSC generato è:

```
{indirizzo base}/{id del campo}
```

Ad esempio, se in Impostazioni hai scritto `/vr` come indirizzo base, il campo con id `sliderLive` viene inviato all'indirizzo OSC `/vr/sliderLive`.

### 11.2 Cosa contiene ogni messaggio

Ogni messaggio porta **sempre** come primo argomento l'id del campo (in chiaro, come stringa), seguito dal valore vero e proprio. Questa "ripetizione" (l'id è già nell'indirizzo, e viene ripetuto anche nel contenuto) è voluta: se chi riceve registra solo il payload grezzo dei messaggi senza guardare l'indirizzo, riesce comunque a capire a quale campo appartiene ogni valore.

Il valore viene poi codificato in uno dei 3 formati OSC standard, a seconda del tipo:

| Tipo Dart del campo | Tipo OSC inviato |
|---|---|
| numero intero (switch, checkbox, counter, stepper, rating...) | `i` (int32) |
| numero decimale (slider, numberSlider...) | `f` (float32) |
| tutto il resto (testo, date, colori, orari...) | `s` (stringa) |

Casi particolari:
- **booleani** (switch, checkbox, momentaryButton): inviati come intero `0`/`1`, non come testo "true"/"false".
- **xyPad**: invia **due** argomenti float consecutivi (x e y) dopo l'id, invece di uno solo.
- **tutti gli altri tipi complessi** (colori, date, orari, intervalli...): vengono prima trasformati in una stringa (vedi 11.3) e inviati come argomento di tipo stringa.

Questa logica di conversione è nella funzione privata `_buildArgs` di `lib/osc_sender.dart`.

### 11.3 Come i valori vengono trasformati in testo (serializzazione)

Il "traduttore" che trasforma un valore (un colore, una data, un orario...) in una stringa — e viceversa — è tutto in `lib/form_serializer.dart`, classe `FormSerializer`. È lo **stesso** traduttore usato sia per il salvataggio nel database, sia per l'invio via OSC (quando il valore non è già un numero), sia per l'export/import JSON: cambiarlo in un punto lo cambia ovunque.

| Valore | Formato testo |
|---|---|
| Intervallo numerico (`range`) | `min-max`, es. `20.0-80.0` |
| Colore (`colorPicker`) | `#AARRGGBB`, es. `#FF1565C0` |
| Posizione XY (`xyPad`) | `x,y`, es. `0.5,0.75` |
| Booleano | `true` / `false` |
| Dropdown multiplo | valori separati da `\|`, es. `Rosso\|Verde` |
| Data (`date`) | formato ISO8601, es. `2026-07-15T00:00:00.000` |
| Ora (`time`) | `HH:mm`, es. `14:30` |
| Intervallo ora (`timeRange`) | `HH:mm-HH:mm`, es. `14:30-15:45` |
| Testo, numeri semplici | il valore così com'è |

### 11.4 Il trasporto: UDP, non TCP

I messaggi viaggiano su **UDP** (vedi glossario): l'app apre una porta, invia i byte del messaggio, e la chiude. Non c'è alcuna conferma che il messaggio sia arrivato — è una scelta tipica per il controllo in tempo reale (bassa latenza), a costo di poter perdere occasionalmente un messaggio senza che l'app se ne accorga.

Per compensare parzialmente questa mancanza di garanzie, `OscSender` ritenta l'invio fino a 3 volte (con 200ms di pausa tra un tentativo e l'altro) **solo** se il sistema operativo segnala un errore nell'invio stesso (es. rete non raggiungibile). Non c'è invece alcun modo, ad oggi, per sapere se il visore ha davvero ricevuto ed elaborato il messaggio.

### 11.5 Come e dove modificare questo comportamento

Se in futuro servisse cambiare il modo in cui i dati vengono inviati, ecco le modifiche più comuni e dove intervenire:

| Cosa vuoi ottenere | Dove intervenire | Note |
|---|---|---|
| Cambiare lo schema degli indirizzi OSC (es. `/vr/live/...` invece di `/vr/...`) | `lib/osc_sender.dart`, funzione `sendForm` | Basta cambiare come viene composta la stringa `address` |
| Inviare più campi in un unico pacchetto invece di uno per campo (OSC Bundle) | `lib/osc_sender.dart` | Un bundle OSC contiene più messaggi con un timestamp comune: garantisce che valori collegati (es. X e Y di un pad) arrivino "nello stesso istante" per il ricevente. Richiede di costruire l'intestazione `#bundle` e concatenare più messaggi già pronti |
| Passare da UDP a TCP (per avere garanzia di consegna) | `lib/osc_sender.dart` (sostituire `RawDatagramSocket` con `Socket.connect`) | Serve anche che il ricevente supporti OSC su TCP, che richiede un framing dei messaggi (es. prefisso con la lunghezza). Sconsigliato per dati ad alta frequenza: è più lento di UDP |
| Avere conferma che il visore ha ricevuto il dato | `lib/osc_sender.dart` + `lib/receiver_osc_page.dart` | Il visore dovrebbe rispondere con un proprio messaggio OSC (es. su `/ack`); l'app dovrebbe aprire un socket in ricezione (come già fa `ReceiverOscPage`) e aspettare la risposta con un timeout |
| Evitare troppi invii ravvicinati (es. xyPad impostato su `onChange`) | Nello schema, usa `trigger: FieldTrigger.onFocusLost` invece di `onChange` | In alternativa (senza cambiare trigger) si può introdurre un "debounce" nel codice: aspettare che i cambiamenti si fermino per un breve istante (es. 50-100ms) prima di inviare davvero |
| Inviare i colori come 3 numeri (r, g, b) invece di una stringa esadecimale | `lib/osc_sender.dart`, funzione `_buildArgs` | Molti software di luci/VR preferiscono ricevere direttamente 3 valori float invece di dover interpretare una stringa `#RRGGBB` |
| Vedere anche i messaggi INVIATI (oggi "Ricevi OSC" mostra solo quelli ricevuti) | `lib/osc_sender.dart` + `lib/receiver_osc_page.dart` | Basterebbe un "log" condiviso (es. un `ValueNotifier<List<String>>`, sullo stesso modello di `configRevision`) aggiornato ogni volta che `sendForm` invia un messaggio |

Nessuna di queste modifiche è obbligatoria: il comportamento attuale (un messaggio UDP per campo, con retry automatico) è lo standard per la maggior parte dei software di controllo OSC per VR/luci, ed è compatibile con la stragrande maggioranza dei ricevitori OSC esistenti (es. TouchOSC, Resolume, la maggior parte dei plugin VR).

---

## 12. La pagina Listener attiva: ricevere dati in tempo reale

La pagina "Ricevi OSC" non si limita a registrare i messaggi ricevuti come testo: in cima mostra anche dei **campi del form veri e propri** in "sola lettura" (oggi: uno slider e un'area di testo), che si aggiornano da soli quando arriva un dato OSC con il loro nome (id) — sono gli **stessi identici mattoncini** usati per inviare (stessa classe `DynamicFormField`, stesso motore di disegno `buildDynamicField` di `lib/form_schema.dart` e `lib/dynamic_field_builder.dart`), con la differenza che l'utente non può toccarli/scriverci e il loro valore cambia perché arriva da fuori (via OSC), non perché qualcuno interagisce con loro. Subito sotto, la pagina mostra anche un paio di **grafici** con lo storico dei valori ricevuti (vedi [sezione 13](#13-i-grafici-visualizzare-i-dati-con-fl_chart)): campi "in sola lettura" e grafici possono coesistere e restare collegati allo stesso id, mostrando lo stesso dato in due modi (valore attuale + storico).

### 12.1 Dove sono definiti

I campi mostrati nella pagina Listener sono elencati in `lib/form_schema.dart`, nella lista `receiverPageSchema` (sezione 7.3, in fondo al file):

```dart
final List<DynamicFormField> receiverPageSchema = [
  DynamicFormField(
    id: 'sliderRx',
    label: 'Slider ricevuto',
    type: FormFieldType.slider,
    value: 0.0,
    min: 0,
    max: 100,
  ),
  DynamicFormField(
    id: 'textAreaRx',
    label: 'Testo ricevuto',
    type: FormFieldType.multiline,
    value: '',
  ),
];
```

### 12.2 Come funziona l'aggiornamento

Quando arriva un pacchetto OSC, la pagina che lo riceve lo decodifica con `lib/osc_decoder.dart` (che fa l'operazione inversa di `osc_sender.dart`: dai byte grezzi ricava di nuovo indirizzo, id del campo e valore/i). Se il primo argomento del messaggio (il "fieldId", esattamente come lo manda `OscSender`) corrisponde all'`id` di uno dei campi in `receiverPageSchema`, il valore di quel campo viene aggiornato (funzione `_updateReceiverFields` in `receiver_osc_page.dart`) e lo slider/l'area di testo corrispondente si aggiorna, nel giro di una frazione di secondo. Lo stesso messaggio, se il suo id corrisponde anche a un grafico di `receiverChartSchema`, aggiorna in parallelo anche quello (funzione `_updateLiveChart`, vedi [sezione 13](#13-i-grafici-visualizzare-i-dati-con-fl_chart)) — è per questo che `sliderRx` compare sia come slider sia (con lo stesso id) come grafico a linea: sono due visualizzazioni indipendenti, collegate allo stesso dato in arrivo.

Il campo viene disegnato passando `readOnly: true` a `buildDynamicField` (un'opzione pensata apposta per questo caso): lo slider mostra il valore ma non risponde al tocco/trascinamento dell'utente, e l'area di testo mostra il testo ricevuto ma non è modificabile (il suo controller viene risincronizzato ad ogni nuovo valore in arrivo, invece che lasciato alla digitazione dell'utente).

### 12.3 Come aggiungere un nuovo campo "ricevente"

Per far comparire un nuovo campo che si aggiorna da solo quando arriva un certo dato via OSC:

1. Apri `lib/form_schema.dart` e aggiungi una riga a `receiverPageSchema` (sezione 7.3), con l'`id` esattamente uguale al nome del campo che ti aspetti nel pacchetto in arrivo (il "fieldId", primo argomento del messaggio — se il dato arriva da un'altra pagina di questa stessa app, è l'`id` che hai dato a quel campo nel suo schema; se arriva da un dispositivo/software esterno, è come quel dispositivo chiama il dato).
2. Scegli il `type` più adatto (per ora sono stati testati `slider`, `numberSlider` e `multiline`; gli altri tipi funzionano nel motore di disegno ma non hanno ancora la modalità "sola lettura" applicata — vedi punto 3 se ti serve estenderla).
3. Nella pagina che vuoi usare, disegna la lista con `...receiverPageSchema.map((field) => buildDynamicField(field, ..., readOnly: true))`, sullo stesso modello già usato per `formPageSchema`/`livePageSchema` nelle altre pagine (`receiver_osc_page.dart` lo fa già per questa lista).

Esempio — aggiungere un secondo slider che riceve la temperatura da un sensore esterno che manda pacchetti OSC con id `temperatura`:

```dart
DynamicFormField(
  id: 'temperatura',
  label: 'Temperatura ricevuta',
  type: FormFieldType.slider,
  value: 0.0,
  min: -20,
  max: 50,
),
```

Se invece vuoi che anche altri tipi di campo (es. `switchField`, `xyPad`) possano essere mostrati in sola lettura nella pagina Listener, va estesa la gestione di `readOnly` per quel tipo in `lib/dynamic_field_builder.dart` (oggi è implementata per `slider`, `numberSlider` e `multiline`): basta seguire lo stesso schema già usato per gli slider/l'area di testo (disabilitare gli `onChanged`/`onPanUpdate` quando `readOnly` è `true`, nascondere l'eventuale pulsante "Invia", e per i campi con controller di testo risincronizzare `controller.text` col valore in arrivo).

### 12.4 Provarla senza un visore vero

Per vedere la pagina Listener "in azione" senza dover collegare davvero un visore VR, vedi lo script `tools/test_osc_sender.py`, descritto nella [sezione 14](#14-come-eseguire-i-test): aggiorna sia lo slider e l'area di testo "in sola lettura" (`sliderRx`, `textAreaRx`), sia i grafici che mostrano lo storico dei valori ricevuti (vedi [sezione 13](#13-i-grafici-visualizzare-i-dati-con-fl_chart)).

### 12.5 Errori di layout: "RenderFlex overflowed" (barre gialle e nere)

Se in una pagina vedi comparire delle strisce diagonali gialle e nere con scritto qualcosa come **"BOTTOM OVERFLOWED BY 244 PIXELS"** (o `RIGHT OVERFLOWED`), non è un bug nei dati: è Flutter che segnala che il contenuto di quella zona dello schermo è **più alto (o più largo) dello spazio realmente disponibile**. È uno degli errori più comuni quando si aggiungono nuovi elementi (slider, grafici, campi...) a una pagina già esistente.

**Perché succede.** Un `Column` (o `Row`) normalmente chiede ad ogni figlio quanto spazio vuole e li mette in fila. Se la somma delle altezze dei figli supera l'altezza disponibile sullo schermo, Flutter **non riduce automaticamente i figli né aggiunge uno scroll da solo**: segnala l'overflow con la striscia gialla/nera, a meno che tu non gli dica esplicitamente come comportarsi. Questo è capitato aggiungendo i grafici (sezione 13) alla pagina Listener: due grafici da 180px di altezza ciascuno, più le etichette e il registro messaggi sotto, superavano facilmente l'altezza di uno schermo di telefono in verticale.

**Le due soluzioni principali** (si possono anche combinare):

| Soluzione | Quando usarla | Esempio |
|---|---|---|
| **`Expanded`** (o `Flexible`) attorno a un figlio del `Column`/`Row` | Quando vuoi che quel figlio occupi "tutto lo spazio rimasto" invece di un'altezza fissa | `Expanded(child: ListView.builder(...))` — è già usato per il registro messaggi della pagina Listener |
| **`SingleChildScrollView`** attorno al contenuto | Quando il contenuto può essere più alto dello schermo e va bene farlo scorrere invece di comprimerlo | `SingleChildScrollView(child: Column(children: [...]))` |

Nella pagina Listener (`lib/receiver_osc_page.dart`) è stata usata **la combinazione di entrambe**: l'area dei grafici e l'area del registro messaggi sono ciascuna dentro un proprio `Expanded` (con un `flex` che decide quanto spazio prende l'una rispetto all'altra), e dentro l'`Expanded` dei grafici c'è anche uno `SingleChildScrollView`, così se in futuro si aggiungono altri grafici quell'area scorre da sola invece di andare in overflow:

```dart
Expanded(
  flex: 3,                              // 3 parti di spazio su 5 totali (3+2)
  child: SingleChildScrollView(         // se il contenuto è più alto, scorre
    child: Column(
      children: [
        ...receiverChartSchema.map((c) => buildDynamicChart(c)),
      ],
    ),
  ),
),
// ... Divider ...
Expanded(
  flex: 2,                              // le restanti 2 parti su 5
  child: ListView.builder(...),         // scorre già da solo
),
```

**Regola pratica per non ricadere nell'errore:** ogni volta che aggiungi un widget con altezza "fissa o imprevedibile" (un grafico, un'immagine, una lista) dentro un `Column` che sta già dentro uno spazio limitato (uno schermo, un `Scaffold`), chiediti "questo `Column` può scorrere, oppure ha un `Expanded`/`Flexible` che lo contiene?". Se la risposta è no per entrambe, rischi l'overflow non appena il contenuto cresce (più campi, testo più lungo, schermo più piccolo di quello su cui hai provato).

Un'eccezione da ricordare: un `ListView` (o `SingleChildScrollView`) messo **direttamente** dentro un `Column` **senza** `Expanded` intorno dà un errore diverso ("`RenderBox was not laid out`" o vincoli infiniti), perché quei widget vogliono occupare tutto lo spazio verticale disponibile ma un `Column` normale offre spazio "infinito" ai suoi figli. Per questo la regola è sempre: widget scorrevoli dentro `Expanded`/`Flexible`, non direttamente dentro un `Column`.

### 12.6 Esempio: creare una seconda pagina di ricezione dedicata

A volte non basta la pagina Listener unica già presente: ad esempio potresti voler tenere separati i dati che arrivano da un visore VR da quelli di un gruppo di sensori esterni, mostrandoli in due pagine diverse invece di mescolarli tutti nella stessa. Vediamo come creare una seconda pagina "Ricevi Sensori", che mostra **due campi in sola lettura** (temperatura e umidità) e i **due grafici** collegati con il loro storico — stessa combinazione campi+grafici già vista nella pagina Listener principale (sezioni 12 e 13).

**Attenzione al punto più importante — la porta UDP:** `RawDatagramSocket.bind(...)` (usato da `receiver_osc_page.dart`) può avere **un solo "proprietario" per porta** sullo stesso dispositivo: due pagine non possono ascoltare **la stessa** porta (9000) contemporaneamente. La soluzione più semplice è far ascoltare la nuova pagina su una **porta diversa** (es. 9001), e configurare il mittente (visore/sensore/script di test) perché mandi i dati dei sensori a quella porta invece che a 9000.

> **Scorciatoia:** questo intero esempio esiste già, pronto all'uso, in `lib/sensor_receiver_page.dart.example` (già impostato sulla porta 9001). Basta rinominarlo in `lib/sensor_receiver_page.dart`, spostare `sensorPageSchema`/`sensorChartSchema` che contiene dentro `lib/form_schema.dart` (sezione 7.3) e fare il Passo 3 qui sotto.

**Passo 1 — Aggiungi gli schemi dei campi "riceventi" e dei grafici**

In `lib/form_schema.dart`, vicino a `receiverPageSchema` (sezione 7.3), aggiungi una nuova lista con i **due campi in sola lettura** (vedi [sezione 12.1](#121-dove-sono-definiti)):

```dart
// ※ Schema dei CAMPI per la pagina "Ricevi Sensori" (porta UDP 9001)
final List<DynamicFormField> sensorPageSchema = [
  DynamicFormField(
    id: 'temperaturaRx',
    label: 'Temperatura ricevuta',
    type: FormFieldType.slider,
    value: 0.0,
    min: -20,
    max: 50,
  ),
  DynamicFormField(
    id: 'umiditaRx',
    label: 'Umidità ricevuta',
    type: FormFieldType.numberSlider,
    value: 0.0,
    min: 0,
    max: 100,
    step: 5,
  ),
];
```

Sempre in `lib/form_schema.dart` (sezione 7.3, subito sotto, vicino a `receiverChartSchema`), aggiungi i **due grafici** corrispondenti, usando **lo stesso id** dei campi qui sopra (è quello che li collega automaticamente, vedi [sezione 13.1](#131-dove-sono-definiti)):

```dart
// ※ Schema dei GRAFICI per la pagina "Ricevi Sensori" (porta UDP 9001)
final List<DynamicChartField> sensorChartSchema = [
  DynamicChartField(
    id: 'temperaturaRx',   // <- stesso id del campo slider qui sopra
    label: 'Andamento nel tempo — Temperatura',
    type: ChartType.line,
    color: AppColors.error,
    min: -20,
    max: 50,
    maxPoints: 30,
  ),
  DynamicChartField(
    id: 'umiditaRx',        // <- stesso id del campo numberSlider qui sopra
    label: 'Andamento nel tempo — Umidità',
    type: ChartType.bar,
    color: AppColors.primary,
    min: 0,
    max: 100,
    maxPoints: 20,
  ),
];
```

**Passo 2 — Crea il file della pagina copiando `receiver_osc_page.dart`**

Crea `lib/sensor_receiver_page.dart` copiando interamente `lib/receiver_osc_page.dart`: la struttura è già pronta per campi + grafici insieme (è esattamente quello che fa oggi per la pagina Listener principale), quindi cambia solo questi punti (il resto — decodifica OSC, registro messaggi, layout con `Expanded`/scroll per evitare l'overflow, vedi sezione 12.5 — resta identico):

```dart
// 1. Rinomina le classi:
//    ReceiverOscPage      -> SensorReceiverPage
//    _ReceiverOscPageState -> _SensorReceiverPageState

// 2. Cambia la porta di ascolto di default (era 9000):
Future<void> _startListening({int port = 9001}) async {
  // ... resto invariato ...
}

// 3. Nei due metodi che aggiornano campi e grafici, itera sulle nuove
//    liste invece che su receiverPageSchema/receiverChartSchema:
void _updateReceiverFields(OscDecodedMessage decoded) {
  if (decoded.args.length < 2) return;
  final fieldId = decoded.args.first;
  final value = decoded.args[1];

  for (final field in sensorPageSchema) {   // <- era receiverPageSchema
    if (field.id == fieldId) {
      field.value = convertValueForType(field.type, value);
      break;
    }
  }
}

void _updateLiveChart(OscDecodedMessage decoded) {
  if (decoded.args.length < 2) return;
  final fieldId = decoded.args.first;
  final value = decoded.args[1];
  if (value is! num) return;

  for (final chart in sensorChartSchema) {   // <- era receiverChartSchema
    if (chart.id == fieldId) {
      chart.addValue(value.toDouble());
      break;
    }
  }
}

// 4. Nella build(), disegna sensorPageSchema al posto di receiverPageSchema
//    e sensorChartSchema al posto di receiverChartSchema (stesse due righe
//    con ...schema.map((f) => ...), solo il nome della lista cambia).
```

**Passo 3 — Aggiungi la pagina alla barra di navigazione**

Come nei tutorial precedenti: import in `lib/app_main.dart`, `const SensorReceiverPage()` in `_pages`, voce corrispondente in `items`.

**Passo 4 — Adatta lo script di test per mandare dati anche alla nuova pagina**

`tools/test_osc_sender.py` (vedi [sezione 14.2](#142-test-manuale-in-tempo-reale-toolstest_osc_senderpy)) manda tutti i suoi messaggi finti a **un solo** `ip:porta` per esecuzione (quello passato con `--ip`/`--port`, di default `127.0.0.1:9000`). Per generare anche dei dati finti di temperatura e umidità per la nuova pagina, hai due strade:

1. **Più semplice — una seconda esecuzione dedicata**, puntata alla nuova porta, in un terzo terminale (in aggiunta ai due già usati per app + script "normale"):
   ```bash
   python3 tools/test_osc_sender.py --port 9001 --base-address /sensori
   ```
   Con questa sola modifica lo script continua a mandare TUTTI i suoi messaggi di esempio (`sliderRx`, `textAreaRx`, ecc.) ma alla porta 9001: dato che `sensorPageSchema`/`sensorChartSchema` hanno solo gli id `temperaturaRx` e `umiditaRx`, la nuova pagina ignorerà semplicemente gli id che non riconosce (non è un errore) — utile per un test rapido, ma non genera valori di temperatura/umidità veri e propri.

2. **Più corretto — aggiungi due messaggi dedicati in `make_messages()`**, così anche i valori che arrivano sono sensati. Apri `tools/test_osc_sender.py` e nella funzione `make_messages` aggiungi:
   ```python
   # Valori finti di temperatura e umidità, per i campi/grafici
   # temperaturaRx e umiditaRx della pagina "Ricevi Sensori"
   # (lib/sensor_receiver_page.dart).
   temperatura_val = round(random.uniform(-10, 40), 1)
   umidita_val = float(random.choice(range(0, 101, 5)))
   ```
   e nella lista restituita:
   ```python
   build_osc_message(f"{base_address}/temperaturaRx", "temperaturaRx", temperatura_val),
   build_osc_message(f"{base_address}/umiditaRx", "umiditaRx", umidita_val),
   ```
   Poi lancia lo script puntato alla porta 9001 come al punto 1. Se preferisci tenere il test dei sensori completamente separato da quello del Listener principale, puoi anche duplicare il file in `tools/test_osc_sender_sensori.py` e lasciare in quello solo i messaggi che ti servono, cancellando gli altri: sono due script indipendenti, nessuno dei due ha bisogno dell'altro per funzionare.

---

## 13. I grafici: visualizzare i dati con fl_chart

Oltre agli slider "in sola lettura" (sezione 12), la pagina Listener mostra anche un paio di **grafici** che tengono uno storico degli ultimi valori ricevuti, non solo l'ultimo. Sono realizzati con il pacchetto esterno [fl_chart](https://pub.dev/packages/fl_chart), aggiunto a `pubspec.yaml`.

Anche qui vale la stessa idea "mattoncino" usata per i campi del form: una classe che descrive UN grafico (`lib/form_schema.dart`, sezione 6) e un motore di disegno che la trasforma nel widget giusto (`lib/chart_builder.dart`), così chi aggiunge un grafico nuovo non deve sapere come è fatto `fl_chart` internamente.

### 13.1 Dove sono definiti

La classe e gli enum "motore" sono nella parte alta di `lib/form_schema.dart` (sezione 6, subito dopo gli esempi di campo):

- `ChartType`: i tipi di grafico disponibili — `line` (a linea, andamento nel tempo), `bar` (a barre) e `pie` (a torta, proporzioni tra categorie).
- `DynamicChartField`: il "mattoncino" grafico — id, etichetta, tipo, colore, estremi dell'asse Y (`min`/`max`) e quanti punti tenere in memoria (`maxPoints`, una "finestra scorrevole": oltre questo numero, i valori più vecchi vengono scartati automaticamente).
- `ChartSlice`: una singola fetta di un grafico a torta (etichetta, valore, colore).

I grafici oggi mostrati nella pagina Listener sono elencati nella lista `receiverChartSchema`, in fondo allo stesso file (sezione 7.3, subito sotto `receiverPageSchema`):

```dart
final List<DynamicChartField> receiverChartSchema = [
  DynamicChartField(
    id: 'sliderRx',
    label: 'Andamento nel tempo — Slider ricevuto',
    type: ChartType.line,
    color: AppColors.primary,
    min: 0,
    max: 100,
    maxPoints: 30,
  ),
  DynamicChartField(
    id: 'numberSliderRx',
    label: 'Andamento nel tempo — Slider con Step ricevuto',
    type: ChartType.bar,
    color: AppColors.success,
    min: 0,
    max: 100,
    maxPoints: 20,
  ),
];
```

Nota l'`id` del primo grafico (`sliderRx`): è **lo stesso** id usato dallo slider di `receiverPageSchema` (sezione 12) — questo è ciò che collega un grafico al campo corrispondente. Quando arriva un pacchetto OSC con quell'id, `receiver_osc_page.dart` aggiorna sia lo slider sia lo storico del grafico. Non è obbligatorio avere entrambi: il secondo grafico (`numberSliderRx`, a barre) oggi esiste solo come grafico, senza un campo "in sola lettura" abbinato con lo stesso id.

### 13.2 Come funziona l'aggiornamento

Ogni `DynamicChartField` ha un metodo `addValue(v)`: aggiunge un nuovo valore alla serie e, se si supera `maxPoints`, scarta automaticamente il valore più vecchio. Non aggiorna da sola lo schermo: va sempre richiamata dentro un `setState(() {...})` nella pagina che la usa (esattamente come si fa con `field.value = ...` per i campi del form).

Per i grafici a torta (`ChartType.pie`) non c'è uno storico da far scorrere: si usa invece `setSlices([...])` per sostituire tutte le fette in un colpo solo, quando cambia la "fotografia" delle proporzioni.

### 13.3 Come aggiungere un nuovo grafico

1. Apri `lib/form_schema.dart` (sezione 7.3, in fondo al file) e aggiungi una riga `DynamicChartField` a `receiverChartSchema` (o a una nuova lista, se il grafico serve in un'altra pagina), scegliendo `type` tra `line`, `bar` e `pie`.
2. Se vuoi ANCHE un campo "in sola lettura" (slider o area di testo) abbinato allo stesso dato, usa lo stesso `id` di una riga in `receiverPageSchema` (sezione 12): `receiver_osc_page.dart` collega automaticamente campo e grafico per id. Non è obbligatorio: un grafico può benissimo esistere da solo, senza un campo abbinato.
3. In qualunque altra pagina, per disegnare il grafico basta chiamare `buildDynamicChart(ilTuoGrafico)` — nessun'altra configurazione necessaria.

Esempio — grafico a linea per un sensore di temperatura ricevuto via OSC con id `temperatura`:

```dart
DynamicChartField(
  id: 'temperatura',
  label: 'Temperatura',
  type: ChartType.line,
  color: AppColors.error,
  min: -20,
  max: 50,
  maxPoints: 40,
),
```

Esempio — grafico a torta con dati statici (assegnati "a mano", non da OSC):

```dart
final distribuzione = DynamicChartField(
  id: 'distribuzioneChart',
  label: 'Distribuzione risposte',
  type: ChartType.pie,
);

// altrove, dentro un setState:
distribuzione.setSlices([
  ChartSlice(label: 'Sì', value: 70, color: AppColors.success),
  ChartSlice(label: 'No', value: 30, color: AppColors.error),
]);
```

### 13.4 Aggiungere un tipo di grafico nuovo

`fl_chart` supporta anche altri tipi (es. scatter, radar) non ancora collegati a `buildDynamicChart`. Per aggiungerne uno: apri `lib/chart_builder.dart`, aggiungi il nuovo valore a `ChartType` (in `form_schema.dart`, sezione 6) e un nuovo `case` nello switch di `buildDynamicChart`, seguendo lo stesso schema già usato per `line`/`bar`/`pie` (una funzione privata `_buildXxxChart` che legge i dati dal campo e ritorna il widget `fl_chart` corrispondente).

---

## 14. Come eseguire i test

Il progetto include sia **test automatici** (scritti con `flutter_test`, verificano che il codice si comporti come previsto) sia uno **script di test manuale** (per vedere l'app "in azione" con dati finti, senza un visore vero collegato). Non serve capire il codice per usarli: bastano i comandi qui sotto.

### 14.1 Test automatici (`flutter test`)

Si trovano nella cartella `test/` e si lanciano dal terminale, dalla cartella del progetto:

```
flutter test
```

Questo comando esegue **tutti** i test del progetto in pochi secondi e stampa un riepilogo (quanti passati, quanti falliti). Per lanciare un singolo file di test:

```
flutter test test/form_serializer_test.dart
flutter test test/osc_sender_test.dart
flutter test test/widget_test.dart
```

Cosa verificano:

| File di test | Cosa controlla |
|---|---|
| `test/widget_test.dart` | Che l'app si avvii senza errori (test "di base", già presente prima di queste modifiche). |
| `test/form_serializer_test.dart` | Che `FormSerializer` converta correttamente ogni tipo di valore (numeri, booleani, colori, date, orari, range, xyPad, dropdown multiplo) in testo e viceversa, senza perdere né corrompere i dati. |
| `test/osc_sender_test.dart` | Che `OscSender.sendForm` costruisca pacchetti OSC corretti: apre un vero socket UDP in ascolto su `127.0.0.1` (come farebbe il visore), fa inviare dei dati, e controlla byte per byte che l'indirizzo, i tipi (`i`/`f`/`s`) e i valori siano quelli attesi. Controlla anche i casi d'errore (indirizzo senza "/", IP di destinazione vuoto) e che più campi producano messaggi separati e nell'ordine giusto. |

Se un test fallisce dopo una modifica al codice, il messaggio d'errore nel terminale indica esattamente quale controllo (`expect(...)`) non è passato: è il primo posto dove guardare per capire cosa si è rotto.

Non serve un dispositivo/emulatore collegato per lanciare questi test: girano "a secco" sul computer.

### 14.2 Test manuale in tempo reale (`tools/test_osc_sender.py`)

Questo non è un test automatico: è uno script che invia dati OSC finti in continuazione, così puoi guardare l'app reagire dal vivo — utile soprattutto per provare la pagina Listener (sezione 12) senza dover collegare un visore VR vero.

Richiede solo Python 3 (già presente su macOS; nessuna libreria da installare).

Procedura:

1. Avvia l'app (es. `flutter run -d macos`) e apri la pagina "Ricevi OSC".
2. In un **secondo** terminale (lascia l'app in esecuzione nel primo), lancia:
   ```
   python3 tools/test_osc_sender.py
   ```
3. Guarda la pagina Listener dell'app: ogni 2 secondi circa vedrai lo slider `sliderRx` muoversi da solo, l'area di testo `textAreaRx` cambiare frase, il grafico a barre `numberSliderRx` aggiornarsi, e nuove righe comparire nel registro messaggi sotto.
4. Premi `Ctrl+C` nel terminale dello script per fermare l'invio.

Opzioni disponibili (facoltative):

```
python3 tools/test_osc_sender.py --ip 127.0.0.1 --port 9000 --interval 2 --once
```

| Opzione | A cosa serve |
|---|---|
| `--ip` | IP del computer con l'app in esecuzione (default `127.0.0.1`, cioè "questo stesso computer": va bene per i test in locale) |
| `--port` | Porta UDP di ascolto (default `9000`, deve combaciare con quella mostrata nella pagina Listener) |
| `--interval` | Secondi di pausa tra un invio e il successivo (default `2`) |
| `--once` | Invia un solo giro di messaggi e poi esce, invece di continuare all'infinito |

---

## 15. Piccolo glossario

- **OSC (Open Sound Control)**: un "linguaggio" per inviare messaggi di controllo in tempo reale (nato per la musica elettronica, oggi usato anche per luci, VR, installazioni interattive).
- **UDP**: il protocollo di rete su cui viaggiano i messaggi OSC in questa app; è veloce ma "spara e dimentica" (non garantisce che il messaggio arrivi sempre, a differenza di altri protocolli come TCP).
- **Hot reload**: mentre l'app gira dal terminale (`flutter run`), premendo il tasto `r` si aggiornano le modifiche al codice senza riavviare tutto da capo (utile solo per modifiche di codice, non per le immagini negli assets).
- **Widget**: in Flutter, ogni elemento grafico (un pulsante, una casella di testo, un'intera pagina) è un "widget".
- **Schema**: nel contesto di questa app, la lista di `DynamicFormField` che descrive quali campi mostrare in una pagina (es. `formPageSchema`).
