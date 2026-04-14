/// App-wide constants for Smart Bible.
library;

class AppConstants {
  const AppConstants._();

  static const String appName = 'Smart Bible';
  static const String appVersion = '1.0.0';

  // Database file names (shipped in assets)
  static const String bibleDbFileName = 'bible.db';
  static const String strongsDbFileName = 'strongs.db';

  // Default reading settings
  static const String defaultTranslationId = 'ARA';
  static const int defaultBookId = 43; // John
  static const int defaultChapter = 3;

  // AI model settings
  static const String defaultAiModel = 'gemma-4-e2b';
  static const int maxAiContextTokens = 4096;

  // UI
  static const double verseTextSizeDefault = 18.0;
  static const double verseTextSizeMin = 12.0;
  static const double verseTextSizeMax = 32.0;
}
