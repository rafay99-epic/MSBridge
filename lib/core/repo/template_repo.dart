import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/templates/note_template.dart';

class TemplateRepo {
  static const String _boxName = 'note_templates';
  static Box<NoteTemplate>? _box;

  static Future<Box<NoteTemplate>> getBox() async {
    _box ??= await Hive.openBox<NoteTemplate>(_boxName);
    return _box!;
  }

  static Future<ValueListenable<Box<NoteTemplate>>>
      getTemplatesListenable() async {
    final box = await getBox();
    return box.listenable();
  }

  static Future<List<NoteTemplate>> getTemplates() async {
    final box = await getBox();
    return box.values.toList(growable: false);
  }

  static Future<void> createTemplate(NoteTemplate template) async {
    final box = await getBox();
    await box.put(template.templateId, template);
  }

  static Future<void> updateTemplate(NoteTemplate template) async {
    template.updatedAt = DateTime.now();
    await template.save();
  }

  static Future<void> deleteTemplate(NoteTemplate template) async {
    await template.delete();
  }
}
