import 'package:hive/hive.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';

class HiveNoteTakingRepo {
  static Future<Box<NoteTakingModel>> getBox() async {
    return Hive.openBox<NoteTakingModel>('notes');
  }

  static Future<void> addNote(NoteTakingModel note) async {
    var box = await getBox();
    await box.add(note);
  }

  static Future<void> updateNote(int key, NoteTakingModel note) async {
    var box = await getBox();
    await box.put(key, note);
  }

  static Future<void> deleteNote(int key) async {
    var box = await getBox();
    await box.delete(key);
  }

  static Future<List<NoteTakingModel>> getNotes() async {
    var box = await getBox();
    return box.values.toList();
  }
}
