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

  /// Label for commited field
  ///
  /// In en, this message translates to:
  /// **'Commited'**
  String get commited;

  /// Label for reserved field
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

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

  /// Snackbar message when task is deleted
  ///
  /// In en, this message translates to:
  /// **'Task \"{taskTitle}\" deleted'**
  String taskDeleted(String taskTitle);

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

  /// Hint text for goal field
  ///
  /// In en, this message translates to:
  /// **'Goal (optional)'**
  String get goalOptional;

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

  /// Label for time reserved field
  ///
  /// In en, this message translates to:
  /// **'Time reserved'**
  String get timeReserved;

  /// Label for delete goal button
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get deleteGoal;

  /// Confirmation message for deleting goal
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the goal \"{goalTitle}\"? This action cannot be undone.'**
  String areYouSureYouWantToDeleteGoal(String goalTitle);

  /// Label for cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Message for goal needs time
  ///
  /// In en, this message translates to:
  /// **'{goalTitle} needs +{minutesMissing}min/w'**
  String goalNeedsTime(String goalTitle, int minutesMissing);

  /// Label for dismiss button
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Message for required fields
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields.'**
  String get pleaseFillAllRequiredFields;

  /// Label for title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Label for create task screen
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// Helper text for specific goal selection
  ///
  /// In en, this message translates to:
  /// **'If the task has a specific goal, you can select it here.'**
  String get ifTheTaskHasASpecificGoal;

  /// Label for hour field
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// Label for pick time button
  ///
  /// In en, this message translates to:
  /// **'Pick Time'**
  String get pickTime;

  /// Label for duration field
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Label for edit task screen
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// Sunday abbreviation
  ///
  /// In en, this message translates to:
  /// **'SUN'**
  String get sunday;

  /// Monday abbreviation
  ///
  /// In en, this message translates to:
  /// **'MON'**
  String get monday;

  /// Tuesday abbreviation
  ///
  /// In en, this message translates to:
  /// **'TUE'**
  String get tuesday;

  /// Wednesday abbreviation
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get wednesday;

  /// Thursday abbreviation
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get thursday;

  /// Friday abbreviation
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get friday;

  /// Saturday abbreviation
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get saturday;

  /// Message for empty tasks state
  ///
  /// In en, this message translates to:
  /// **'No activities for the day (yet)'**
  String get noActivitiesForTheDayYet;

  /// Label for no goal option
  ///
  /// In en, this message translates to:
  /// **'No goal'**
  String get noGoal;

  /// Label for days of the week
  ///
  /// In en, this message translates to:
  /// **'Days of the week'**
  String get daysOfTheWeek;

  /// Label for goal field
  ///
  /// In en, this message translates to:
  /// **'Goal: {goalTitle}'**
  String goal(String goalTitle);

  /// Label for delete task button
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// Confirmation message for deleting task
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the task \"{taskTitle}\"? This action cannot be undone.'**
  String areYouSureYouWantToDeleteTask(String taskTitle);

  /// Label for create goal screen
  ///
  /// In en, this message translates to:
  /// **'Create your goal'**
  String get createYourGoal;

  /// Helper text for create goal
  ///
  /// In en, this message translates to:
  /// **'Write what you want to do and how much you\'ll dedicate to it weekly'**
  String get writeWhatYouWantToDoAndHowMuchYouWillDedicateToItWeekly;

  /// Label for create task screen
  ///
  /// In en, this message translates to:
  /// **'Create your task'**
  String get createYourTask;

  /// Helper text for create task
  ///
  /// In en, this message translates to:
  /// **'Write down how you\'ll use your time for the day'**
  String get writeDownHowYouWillUseYourTimeForTheDay;

  /// Label for task to goal screen
  ///
  /// In en, this message translates to:
  /// **'Task to Goal'**
  String get taskToGoal;

  /// Helper text for task to goal
  ///
  /// In en, this message translates to:
  /// **'You can mark a task as being part of achieving a goal'**
  String get youCanMarkATaskAsBeingPartOfAchievingAGoal;

  /// Label for free tasks screen
  ///
  /// In en, this message translates to:
  /// **'Free tasks'**
  String get freeTasks;

  /// Helper text for free tasks
  ///
  /// In en, this message translates to:
  /// **'Not every task needs to achieve a big goal. Like doing the dishes'**
  String get notEveryTaskNeedsToAchieveABigGoalLikeDoingTheDishes;

  /// Label for ready to achieve screen
  ///
  /// In en, this message translates to:
  /// **'Ready to achieve?'**
  String get readyToAchieve;

  /// Helper text for ready to achieve
  ///
  /// In en, this message translates to:
  /// **'Explore. Dream. Discover'**
  String get exploreDreamDiscover;

  /// Label for skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Label for next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Label for get started button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

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
  /// **'Tell what your goal is, what can you do so far, and what is the purpose'**
  String get tellWhatYourGoalIs;

  /// Hint text for goal description
  ///
  /// In en, this message translates to:
  /// **'I want to learn guitar, i can play most basic chords like G, D, E, and i wanna play some songs i like, like \"Hey Jude\"'**
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
  /// **'Just so you know...'**
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
