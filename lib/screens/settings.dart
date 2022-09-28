import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lcbc_athletica_booker/dbsettings.dart';
import 'package:lcbc_athletica_booker/helpers.dart';
import 'package:provider/provider.dart';

import '../reservationscache.dart';

Widget buildListItem(String title, Function() onTab) {
  return ListTile(
    title: Text(title,
        style:
            const TextStyle(fontWeight: FontWeight.normal, color: Colors.blue)),
    onTap: onTab,
  );
}

/*----------------------------------------------------------------------------*/

class SelectBookingAvailHoursDialog extends StatefulWidget {
  const SelectBookingAvailHoursDialog({Key? key}) : super(key: key);

  @override
  State<SelectBookingAvailHoursDialog> createState() =>
      _SelectBookingAvailHoursDialogState();
}

class _SelectBookingAvailHoursDialogState
    extends State<SelectBookingAvailHoursDialog> {
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final durationHours = context
        .read<DbSettings>()
        .getInt(DbSettings.BOOKING_AVAILABLE_HOURS_INT);
    textController.text = durationHours.toString();
  }

  void submit() async {
    final dh = int.tryParse(textController.text);
    // valid value?
    if (dh == null) {
      Navigator.pop(context, null);
    }
    // save to db
    await context
        .read<DbSettings>()
        .setInt(DbSettings.BOOKING_AVAILABLE_HOURS_INT, dh!);
    Navigator.pop(context, Duration(hours: dh));
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text(
          'Set how much time in advance booking is available (in hours)'),
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: textController,
              keyboardType: TextInputType.number,
              //   decoration: const InputDecoration(
              //   labelText: 'SIO Username',
              // ),
            )),
        SimpleDialogOption(
          onPressed: submit,
          child: const Text('OK'),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/*----------------------------------------------------------------------------*/

class SetNofityBeforeWorkoutTimeDialog extends StatefulWidget {
  const SetNofityBeforeWorkoutTimeDialog({Key? key}) : super(key: key);

  @override
  State<SetNofityBeforeWorkoutTimeDialog> createState() =>
      _SetNofityBeforeWorkoutTimeDialogState();
}

class _SetNofityBeforeWorkoutTimeDialogState
    extends State<SetNofityBeforeWorkoutTimeDialog> {
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final durationMinutes = context
        .read<DbSettings>()
        .getInt(DbSettings.NOTIFY_BEFORE_WORKOUT_MIN_INT);
    textController.text = durationMinutes.toString();
  }

  void submit() async {
    final dm = int.tryParse(textController.text);
    // valid value?
    if (dm == null) {
      Navigator.pop(context, null);
    }
    // save to db
    await context
        .read<DbSettings>()
        .setInt(DbSettings.NOTIFY_BEFORE_WORKOUT_MIN_INT, dm!);
    // reschedule notifications
    await Provider.of<ReservationsCache>(context, listen: false)
        .update(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Notifications have been updated"),
    ));
    Navigator.pop(context, Duration(minutes: dm));
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text(
          'Set how much time in advance you want to be notified before a workout starts (in minutes)'),
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: textController,
              keyboardType: TextInputType.number,
              //   decoration: const InputDecoration(
              //   labelText: 'SIO Username',
              // ),
            )),
        SimpleDialogOption(
          onPressed: submit,
          child: const Text('OK'),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/*----------------------------------------------------------------------------*/

Future<void> showSetBookingDeltaDialog(context) async {
  // get old duration

  await showDialog<Duration?>(
      builder: (BuildContext context) {
        return const SelectBookingAvailHoursDialog();
      },
      context: context);
}

Future<void> showSetNofifyBeforeWorkoutDialog(context) async {
  // get old duration

  await showDialog<Duration?>(
      builder: (BuildContext context) {
        return const SetNofityBeforeWorkoutTimeDialog();
      },
      context: context);
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LaScaffold(
        body: Padding(
      padding: const EdgeInsets.all(8),
      child: ListView(
        children: [
          buildListItem("Reset login", () async {
            await context
                .read<DbSettings>()
                .delete(DbSettings.ACCESS_TOKEN_STR);
            exit(0);
          }),
          const Divider(),
          buildListItem("Set hours booking available",
              () => showSetBookingDeltaDialog(context)),
          const Divider(),
          buildListItem("Notify before workout",
              () => showSetNofifyBeforeWorkoutDialog(context))
        ],
      ),
    ));
  }
}
