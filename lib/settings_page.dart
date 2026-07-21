import 'package:flutter/material.dart';
import 'package:osc_controller/widgets/custom_app_bar.dart';
import 'device_settings.dart';
import 'config_service.dart';
import 'app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Se un import da un'altra pagina cambia le impostazioni, aggiorna i campi.
    configRevision.addListener(_loadSettings);
  }

  @override
  void dispose() {
    configRevision.removeListener(_loadSettings);
    _ipController.dispose();
    _portController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await DeviceSettings().load();
    if (!mounted) return;
    setState(() {
      _ipController.text = settings['ip'];
      _portController.text = settings['port'].toString();
      _addressController.text = settings['address'];
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    await DeviceSettings().save(
      ip: _ipController.text,
      port: int.parse(_portController.text),
      address: _addressController.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Impostazioni salvate')));
  }

  Future<void> _exportConfig() async {
    try {
      final savedPath = await ConfigService.exportToFile();
      if (savedPath == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Esportato in: $savedPath'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Errore esportazione: $e'),
        ),
      );
    }
  }

  Future<void> _importConfig() async {
    try {
      final imported = await ConfigService.importFromFile();
      if (!imported || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Importazione completata'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Errore importazione: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP del dispositivo',
                      ),
                      keyboardType: TextInputType.text,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Inserisci IP' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(labelText: 'Porta OSC'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || int.tryParse(v) == null
                          ? 'Inserisci porta valida'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Indirizzo OSC',
                        hintText: '/vr',
                        helperText:
                            'Deve iniziare con "/" (es. "/vr"): è il prefisso di ogni messaggio OSC inviato.',
                      ),
                      // Controlla SUBITO, al salvataggio, che l'indirizzo sia
                      // valido: senza questo controllo, un indirizzo vuoto o
                      // senza "/" viene salvato senza errori, e il problema
                      // emerge solo più tardi (e in modo criptico) quando si
                      // prova davvero a inviare un dato via OSC, con
                      // l'errore "OSC base address must start with '/'".
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Inserisci indirizzo OSC';
                        }
                        if (!v.startsWith('/')) {
                          return 'Deve iniziare con "/" (es. "/vr")';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: isMobile ? double.infinity : 300,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Salva'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: ElevatedButton(
                      onPressed: _exportConfig,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Esporta JSON'),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 0, width: isMobile ? 0 : 12),
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: ElevatedButton(
                      onPressed: _importConfig,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Importa JSON'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
