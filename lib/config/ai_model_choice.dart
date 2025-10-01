// Project imports:
import 'package:msbridge/core/models/ai_model.dart';

class AIModelsConfig {
  static const String selectedModelKey = 'selected_ai_model';

  static List<AIModel> get models => [
        AIModel(
          name: "Gemini 2.5 Flash",
          modelName: "gemini-2.5-flash",
          description:
              "Gemini 2.5 Flash, a powerful and fast AI model designed for real-time applications.",
        ),
        AIModel(
          name: "Gemini 2.5 Pro",
          modelName: "gemini-2.5-pro",
          description:
              "Gemini 2.5 Pro, a powerful and fast AI model designed for real-time applications.",
        ),
        AIModel(
          name: "Gemini 2.0 Flash",
          modelName: "gemini-2.0-flash",
          description:
              "Gemini 2.0 Flash, a powerful and fast AI model designed for real-time applications.",
        ),
      ];
}
