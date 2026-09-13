import 'dart:math';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'api_service.dart';
import 'storage_service.dart';

final _algorithm = Argon2id(
  parallelism: 1,
  memory: 19456,
  iterations: 2,
  hashLength: 32,
);

String _bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

List<int> _hexToBytes(String hex) {
  final result = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    result.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return result;
}

class AuthService {
  final AuthApiService _authApiService;
  final StorageService _storageService = StorageService();

  AuthService(this._authApiService);

  Future<void> register(String email, String password, String username) async {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final salt = _bytesToHex(saltBytes);

    final derivedKey = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: saltBytes,
    );
    final authVerifier = _bytesToHex(await derivedKey.extractBytes());

    final result = await _authApiService.register(email, authVerifier, salt, username);

    await _storageService.saveToken(result.token);
    await _storageService.saveEmail(email);
    await _storageService.saveUsername(result.username);
  }

  Future<void> login(String email, String password) async {
    final salt = await _authApiService.fetchSalt(email);
    final saltBytes = _hexToBytes(salt);

    final derivedKey = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: saltBytes,
    );
    final authVerifier = _bytesToHex(await derivedKey.extractBytes());

    final result = await _authApiService.login(email, authVerifier);

    await _storageService.saveToken(result.token);
    await _storageService.saveEmail(email);
    await _storageService.saveUsername(result.username);
  }
}