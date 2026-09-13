import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _storage.write(key: 'token', value: token);
  Future<String?> getToken() => _storage.read(key: 'token');

  Future<void> saveEmail(String email) =>
      _storage.write(key: 'email', value: email);
  Future<String?> getEmail() => _storage.read(key: 'email');

  Future<void> saveDeviceName(String deviceName) =>
      _storage.write(key: 'device_name', value: deviceName);
  Future<String?> getDeviceName() => _storage.read(key: 'device_name');

  Future<void> saveUsername(String username) =>
      _storage.write(key: 'username', value: username);
  Future<String?> getUsername() => _storage.read(key: 'username');

  Future<void> saveLanguage(String? languageCode) => languageCode == null
      ? _storage.delete(key: 'language')
      : _storage.write(key: 'language', value: languageCode);
  Future<String?> getLanguage() => _storage.read(key: 'language');

  Future<void> clearAll() => _storage.deleteAll();
}
