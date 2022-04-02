import 'package:lcbc_athletica_booker/workout.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

class DbWhishlist extends DbListener {
  DbWhishlist(LaDb db) : super(db);

  @override
  Future<void> onInit() async {
    final db = await database();
    //await db.execute(_kDropTableWhishlist);
    await db.execute(_kCreateTableWhishlist);
  }

  // add fav
  Future<int> add(Workout w) async {
    final db = await database();
    final int r = await db.insert(
      _kTableNameWhishlist,
      w.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return r;
  }

  Future<int> remove(Workout w) async {
    final db = await database();
    final int r = await db.delete(_kTableNameWhishlist,
        where: "id = ? and centerId = ?", whereArgs: [w.id, w.centerId]);
    return r;
  }

  Future<List<Workout>> fetchAll() async {
    final db = await database();
    final r = await db.query(_kTableNameWhishlist, orderBy: "date");
    return r.map((e) => Workout.fromMap(e)).toList();
  }
}

const String _kTableNameWhishlist = "whishlist";

const String _kDropTableWhishlist = """
DROP TABLE IF EXISTS $_kTableNameWhishlist;
""";

const String _kCreateTableWhishlist = """
CREATE TABLE IF NOT EXISTS $_kTableNameWhishlist(
  id    INT,
  name  TEXT,
  date  TEXT,
  centerName TEXT,   
  centerId TEXT,
  instructorName TEXT,
  PRIMARY KEY (id, centerId)
);
""";
