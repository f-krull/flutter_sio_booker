import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:io' as io;

import 'package:intl/intl.dart';
import 'package:lcbc_athletica_booker/reservation.dart';

import 'workout.dart';

const String urlBase = "https://www.sio.no/api/idrett/v1";

Future<String> fetchAccessToken(
    {required String username, required String password}) async {
  const url = "https://www.sio.no/api/auth/v1/login/";
  const headers = {"Content-Type": "application/json"};
  http.Response r = await http.post(Uri.parse(url),
      headers: headers,
      body: jsonEncode({"username": username, "password": password}));
  if (r.statusCode != io.HttpStatus.ok) {
    throw Exception("Unable to get access token (${r.statusCode})");
  }
  final Map<String, dynamic> j = jsonDecode(r.body);
  const keyAccessToken = "accessToken";
  if (!j.containsKey(keyAccessToken)) {
    throw Exception("Unexpected response (expected key \"$keyAccessToken\")");
  }
  return j[keyAccessToken];
}

Future<List<Workout>> fetchWorkouts(
    {required dateFrom, required dateTo}) async {
  final df = DateFormat('yyyy-MM-dd');
  var fromDate = df.format(dateFrom);
  var toDate = df.format(dateTo);
  var url = "$urlBase/open/groupexercises?fromDate=$fromDate&toDate=$toDate";
  http.Response r = await http.get(Uri.parse(url));
  List<Workout> l = [];
  if (r.statusCode != io.HttpStatus.ok) {
    return l;
  }
  l = (jsonDecode(r.body) as List<dynamic>)
      .map((e) => Workout.fromJson(e))
      .toList();
  return l;
}

Future<void> putReservation(Workout workout, String accessToken) async {
  var url = "$urlBase/secure/reservations/${workout.centerId}/${workout.id}";
  final headers = {'AccessToken': accessToken};
  http.Response r = await http.put(Uri.parse(url), headers: headers);
  print(r.headers);
  print(r.body);
  print("booked");
  return;
}

Future<void> deleteReservation(Workout workout, String accessToken) async {
  var url =
      "$urlBase/secure/reservations/${workout.centerId}/${workout.id}/${workout.id}";
  final headers = {'AccessToken': accessToken};
  http.Response r = await http.delete(Uri.parse(url), headers: headers);
  if (r.statusCode != io.HttpStatus.noContent) {
    throw Exception(
        "status code was ${r.statusCode}; expected ${io.HttpStatus.noContent}");
  }
  print("cancelled");
  return;
}

Future<List<Reservation>> fetchReservations(String accessToken) async {
  const url = "https://www.sio.no/api/idrett/v1/secure/reservations";
  print("fetching $url");
  final headers = {'AccessToken': accessToken};
  http.Response r = await http.get(Uri.parse(url), headers: headers);
  List<Reservation> l = [];
  if (r.statusCode != io.HttpStatus.ok) {
    return l;
  }
  l = (jsonDecode(r.body) as List<dynamic>)
      .map((e) => Reservation.fromJson(e))
      .toList();
  print("fetching $url done");
  return l;
}
