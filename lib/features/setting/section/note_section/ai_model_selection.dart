import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/ai_model_choice.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIModelSelectionPage extends StatefulWidget {
  const AIModelSelectionPage({super.key});

  @override
  State<AIModelSelectionPage> createState() => _AIModelSelectionPageState();
}

class _AIModelSelectionPageState extends State<AIModelSelectionPage>
    with TickerProviderStateMixin {
  String? selectedModelName;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSelectedModel();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  Future<void> _loadSelectedModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModelName = prefs.getString(AIModelsConfig.selectedModelKey) ??
          'gemini-1.5-pro-latest';

      final selectedModel = AIModelsConfig.models.firstWhere(
        (model) => model.modelName == savedModelName,
        orElse: () => AIModelsConfig.models.first,
      );

      setState(() {
        selectedModelName = selectedModel.name;
      });
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error loading selected model: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error loading selected model: $e');
      CustomSnackBar.show(context, "Error loading selected model: $e");
      setState(() {
        selectedModelName = AIModelsConfig.models.first.name;
      });
    }
  }

  Future<void> saveSelectedModel() async {
    try {
      final selectedModel = AIModelsConfig.models.firstWhere(
        (model) => model.name == selectedModelName,
        orElse: () => AIModelsConfig.models.first,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AIModelsConfig.selectedModelKey, selectedModel.modelName);
      CustomSnackBar.show(context, "Selected model: ${selectedModel.name}");
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error saving selected model: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error saving selected model: $e');
      CustomSnackBar.show(context, "Error saving selected model: $e");
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "AI Model Selection",
        showBackButton: true,
        showTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                _buildHeaderSection(context, colorScheme, theme),

                // Models List
                _buildModelsList(context, colorScheme, theme),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildSaveButton(context, colorScheme, theme),
    );
  }

  Widget _buildHeaderSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.05),
            colorScheme.secondary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LineIcons.robot,
              size: 32,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            "Choose Your AI Model",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            "Select the AI model that best fits your needs. Each model has different capabilities and performance characteristics.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModelsList(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (int index = 0;
              index < AIModelsConfig.models.length;
              index++) ...[
            _buildModelCard(
                context,
                AIModelsConfig.models[index],
                AIModelsConfig.models[index].name == selectedModelName,
                colorScheme,
                theme,
                index),
            if (index < AIModelsConfig.models.length - 1)
              const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, dynamic model, bool isSelected,
      ColorScheme colorScheme, ThemeData theme, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedModelName = model.name;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.05)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected
                              ? colorScheme.primary
                              : colorScheme.shadow)
                          .withOpacity(0.1),
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Model Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.2)
                                  : colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LineIcons.robot,
                              size: 24,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.primary.withOpacity(0.7),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Model Name
                          Expanded(
                            child: Text(
                              model.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.primary,
                              ),
                            ),
                          ),

                          // Selection Indicator
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.check
                                  : Icons.radio_button_unchecked,
                              size: 20,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.outline,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        model.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Model Details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LineIcons.infoCircle,
                              size: 16,
                              color: colorScheme.primary.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Model ID: ${model.modelName}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary.withOpacity(0.6),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: FloatingActionButton.extended(
        onPressed: saveSelectedModel,
        icon: Icon(
          LineIcons.save,
          color: colorScheme.onPrimary,
          size: 20,
        ),
        label: Text(
          "Save Selection",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
