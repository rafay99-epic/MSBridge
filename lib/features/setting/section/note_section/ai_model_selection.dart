import 'package:flutter/material.dart';
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

class _AIModelSelectionPageState extends State<AIModelSelectionPage> {
  String? selectedModelName;

  @override
  void initState() {
    super.initState();
    _loadSelectedModel();
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
      CustomSnackBar.show(
          context, "Selected model: ${selectedModel.modelName}");
    } catch (e) {
      CustomSnackBar.show(context, "Error saving selected model: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        title: "AI Model Selection",
        showBackButton: true,
        showTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: ListView.separated(
          itemCount: AIModelsConfig.models.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final model = AIModelsConfig.models[index];
            final isSelected = model.name == selectedModelName;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedModelName = model.name;
                });
              },
              child: Card(
                color: theme.cardColor,
                elevation: isSelected ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                    width: isSelected ? 4 : 2,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          model.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        subtitle: Text(
                          model.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: theme.colorScheme.primary, size: 28)
                            : Icon(Icons.radio_button_off,
                                color: theme.colorScheme.secondary),
                        onTap: () {
                          setState(() {
                            selectedModelName = model.name;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saveSelectedModel,
        icon: Icon(LineIcons.save, color: theme.colorScheme.surface),
        label: Text(
          "Save Selection",
          style: TextStyle(color: theme.colorScheme.surface),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
