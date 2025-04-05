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
        print('No user logged in. Skipping sync.');
        return;
      }

      final user = userResult.user!;
      final userId = user.uid;

      final isHiveEmpty = await HiveNoteTakingRepo.isBoxEmpty();

      if (isHiveEmpty) {
        print("================================================");
        print('Hive is empty. Fetching data from Firebase.');
        print("================================================");
        final userNotesCollection =
            _firestore.collection('users').doc(userId).collection('notes');

        final QuerySnapshot notesSnapshot = await userNotesCollection.get();

        for (final doc in notesSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          final noteMap = {
            'noteId': doc.id,
            'noteTitle': data['noteTitle'] ?? '',
            'noteContent': data['noteContent'] ?? '',
            'isSynced': data['isSynced'] ?? false,
            'isDeleted': data['isDeleted'] ?? false,
            'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
            'userId': userId,
          };

          final note = NoteTakingModel.fromMap(noteMap);
          await HiveNoteTakingRepo.addNote(note);
          print("================================================");

          print('Added note to Hive: ${note.noteTitle}');
          print("================================================");
        }
        print("================================================");

        print('Successfully synced data from Firebase to Hive.');
        print("================================================");
      } else {
        print("================================================");

        print('Hive is not empty. Skipping Firebase sync.');
        print("================================================");
      }
    } catch (e) {
      print("================================================");

      print('Error during Firebase to Hive sync: $e');
      print("================================================");
    }
  }
}
