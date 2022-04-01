import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lcbc_athletica_booker/whishlistcache.dart';
import 'package:provider/provider.dart';

import '../backgroundbooker.dart';
import '../dbsettings.dart';
import '../helpers.dart';
import '../reservationscache.dart';
import '../sioapi.dart';
import '../workout.dart';
import 'workoutitem_subtitle.dart';

class ChooseWorkoutScreen extends StatelessWidget {
  final DateTime date;
  const ChooseWorkoutScreen({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const oneDay = Duration(days: 1);
    final df = DateFormat('EEE dd. MMM');
    return LaScaffold(
        title: df.format(date),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Expanded(
                  child: FutureBuilder<List<Workout>>(
                      future: fetchWorkouts(dateFrom: date, dateTo: date),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Consumer<ReservationsCache>(
                              builder: (context, reservationsCache, child) =>
                                  Consumer<WhishlistCache>(builder:
                                      (context, whishlistCache, child) {
                                    // get booked workouts (or null)
                                    final List<WorkoutId> bookedWorkouts =
                                        reservationsCache.state ==
                                                ReservationsCacheState.ready
                                            ? reservationsCache.reservations
                                                .map((r) => WorkoutId(
                                                    centerId: r.centerId,
                                                    classId: r.id))
                                                .toList()
                                            : [];
                                    final List<WorkoutId> whishlistWorkouts =
                                        whishlistCache.workouts
                                            .map((w) => WorkoutId(
                                                centerId: w.centerId,
                                                classId: w.id))
                                            .toList();
                                    return WorkoutList(
                                        workouts: snapshot.data!,
                                        bookedWorkouts: bookedWorkouts,
                                        whishlistWorkouts: whishlistWorkouts);
                                  }));
                        }
                        return const Center(child: CircularProgressIndicator());
                      })),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  NavButton(
                      label: "prev",
                      onClick: () => replacePage(context,
                          ChooseWorkoutScreen(date: date.subtract(oneDay)))),
                  NavButton(
                      label: "next",
                      onClick: () => replacePage(
                          context, ChooseWorkoutScreen(date: date.add(oneDay))))
                ]
                    .map((e) => Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: e)))
                    .toList(),
              )
            ])));
  }
}

class NavButton extends StatelessWidget {
  final String label;
  final void Function() onClick;

  const NavButton({Key? key, required this.label, required this.onClick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onClick,
      child: Text(label),
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
      ),
    );
  }
}

class BookButton extends StatelessWidget {
  final Workout workout;
  final List<WorkoutId> bookedWorkoutIds;
  final List<WorkoutId> whishlistWorkoutIds;
  final DateFormat df;

  const BookButton(
      {Key? key,
      required this.workout,
      required this.bookedWorkoutIds,
      required this.whishlistWorkoutIds,
      required this.df})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBooked = bookedWorkoutIds
        .any((e) => e.centerId == workout.centerId && e.classId == workout.id);
    final isFav = whishlistWorkoutIds
        .any((e) => e.centerId == workout.centerId && e.classId == workout.id);
    final bool isAvailForBooking = (() {
      final bookingAvailableDelta = Duration(
          hours: context
              .read<DbSettings>()
              .getInt(DbSettings.BOOKING_AVAILABLE_HOURS_INT));
      final bookingAvailable = workout.date.subtract(bookingAvailableDelta);
      final timeNow = DateTime.now();
      final bool isAvailableForBooking = bookingAvailable.isBefore(timeNow);
      return isAvailableForBooking;
    })();

