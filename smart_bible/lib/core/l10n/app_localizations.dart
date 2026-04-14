import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt'),
    Locale('en'),
  ];

  /// Nome do aplicativo
  ///
  /// In pt, this message translates to:
  /// **'Smart Bible'**
  String get appTitle;

  /// Título da tela inicial
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get homeTitle;

  /// Título da tela do leitor
  ///
  /// In pt, this message translates to:
  /// **'Leitor Bíblico'**
  String get readerTitle;

  /// Título da tela de estudo de palavras
  ///
  /// In pt, this message translates to:
  /// **'Estudo de Palavras'**
  String get wordStudyTitle;

  /// Título da tela do chat com IA
  ///
  /// In pt, this message translates to:
  /// **'Assistente IA'**
  String get aiChatTitle;

  /// Texto de carregamento
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loading;

  /// Mensagem de erro genérica
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro'**
  String get errorGeneric;

  /// Nome do Antigo Testamento
  ///
  /// In pt, this message translates to:
  /// **'Antigo Testamento'**
  String get oldTestament;

  /// Nome do Novo Testamento
  ///
  /// In pt, this message translates to:
  /// **'Novo Testamento'**
  String get newTestament;

  /// Botão de seleção de livro
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Livro'**
  String get selectBook;

  /// Botão de seleção de capítulo
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Capítulo'**
  String get selectChapter;

  /// Botão de seleção de tradução
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Tradução'**
  String get selectTranslation;

  /// Texto de busca
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get search;

  /// Dica do campo de busca
  ///
  /// In pt, this message translates to:
  /// **'Buscar versículos...'**
  String get searchHint;

  /// Mensagem quando não há resultados
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado encontrado'**
  String get noResults;

  /// Rótulo do número Strong
  ///
  /// In pt, this message translates to:
  /// **'Número Strong'**
  String get strongsNumber;

  /// Idioma hebraico
  ///
  /// In pt, this message translates to:
  /// **'Hebraico'**
  String get hebrew;

  /// Idioma grego
  ///
  /// In pt, this message translates to:
  /// **'Grego'**
  String get greek;

  /// Rótulo de definição
  ///
  /// In pt, this message translates to:
  /// **'Definição'**
  String get definition;

  /// Rótulo de definição breve
  ///
  /// In pt, this message translates to:
  /// **'Definição breve'**
  String get shortDefinition;

  /// Rótulo de definição completa
  ///
  /// In pt, this message translates to:
  /// **'Definição completa'**
  String get fullDefinition;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
