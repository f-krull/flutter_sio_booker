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

class Reservation extends Workout {
  Reservation(
      {required int classId,
      required String name,
      required DateTime date,
      required String centerName,
      required String centerId,
      required int reservationsCount,
      required int maxReservations,
      required String instructorName})
      : super(
            id: classId,
            name: name,
            date: date,
            centerName: centerName,
            centerId: centerId,
            reservationsCount: reservationsCount,
            maxReservations: maxReservations,
            instructorName: instructorName);
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
        classId: json["classId"],
        name: json["name"],
        date: DateTime.fromMillisecondsSinceEpoch(json["startTime"]),
        centerName: json["centerName"],
        centerId: json["centerId"],
        reservationsCount: json["reservationsCount"],
        maxReservations: json["maxReservations"],
        instructorName: json["instructorName"]);
  }
}
