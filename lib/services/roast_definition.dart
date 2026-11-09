import '../models/roast.dart';

/// Structured definition for a base roast item across all supported languages.
class RoastDefinition {
  final String id;
  final RoastIntensity intensity;
  final RoastCategory situation;
  final String category;
  final String mascotEmoji;
  final Map<String, String> translations;

  const RoastDefinition({
    required this.id,
    required this.intensity,
    required this.situation,
    required this.category,
    required this.mascotEmoji,
    required this.translations,
  });

  /// Converts this definition into a localized RoastItem for the specified language.
  RoastItem toRoastItem(String language) {
    final text = translations[language] ?? translations['English'] ?? '';
    return RoastItem(
      id: id,
      language: language,
      text: text,
      category: category,
      mascotEmoji: mascotEmoji,
      situation: situation,
      intensity: intensity,
    );
  }
}

