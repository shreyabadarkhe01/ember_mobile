class CheckIn {
  final int id;
  final int energyScore;
  final String? nudgeText;
  final String checkInDate;

  CheckIn({
    required this.id,
    required this.energyScore,
    this.nudgeText,
    required this.checkInDate,
  });

  CheckIn copyWith({String? nudgeText}) {
  return CheckIn(
    id: id,
    energyScore: energyScore,
    nudgeText: nudgeText ?? this.nudgeText,
    checkInDate: checkInDate,
  );
}

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    // checkInDate comes as [2026, 5, 30] from backend
    String dateStr;
    final raw = json['checkInDate'];
    if (raw is List) {
      dateStr = '${raw[0]}-${raw[1].toString().padLeft(2, '0')}-${raw[2].toString().padLeft(2, '0')}';
    } else {
      dateStr = raw.toString();
    }

    return CheckIn(
      id: json['id'],
      energyScore: json['energyScore'],
      nudgeText: json['nudgeText'] ?? json['message'],
      checkInDate: dateStr,
    );
  }
}