import 'dart:convert';
import '../models/checkin.dart';
import 'api_client.dart';

class CheckInService {
  static Future<CheckIn?> getTodayCheckin(int userId) async {
  final response = await ApiClient.get('/users/$userId/checkins/today');
  print('=== today checkin status: ${response.statusCode} body: ${response.body} ===');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Backend might return a list or a single object
    if (data is List) {
      if (data.isEmpty) return null;
      return CheckIn.fromJson(data[0]);
    }
    return CheckIn.fromJson(data);
  }
  return null;
}

  static Future<CheckIn?> createCheckin(int userId, int energyScore) async {
  final response = await ApiClient.post(
    '/users/$userId/checkins',
    {'energyScore': energyScore},
  );
  print('=== create checkin status: ${response.statusCode} body: ${response.body} ===');
  if (response.statusCode == 200 || response.statusCode == 201) {
    final data = jsonDecode(response.body);
    if (data is List) {
      if (data.isEmpty) return null;
      return CheckIn.fromJson(data[0]);
    }
    return CheckIn.fromJson(data);
  }
  return null;
}

static Future<String?> getNudge(int userId, int energyScore) async {
  try {
    final response = await ApiClient.post(
      '/users/$userId/ai/nudge',
      {'energyScore': energyScore},
    );
    print('=== nudge status: ${response.statusCode} body: ${response.body} ===');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['nudge'] as String?;
    }
  } catch (e) {
    print('Nudge call failed: $e');
  }
  return null;
}

}