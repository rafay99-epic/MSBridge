import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';

class AdvancedNoteSearchService {
  static const double _titleMatchWeight = 3.0;
  static const double _contentMatchWeight = 1.0;
  static const double _tagMatchWeight = 2.0;
  static const double fuzzyThreshold = 0.3;

  /// Extract plain text from Quill Delta content
  static String extractPlainTextFromQuill(String quillContent) {
    try {
      // Quick check for common patterns to avoid expensive parsing
      if (quillContent.length < 50) return quillContent;

      final jsonResult = jsonDecode(quillContent);
      if (jsonResult is List) {
        final document = Document.fromJson(jsonResult);
        return document.toPlainText();
      } else if (jsonResult is Map) {
        // Handle both formats: direct ops array or nested ops
        if (jsonResult['ops'] != null) {
          final ops = jsonResult['ops'] as List;
          final document = Document.fromJson(ops);
          return document.toPlainText();
        } else if (jsonResult['delta'] != null) {
          final delta = jsonResult['delta'] as List;
          final document = Document.fromJson(delta);
          return document.toPlainText();
        }
      }
    } catch (e) {
      // If parsing fails, return the raw content as fallback
      return quillContent;
    }
    return quillContent;
  }

  /// Perform advanced search with multiple criteria
  static List<NoteSearchResult> searchNotes({
    required List<NoteTakingModel> notes,
    required String query,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? tags,
    bool includeDeleted = false,
  }) {
    if (query.trim().isEmpty &&
        fromDate == null &&
        toDate == null &&
        tags == null) {
      return notes
          .map((note) => NoteSearchResult(
              note: note, relevanceScore: 1.0, matchPositions: []))
          .toList();
    }

    final List<NoteSearchResult> results = [];
    final String lowerCaseQuery = query.toLowerCase().trim();

    // Pre-filter notes for better performance
    final filteredNotes = notes.where((note) {
      // Skip deleted notes if not included
      if (!includeDeleted && note.isDeleted) return false;

      // Apply date filter early
      if (!_matchesDateFilter(note, fromDate, toDate)) return false;

      // Apply tag filter early
      if (!_matchesTagFilter(note, tags)) return false;

      return true;
    }).toList();

    // Limit processing for very large note collections
    final notesToProcess = filteredNotes.length > 500
        ? filteredNotes.take(500).toList()
        : filteredNotes;

    // Process in smaller batches for better performance
    const int batchSize = 100;
    for (int i = 0; i < notesToProcess.length; i += batchSize) {
      final endIndex = (i + batchSize < notesToProcess.length)
          ? i + batchSize
          : notesToProcess.length;
      final batch = notesToProcess.sublist(i, endIndex);

      for (final note in batch) {
        // Calculate search relevance
        final searchResult = _calculateSearchRelevance(note, lowerCaseQuery);

        if (searchResult.relevanceScore > 0) {
          results.add(searchResult);

          // Early exit if we have enough high-quality results
          if (results.length >= 100 && searchResult.relevanceScore < 1.0) {
            break;
          }
        }
      }

      // Early exit if we have enough results
      if (results.length >= 100) break;
    }

    // Sort by relevance score (highest first)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    // Limit results for performance
    return results.take(100).toList();
  }

  /// Calculate search relevance score for a note
  static NoteSearchResult _calculateSearchRelevance(
      NoteTakingModel note, String query) {
    if (query.isEmpty) {
      return NoteSearchResult(
          note: note, relevanceScore: 1.0, matchPositions: []);
    }

    double totalScore = 0.0;
    final List<MatchPosition> matchPositions = [];

    // Search in title
    final titleMatches = _findMatches(note.noteTitle, query);
    if (titleMatches.isNotEmpty) {
      totalScore += titleMatches.length * _titleMatchWeight;
      matchPositions.addAll(titleMatches.map((m) => MatchPosition(
            field: 'title',
            start: m.start,
            end: m.end,
            weight: _titleMatchWeight,
          )));
    }

    // Search in content (parsed from Quill)
    final plainContent = extractPlainTextFromQuill(note.noteContent);
    final contentMatches = _findMatches(plainContent, query);
    if (contentMatches.isNotEmpty) {
      totalScore += contentMatches.length * _contentMatchWeight;
      matchPositions.addAll(contentMatches.map((m) => MatchPosition(
            field: 'content',
            start: m.start,
            end: m.end,
            weight: _contentMatchWeight,
          )));
    }

    // Search in tags (if available)
    if (note.tags.isNotEmpty) {
      for (final tag in note.tags) {
        final tagMatches = _findMatches(tag, query);
        if (tagMatches.isNotEmpty) {
          totalScore += tagMatches.length * _tagMatchWeight;
          matchPositions.addAll(tagMatches.map((m) => MatchPosition(
                field: 'tag',
                start: m.start,
                end: m.end,
                weight: _tagMatchWeight,
              )));
        }
      }
    }

    // Apply fuzzy matching bonus
    if (totalScore > 0) {
      totalScore += _calculateFuzzyBonus(note, query);
    }

    return NoteSearchResult(
      note: note,
      relevanceScore: totalScore,
      matchPositions: matchPositions,
    );
  }

