import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lcbc_athletica_booker/screens/home.dart';
import 'package:lcbc_athletica_booker/screens/login.dart';
import 'package:lcbc_athletica_booker/whishlistcache.dart';
import 'package:provider/provider.dart';
import 'backgroundbooker.dart';
import 'db.dart';
import 'dbsettings.dart';
import 'dbwhishlist.dart';
import 'helpers.dart';
import 'reservationscache.dart';
import 'screens/workouts.dart';
import 'workout.dart';

// todo
// book directly (from whishlist / from workout list)
// call BackgroundBooker init from relevant places
// cancel booking (from reservations)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
  });
  final ladb = await LaDb.create();
  final dbwl = DbWhishlist(ladb);
  final dbsettings = DbSettings(ladb);
  final whishlist = WhishlistCache(dbwl);
  final reservations = ReservationsCache(whishlist);
  await ladb.init();
  await whishlist.init();
  final secStream =
      Stream<SteamSec>.periodic(const Duration(seconds: 1), (sec) {
    return sec;
  });
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
        Provider<FlutterLocalNotificationsPlugin>(
            create: (_) => flutterLocalNotificationsPlugin),
        StreamProvider<SteamSec>(initialData: 1, create: (_) => secStream)
      ],
      child: LaApp(
          firstScreen: hasLogin ? const HomeScreen() : const LoginScreen()),
    ),
  );
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
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
    return LaScaffold(
        title: "Select date",
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
