import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  SearchState createState() => SearchState();
}

class SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredResults = [];
  final List<String> _allItems = [
    "Flutter",
    "Dart",
    "React",
    "Astro",
    "Firebase",
    "Tailwind CSS",
    "Node.js",
    "MongoDB",
    "TypeScript",
    "GraphQL",
    "Vercel",
  ];

  void _search(String query) {
    setState(() {
      _filteredResults = _allItems
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Search"),
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
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
                  hintStyle: TextStyle(
                      color: theme.colorScheme.primary.withOpacity(0.6)),
                  prefixIcon: Icon(LineIcons.search,
                      color: theme.colorScheme.secondary),
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
            ),
            const SizedBox(height: 16),

            // Search Results
            Expanded(
              child: _filteredResults.isEmpty
                  ? Center(
                      child: Text(
                        "No results found",
                        style: TextStyle(
                            color: theme.colorScheme.primary.withOpacity(0.7)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        return _buildSearchResultTile(
                            _filteredResults[index], theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(String title, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {}, // Handle click
        borderRadius: BorderRadius.circular(8),
        splashColor: theme.colorScheme.secondary.withOpacity(0.2),
        highlightColor: theme.colorScheme.secondary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading:
                Icon(LineIcons.fileAlt, color: theme.colorScheme.secondary),
            title:
                Text(title, style: TextStyle(color: theme.colorScheme.primary)),
            trailing:
                Icon(LineIcons.angleRight, color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
