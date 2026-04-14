// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Bible';

  @override
  String get homeTitle => 'Home';

  @override
  String get readerTitle => 'Bible Reader';

  @override
  String get wordStudyTitle => 'Word Study';

  @override
  String get aiChatTitle => 'AI Assistant';

  @override
  String get loading => 'Loading...';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get oldTestament => 'Old Testament';

  @override
  String get newTestament => 'New Testament';

  @override
  String get selectBook => 'Select Book';

  @override
  String get selectChapter => 'Select Chapter';

  @override
  String get selectTranslation => 'Select Translation';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search verses...';

  @override
  String get noResults => 'No results found';

  @override
  String get strongsNumber => 'Strongs Number';

  @override
  String get hebrew => 'Hebrew';

  @override
  String get greek => 'Greek';

  @override
  String get definition => 'Definition';

  @override
  String get shortDefinition => 'Short Definition';

  @override
  String get fullDefinition => 'Full Definition';
}
