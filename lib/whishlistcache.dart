import 'package:flutter/widgets.dart';
import 'package:lcbc_athletica_booker/dbwhishlist.dart';
import 'package:lcbc_athletica_booker/reservation.dart';

import 'workout.dart';

class _WcId {
  final int classId;
  final String centerId;

  _WcId(this.classId, this.centerId);

  @override
  bool operator ==(other) {
    return other is _WcId &&
        other.centerId == centerId &&
        other.classId == classId;
  }

  @override
  int get hashCode => classId;
}

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

  get workouts => _workouts;

  Future<void> update(List<Reservation> reservations) async {
    final Set<_WcId> resIds =
        reservations.map((e) => _WcId(e.id, e.centerId)).toSet();
    List<Workout> toRemove = _workouts.where((w) {
      final b = resIds.contains(_WcId(w.id, w.centerId));
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
