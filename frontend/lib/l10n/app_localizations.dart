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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// The current language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Label for next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Label for create roadmap button
  ///
  /// In en, this message translates to:
  /// **'Create Roadmap'**
  String get createRoadmap;

  /// Label for be detailed of your goal
  ///
  /// In en, this message translates to:
  /// **'Be detailed of your goal!'**
  String get beDetailedOfYourGoal;

  /// Label for tell what your goal is
  ///
  /// In en, this message translates to:
  /// **'Tell your goal is, what can you do so far, and what is the purpose'**
  String get tellWhatYourGoalIs;

  /// Hint text for goal description
  ///
  /// In en, this message translates to:
  /// **'I wanna learn guitar, i can play most basic chords'**
  String get goalDescriptionHintText;

  /// Label for enter button
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// Label for questions screen
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// Label for send button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Label for roadmap screen
  ///
  /// In en, this message translates to:
  /// **'Roadmap'**
  String get roadmap;

  /// Label for before you start
  ///
  /// In en, this message translates to:
  /// **'Before you start...'**
  String get beforeYouStart;

  /// Label for goal started
  ///
  /// In en, this message translates to:
  /// **'Goal started!'**
  String get goalStarted;

  /// Label for let's go button
  ///
  /// In en, this message translates to:
  /// **'LET\'S GO!'**
  String get letSGo;

  /// Label for your answer
  ///
  /// In en, this message translates to:
  /// **'Your answer...'**
  String get yourAnswer;

  /// Validation message for empty answer
  ///
  /// In en, this message translates to:
  /// **'Please answer this question'**
  String get pleaseAnswerThisQuestion;

  /// Label para dias de streak
  ///
  /// In en, this message translates to:
  /// **'dias de streak!'**
  String get dayStreak;

  /// Label para botão continuar
  ///
  /// In en, this message translates to:
  /// **'Continuar'**
  String get continuate;

  /// Label for sunday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Label for monday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Label for tuesday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Label for wednesday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Label for thursday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Label for friday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Label for saturday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Label for sunday short
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// Label for monday short
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// Label for tuesday short
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// Label for wednesday short
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// Label for thursday short
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// Label for friday short
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// Label for saturday short
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// Label for book
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// Label for youtube
  ///
  /// In en, this message translates to:
  /// **'Youtube'**
  String get youtube;

  /// Label for sites
  ///
  /// In en, this message translates to:
  /// **'Sites'**
  String get sites;

  /// Label for lesson session
  ///
  /// In en, this message translates to:
  /// **'Lesson Session'**
  String get lessonSession;

  /// Label for show me what you got
  ///
  /// In en, this message translates to:
  /// **'Show me what you got'**
  String get showMeWhatYouGot;

  /// Label for notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Label for progress
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Label for achievements
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// Label for awards
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get awards;

  /// Label for type your message
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// Label for keep the pressure on
  ///
  /// In en, this message translates to:
  /// **'Yeah, keep the pressure on !!!'**
  String get keepThePressureOn;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
