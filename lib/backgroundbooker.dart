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

import 'dart:convert';
import 'dart:ui';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/widgets.dart';
import 'package:lcbc_athletica_booker/whishlistcache.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dbsettings.dart';
import 'helpers.dart';
import 'sioapi.dart';
import 'workout.dart';
import 'notifications.dart' as noti;

const _kKeyCommDataStr = "commData";

Future<void> backgroundFetchHeadlessTask(HeadlessTask task) async {
  // register plugins - needed for isolate
  DartPluginRegistrant.ensureInitialized();
  var taskId = task.taskId;
  print("backgroundFetchHeadlessTask start $taskId");
  var timeout = task.timeout;
  if (timeout) {
    print("backgroundFetchHeadlessTask timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  // try init notifications to be able to show errors
  final notification = noti.Notification();
  try {
    await notification.init();
  } catch (e) {
    print("error init notifications: $e");
  }
  // try to find workout
  Workout? workout;
  String accessToken = "";
  try {
    final commData = await _CommData.read();
    accessToken = commData.accessToken;
    workout = commData.workouts[taskId];
    if (workout == null) {
      throw Exception("Workout ($taskId) not found.");
    }
  } catch (e) {
    notification.showNow(
        title: "Failed to book workout $taskId", body: "Internal error: $e");
  }
  // try to reserve workout
  try {
    print("reserving my workout: ${jsonEncode(workout?.toMap())}");
    await putReservation(workout!, accessToken);
    notification.showNow(
        title: 'Yay, ${workout.name} has been booked',
        body:
            "${kDateFormatEEEddMMHHmm.format(workout.date.toLocal())} at ${workout.centerName}");
  } catch (e) {
    notification.showNow(
        title: 'Failed to book workout "${workout?.name}"',
        body:
            "Please book manually: ${kDateFormatEEEddMMHHmm.format(workout!.date.toLocal())},${workout.centerName}. ${e.toString()}");
    print(e);
  }
  BackgroundFetch.finish(taskId);
}

class _CommData {
  final String accessToken;
  final Map<String, Workout> workouts;

  _CommData(this.accessToken, this.workouts);

  Future<void> writeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kKeyCommDataStr,
        jsonEncode({
          "access_token": accessToken,
          "workouts": {
            ...workouts.map<String, Map<String, dynamic>>((key, value) {
              return MapEntry(key.toString(), value.toMap());
            })
          }
        }));
  }

  static Future<_CommData> read() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> j =
        jsonDecode(prefs.getString(_kKeyCommDataStr)!);
    final jIndexedWorkouts = j["workouts"] as Map<String, dynamic>;
    final t = jIndexedWorkouts.map<String, Workout>(
        (taskId, v) => MapEntry(taskId, Workout.fromMap(v)));
    return _CommData(j["access_token"], t);
  }
}

Future<void> _onBackgroundFetch(String taskId) async {
  print("_onBackgroundFetch: $taskId");
  await backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
}

String _getTaskId(Workout workout) => "com.${workout.id}.${workout.centerId}";

class BackgroundBooker {
  static Future<void> init(BuildContext context) async {
    final dbs = context.read<DbSettings>();
    final accessToken = dbs.getStr(DbSettings.ACCESS_TOKEN_STR);
    final dbwl = context.read<WhishlistCache>();
    // workouts with alarm ids
    final Map<String, Workout> indexedWorkouts =
        dbwl.workouts.asMap().map((index, e) => MapEntry(_getTaskId(e), e));
    final commData = _CommData(accessToken, indexedWorkouts);
    await commData.writeData();
    BackgroundFetch.stop();
    print("creating headless task");
    var status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 999999999, // -> 31.70979 yrs
          enableHeadless: true,
        ),
        _onBackgroundFetch);

    final bookingAvailableDelta = Duration(
        hours: context
            .read<DbSettings>()
            .getInt(DbSettings.BOOKING_AVAILABLE_HOURS_INT));
    for (final entry in indexedWorkouts.entries) {
      final Workout workout = entry.value;
      final taskId = _getTaskId(workout);
      print("BackgroundBooker workout ${workout.name} $taskId");
      final bookingAvailable = workout.date.subtract(bookingAvailableDelta);
      final now = DateTime.now();
      final bool isAvailableForBooking = bookingAvailable.isBefore(now);
      if (isAvailableForBooking) {
        // ignore
        continue;
      }
      // schedule booking
      final delay = bookingAvailable.difference(now);
      print("BackgroundBooker workout scheduled in ${printDuration(delay)}");
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: taskId,
          delay: delay.inMilliseconds,
          periodic: false,
          enableHeadless: true,
          startOnBoot: true,
          stopOnTerminate: false,
          requiresNetworkConnectivity: true));
    }
  }

  //   BackgroundFetch.scheduleTask(TaskConfig(
  //       taskId: "sd",
  //       delay: 2000,
  //       periodic: false,
  //       enableHeadless: true,
  //       startOnBoot: true,
  //       stopOnTerminate: false,
  //       requiresNetworkConnectivity: true));
  // }
}
