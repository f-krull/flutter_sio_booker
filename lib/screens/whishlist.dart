import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lcbc_athletica_booker/dbsettings.dart';
import 'package:lcbc_athletica_booker/dbwhishlist.dart';
import 'package:lcbc_athletica_booker/helpers.dart';
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
    final df = DateFormat('EEE dd/MM HH:mm');
    final timeNow = DateTime.now();
    final bookingAvailable = workout.date.subtract(bookingAvailableDelta);
    final bool isAvailableForBooking = bookingAvailable.isBefore(timeNow);
    return ListTile(
        tileColor: isAvailableForBooking ? Colors.green[50] : Colors.grey[100],
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text("${workout.name}  (${workout.instructorName})"),
        leading: Text(workout.centerName.replaceFirst("Athletica", "")),
        // trailing: TextButton(
        //     style: ButtonStyle(
        //       foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        //       backgroundColor:
        //           MaterialStateProperty.all<Color>(Colors.lightBlue),
        //     ),
        //     onPressed: () async {
        //       await context.read<DbWhishlist>().add(workout);
        //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //         content: Text(
        //             "Added \"${workout.name}\" at ${workout.centerName}, ${df.format(workout.date.toLocal())}"),
        //       ));
        //     },
        //     child: const Icon(Icons.star)),
        subtitle: Text(df.format(workout.date.toLocal()) +
            "  " +
            (!isAvailableForBooking
                ? "opens in:" +
                    printDuration(bookingAvailable.difference(timeNow))
                : "ready (${workout.reservationsCount}/${workout.maxReservations})")));
  }
}

class Whishlist extends StatelessWidget {
  final List<Workout> workouts;

  const Whishlist({Key? key, required this.workouts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(
              height: 4,
            ),
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          return WhishlistItem(workout: workouts[index]);
        });
  }
}

class WhishlistScreen extends StatelessWidget {
  const WhishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LaScaffold(
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Expanded(
                  child: FutureBuilder<List<Workout>>(future: (() async {
                final dbs = context.read<DbWhishlist>();
                return await dbs.fetchAll();
              })(), builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Whishlist(workouts: snapshot.data!);
                }
                return const Center(child: CircularProgressIndicator());
              }))
            ])));
  }
}
