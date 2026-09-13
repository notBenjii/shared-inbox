import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiService {
  final String serverUrl;
  final String token;

  ApiService({required this.serverUrl, required this.token});

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final response = await http.get(
      Uri.parse('$serverUrl/items'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch items');
    }
  }

  Future<void> sendItem(String content, String deviceName) async {
    final response = await http.post(
      Uri.parse('$serverUrl/items'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content, 'device_name': deviceName}),
    );
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, 'Failed to send item');
    }
  }

  Future<void> logout() async {
    final response = await http.delete(
      Uri.parse('$serverUrl/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Failed to logout');
    }
  }

  Future<void> deleteItem(int itemId) async {
    final response = await http.delete(
      Uri.parse('$serverUrl/items/$itemId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Failed to delete item');
    }
  }

  Future<void> updateUsername(String username) async {
    final response = await http.patch(
      Uri.parse('$serverUrl/accounts/username'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username}),
    );
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Failed to update username');
    }
  }

  Future<String> createPairingCode() async {
    final response = await http.post(
      Uri.parse('$serverUrl/pairing-codes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['code'] as String;
    } else {
      throw ApiException(response.statusCode, 'Failed to create pairing code');
    }
  }
}

class AuthApiService {
  final String serverUrl;

  AuthApiService({required this.serverUrl});

  Future<String> register(
    String email,
    String authVerifier,
    String salt,
    String username,
  ) async {
    final response = await http.post(
      Uri.parse('$serverUrl/accounts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'auth_verifier': authVerifier,
        'salt': salt,
        'username': username,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['token'] as String;
    } else {
      throw ApiException(response.statusCode, 'Failed to register');
    }
  }

  Future<String> login(String email, String authVerifier) async {
    final response = await http.post(
      Uri.parse('$serverUrl/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'auth_verifier': authVerifier}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'] as String;
    } else {
      final retryAfterHeader = response.headers['retry-after'];
      final retryAfter = retryAfterHeader != null
          ? int.tryParse(retryAfterHeader)
          : null;
      throw ApiException(
        response.statusCode,
        'Failed to login',
        retryAfterSeconds: retryAfter,
      );
    }
  }

  Future<String> fetchSalt(String email) async {
    final uri = Uri.parse('$serverUrl/accounts/salt')
        .replace(queryParameters: {'email': email});
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['salt'] as String;
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch salt');
    }
  }

  Future<Map<String, String>> redeemPairingCode(
    String serverUrl,
    String code,
  ) async {
    final response = await http.post(
      Uri.parse('$serverUrl/pairing-codes/$code/redeem'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'token': data['token'] as String,
        'server_url': data['server_url'] as String,
      };
    } else {
      throw ApiException(response.statusCode, 'Failed to redeem code');
    }
  }
}
