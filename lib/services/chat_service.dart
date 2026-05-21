import 'package:dart_openai/dart_openai.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool get isListening => _isListening;

  ChatService() {
    // ⚠️ ADD YOUR OWN GROQ API CREDENTIALS BELOW
    // Get your API key from: https://console.groq.com/keys
    OpenAI.baseUrl = 'YOUR_GROQ_BASE_URL';  // e.g. 'https://api.groq.com/openai'
    OpenAI.apiKey = 'YOUR_GROQ_API_KEY';     // e.g. 'gsk_...'
  }

  // this sends the full chat history to Groq and gets the AI's reply back
  Future<String> getAIResponse(
    List<OpenAIChatCompletionChoiceMessageModel> history,
  ) async {
    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: 'llama-3.3-70b-versatile',
        messages: history,
      );
      return chatCompletion.choices.first.message.content?.first.text ??
          "I couldn't process that query. Please try phrasing it differently.";
    } catch (e) {
      return 'Connection note: Unable to reach Groq API. Details: $e';
    }
  }

  // I used this to let the user talk to the botanist using their voice instead of typing
  Future<void> toggleRecording({
    required Function(String text) onResult,
    required Function(bool listening) onStatusChange,
  }) async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      onStatusChange(false);
    } else {
      final bool available = await _speechToText.initialize();
      if (available) {
        _isListening = true;
        onStatusChange(true);
        _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              onResult(result.recognizedWords);
              _isListening = false;
              onStatusChange(false);
            }
          },
        );
      }
    }
  }
}
