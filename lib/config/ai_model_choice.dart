import 'package:msbridge/core/models/ai_model.dart';

class AIModelsConfig {
  static const String selectedModelKey = 'selected_ai_model';

  static List<AIModel> get models => [
        AIModel(
          name: "Gemini 1.5 Pro Latest",
          modelName: "gemini-1.5-pro-latest",
          description:
              "The latest version of Gemini 1.5 Pro, optimized for reasoning and summarization.",
        ),
        AIModel(
          name: "Gemini 1.5 Pro",
          modelName: "gemini-1.5-pro",
          description:
              "Gemini 1.5 Pro, capable of handling large-scale multimodal tasks efficiently.",
        ),
        AIModel(
          name: "Gemini 1.5 Flash",
          modelName: "gemini-1.5-flash",
          description:
              "A lightweight and faster version of Gemini 1.5, optimized for real-time responses.",
        ),
        AIModel(
          name: "Gemini 2.0 Pro Experimental",
          modelName: "gemini-2.0-pro-experimental",
          description:
              "An experimental version of Gemini 2.0 with advanced reasoning capabilities.",
        ),
        AIModel(
          name: "Gemini Pro",
          modelName: "gemini-pro",
          description:
              "Gemini Pro, a general-purpose AI model designed for high-quality text generation.",
        ),
        AIModel(
          name: "Gemma 1 - 2B",
          modelName: "gemma-1-2b",
          description:
              "Gemma 1 with 2 billion parameters, optimized for lightweight AI tasks.",
        ),
        AIModel(
          name: "Gemma 1 - 7B",
          modelName: "gemma-1-7b",
          description:
              "Gemma 1 with 7 billion parameters, ideal for more complex AI applications.",
        ),
        AIModel(
          name: "Gemma 2 - 2B",
          modelName: "gemma-2-2b",
          description:
              "Gemma 2 with 2 billion parameters, updated for improved efficiency.",
        ),
        AIModel(
          name: "Gemma 2 - 9B",
          modelName: "gemma-2-9b",
          description:
              "Gemma 2 with 9 billion parameters, providing better performance for AI tasks.",
        ),
        AIModel(
          name: "Gemma 2 - 27B",
          modelName: "gemma-2-27b",
          description:
              "Gemma 2 with 27 billion parameters, offering state-of-the-art AI capabilities.",
        ),
        AIModel(
          name: "Gemma 3 - 128K",
          modelName: "gemma-3-128k",
          description:
              "Gemma 3 with a 128K token context window for extensive text understanding.",
        ),
      ];
}
