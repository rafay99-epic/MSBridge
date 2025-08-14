import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';

class ReverseSyncService {
  final AuthRepo _authRepo = AuthRepo();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveNoteTakingRepo hiveNoteTakingRepo = HiveNoteTakingRepo();

  Future<void> syncDataFromFirebaseToHive() async {
    try {
      final userResult = await _authRepo.getCurrentUser();

      if (!userResult.isSuccess || userResult.user == null) {
        return;
      }

      final user = userResult.user!;
      final userId = user.uid;

      final isHiveEmpty = await HiveNoteTakingRepo.isBoxEmpty();

      if (isHiveEmpty) {
        try {
          final userNotesCollection =
              _firestore.collection('users').doc(userId).collection('notes');

          final QuerySnapshot notesSnapshot = await userNotesCollection.get();

          const batchSize = 50;
          for (var i = 0; i < notesSnapshot.docs.length; i += batchSize) {
            final batch = notesSnapshot.docs.sublist(
                i,
                (i + batchSize < notesSnapshot.docs.length)
                    ? i + batchSize
                    : notesSnapshot.docs.length);

            final Map<String, NoteTakingModel> notesToAdd = {};
            for (final doc in batch) {
              final data = doc.data() as Map<String, dynamic>;

              final noteMap = {
                'noteId': doc.id,
                'noteTitle': data['noteTitle'] ?? '',
                'noteContent': data['noteContent'] ?? '',
                'isSynced': data['isSynced'] ?? false,
                'isDeleted': data['isDeleted'] ?? false,
                'updatedAt':
                    data['updatedAt'] ?? DateTime.now().toIso8601String(),
                'userId': userId,
                'tags': (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
              };

              final note = NoteTakingModel.fromMap(noteMap);
              notesToAdd[note.noteId!] = note;
            }

            final box = await HiveNoteTakingRepo.getBox();
            await box.putAll(notesToAdd);
          }
        } catch (firebaseError) {
          rethrow;
        }
      }
    } catch (authError) {
      rethrow;
    }
  }
}
