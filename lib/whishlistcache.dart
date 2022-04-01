import 'package:flutter/widgets.dart';
import 'package:lcbc_athletica_booker/dbwhishlist.dart';
import 'package:lcbc_athletica_booker/reservation.dart';

import 'workout.dart';

class WhishlistCache with ChangeNotifier {
  final DbWhishlist dbw;
  List<Workout> _workouts = [];

  WhishlistCache(this.dbw);

  init() async {
    _workouts = await dbw.fetchAll();
    notifyListeners();
  }

  Future<int> add(Workout w) async {
    final r = await dbw.add(w);
    _workouts = await dbw.fetchAll();
    notifyListeners();
    return r;
  }

  Future<int> remove(Workout w) async {
    final r = await dbw.remove(w);
    _workouts = await dbw.fetchAll();
    notifyListeners();
    return r;
  }

  List<Workout> get workouts => _workouts;

  Future<void> update(List<Reservation> reservations) async {
    final Set<WorkoutId> resIds = reservations
        .map((e) => WorkoutId(classId: e.id, centerId: e.centerId))
        .toSet();
    List<Workout> toRemove = _workouts.where((w) {
      final b = resIds.contains(WorkoutId(classId: w.id, centerId: w.centerId));
      return b;
    }).toList();
    if (toRemove.isNotEmpty) {
      // persist
      for (var i = 0; i < toRemove.length; i++) {
        await dbw.remove(toRemove[i]);
      }
      // sync
      _workouts = await dbw.fetchAll();
    }
    notifyListeners();
  }
}
