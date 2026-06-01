class Habit {
  final int id;
  final String name;
  final String minimalVersion;
  final String liteVersion;
  final String fullVersion;
  final String status;
  final int streakCount;

  Habit({
    required this.id,
    required this.name,
    required this.minimalVersion,
    required this.liteVersion,
    required this.fullVersion,
    required this.status,
    required this.streakCount,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      minimalVersion: json['minimalVersion'] ?? '',
      liteVersion: json['liteVersion'] ?? '',
      fullVersion: json['fullVersion'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      streakCount: json['streakCount'] ?? 0,
    );
  }

  String versionForEnergy(int energy) {
    if (energy <= 2) return minimalVersion;
    if (energy == 3) return liteVersion;
    return fullVersion;
  }
}