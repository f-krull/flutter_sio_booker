import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lcbc_athletica_booker/reservationscache.dart';
import 'package:lcbc_athletica_booker/sioapi.dart';
import 'package:provider/provider.dart';

import '../dbsettings.dart';
import '../helpers.dart';
import '../reservation.dart';

class ShowReservationsScreen extends StatelessWidget {
  const ShowReservationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LaScaffold(
        title: "My reservations",
        body: Consumer<ReservationsCache>(
            builder: (context, reservationsCache, child) {
          if (reservationsCache.state != ReservationsCacheState.ready) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                ReservationsList(reservations: reservationsCache.reservations),
          );
        }));
  }
}

dynamic _getConfirmDelete(Reservation workout, BuildContext context) {
  return (DismissDirection direction) async {
    final bool res = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            // title: Text("Are you sure you wish to unbook \"${worout.name}\"?"),
            title: const Text("Cancel reservation?"),
            content: Text(
                "Cancel reservation for ${workout.name} (${kDateFormatEEEddMMHHmm.format(workout.date.toLocal())} at ${workout.centerName})"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text("Unbook"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ]);
      },
    );
    return res;
  };
}

class ReservationsList extends StatelessWidget {
  final List<Reservation> reservations;

  const ReservationsList({Key? key, required this.reservations})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: kListSepBuilder,
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final Reservation reservation = reservations[index];
          return Dismissible(
              key: Key(reservation.id.toString()),
              confirmDismiss: _getConfirmDelete(reservation, context),
              onDismissed: (_) async {
                final dbs = context.read<DbSettings>();
                final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);
                try {
                  await deleteReservation(reservation, accessToken);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Unbooked \"${reservation.name}\" at ${reservation.centerName}, ${kDateFormatEEEddMMHHmm.format(reservation.date.toLocal())}"),
                  ));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Unable to cancel reservation for \"${reservation.name}\" ($e)")));
                  print(e);
                }
                await Provider.of<ReservationsCache>(context, listen: false)
                    .update(context);
              },
              child: Card(
                  shape: kListItemShape,
                  color: reservation.queuePosition > 0
                      ? Colors.grey[300]
                      : Colors.green[100],
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(reservation.name),
                    trailing: Text(reservation.centerName),
                    subtitle: Text(kDateFormatEEEddMMHHmm
                            .format(reservation.date.toLocal()) +
                        "  (${reservation.reservationsCount}/${reservation.maxReservations})${reservation.queuePosition > 0 ? "\nYour place in queue: ${reservation.queuePosition}" : ""}"),
                    // onTap: () => {},
                  )));
        });
  }
}
