// device_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSettings {
  Future<void> save({
    required String ip,
    required int port,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', ip);
    await prefs.setInt('port', port);
    await prefs.setString('address', address);
  }

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ip': prefs.getString('ip') ?? '',
      'port': prefs.getInt('port') ?? 0,
      'address': prefs.getString('address') ?? '',
    };
  }
}
