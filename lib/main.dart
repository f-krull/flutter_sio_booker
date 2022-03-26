import 'package:flutter/material.dart';
import 'package:lcbc_athletica_booker/screens/home.dart';
import 'package:lcbc_athletica_booker/screens/login.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'dbsettings.dart';
import 'dbwhishlist.dart';
import 'helpers.dart';
import 'screens/workouts.dart';
import 'workout.dart';

// todo
// schedule booking
//

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ladb = await LaDb.create();
  final dbwl = DbWhishlist(ladb);
  final dbsettings = DbSettings(ladb);
  await ladb.init();
  bool hasLogin = dbsettings.isDef(DbSettings.ACCESS_TOKEN_STR);
  runApp(
    MultiProvider(
      providers: [
        Provider<DbWhishlist>(create: (_) => dbwl),
        Provider<DbSettings>(create: (_) => dbsettings),
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
