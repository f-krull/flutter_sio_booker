import 'package:flutter/material.dart';
import 'package:lcbc_athletica_booker/screens/home.dart';
import 'package:lcbc_athletica_booker/screens/login.dart';
import 'package:lcbc_athletica_booker/whishlistcache.dart';
import 'package:provider/provider.dart';
import 'db.dart';
import 'dbsettings.dart';
import 'dbwhishlist.dart';
import 'helpers.dart';
import 'reservationscache.dart';
import 'screens/workouts.dart';
import 'workout.dart';

// todo
// schedule booking
//

// static

// Future<void> bla() async {
//   await AndroidAlarmManager.periodic(
//       const Duration(seconds: 15), kAlarmId, doStuff);
// }

// save access token in shared prefs
// save workout data in shared prefs with alarm id as key
// schedule alarm for next avail booking
// when alarm is triggered, do booking

// final prefs = await SharedPreferences.getInstance();
//  int currentCount = prefs.getInt(countKey) ?? 0;
//     await prefs.setInt(countKey, currentCount + 1);
// This will be null if we're running in the background.
// uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
// uiSendPort?.send(null);

// await prefs.reload();

// https://stackoverflow.com/questions/66590587/flutter-android-alarm-manager-plugin-cant-pass-a-parameter-to-a-callback-functi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ladb = await LaDb.create();
  final dbwl = DbWhishlist(ladb);
  final dbsettings = DbSettings(ladb);
  final whishlist = WhishlistCache(dbwl);
  final reservations = ReservationsCache(whishlist);
  await ladb.init();
  await whishlist.init();
  bool hasLogin = dbsettings.isDef(DbSettings.ACCESS_TOKEN_STR);
  runApp(
    MultiProvider(
      providers: [
        Provider<DbWhishlist>(create: (_) => dbwl),
        Provider<DbSettings>(create: (_) => dbsettings),
        ChangeNotifierProvider<ReservationsCache>(
          create: (context) {
            // get reservations on app start
            reservations.update(context);
            return reservations;
          },
          lazy: false,
        ),
        ChangeNotifierProvider<WhishlistCache>(create: (context) => whishlist),
      ],
      child: LaApp(
          firstScreen: hasLogin ? const HomeScreen() : const LoginScreen()),
    ),
  );
}

class LaApp extends StatelessWidget {
  final Widget firstScreen;
  const LaApp({Key? key, required this.firstScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: firstScreen,
    );
  }
}

class SelectDateScreen extends StatelessWidget {
  const SelectDateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: CalendarDatePicker(
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 120)),
          initialDate: DateTime.now().add(const Duration(days: 5)),
          onDateChanged: (date) =>
              {replacePage(context, ChooseWorkoutScreen(date: date))},
        ));
  }
}

class ShowWorkoutScreen extends StatelessWidget {
  final Workout workout;

  const ShowWorkoutScreen({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(workout.name),
          Text(workout.date.toString()),
          Text(workout.centerName),
          Text(workout.centerId),
          Text(workout.id.toString()),
          ElevatedButton(
              onPressed: () => {
                    showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 14)),
                      initialDate: DateTime.now(),
                    )
                  },
              child: const Text("Book"))
        ],
      ),
    );
  }
}
