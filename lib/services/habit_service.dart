import 'dart:convert';
import '../models/habit.dart';
import 'api_client.dart';

class HabitService {
  static Future<List<Habit>> getHabits(int userId) async {
    final response = await ApiClient.get('/users/$userId/habits');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((h) => Habit.fromJson(h)).toList();
    }
    return [];
  }

  static Future<bool> completeHabit(int userId, int habitId) async {
  final response = await ApiClient.patch(
    '/users/$userId/habits/$habitId/complete',
    {},
  );
  return response.statusCode == 200;
}

static Future<bool> skipHabit(int userId, int habitId) async {
  final response = await ApiClient.patch(
    '/users/$userId/habits/$habitId/skip',
    {},
  );
  return response.statusCode == 200;
}

static Future<bool> resetHabit(int userId, int habitId) async {
  final response = await ApiClient.patch(
    '/users/$userId/habits/$habitId/reset',
    {},
  );
  return response.statusCode == 200;
}

static Future<void> archiveHabit(int userId, int habitId) async {
  print('Calling PATCH for habitId: $habitId, userId: $userId');
  try{final response = await ApiClient.patch(
    '/users/$userId/habits/$habitId',
    {'status': 'ARCHIVED'},
  );
   print('PATCH response: ${response.statusCode} — ${response.body}');}
  // if (response.statusCode != 200) {
  //   throw Exception('Failed to archive habit');
  // }
  catch (e) {
  print('PATCH threw: $e');
}
}

static Future<void> unarchiveHabit(int userId, int habitId) async {
  final response = await ApiClient.patch(
    '/users/$userId/habits/$habitId',
    {'status': 'ACTIVE'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to unarchive habit');
  }
}

}