import 'package:flutter/material.dart';

getPageRoute(Widget w) => MaterialPageRoute(
      builder: (context) => w,
    );

pushPage(BuildContext context, Widget w) =>
    Navigator.of(context).push(getPageRoute(w));

replacePage(BuildContext context, Widget w) =>
    Navigator.of(context).pushReplacement(getPageRoute(w));

class LaScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  const LaScaffold({Key? key, required this.body, this.actions, this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: title != null ? Text(title!) : null,
          actions: actions,
        ),
        body: body);
  }
}

String printDuration(Duration duration) {
  if (duration.inDays > 0) {
    return "${duration.inDays} days";
  }
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitHours = twoDigits(duration.inHours.remainder(24));
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
}
