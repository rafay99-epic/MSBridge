import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/services/sync/templates_sync.dart';

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
    // Best-effort immediate cloud sync for this template
    TemplatesSyncService().syncLocalTemplatesToFirebase();
  }

  static Future<void> updateTemplate(NoteTemplate template) async {
    template.updatedAt = DateTime.now();
    if (template.isInBox) {
      await template.save();
    } else {
      final box = await getBox();
      await box.put(template.templateId, template);
    }
    TemplatesSyncService().syncLocalTemplatesToFirebase();
  }

  static Future<void> deleteTemplate(NoteTemplate template) async {
    final id = template.templateId;
    await template.delete();
    TemplatesSyncService().deleteTemplateInCloud(id);
  }
}
