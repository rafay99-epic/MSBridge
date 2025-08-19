# Version History Feature

## Overview

The Version History feature automatically tracks changes to notes, creating a complete audit trail of all modifications. This allows users to view previous versions of their notes, compare changes, and recover content if needed.

## Features

- **Automatic Version Creation**: Every time a note is edited, a new version is automatically created
- **Version Browsing**: View all versions of a note in chronological order
- **Content Comparison**: Preview previous versions to see what changed
- **Smart Cleanup**: Automatically remove old versions based on user preferences
- **Settings Management**: Configure version retention policies

## Architecture

### Data Models

#### NoteVersion
```dart
class NoteVersion extends HiveObject {
  String? versionId;           // Unique identifier for the version
  String noteId;               // Reference to the parent note
  String noteTitle;            // Title at this version
  String noteContent;          // Content at this version
  List<String> tags;           // Tags at this version
  DateTime createdAt;          // When this version was created
  String userId;               // User who created this version
  String changeDescription;    // Optional description of changes
  int versionNumber;           // Sequential version number
}
```

#### Updated NoteTakingModel
```dart
class NoteTakingModel extends HiveObject {
  // ... existing fields ...
  int versionNumber;           // Current version number
  DateTime createdAt;          // When the note was first created
}
```

### Components

#### 1. NoteVersionRepo
- **Purpose**: Handles all database operations for note versions
- **Features**: CRUD operations, version cleanup, version counting
- **Storage**: Uses Hive for local storage with the `note_versions` box

#### 2. NoteVersionProvider
- **Purpose**: State management for version history UI
- **Features**: Loading versions, error handling, state notifications
- **Integration**: Works with Provider pattern for reactive UI updates

#### 3. VersionHistoryScreen
- **Purpose**: Main UI for viewing version history
- **Features**: Version list, version preview, current version display
- **Navigation**: Accessible from note cards via history icon

#### 4. VersionHistorySettings
- **Purpose**: Configuration and management of version history
- **Features**: Retention policies, cleanup settings, information display

## How It Works

### 1. Version Creation
When a note is updated via `NoteTakingActions.updateNote()`:

```dart
// 1. Create version before updating
await NoteVersionRepo.createVersion(
  noteId: note.noteId!,
  noteTitle: note.noteTitle,
  noteContent: note.noteContent,
  tags: note.tags,
  userId: note.userId,
  versionNumber: note.versionNumber,
  changeDescription: changeDescription,
);

// 2. Update the note
note.versionNumber++;
// ... other updates
```

### 2. Version Storage
- Versions are stored in a separate Hive box (`note_versions`)
- Each version contains a complete snapshot of the note at that point
- Versions are linked to notes via `noteId`
- Automatic cleanup removes old versions based on user settings

### 3. Version Retrieval
- Versions are loaded on-demand when viewing version history
- Sorted by version number (newest first)
- Includes metadata like creation time and change descriptions

## User Experience

### Accessing Version History
1. **From Note Cards**: Tap the history icon (📚) on any note card
2. **Navigation**: Uses page transitions for smooth navigation
3. **Loading States**: Shows loading indicators while fetching versions

### Viewing Versions
1. **Current Version Header**: Shows current note information
2. **Version List**: Chronological list of all versions
3. **Version Preview**: Tap the eye icon to preview a specific version
4. **Empty State**: Helpful message when no versions exist

### Settings Management
1. **Retention Policy**: Configure how many versions to keep (5-50)
2. **Auto Cleanup**: Toggle automatic version cleanup
3. **Manual Cleanup**: Manually trigger cleanup of old versions
4. **Information**: Learn how version history works

## Configuration

### Default Settings
- **Max Versions**: 10 versions per note
- **Auto Cleanup**: Enabled
- **Storage**: Local Hive database

### Customization
Users can modify:
- Number of versions to retain
- Automatic cleanup behavior
- Manual cleanup triggers

## Performance Considerations

### Storage Optimization
- Versions are stored locally for fast access
- Automatic cleanup prevents unlimited storage growth
- Efficient querying using Hive indexes

### UI Performance
- Lazy loading of version data
- Efficient list rendering with ListView.builder
- Minimal state updates using Provider pattern

## Error Handling

### Graceful Degradation
- Version creation failures don't prevent note updates
- UI shows appropriate error states with retry options
- Fallback to basic functionality if version system fails

### User Feedback
- Clear error messages for common issues
- Loading states for long operations
- Success confirmations for completed actions

## Future Enhancements

### Potential Features
1. **Version Comparison**: Side-by-side diff view
2. **Version Restoration**: Restore notes to previous versions
3. **Cloud Sync**: Sync versions across devices
4. **Change Tracking**: Highlight specific changes between versions
5. **Version Tags**: Mark important versions for easy identification

### Technical Improvements
1. **Compression**: Compress old versions to save space
2. **Batch Operations**: Efficient bulk version management
3. **Analytics**: Track version creation patterns
4. **Backup**: Include versions in note backup/restore

## Integration Points

### Existing Systems
- **Note Taking**: Integrates with existing note creation/editing
- **Settings**: Follows existing settings UI patterns
- **Navigation**: Uses existing page transition system
- **Theming**: Respects app-wide theme and color scheme

### Dependencies
- **Hive**: Local database storage
- **Provider**: State management
- **Line Icons**: Icon library
- **Intl**: Date formatting

## Testing

### Manual Testing
1. Create a new note
2. Edit the note multiple times
3. Access version history from note card
4. View different versions
5. Test settings configuration
6. Verify cleanup functionality

### Automated Testing
- Unit tests for NoteVersionRepo
- Provider tests for NoteVersionProvider
- Widget tests for VersionHistoryScreen
- Integration tests for complete workflow

## Troubleshooting

### Common Issues
1. **Versions Not Appearing**: Check Hive box initialization
2. **Performance Issues**: Verify version cleanup is working
3. **Storage Growth**: Monitor version retention settings
4. **UI Errors**: Check Provider setup and error handling

### Debug Information
- Version creation logs in note update operations
- Hive box status and error messages
- Provider state changes and notifications
- UI loading and error states

## Conclusion

The Version History feature provides a robust, user-friendly way to track note changes while maintaining good performance and storage efficiency. It integrates seamlessly with the existing note-taking system and follows the established patterns for UI, state management, and data persistence.
