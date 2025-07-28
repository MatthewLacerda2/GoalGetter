// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get options => 'Options';

  @override
  String get goals => 'Goals';

  @override
  String get agenda => 'Agenda';

  @override
  String get profile => 'Profile';

  @override
  String get howToUse => 'How to use';

  @override
  String get about => 'About';

  @override
  String get name => 'Name';

  @override
  String get time => 'Time';

  @override
  String get setUpYourGoals => 'Set up your Goals';

  @override
  String get createFirstGoalMessage => 'Create your first goal to get started!';

  @override
  String goalDeleted(String goalTitle) {
    return 'Goal \"$goalTitle\" deleted';
  }

  @override
  String get undo => 'Undo';

  @override
  String get createNewGoal => 'Create New Goal';

  @override
  String get goalTitle => 'Goal Title';

  @override
  String get goalTitleHint => 'e.g., Read a book';

  @override
  String get pleaseEnterGoalTitle => 'Please enter a goal title';

  @override
  String get description => 'Description (Optional)';

  @override
  String get descriptionHint => 'Describe your goal in detail...';

  @override
  String get weeklyTimeCommitment => 'Weekly Time Commitment';

  @override
  String get pleaseEnterWeeklyTime => 'Please enter weekly time commitment';

  @override
  String get weeklyTimeMustBeGreater => 'Weekly time must be greater than 0';

  @override
  String weeklyTimeCannotExceed(int maxHours) {
    return 'Weekly time cannot exceed $maxHours hours';
  }

  @override
  String get youCanCreateTasksLater => 'You can create tasks for this goal later';

  @override
  String get create => 'Create';

  @override
  String get goalCreatedSuccessfully => 'Goal created successfully!';

  @override
  String get createTask => 'Create Task';

  @override
  String get thisFieldIsRequired => 'This field is required';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get valueMustBeNonNegative => 'Value must be non-negative';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get minutesMustBeLessThan60 => 'Minutes must be less than 60';

  @override
  String get save => 'Save';

  @override
  String get goalUpdatedSuccessfully => 'Goal updated successfully!';

  @override
  String get goalUpdated => 'Goal updated';
}
