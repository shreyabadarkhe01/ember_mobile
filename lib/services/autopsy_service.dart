import '../services/api_client.dart';
import 'dart:convert';

class AutopsyService {
  static Future<Map<String, dynamic>> getAutopsy(int userId) async {
    final response = await ApiClient.get('/users/$userId/autopsy');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load autopsy: ${response.statusCode}');
  }
}