    return TextButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
          backgroundColor: MaterialStateProperty.all<Color>(Color(0x55ffffff)),
        ),
        onPressed: (() {
          if (isBooked || isFav) {
            return null;
          }
          if (isAvailForBooking) {
            return () async {
              final dbs = context.read<DbSettings>();
              final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);
              try {
                await putReservation(workout, accessToken);
                try {
                  await Provider.of<ReservationsCache>(context, listen: false)
                      .update(context);
                } catch (e) {
                  print(e);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "Booked \"${workout.name}\" at ${workout.centerName}, ${df.format(workout.date.toLocal())}"),
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Unable to book \"${workout.name}\" ($e)")));
              }
            };
          }
          return () async {
            // TODO: book or queue depending on time
            await context.read<WhishlistCache>().add(workout);
            await BackgroundBooker.init(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Added \"${workout.name}\" at ${workout.centerName}, ${df.format(workout.date.toLocal())}"),
            ));
          };
        })(),
        child: (() {
          if (isBooked) {
            return const Icon(Icons.check, color: Colors.green);
          }
          if (isFav) {
            return const Icon(Icons.star, color: Colors.red);
          }
          if (isAvailForBooking) {
            return const Icon(Icons.add_box_rounded, color: Colors.blue);
          }
          return const Icon(Icons.star_border_outlined, color: Colors.red);
        })());
  }
}

class WorkoutList extends StatefulWidget {
  final List<Workout> workouts;
  final List<WorkoutId> bookedWorkouts;
  final List<WorkoutId> whishlistWorkouts;

  const WorkoutList(
      {Key? key,
      required this.workouts,
      required this.bookedWorkouts,
      required this.whishlistWorkouts})
      : super(key: key);

  @override
  State<WorkoutList> createState() => _WorkoutListState();
}

class _WorkoutListState extends State<WorkoutList> {
  String query = "";
  static const String centerAll = "All";
  String selectedCenter = centerAll;

  static List<Workout> searchWodData(List<Workout> workouts, String query) {
    query = query.toLowerCase();
    RegExp re = RegExp(" ");
    List<String> queryWords = query.split(re);
    return workouts.where((Workout workout) {
      return queryWords.every((queryWord) {
        bool b = false;
        b = b || workout.name.toLowerCase().contains(queryWord);
        b = b || workout.centerName.toLowerCase().contains(queryWord);
        return b;
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // build list of unique center names
    List<String> centers = [
      centerAll,
      ...widget.workouts
          .map((e) => e.centerName.replaceAll("Athletica ", ""))
          .toSet()
          .toList()
    ];
    // filter by query
    List<Workout> filteredWorkouts =
        query == "" ? widget.workouts : searchWodData(widget.workouts, query);
    // filter selected center ?
    filteredWorkouts = selectedCenter == centerAll
        ? filteredWorkouts
        : filteredWorkouts
            .where((e) => e.centerName.contains(selectedCenter))
            .toList();
    return Column(children: [
      Row(
        children: [
          DropdownButton<String>(
              value: selectedCenter,
              items: centers
                  .map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (String? v) => {
                    setState(() {
                      selectedCenter = v!;
                    })
                  }),
          const SizedBox(
            width: 16,
          ),
          Expanded(child: TextField(
            onChanged: (v) {
              setState(() {
                query = v;
              });
            },
          )),
        ],
      ),
      Expanded(
          child: ListView.separated(
              separatorBuilder: kListSepBuilder,
              itemCount: filteredWorkouts.length,
              itemBuilder: (context, index) {
                final workout = filteredWorkouts[index];
                final df = DateFormat('EEE dd/MM HH:mm');
                return Card(
                    shape: kListItemShape,
                    color: Colors.blue[100],
                    child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(
                            "${workout.name}  (${workout.instructorName})"),
                        leading: Text(
                            workout.centerName.replaceFirst("Athletica", "")),
                        trailing: BookButton(
                            workout: workout,
                            bookedWorkoutIds: widget.bookedWorkouts,
                            whishlistWorkoutIds: widget.whishlistWorkouts,
                            df: df),
                        subtitle: WorkoutItemSubTitle(workout: workout)
                        // onTap: () => {
                        //   Navigator.of(context).push(
                        //     MaterialPageRoute(
                        //         builder: (context) => ShowWorkoutScreen(
                        //               workout: workout,
                        //             )),
                        //   )
                        // },
                        ));
              })),
    ]);
  }
}
