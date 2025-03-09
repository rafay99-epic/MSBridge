import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:msbridge/backend/provider/pin_note_provider.dart';
import 'package:msbridge/backend/repo/hive_note_taking_repo.dart';
import 'package:msbridge/frontend/screens/notes_taking/create/create_note.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/frontend/utils/error.dart';
import 'package:msbridge/frontend/utils/loading.dart';
import 'package:msbridge/frontend/widgets/note_taking_card.dart';
import 'package:provider/provider.dart';

class Notetaking extends StatefulWidget {
  const Notetaking({super.key});

  @override
  State<Notetaking> createState() => _NotetakingState();
}

class _NotetakingState extends State<Notetaking> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Note Taking"),
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 1,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
      body: ChangeNotifierProvider(
        create: (context) {
          final noteProvider = NoteProvider();
          noteProvider.initialize();
          return noteProvider;
        },
        child: Consumer<NoteProvider>(
          builder: (context, noteProvider, _) {
            return StreamBuilder<BoxEvent>(
              stream: Hive.box<NoteTakingModel>('notes').watch(),
              builder: (context, snapshot) {
                return FutureBuilder<List<NoteTakingModel>>(
                  future: HiveNoteTakingRepo.getNotes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const L oading(message: "Loading notes...");
                    } else if (snapshot.hasError) {
                      return ErrorApp(
                        errorMessage: 'Error: ${snapshot.error}',
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No notes yet!"));
                    } else {
                      final notes = snapshot.data!;

                      final pinnedNotes = notes
                          .where((note) =>
                              noteProvider.isNotePinned(note.noteId.toString()))
                          .toList();
                      final unpinnedNotes = notes
                          .where((note) => !noteProvider
                              .isNotePinned(note.noteId.toString()))
                          .toList();

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pinnedNotes.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16.0, 16.0, 16.0, 8.0),
                                child: Text(
                                  "Pinned Notes",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: MasonryGridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  itemCount: pinnedNotes.length,
                                  itemBuilder: (context, index) {
                                    final note = pinnedNotes[index];
                                    return GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation,
                                                    secondaryAnimation) =>
                                                CreateNote(
                                              note: note,
                                            ),
                                            transitionsBuilder: (context,
                                                animation,
                                                secondaryAnimation,
                                                child) {
                                              return FadeTransition(
                                                  opacity: animation,
                                                  child: child);
                                            },
                                            transitionDuration: const Duration(
                                                milliseconds: 300),
                                          ),
                                        );
                                      },
                                      child: NoteCard(note: note),
                                    );
                                  },
                                ),
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 16.0, 16.0, 8.0),
                              child: Text(
                                " Notes",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: MasonryGridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                itemCount: unpinnedNotes.length,
                                itemBuilder: (context, index) {
                                  final note = unpinnedNotes[index];
                                  return GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              CreateNote(
                                            note: note,
                                          ),
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            return FadeTransition(
                                                opacity: animation,
                                                child: child);
                                          },
                                          transitionDuration:
                                              const Duration(milliseconds: 300),
                                        ),
                                      );
                                    },
                                    child: NoteCard(note: note),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.primary,
        elevation: 4,
        onPressed: () async {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const CreateNote(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        tooltip: 'Add New Note',
        child: const Icon(Icons.edit_note),
      ),
    );
  }
}
