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

  /// Options menu
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// Goals tab label
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// Agenda tab label
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// How to use section title
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Name sort button label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Time sort button label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Empty state title when no goals exist
  ///
  /// In en, this message translates to:
  /// **'Set up your Goals'**
  String get setUpYourGoals;

  /// Empty state message when no goals exist
  ///
  /// In en, this message translates to:
  /// **'Create your first goal to get started!'**
  String get createFirstGoalMessage;

  /// Snackbar message when goal is deleted
  ///
  /// In en, this message translates to:
  /// **'Goal \"{goalTitle}\" deleted'**
  String goalDeleted(String goalTitle);

  /// Undo button label
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Title for create goal screen
  ///
  /// In en, this message translates to:
  /// **'Create New Goal'**
  String get createNewGoal;

  /// Label for goal title field
  ///
  /// In en, this message translates to:
  /// **'Goal Title'**
  String get goalTitle;

  /// Hint text for goal title field
  ///
  /// In en, this message translates to:
  /// **'e.g., Read a book'**
  String get goalTitleHint;

  /// Validation message for empty goal title
  ///
  /// In en, this message translates to:
  /// **'Please enter a goal title'**
  String get pleaseEnterGoalTitle;

  /// Label for description field
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get description;

  /// Hint text for description field
  ///
  /// In en, this message translates to:
  /// **'Describe your goal in detail...'**
  String get descriptionHint;

  /// Section title for weekly time commitment
  ///
  /// In en, this message translates to:
  /// **'Weekly Time Commitment'**
  String get weeklyTimeCommitment;

  /// Validation message for empty weekly time
  ///
  /// In en, this message translates to:
  /// **'Please enter weekly time commitment'**
  String get pleaseEnterWeeklyTime;

  /// Validation message for zero weekly time
  ///
  /// In en, this message translates to:
  /// **'Weekly time must be greater than 0'**
  String get weeklyTimeMustBeGreater;

  /// Validation message for exceeding max weekly time
  ///
  /// In en, this message translates to:
  /// **'Weekly time cannot exceed {maxHours} hours'**
  String weeklyTimeCannotExceed(int maxHours);

  /// Helper text about creating tasks later
  ///
  /// In en, this message translates to:
  /// **'You can create tasks for this goal later'**
  String get youCanCreateTasksLater;

  /// Create button label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Success message when goal is created
  ///
  /// In en, this message translates to:
  /// **'Goal created successfully!'**
  String get goalCreatedSuccessfully;

  /// Create task button label
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// Validation message for required field
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get thisFieldIsRequired;

  /// Validation message for invalid number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// Validation message for negative value
  ///
  /// In en, this message translates to:
  /// **'Value must be non-negative'**
  String get valueMustBeNonNegative;

  /// Label for hours field
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// Label for minutes field
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// Validation message for minutes greater than 60
  ///
  /// In en, this message translates to:
  /// **'Minutes must be less than 60'**
  String get minutesMustBeLessThan60;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Success message when goal is updated
  ///
  /// In en, this message translates to:
  /// **'Goal updated successfully!'**
  String get goalUpdatedSuccessfully;

  /// Snackbar message when goal is updated
  ///
  /// In en, this message translates to:
  /// **'Goal updated'**
  String get goalUpdated;
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
