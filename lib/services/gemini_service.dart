import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import '../models/custom_image_content_item.dart';

class GeminiService {
  GeminiService() {
    // ⚠️ ADD YOUR OWN GROQ API CREDENTIALS BELOW
    // Get your API key from: https://console.groq.com/keys
    OpenAI.baseUrl = 'YOUR_GROQ_BASE_URL';  // e.g. 'https://api.groq.com/openai'
    OpenAI.apiKey = 'YOUR_GROQ_API_KEY';     // e.g. 'gsk_...'
  }

  Future<String> generateCarePlan({
    required String plantName,
    required String location,
    required String weatherContext,
    List<int>? imageBytes,
  }) async {
    try {
      final promptText =
          "You are an expert, disciplined AI botanist. The user wants to plant '$plantName' in "
          "this location: '$location'. The current local weather is: $weatherContext. "
          "Provide a concise, 3-step action plan for planting and watering. Keep it simple, "
          "highly practical, and formatted cleanly for a beginner.";

      final List<OpenAIChatCompletionChoiceMessageContentItemModel>
          contentParts = [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(promptText),
      ];

      // if the user attached a photo I switch to the vision model to analyze it
      String modelToUse = 'llama-3.3-70b-versatile';
      if (imageBytes != null && imageBytes.isNotEmpty) {
        modelToUse = 'llama-3.2-90b-vision-preview';
        final base64Image = base64Encode(imageBytes);
        contentParts.add(
          CustomImageContentItem(
            'data:image/jpeg;base64,$base64Image',
          ),
        );
      }

      final chatCompletion = await OpenAI.instance.chat.create(
        model: modelToUse,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: contentParts,
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      return chatCompletion.choices.first.message.content?.first.text ??
          'Cultivation plan generated. Standard watering rules apply.';
    } catch (e) {
      return 'Groq connection note: Unable to generate personalised plan. Details: $e';
    }
  }
}
