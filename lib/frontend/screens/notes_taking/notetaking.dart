import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:msbridge/backend/repo/hive_note_taking_repo.dart';
import 'package:msbridge/frontend/screens/notes_taking/create/create_note.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
        shadowColor:
            theme.colorScheme.shadow.withOpacity(0.2), // Customize shadow color
        centerTitle: true, //Center title
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ), //Adjust the text style as needed
      ),
      body: StreamBuilder<BoxEvent>(
        stream: Hive.box<NoteTakingModel>('notes').watch(),
        builder: (context, snapshot) {
          return FutureBuilder<List<NoteTakingModel>>(
            future: HiveNoteTakingRepo.getNotes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No notes yet!"));
              } else {
                final notes = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      CreateNote(
                                note: note,
                              ),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        child: Card(
                          elevation:
                              5, // Slightly higher elevation for more pop
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                12), // More rounded corners
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                                12.0), // Slightly larger padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.noteTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    // Use titleMedium
                                    fontWeight: FontWeight
                                        .w600, // Semi-bold for emphasis
                                    color: theme.colorScheme
                                        .onSurface, // Use onSurface for better contrast
                                  ),
                                  maxLines:
                                      2, // Allow two lines for longer titles
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  note.noteContent,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    // Use bodyMedium
                                    color: theme.colorScheme
                                        .onSurfaceVariant, // Softer text color
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${DateTime.parse(note.updatedAt.toString()).day}/${DateTime.parse(note.updatedAt.toString()).month}/${DateTime.parse(note.updatedAt.toString()).year}', // Using DateTime.parse, change note.created_at to appropriate variable that stores time
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    //Add a small icon button to delete a note or pin it
                                    IconButton(
                                      icon: const Icon(Icons.push_pin_outlined),
                                      color: theme.colorScheme.onSurfaceVariant,
                                      onPressed: () {},
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.primary,
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
