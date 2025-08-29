// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:line_icons/line_icons.dart';
// import 'package:msbridge/core/database/note_reading/notes_model.dart';
// import 'package:msbridge/features/msnotes/notes_detail.dart';
// import 'package:msbridge/widgets/appbar.dart';
// import 'package:msbridge/widgets/snakbar.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:intl/intl.dart';

// class Search extends StatefulWidget {
//   const Search({super.key});

//   @override
//   SearchState createState() => SearchState();
// }

// class SearchState extends State<Search>
//     with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
//   @override
//   bool get wantKeepAlive => true;

//   final TextEditingController _searchController = TextEditingController();
//   List<MSNote> _filteredResults = [];
//   List<MSNote> _allItems = [];
//   String? _selectedSubject;
//   List<String> _availableSubjects = [];

//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _loadNotesFromHive();
//   }

//   void _initializeAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     ));

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));

//     _fadeController.forward();
//     _slideController.forward();
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadNotesFromHive() async {
//     try {
//       var box = Hive.box<MSNote>('notesBox');
//       setState(() {
//         _allItems = box.values.toList();
//         _filteredResults = _allItems;
//         _availableSubjects =
//             _allItems.map((note) => note.subject).toSet().toList();
//       });
//     } catch (e) {
//       CustomSnackBar.show(context, "Failed to load data from Hive: $e");
//     }
//   }

//   void _search(String query) {
//     try {
//       setState(() {
//         _filteredResults = _allItems.where((note) {
//           final bool matchesQuery = query.isEmpty ||
//               note.lectureTitle.toLowerCase().contains(query.toLowerCase()) ||
//               note.lectureDescription
//                   .toLowerCase()
//                   .contains(query.toLowerCase()) ||
//               note.subject.toLowerCase().contains(query.toLowerCase()) ||
//               (note.body?.toLowerCase().contains(query.toLowerCase()) ?? false);

//           final bool matchesSubject =
//               _selectedSubject == null || note.subject == _selectedSubject;

//           return matchesQuery && matchesSubject;
//         }).toList();
//       });
//     } catch (e) {
//       CustomSnackBar.show(context, "Search failed: $e");
//     }
//   }

//   String _formatDate(String pubDate) {
//     try {
//       DateTime date = DateTime.parse(pubDate).toLocal();
//       return DateFormat('MMMM d, yyyy').format(date);
//     } catch (e) {
//       return pubDate; // Fallback to original if formatting fails
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       backgroundColor: colorScheme.surface,
//       appBar: const CustomAppBar(title: "Search"),
//       body: FadeTransition(
//         opacity: _fadeAnimation,
//         child: SlideTransition(
//           position: _slideAnimation,
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 _buildSearchBar(colorScheme),
//                 const SizedBox(height: 24),
//                 _buildSubjectTags(colorScheme),
//                 const SizedBox(height: 24),
//                 Expanded(child: _buildSearchResults(colorScheme)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBar(ColorScheme colorScheme) {
//     return Container(
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceContainerHighest,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: colorScheme.outline.withOpacity(0.2),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: colorScheme.shadow.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: _searchController,
//         onChanged: _search,
//         style: TextStyle(
//           color: colorScheme.onSurface,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//         cursorColor: colorScheme.primary,
//         decoration: InputDecoration(
//           hintText: "Search lectures, subjects, or descriptions...",
//           hintStyle: TextStyle(
//             color: colorScheme.onSurface.withOpacity(0.5),
//             fontSize: 16,
//           ),
//           prefixIcon: Container(
//             margin: const EdgeInsets.all(12),
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: colorScheme.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(
//               LineIcons.search,
//               color: colorScheme.primary,
//               size: 20,
//             ),
//           ),
//           suffixIcon: _searchController.text.isNotEmpty
//               ? Container(
//                   margin: const EdgeInsets.all(12),
//                   child: IconButton(
//                     icon: Icon(
//                       LineIcons.timesCircle,
//                       color: colorScheme.primary,
//                       size: 20,
//                     ),
//                     onPressed: () {
//                       _searchController.clear();
//                       _search('');
//                     },
//                   ),
//                 )
//               : null,
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 18,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSubjectTags(ColorScheme colorScheme) {
//     if (_availableSubjects.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Filter by Subject",
//           style: TextStyle(
//             color: colorScheme.onSurface,
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 44,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: _availableSubjects.length,
//             itemBuilder: (context, index) {
//               final subject = _availableSubjects[index];
//               final isSelected = _selectedSubject == subject;

//               return AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 margin: const EdgeInsets.only(right: 12),
//                 child: FilterChip(
//                   label: Text(
//                     subject,
//                     style: TextStyle(
//                       color: isSelected
//                           ? colorScheme.onPrimary
//                           : colorScheme.onSurface,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 14,
//                     ),
//                   ),
//                   selected: isSelected,
//                   onSelected: (bool selected) {
//                     setState(() {
//                       _selectedSubject = selected ? subject : null;
//                       _search(_searchController.text);
//                     });
//                   },
//                   checkmarkColor: colorScheme.onPrimary,
//                   selectedColor: colorScheme.primary,
//                   backgroundColor: colorScheme.surfaceContainerHighest,
//                   side: BorderSide(
//                     color: isSelected
//                         ? colorScheme.primary
//                         : colorScheme.outline.withOpacity(0.3),
//                     width: 1.5,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   elevation: isSelected ? 4 : 0,
//                   shadowColor: colorScheme.primary.withOpacity(0.3),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchResults(ColorScheme colorScheme) {
//     if (_filteredResults.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               LineIcons.search,
//               size: 64,
//               color: colorScheme.onSurface.withOpacity(0.3),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               _searchController.text.isEmpty
//                   ? "No notes available"
//                   : "No results found",
//               style: TextStyle(
//                 color: colorScheme.onSurface.withOpacity(0.6),
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             if (_searchController.text.isNotEmpty) ...[
//               const SizedBox(height: 8),
//               Text(
//                 "Try adjusting your search terms",
//                 style: TextStyle(
//                   color: colorScheme.onSurface.withOpacity(0.4),
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       itemCount: _filteredResults.length,
//       physics: const BouncingScrollPhysics(),
//       addAutomaticKeepAlives: false,
//       addRepaintBoundaries: false,
//       itemBuilder: (context, index) {
//         final MSNote note = _filteredResults[index];

//         return RepaintBoundary(
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             margin: const EdgeInsets.only(bottom: 16),
//             child: _buildSearchResultCard(note, colorScheme),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSearchResultCard(MSNote note, ColorScheme colorScheme) {
//     return Card(
//       color: colorScheme.surfaceContainerHighest,
//       elevation: 4,
//       shadowColor: colorScheme.shadow.withOpacity(0.2),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: colorScheme.primary.withOpacity(0.3),
//           width: 2,
//         ),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: () {
//           debugPrint("Lecture Selected: ${note.lectureTitle}");
//           Navigator.push(
//             context,
//             PageTransition(
//               child: LectureDetailScreen(lecture: note),
//               type: PageTransitionType.rightToLeft,
//               duration: const Duration(milliseconds: 300),
//             ),
//           );
//         },
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header row with lecture number and arrow
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: colorScheme.primary.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: colorScheme.primary,
//                         width: 2,
//                       ),
//                     ),
//                     child: Text(
//                       "Lecture ${note.lectureNumber}",
//                       style: TextStyle(
//                         color: colorScheme.primary,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                   const Spacer(),
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: colorScheme.primary.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: colorScheme.primary.withOpacity(0.5),
//                         width: 1,
//                       ),
//                     ),
//                     child: Icon(
//                       LineIcons.arrowRight,
//                       color: colorScheme.primary,
//                       size: 16,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               // Lecture title
//               Text(
//                 note.lectureTitle,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: colorScheme.onSurface,
//                   height: 1.3,
//                 ),
//                 maxLines: 3,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 12),

//               // Lecture description
//               if (note.lectureDescription.isNotEmpty) ...[
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: colorScheme.surface.withOpacity(0.7),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: colorScheme.outline.withOpacity(0.2),
//                       width: 1,
//                     ),
//                   ),
//                   child: Text(
//                     note.lectureDescription,
//                     style: TextStyle(
//                       color: colorScheme.onSurface.withOpacity(0.9),
//                       fontSize: 14,
//                       height: 1.4,
//                     ),
//                     maxLines: 3,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//               ],

//               // Footer row with date and subject
//               Row(
//                 children: [
//                   // Subject section
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: colorScheme.secondary.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: colorScheme.secondary.withOpacity(0.4),
//                         width: 1.5,
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           LineIcons.book,
//                           size: 14,
//                           color: colorScheme.secondary,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           note.subject,
//                           style: TextStyle(
//                             color: colorScheme.secondary,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 12),

//               // Date section - moved below subject for better layout
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: colorScheme.secondary.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: colorScheme.secondary.withOpacity(0.4),
//                         width: 1,
//                       ),
//                     ),
//                     child: Icon(
//                       LineIcons.calendar,
//                       size: 14,
//                       color: colorScheme.secondary,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     "Published ${_formatDate(note.pubDate)}",
//                     style: TextStyle(
//                       color: colorScheme.onSurface.withOpacity(0.7),
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/features/msnotes/notes_detail.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  SearchState createState() => SearchState();
}

class SearchState extends State<Search> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  List<MSNote> _filteredResults = [];
  List<MSNote> _allItems = [];
  String? _selectedSubject;
  List<String> _availableSubjects = [];
  bool _isLoading = true;

  // Cached formatters
  final DateFormat _dateFormatter = DateFormat('MMMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _loadNotesFromHive();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotesFromHive() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var box = Hive.box<MSNote>('notesBox');
      final allItems = box.values.toList();

      // Extract subjects once
      final subjects = <String>{};
      for (final note in allItems) {
        subjects.add(note.subject);
      }

      if (mounted) {
        setState(() {
          _allItems = allItems;
          _filteredResults = allItems;
          _availableSubjects = subjects.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(context, "Failed to load data from Hive: $e");
      }
    }
  }

  void _search(String query) {
    if (!mounted) return;

    final String lowercaseQuery = query.toLowerCase();
    final bool hasSubjectFilter = _selectedSubject != null;

    setState(() {
      _filteredResults = _allItems.where((note) {
        // Skip subject check if no filter is applied
        if (hasSubjectFilter && note.subject != _selectedSubject) {
          return false;
        }

        // Skip query check if query is empty
        if (query.isEmpty) {
          return true;
        }

        // Check if note matches query
        return note.lectureTitle.toLowerCase().contains(lowercaseQuery) ||
            note.lectureDescription.toLowerCase().contains(lowercaseQuery) ||
            note.subject.toLowerCase().contains(lowercaseQuery) ||
            (note.body?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    });
  }

  String _formatDate(String pubDate) {
    try {
      final date = DateTime.parse(pubDate).toLocal();
      return _dateFormatter.format(date);
    } catch (e) {
      return pubDate; // Fallback to original if formatting fails
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(title: "Search"),
      body: _isLoading
          ? _buildLoadingState(colorScheme)
          : _buildSearchContent(colorScheme),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading notes...",
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildSearchBar(colorScheme),
          const SizedBox(height: 24),
          _buildSubjectTags(colorScheme),
          const SizedBox(height: 24),
          Expanded(child: _buildSearchResults(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _search,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          hintText: "Search lectures, subjects, or descriptions...",
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LineIcons.search,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  padding: const EdgeInsets.all(12),
                  icon: Icon(
                    LineIcons.timesCircle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectTags(ColorScheme colorScheme) {
    if (_availableSubjects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Filter by Subject",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableSubjects.length,
            itemBuilder: (context, index) {
              final subject = _availableSubjects[index];
              final isSelected = _selectedSubject == subject;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(
                    subject,
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedSubject = selected ? subject : null;
                    });
                    _search(_searchController.text);
                  },
                  checkmarkColor: colorScheme.onPrimary,
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.3),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: isSelected ? 4 : 0,
                  shadowColor: colorScheme.primary.withOpacity(0.3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(ColorScheme colorScheme) {
    if (_filteredResults.isEmpty) {
      return _buildEmptyResults(colorScheme);
    }

    return ListView.builder(
      itemCount: _filteredResults.length,
      physics: const BouncingScrollPhysics(),
      itemExtent: 280, // Fixed height for better performance
      cacheExtent: 500, // Cache more items for smoother scrolling
      itemBuilder: (context, index) {
        final MSNote note = _filteredResults[index];
        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSearchResultCard(note, colorScheme),
          ),
        );
      },
    );
  }

  Widget _buildEmptyResults(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LineIcons.search,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? "No notes available"
                : "No results found",
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Try adjusting your search terms",
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(MSNote note, ColorScheme colorScheme) {
    // Pre-calculate formatted date to avoid doing it during build
    final formattedDate = _formatDate(note.pubDate);

    return Card(
      color: colorScheme.surfaceContainerHighest,
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              child: LectureDetailScreen(lecture: note),
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced from 20
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with lecture number and arrow
              _buildCardHeader(note, colorScheme),
              const SizedBox(height: 12), // Reduced from 16

              // Lecture title
              Text(
                note.lectureTitle,
                style: TextStyle(
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  height: 1.2, // Reduced from 1.3
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8), // Reduced from 12

              // Lecture description - only if there's space
              if (note.lectureDescription.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10), // Reduced from 12
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    note.lectureDescription,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.9),
                      fontSize: 13, // Reduced from 14
                      height: 1.3, // Reduced from 1.4
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12), // Reduced from 16

              // Footer with subject and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subject tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, // Reduced from 12
                      vertical: 6, // Reduced from 8
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LineIcons.book,
                          size: 12, // Reduced from 14
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          note.subject,
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 11, // Reduced from 12
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6), // Reduced from 8

                  // Date info
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LineIcons.calendar,
                        size: 12, // Reduced from 14
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 6), // Reduced from 8
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12, // Reduced from 13
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(MSNote note, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          child: Text(
            "Lecture ${note.lectureNumber}",
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            LineIcons.arrowRight,
            color: colorScheme.primary,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionBox(MSNote note, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            note.lectureDescription,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubjectTag(MSNote note, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LineIcons.book,
            size: 14,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            note.subject,
            style: TextStyle(
              color: colorScheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String formattedDate, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.secondary.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Icon(
            LineIcons.calendar,
            size: 14,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Published $formattedDate",
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
