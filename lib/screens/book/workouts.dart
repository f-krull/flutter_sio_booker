import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lcbc_athletica_booker/screens/book/workoutlist.dart';
import 'package:lcbc_athletica_booker/whishlistcache.dart';
import 'package:provider/provider.dart';

import '../../backgroundbooker.dart';
import '../../dbsettings.dart';
import '../../helpers.dart';
import '../../reservationscache.dart';
import '../../sioapi.dart';
import '../../workout.dart';
import '../workoutitem_subtitle.dart';

class ChooseWorkoutScreen extends StatefulWidget {
  final DateTime date;
  const ChooseWorkoutScreen({Key? key, required this.date}) : super(key: key);

  @override
  State<ChooseWorkoutScreen> createState() => _ChooseWorkoutScreenState();
}

class _ChooseWorkoutScreenState extends State<ChooseWorkoutScreen> {
  late DateTime date;
  String query = "";
  static const String centerAll = "All centers";
  String selectedCenter = centerAll;
  late Future<List<Workout>> fWorkouts;
  List<String> centers = [centerAll];

  @override
  void initState() {
    setDay(widget.date);
    super.initState();
  }

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

  void setDay(DateTime d) {
    date = d;
    fWorkouts = () async {
      // fetch workout
      // set state - hmm, do we set state from render()?...
      final workouts = await fetchWorkouts(dateFrom: d, dateTo: d);
      final c = workouts
          .map((e) => e.centerName.replaceAll("Athletica ", ""))
          .toList();
      c.sort();
      setState(() {
        centers = {centerAll, ...centers, ...c}.toList();
      });
      return workouts;
    }();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE dd. MMM');
    const oneDay = Duration(days: 1);

    return LaScaffold(
      title: df.format(date),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
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
                Expanded(
                    child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    hintText: 'search',
                  ),
                  onChanged: (v) {
                    setState(() {
                      query = v;
                    });
                  },
                )),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Expanded(
                child: FutureBuilder<List<Workout>>(
                    future: fWorkouts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasData) {
                        final workouts = snapshot.data!;
                        // // filter by query
                        List<Workout> filteredWorkouts = query == ""
                            ? workouts
                            : searchWodData(workouts, query);
                        // filter selected center ?
                        filteredWorkouts = selectedCenter == centerAll
                            ? filteredWorkouts
                            : filteredWorkouts
                                .where((e) =>
                                    e.centerName.contains(selectedCenter))
                                .toList();

                        return Consumer<ReservationsCache>(
                            builder: (context, reservationsCache, child) =>
                                Consumer<WhishlistCache>(
                                    builder: (context, whishlistCache, child) {
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
                                  return Column(children: [
                                    Expanded(
                                        child: (WorkoutList(
                                            workouts: filteredWorkouts,
                                            bookedWorkouts: bookedWorkouts,
                                            whishlistWorkouts:
                                                whishlistWorkouts)))
                                  ]);
                                }));
                      }
                      return Center(child: Text(snapshot.error.toString()));
                    })),
          ])),
      bottomNav: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NavButton(
              label: "prev",
              onClick: () => {
                    setState(() {
                      setDay(date.subtract(oneDay));
                    })
                  }),
          NavButton(
              label: "next",
              onClick: () => {
                    setState(() {
                      setDay(date.add(oneDay));
                    })
                  })
        ]
            .map((e) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: e)))
            .toList(),
      ),
    );
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

  const BookButton(
      {Key? key,
      required this.workout,
      required this.bookedWorkoutIds,
      required this.whishlistWorkoutIds})
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
                      "Booked \"${workout.name}\" at ${workout.centerName}, ${kDateFormatEEEddMMHHmm.format(workout.date.toLocal())}"),
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("D: Unable to book \"${workout.name}\" ($e)")));
              }
            };
          }
          return () async {
            // TODO: book or queue depending on time
            await context.read<WhishlistCache>().add(workout);
            await BackgroundBooker.init(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Added \"${workout.name}\" at ${workout.centerName}, ${kDateFormatEEEddMMHHmm.format(workout.date.toLocal())}"),
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


//INPUT

