import 'dart:convert';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiClient.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await ApiClient.saveToken(data['token']);
      await ApiClient.saveUserId(data['userId']);
      return {'success': true, 'name': data['name']};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Login failed'};
    }
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await ApiClient.post(
      '/auth/register',
      {'name': name, 'email': email, 'password': password},
      auth: false,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Registration failed'};
    }
  }

  static Future<void> logout() async {
    await ApiClient.clearToken();
    await ApiClient.clearUserId();
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null;
  }

  static Future<int?> getUserId() async {
    return await ApiClient.getUserId();
  }
}