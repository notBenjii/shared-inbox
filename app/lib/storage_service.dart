import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveCredentials(String serverUrl, String token) async {
    await _storage.write(key: 'server_url', value: serverUrl);
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getServerUrl() => _storage.read(key: 'server_url');
  Future<String?> getToken() => _storage.read(key: 'token');

  Future<void> saveDeviceName(String deviceName) => _storage.write(key: 'device_name', value: deviceName);
  Future<String?> getDeviceName() => _storage.read(key: 'device_name');

  Future<void> clearAll() => _storage.deleteAll();
}