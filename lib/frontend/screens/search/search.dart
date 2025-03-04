import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/backend/models/notes_model.dart';
import 'package:msbridge/frontend/screens/msnotes/notes_detail.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  SearchState createState() => SearchState();
}

class SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  List<MSNote> _filteredResults = [];
  List<MSNote> _allItems = [];
  String? _selectedSubject;
  List<String> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadNotesFromHive();
  }

  Future<void> _loadNotesFromHive() async {
    try {
      var box = Hive.box<MSNote>('notesBox');
      setState(() {
        _allItems = box.values.toList();
        _filteredResults = _allItems;
        _availableSubjects =
            _allItems.map((note) => note.subject).toSet().toList();
      });
    } catch (e) {
      CustomSnackBar.show(context, "Failed to load data from Hive: $e");
    }
  }

  void _search(String query) {
    try {
      setState(() {
        _filteredResults = _allItems.where((note) {
          final bool matchesQuery = query.isEmpty ||
              note.lectureTitle.toLowerCase().contains(query.toLowerCase()) ||
              note.lectureDescription
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              note.subject.toLowerCase().contains(query.toLowerCase()) ||
              (note.body?.toLowerCase().contains(query.toLowerCase()) ?? false);

          final bool matchesSubject =
              _selectedSubject == null || note.subject == _selectedSubject;

          return matchesQuery && matchesSubject;
        }).toList();
      });
    } catch (e) {
      CustomSnackBar.show(context, "Search failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(theme),
            const SizedBox(height: 16),
            _buildSubjectTags(theme),
            const SizedBox(height: 16),
            Expanded(child: _buildSearchResults(theme)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text("Search"),
      automaticallyImplyLeading: false,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.primary,
      elevation: 0,
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _search,
        style: TextStyle(color: theme.colorScheme.primary),
        cursorColor: theme.colorScheme.secondary,
        decoration: InputDecoration(
          hintText: "Search...",
          hintStyle:
              TextStyle(color: theme.colorScheme.primary.withOpacity(0.6)),
          prefixIcon:
              Icon(LineIcons.search, color: theme.colorScheme.secondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(LineIcons.timesCircle,
                      color: theme.colorScheme.primary),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSubjectTags(ThemeData theme) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableSubjects.length,
        itemBuilder: (context, index) {
          final subject = _availableSubjects[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FilterChip(
              label: Text(subject,
                  style: TextStyle(color: theme.colorScheme.secondaryFixed)),
              selected: _selectedSubject == subject,
              onSelected: (bool selected) {
                setState(() {
                  _selectedSubject = selected ? subject : null;
                  _search(_searchController.text);
                });
              },
              checkmarkColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.secondary,
              backgroundColor: Colors.grey[200],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return _filteredResults.isEmpty
        ? Center(
            child: Text(
              "No results found",
              style:
                  TextStyle(color: theme.colorScheme.primary.withOpacity(0.7)),
            ),
          )
        : ListView.builder(
            itemCount: _filteredResults.length,
            itemBuilder: (context, index) {
              final MSNote note = _filteredResults[index];
              DateTime pubDate = DateTime.parse(note.pubDate).toLocal();
              String formattedDate = DateFormat('MMMM d, yyyy').format(pubDate);
              return Card(
                color: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.secondary,
                    width: 2,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    "${note.lectureNumber}. ${note.lectureTitle}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.lectureDescription,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Published on: $formattedDate",
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => {
                    debugPrint("Lecture Selected: ${note.lectureTitle}"),
                    Navigator.push(
                      context,
                      PageTransition(
                        child: LectureDetailScreen(lecture: note),
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                      ),
                    )
                  },
                ),
              );
            },
          );
  }
}
