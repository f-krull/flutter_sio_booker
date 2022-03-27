import 'package:flutter/widgets.dart';
import 'package:lcbc_athletica_booker/reservation.dart';
import 'package:provider/provider.dart';

import 'dbsettings.dart';
import 'sioapi.dart';

enum ReservationsCacheState {
  init,
  loading,
  error,
  ready,
}

class ReservationsCache with ChangeNotifier {
  List<Reservation> reservations = [];
  ReservationsCacheState state = ReservationsCacheState.init;

  Future<void> update(BuildContext context) async {
    final dbs = context.read<DbSettings>();
    final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);
    return await _update(accessToken);
  }

  Future<void> _update(String accessToken) async {
    if (state == ReservationsCacheState.loading) {
      return;
    }
    reservations.clear();
    state = ReservationsCacheState.loading;
    notifyListeners();
    reservations = await fetchReservations(accessToken);
    state = ReservationsCacheState.ready;
    notifyListeners();
  }
}
