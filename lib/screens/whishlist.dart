import 'package:flutter/material.dart';
import 'package:lcbc_athletica_booker/backgroundbooker.dart';
import 'package:lcbc_athletica_booker/dbsettings.dart';
import 'package:lcbc_athletica_booker/helpers.dart';
import 'package:lcbc_athletica_booker/whishlistcache.dart';
import 'package:provider/provider.dart';

import '../workout.dart';

class WhishlistItem extends StatelessWidget {
  final Workout workout;
  const WhishlistItem({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookingAvailableDelta = Duration(
        hours: context
            .read<DbSettings>()
            .getInt(DbSettings.BOOKING_AVAILABLE_HOURS_INT));

    final bookingAvailable = workout.date.subtract(bookingAvailableDelta);
    return Consumer<SteamSec>(builder: (BuildContext contxt, sec, __) {
      final timeNow = DateTime.now();
      final bool isAvailableForBooking = bookingAvailable.isBefore(timeNow);

      return Card(
          shape: kListItemShape,
          color: isAvailableForBooking ? Colors.grey[300] : Colors.red[100],
          child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text("${workout.name}  (${workout.instructorName})"),
              leading: Text(workout.centerName.replaceFirst("Athletica", "")),
              subtitle: Text(kDateFormatEEEddMMHHmm
                      .format(workout.date.toLocal()) +
                  "  " +
                  (!isAvailableForBooking
                      ? "opens in: " +
                          printDuration(bookingAvailable.difference(timeNow))
                      : "booking has started - please book manually (${workout.reservationsCount}/${workout.maxReservations})"))));
    });
  }
}

class Whishlist extends StatelessWidget {
  final List<Workout> workouts;

  const Whishlist({Key? key, required this.workouts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: kListSepBuilder,
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return Dismissible(
              key: Key(workout.id.toString()),
              onDismissed: (direction) async {
                await Provider.of<WhishlistCache>(context, listen: false)
                    .remove(workout);
                await BackgroundBooker.init(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Workout "${workout.name}" removed from whish list')));
              },
              child: WhishlistItem(workout: workout));
        });
  }
}

class WhishlistScreen extends StatelessWidget {
  const WhishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LaScaffold(
        title: "My whish list",
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Expanded(child: Consumer<WhishlistCache>(
                  builder: (context, whishlistCache, child) {
                return Whishlist(workouts: whishlistCache.workouts);
              }))
            ])));
  }
}
