import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/font_provider.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';

class FontSelectionPage extends StatefulWidget {
  const FontSelectionPage({super.key});

  @override
  State<FontSelectionPage> createState() => _FontSelectionPageState();
}

class _FontSelectionPageState extends State<FontSelectionPage> {
  String? _selectedFontFamily;
  final String _previewText =
      'The quick brown fox jumps over the lazy dog. 1234567890';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fontProvider = Provider.of<FontProvider>(context, listen: false);
      setState(() {
        _selectedFontFamily = fontProvider.selectedFontFamily;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Font Selection',
        showBackButton: true,
      ),
      body: Consumer<FontProvider>(
        builder: (context, fontProvider, child) {
          return Column(
            children: [
              // Live Preview Section
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Heading preview
                    Text(
                      'Heading Text',
                      style: fontProvider.getPreviewTextStyle(
                        _selectedFontFamily ?? fontProvider.selectedFontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Body text preview
                    Text(
                      _previewText,
                      style: fontProvider.getPreviewTextStyle(
                        _selectedFontFamily ?? fontProvider.selectedFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Small text preview
                    Text(
                      'Small text for captions and details',
                      style: fontProvider.getPreviewTextStyle(
                        _selectedFontFamily ?? fontProvider.selectedFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Font Categories
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _getGroupedFonts().length,
                  itemBuilder: (context, index) {
                    final groupEntry =
                        _getGroupedFonts().entries.elementAt(index);
                    return _buildFontCategory(
                        groupEntry, fontProvider, colorScheme);
                  },
                ),
              ),

              // Apply Button - Always visible, centered and wide
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed:
                      _selectedFontFamily != fontProvider.selectedFontFamily
                          ? () => _applyFont(fontProvider)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _selectedFontFamily != fontProvider.selectedFontFamily
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.3),
                    foregroundColor:
                        _selectedFontFamily != fontProvider.selectedFontFamily
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation:
                        _selectedFontFamily != fontProvider.selectedFontFamily
                            ? 2
                            : 0,
                  ),
                  icon: Icon(
                    _selectedFontFamily != fontProvider.selectedFontFamily
                        ? LineIcons.check
                        : LineIcons.font,
                    size: 20,
                  ),
                  label: Text(
                    _selectedFontFamily != fontProvider.selectedFontFamily
                        ? 'Apply Font'
                        : 'No Changes to Apply',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFontCategory(
    MapEntry<String, List<FontOption>> group,
    FontProvider fontProvider,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            group.key,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary.withOpacity(0.8),
            ),
          ),
        ),
        ...group.value.map((font) => _buildFontOption(
              font,
              fontProvider,
              colorScheme,
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFontOption(
    FontOption font,
    FontProvider fontProvider,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedFontFamily == font.family;
    final isCurrent = fontProvider.selectedFontFamily == font.family;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isSelected ? LineIcons.check : LineIcons.font,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
        ),
        title: Text(
          font.name,
          style: fontProvider.getPreviewTextStyle(
            font.family,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          font.category,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: isCurrent
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        onTap: () {
          setState(() {
            _selectedFontFamily = font.family;
          });
        },
      ),
    );
  }

  Map<String, List<FontOption>> _getGroupedFonts() {
    const fonts = FontProvider.availableFonts;
    final grouped = <String, List<FontOption>>{};

    for (final font in fonts) {
      if (!grouped.containsKey(font.category)) {
        grouped[font.category] = [];
      }
      grouped[font.category]!.add(font);
    }

    return grouped;
  }

  Future<void> _applyFont(FontProvider fontProvider) async {
    if (_selectedFontFamily == null) return;

    try {
      await fontProvider.setFont(_selectedFontFamily!);
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Font applied successfully!',
          isSuccess: true,
        );
      }
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to apply font: $_selectedFontFamily',
          StackTrace.current.toString());
      FlutterBugfender.error('Failed to apply font: $_selectedFontFamily');

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to apply font: $e',
          isSuccess: false,
        );
      }
    }
  }
}
