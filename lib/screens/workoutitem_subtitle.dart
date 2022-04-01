import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dbsettings.dart';
import '../helpers.dart';
import '../workout.dart';

class WorkoutItemSubTitle extends StatelessWidget {
  final df = DateFormat('EEE dd/MM HH:mm');
  final Workout workout;

  WorkoutItemSubTitle({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookingAvailableDelta = Duration(
        hours: context
            .read<DbSettings>()
            .getInt(DbSettings.BOOKING_AVAILABLE_HOURS_INT));

    final bookingAvailable = workout.date.subtract(bookingAvailableDelta);

    return Consumer<SteamSec>(builder: (BuildContext contxt, sec, __) {
      // todo optimize - no need to re-render if booking is not available
      final timeNow = DateTime.now();
      final bool isAvailableForBooking = bookingAvailable.isBefore(timeNow);
      return Text(df.format(workout.date.toLocal()) +
          "  " +
          (!isAvailableForBooking
              ? "opens in: " +
                  printDuration(bookingAvailable.difference(timeNow))
              : "ready (${workout.reservationsCount}/${workout.maxReservations})"));
    });
  }
}
