class WorkoutId {
  final String centerId;
  final int classId;

  WorkoutId({required this.centerId, required this.classId});

  @override
  bool operator ==(other) {
    return other is WorkoutId &&
        other.centerId == centerId &&
        other.classId == classId;
  }

  String toString() => "$centerId/$classId";

  @override
  int get hashCode => classId;

  factory WorkoutId.fromWorkout(Workout w) =>
      WorkoutId(centerId: w.centerId, classId: w.id);
}

class Workout {
  final int id;
  final String name;
  final DateTime date;
  final String centerName;
  final String centerId;
  final String instructorName;

  final int reservationsCount;
  final int maxReservations;

  const Workout({
    required this.id,
    required this.name,
    required this.date,
    required this.centerName,
    required this.centerId,
    required this.reservationsCount,
    required this.maxReservations,
    required this.instructorName,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
        id: json["id"],
        name: json["name"],
        date: DateTime.parse(json["startTime"]),
        centerName: json["centerName"],
        centerId: json["centerId"],
        reservationsCount: json["reservationsCount"],
        maxReservations: json["maxReservations"],
        instructorName: json["instructorName"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "date": date.toIso8601String(),
      "centerName": centerName,
      "centerId": centerId,
      "instructorName": instructorName,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> json) {
    return Workout(
        id: json["id"],
        name: json["name"],
        date: DateTime.parse(json["date"]),
        centerName: json["centerName"],
        centerId: json["centerId"],
        reservationsCount: 0,
        maxReservations: 0,
        instructorName: json["instructorName"]);
  }
}
