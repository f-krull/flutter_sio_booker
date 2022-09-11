import 'package:flutter/material.dart';

import '../../helpers.dart';
import '../../workout.dart';
import '../workoutitem_subtitle.dart';
import 'workouts.dart';

class WorkoutList extends StatelessWidget {
  final List<Workout> workouts;
  final List<WorkoutId> bookedWorkouts;
  final List<WorkoutId> whishlistWorkouts;

  const WorkoutList(
      {Key? key,
      required this.workouts,
      required this.bookedWorkouts,
      required this.whishlistWorkouts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: kListSepBuilder,
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return Card(
              shape: kListItemShape,
              color: Colors.blue[100],
              child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text("${workout.name}  (${workout.instructorName})"),
                  leading:
                      Text(workout.centerName.replaceFirst("Athletica", "")),
                  trailing: BookButton(
                      workout: workout,
                      bookedWorkoutIds: bookedWorkouts,
                      whishlistWorkoutIds: whishlistWorkouts),
                  subtitle: WorkoutItemSubTitle(workout: workout)
                  // onTap: () => {
                  //   Navigator.of(context).push(
                  //     MaterialPageRoute(
                  //         builder: (context) => ShowWorkoutScreen(
                  //               workout: workout,
                  //             )),
                  //   )
                  // },
                  ));
        });
  }
}
