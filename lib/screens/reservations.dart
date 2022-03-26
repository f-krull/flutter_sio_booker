import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lcbc_athletica_booker/sioapi.dart';
import 'package:lcbc_athletica_booker/workout.dart';
import 'package:provider/provider.dart';

import '../dbsettings.dart';
import '../helpers.dart';

class ShowReservationsScreen extends StatelessWidget {
  const ShowReservationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LaScaffold(
        body: FutureBuilder<List<Reservation>>(future: (() async {
      final dbs = context.read<DbSettings>();
      final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);
      return await fetchReservations(accessToken);
    })(), builder: (context, snapshot) {
      if (snapshot.hasData) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ReservationsList(reservations: snapshot.data!),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }));
  }
}

class ReservationsList extends StatelessWidget {
  final List<Reservation> reservations;

  const ReservationsList({Key? key, required this.reservations})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final workout = reservations[index];
          final df = DateFormat('EEE dd/MM HH:mm');
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(workout.name),
            trailing: Text(workout.centerName),
            subtitle: Text(df.format(workout.date.toLocal()) +
                "  (${workout.reservationsCount}/${workout.maxReservations})"),
            // onTap: () => {},
          );
        });
  }
}
