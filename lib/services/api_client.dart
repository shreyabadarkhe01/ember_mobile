import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.1.4:8081/api';


  // ── Token management ──────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<void> saveUserId(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('user_id', userId);
}

static Future<int?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('user_id');
}

static Future<void> clearUserId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_id');
}

  // ── Base headers ──────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── HTTP methods ──────────────────────────────────────────

  static Future<http.Response> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return response;
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body,
    {bool auth = true}) async {
  final url = '$baseUrl$path';
  print('=== POST $url ===');
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    print('=== Response: ${response.statusCode} ${response.body} ===');
    return response;
  } catch (e) {
    print('=== HTTP error: $e ===');
    rethrow;
  }
}

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return response;
  }

  static Future<http.Response> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return response;
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) async {
  return await http.patch(
    Uri.parse('$baseUrl$path'),
    headers: await _headers(),
    body: jsonEncode(body),
  );
  }

}