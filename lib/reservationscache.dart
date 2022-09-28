import 'package:flutter/widgets.dart';
import 'package:lcbc_athletica_booker/reservation.dart';
import 'package:lcbc_athletica_booker/whishlistcache.dart';
import 'package:provider/provider.dart';

import 'dbsettings.dart';
import 'helpers.dart';
import 'sioapi.dart';
import 'notifications.dart' as noti;

enum ReservationsCacheState {
  init,
  loading,
  error,
  ready,
}

class ReservationsCache with ChangeNotifier {
  final WhishlistCache whishlistCache;
  List<Reservation> reservations = [];
  ReservationsCacheState state = ReservationsCacheState.init;

  ReservationsCache(this.whishlistCache);

  Future<void> update(BuildContext context) async {
    final dbs = context.read<DbSettings>();
    final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);

    await _update(accessToken);
    // prune whishlist
    whishlistCache.update(reservations);
    // update notifications
    final notification = noti.Notification();
    final notifiyBeforeMin =
        dbs.getInt(DbSettings.NOTIFY_BEFORE_WORKOUT_MIN_INT);

    try {
      await notification.init();
      notification.clear();
    } catch (e) {
      print("error notifications: $e");
    }
    for (var reservation in reservations) {
      final notifyDate =
          reservation.date.subtract(Duration(minutes: notifiyBeforeMin));
      print("scheduled notification at $notifyDate");
      notification.showAt(
          date: notifyDate,
          title:
              "Your workout starts at ${kDateFormatEEEddMMHHmm.format(reservation.date.toLocal())} (${reservation.centerName})",
          body: "For any last-minute changes check the app");
    }

    return;
  }

  Future<void> _update(String accessToken) async {
    if (state == ReservationsCacheState.loading) {
      return;
    }
    state = ReservationsCacheState.loading;
    notifyListeners();
    final r = await fetchReservations(accessToken);
    reservations = r;
    state = ReservationsCacheState.ready;
    notifyListeners();
  }
}
