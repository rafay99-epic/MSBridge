import 'package:msbridge/core/database/note_taking/note_version.dart';

class VersionDiffUtils {
  /// Detect changes between two versions and return a list of change descriptions
  static List<String> detectChanges({
    required String oldTitle,
    required String newTitle,
    required String oldContent,
    required String newContent,
    required List<String> oldTags,
    required List<String> newTags,
  }) {
    final changes = <String>[];

    // Check title changes
    if (oldTitle != newTitle) {
      if (oldTitle.isEmpty && newTitle.isNotEmpty) {
        changes.add('Added title: "$newTitle"');
      } else if (newTitle.isEmpty && oldTitle.isNotEmpty) {
        changes.add('Removed title: "$oldTitle"');
      } else {
        changes.add('Changed title from "$oldTitle" to "$newTitle"');
      }
    }

    // Check content changes
    if (oldContent != newContent) {
      final oldLines =
          oldContent.split('\n').where((line) => line.trim().isNotEmpty).length;
      final newLines =
          newContent.split('\n').where((line) => line.trim().isNotEmpty).length;

      if (oldContent.isEmpty && newContent.isNotEmpty) {
        changes.add('Added content ($newLines lines)');
      } else if (newContent.isEmpty && oldContent.isNotEmpty) {
        changes.add('Removed all content ($oldLines lines)');
      } else if (newLines > oldLines) {
        changes.add('Added ${newLines - oldLines} lines of content');
      } else if (newLines < oldLines) {
        changes.add('Removed ${oldLines - newLines} lines of content');
      } else {
        changes.add('Modified content');
      }
    }

    // Check tag changes
    final addedTags = newTags.where((tag) => !oldTags.contains(tag)).toList();
    final removedTags = oldTags.where((tag) => !newTags.contains(tag)).toList();

    if (addedTags.isNotEmpty) {
      changes.add('Added tags: ${addedTags.join(", ")}');
    }
    if (removedTags.isNotEmpty) {
      changes.add('Removed tags: ${removedTags.join(", ")}');
    }

    // If no specific changes detected, provide a generic description
    if (changes.isEmpty) {
      changes.add('Minor updates');
    }

    return changes;
  }

  /// Generate a human-readable change description
  static String generateChangeDescription(List<String> changes) {
    if (changes.isEmpty) return 'No changes detected';
    if (changes.length == 1) return changes.first;

    final lastChange = changes.last;
    final otherChanges = changes.take(changes.length - 1);
    return '${otherChanges.join(", ")} and $lastChange';
  }

  /// Get a summary of what changed in a specific version
  static String getVersionSummary(NoteVersion version) {
    if (version.changes.isEmpty) {
      return 'Version ${version.versionNumber}';
    }

    final changeSummary = version.changes.take(2).join(", ");
    if (version.changes.length > 2) {
      return 'Version ${version.versionNumber}: $changeSummary and ${version.changes.length - 2} more changes';
    }
    return 'Version ${version.versionNumber}: $changeSummary';
  }

  /// Compare two versions and highlight differences
  static Map<String, dynamic> compareVersions(
      NoteVersion? oldVersion, NoteVersion newVersion) {
    if (oldVersion == null) {
      return {
        'titleChanged': false,
        'contentChanged': false,
        'tagsChanged': false,
        'titleDiff': {'old': '', 'new': newVersion.noteTitle},
        'contentDiff': {'old': '', 'new': newVersion.noteContent},
        'tagsDiff': {'old': [], 'new': newVersion.tags},
      };
    }

    return {
      'titleChanged': oldVersion.noteTitle != newVersion.noteTitle,
      'contentChanged': oldVersion.noteContent != newVersion.noteContent,
      'tagsChanged': !_areListsEqual(oldVersion.tags, newVersion.tags),
      'titleDiff': {'old': oldVersion.noteTitle, 'new': newVersion.noteTitle},
      'contentDiff': {
        'old': oldVersion.noteContent,
        'new': newVersion.noteContent
      },
      'tagsDiff': {'old': oldVersion.tags, 'new': newVersion.tags},
    };
  }

  static bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}
