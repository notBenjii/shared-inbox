import 'dart:convert';

import 'package:http/http.dart' as http;

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
      throw Exception('Failed to load items (status ${response.statusCode})');
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
      throw Exception('Failed to send item (status ${response.statusCode})');
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
      throw Exception('Failed to delete item (status ${response.statusCode})');
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
      throw Exception(
        'Failed to create pairing code (status ${response.statusCode})',
      );
    }
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
    throw Exception('Failed to redeem code (status ${response.statusCode})');
  }
}
