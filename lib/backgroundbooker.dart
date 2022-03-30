// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_isolate/flutter_isolate.dart';
// import 'package:lcbc_athletica_booker/dbwhishlist.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'dbsettings.dart';
// import 'workout.dart';
// import 'package:path_provider/path_provider.dart';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/widgets.dart';
import 'package:lcbc_athletica_booker/sioapi.dart';
import 'package:lcbc_athletica_booker/whishlistcache.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dbsettings.dart';
import 'dbwhishlist.dart';
import 'workout.dart';

const _kKeyAccessTokenStr = "accessToken";

// const int _kAlarmId = 0;

// class _CommData {
//   final String accessToken;
//   final Map<int, Workout> workouts;

//   _CommData(this.accessToken, this.workouts);

//   Future<void> writeData() async {
//     final prefs = await SharedPreferences.getInstance();
//     // final file = await _localFile;
//     // // Write the file
//     // return file.writeAsString(jsonEncode({
//     //   "access_token": accessToken,
//     //   "workouts": {
//     //     ...workouts.map<String, Map<String, dynamic>>((key, value) {
//     //       return MapEntry(key.toString(), value.toMap());
//     //     })
//     //   }
//     // }));
//   }

//   static Future<void> read() async {
//     // final file = await _localFile;
//     // final contents = await file.readAsString();
//     //final isolate = await FlutterIsolate.spawn(isolate1, "hello");
//     // print(contents);
//     // return int.parse(contents);
//   }

//   // static Future<File> get _localFile async {
//   //   // final path = await getApplicationDocumentsDirectory();
//   //   // return File('$path/counter.txt');
//   // }
// }

// class BackgroundBooker {
//   static Future<void> init(BuildContext context) async {
//     final dbs = context.read<DbSettings>();
//     final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);
//     final dbwl = context.read<DbWhishlist>();
//     // workouts with alarm ids
//     final Map<int, Workout> indexedWorkouts =
//         (await dbwl.fetchAll()).asMap().map((index, e) => MapEntry(index, e));
//     final commData = _CommData(accessToken, indexedWorkouts);
//     commData.writeData();
//     await AndroidAlarmManager.oneShot(
//         const Duration(seconds: 5), _kAlarmId, runAlarmCallback);
//   }
// }

// runAlarmCallback(int alarmId) {
//   print("running alarm $alarmId");
//   //await Future.delayed(Duration(seconds: 2));
//   print("read:");
//   (() async {
//     final bla = await SharedPreferences.getInstance();
//     print(bla);
//   })();
//   //final prefs = await SharedPreferences.getInstance();
//   print("done");
//   _CommData.read();

//   //print("accessToken is $accessToken");
// }

// class BackgroundBooker {
//   static Future<void> init(BuildContext context) async {
//     final dbs = context.read<DbSettings>();
//     final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);
//     final dbwl = context.read<DbWhishlist>();
//     // workouts with alarm ids
//     final Map<int, Workout> indexedWorkouts =
//         (await dbwl.fetchAll()).asMap().map((index, e) => MapEntry(index, e));
//     final commData = _CommData(accessToken, indexedWorkouts);
//     commData.writeData();
//     await AndroidAlarmManager.oneShot(
//         const Duration(seconds: 5), _kAlarmId, runAlarmCallback);
//   }
// }

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  var taskId = task.taskId;
  var timeout = task.timeout;
  if (timeout) {
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  // putReservation(indexedWorkouts.entries.first.value, accessToken);
  print("[BackgroundFetch] Headless event received: $taskId");

  var timestamp = DateTime.now();

  var prefs = await SharedPreferences.getInstance();
  print(prefs.getString(_kKeyAccessTokenStr));

  // // Read fetch_events from SharedPreferences
  // var events = <String>[];
  // var json = prefs.getString(EVENTS_KEY);
  // if (json != null) {
  //   events = jsonDecode(json).cast<String>();
  // }
  // // Add new event.
  // events.insert(0, "$taskId@$timestamp [Headless]");
  // // Persist fetch events in SharedPreferences
  // prefs.setString(EVENTS_KEY, jsonEncode(events));

  // if (taskId == 'flutter_background_fetch') {
  //   /* DISABLED:  uncomment to fire a scheduleTask in headlessTask.
  //   BackgroundFetch.scheduleTask(TaskConfig(
  //       taskId: "com.transistorsoft.customtask",
  //       delay: 5000,
  //       periodic: false,
  //       forceAlarmManager: false,
  //       stopOnTerminate: false,
  //       enableHeadless: true
  //   ));
  //    */
  // }
  BackgroundFetch.finish(taskId);
}

class _CommData {
  final String accessToken;
  final Map<int, Workout> workouts;

  _CommData(this.accessToken, this.workouts);

  Future<void> writeData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_kKeyAccessTokenStr, accessToken);
    // final file = await _localFile;
    // // Write the file
    // return file.writeAsString(jsonEncode({
    //   "access_token": accessToken,
    //   "workouts": {
    //     ...workouts.map<String, Map<String, dynamic>>((key, value) {
    //       return MapEntry(key.toString(), value.toMap());
    //     })
    //   }
    // }));
  }

  static _CommData read() {
    return _CommData("", {});
  }
}

void _onBackgroundFetch(String taskId) async {
  var prefs = await SharedPreferences.getInstance();
  var timestamp = DateTime.now();
  // This is the fetch-event callback.
  print("[BackgroundFetch] Event received: $taskId");
  backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
  BackgroundFetch.finish(taskId);
}

class BackgroundBooker {
  static Future<void> init(BuildContext context) async {
    final dbs = context.read<DbSettings>();
    final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);
    final dbwl = context.read<WhishlistCache>();
    // workouts with alarm ids
    final Map<int, Workout> indexedWorkouts =
        (await dbwl.workouts).asMap().map((index, e) => MapEntry(index, e));
    final commData = _CommData(accessToken, indexedWorkouts);
    commData.writeData();
    BackgroundFetch.stop();
    print("creating healess task");
    var status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 9999999,
          enableHeadless: true,
        ),
        _onBackgroundFetch);

    // indexedWorkouts.entries.where((element) {
    //   element.value.date.isAfter(other)
    // });
    indexedWorkouts.forEach((index, workout) {
      final now = DateTime.now();
    });
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: 'com.foo.my.task',
        delay: 1000,
        periodic: false,
        enableHeadless: true,
        requiresNetworkConnectivity: true));
  }
}
