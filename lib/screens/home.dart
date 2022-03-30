import 'package:flutter/material.dart';
import 'package:lcbc_athletica_booker/backgroundbooker.dart';
import 'package:lcbc_athletica_booker/screens/reservations.dart';
import 'package:lcbc_athletica_booker/screens/settings.dart';
import 'package:lcbc_athletica_booker/screens/whishlist.dart';
import 'package:provider/provider.dart';

import '../helpers.dart';
import '../main.dart';
import '../reservationscache.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LaScaffold(
      actions: [
        IconButton(
            onPressed: () => pushPage(context, const SettingsScreen()),
            icon: const Icon(Icons.settings))
      ],
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            child: const Text("Book workout"),
            onPressed: () => pushPage(context, const SelectDateScreen()),
          ),
          TextButton(
              child: const Text("My reservations"),
              onPressed: () {
                // update reservations
                Provider.of<ReservationsCache>(context, listen: false)
                    .update(context);
                pushPage(context, const ShowReservationsScreen());
              }),
          TextButton(
              child: const Text("Whish list"),
              onPressed: () => pushPage(context, const WhishlistScreen())),
          TextButton(
              child: const Text("Run task"),
              onPressed: () => BackgroundBooker.init(context)),
        ],
      )),
    );
  }
}