  /// Find exact and partial matches in text
  static List<TextMatch> _findMatches(String text, String query) {
    final List<TextMatch> matches = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    // Exact substring matches
    int startIndex = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, startIndex);
      if (index == -1) break;

      matches.add(TextMatch(
        start: index,
        end: index + lowerQuery.length,
        type: MatchType.exact,
      ));
      startIndex = index + 1;
    }

    // Word boundary matches
    final words = lowerText.split(RegExp(r'\s+'));
    int wordStartIndex = 0;
    for (final word in words) {
      if (word.startsWith(lowerQuery) || word.contains(lowerQuery)) {
        final wordIndex = lowerText.indexOf(word, wordStartIndex);
        if (wordIndex != -1) {
          matches.add(TextMatch(
            start: wordIndex,
            end: wordIndex + word.length,
            type: MatchType.partial,
          ));
        }
      }
      wordStartIndex += word.length + 1;
    }

    return matches;
  }

  /// Calculate fuzzy matching bonus
  static double _calculateFuzzyBonus(NoteTakingModel note, String query) {
    final title = note.noteTitle.toLowerCase();
    final content = extractPlainTextFromQuill(note.noteContent).toLowerCase();

    double bonus = 0.0;

    // Check if query words appear in title or content in any order
    final queryWords =
        query.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    for (final word in queryWords) {
      if (title.contains(word)) bonus += 0.5;
      if (content.contains(word)) bonus += 0.2;
    }

    return bonus;
  }

  /// Check if note matches date filter
  static bool _matchesDateFilter(
      NoteTakingModel note, DateTime? fromDate, DateTime? toDate) {
    if (fromDate == null && toDate == null) return true;

    final noteDate = note.createdAt;

    if (fromDate != null && noteDate.isBefore(fromDate)) return false;
    if (toDate != null && noteDate.isAfter(toDate)) return false;

    return true;
  }

  /// Check if note matches tag filter
  static bool _matchesTagFilter(NoteTakingModel note, List<String>? tags) {
    if (tags == null || tags.isEmpty) return true;
    if (note.tags.isEmpty) return false;

    return tags.any((tag) => note.tags.contains(tag));
  }

  /// Get search suggestions based on note titles and content
  static List<String> getSearchSuggestions(
      List<NoteTakingModel> notes, String partialQuery) {
    if (partialQuery.length < 2) return [];

    final Set<String> suggestions = {};
    final String lowerQuery = partialQuery.toLowerCase();

    // Limit processing to first 100 notes for performance
    final notesToProcess = notes.take(100).toList();

    for (final note in notesToProcess) {
      // Add title suggestions
      if (note.noteTitle.toLowerCase().contains(lowerQuery)) {
        suggestions.add(note.noteTitle);
        if (suggestions.length >= 10) break; // Early exit
      }

      // Add content word suggestions (limit processing)
      if (suggestions.length < 10) {
        final content = extractPlainTextFromQuill(note.noteContent);
        final words =
            content.split(RegExp(r'\s+')).take(20); // Limit words per note
        for (final word in words) {
          if (word.toLowerCase().startsWith(lowerQuery) && word.length > 2) {
            suggestions.add(word);
            if (suggestions.length >= 10) break;
          }
        }
      }

      // Add tag suggestions
      if (suggestions.length < 10 && note.tags.isNotEmpty) {
        for (final tag in note.tags) {
          if (tag.toLowerCase().contains(lowerQuery)) {
            suggestions.add(tag);
            if (suggestions.length >= 10) break;
          }
        }
      }

      if (suggestions.length >= 10) break; // Early exit
    }

    return suggestions.take(10).toList();
  }
}

/// Data class for search results
class NoteSearchResult {
  final NoteTakingModel note;
  final double relevanceScore;
  final List<MatchPosition> matchPositions;

  NoteSearchResult({
    required this.note,
    required this.relevanceScore,
    required this.matchPositions,
  });
}

/// Data class for match positions
class MatchPosition {
  final String field;
  final int start;
  final int end;
  final double weight;

  MatchPosition({
    required this.field,
    required this.start,
    required this.end,
    required this.weight,
  });
}

/// Data class for text matches
class TextMatch {
  final int start;
  final int end;
  final MatchType type;

  TextMatch({
    required this.start,
    required this.end,
    required this.type,
  });
}

/// Enum for match types
enum MatchType {
  exact,
  partial,
  fuzzy,
}
