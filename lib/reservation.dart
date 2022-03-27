import 'workout.dart';

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
