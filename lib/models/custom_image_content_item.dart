import 'package:dart_openai/dart_openai.dart';

class CustomImageContentItem implements OpenAIChatCompletionChoiceMessageContentItemModel {
  @override
  final String type = 'image_url';
  
  @override
  final String? imageUrl;
  
  @override
  final String? text = null;

  CustomImageContentItem(this.imageUrl);

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'image_url',
      'image_url': {
        'url': imageUrl,
      },
    };
  }
}
