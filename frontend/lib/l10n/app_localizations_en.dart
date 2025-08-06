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
  String taskDeleted(String taskTitle) {
    return 'Task \"$taskTitle\" deleted';
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
  String get goalOptional => 'Goal (optional)';

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

  @override
  String get timeReserved => 'Time reserved';

  @override
  String get deleteGoal => 'Delete Goal';

  @override
  String areYouSureYouWantToDeleteGoal(String goalTitle) {
    return 'Are you sure you want to delete the goal \"$goalTitle\"? This action cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get commited => 'Commited';

  @override
  String get reserved => 'Reserved';

  @override
  String goalNeedsTime(String goalTitle, int minutesMissing) {
    return '$goalTitle needs +${minutesMissing}min/w';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get pleaseFillAllRequiredFields => 'Please fill all required fields.';

  @override
  String get title => 'Title';

  @override
  String get createTask => 'Create Task';

  @override
  String get ifTheTaskHasASpecificGoal => 'If the task has a specific goal, you can select it here.';

  @override
  String get hour => 'Hour';

  @override
  String get pickTime => 'Pick Time';

  @override
  String get duration => 'Duration';

  @override
  String get editTask => 'Edit Task';

  @override
  String get sunday => 'SUN';

  @override
  String get monday => 'MON';

  @override
  String get tuesday => 'TUE';

  @override
  String get wednesday => 'WED';

  @override
  String get thursday => 'THU';

  @override
  String get friday => 'FRI';

  @override
  String get saturday => 'SAT';

  @override
  String get noActivitiesForTheDayYet => 'No activities for the day (yet)';

  @override
  String get noGoal => 'No goal';

  @override
  String get daysOfTheWeek => 'Days of the week';

  @override
  String goal(String goalTitle) {
    return 'Goal: $goalTitle';
  }

  @override
  String get deleteTask => 'Delete Task';

  @override
  String areYouSureYouWantToDeleteTask(String taskTitle) {
    return 'Are you sure you want to delete the task \"$taskTitle\"? This action cannot be undone.';
  }

  @override
  String get createYourGoal => 'Create your goal';

  @override
  String get writeWhatYouWantToDoAndHowMuchYouWillDedicateToItWeekly => 'Write what you want to do and how much you\'ll dedicate to it weekly';

  @override
  String get createYourTask => 'Create your task';

  @override
  String get writeDownHowYouWillUseYourTimeForTheDay => 'Write down how you\'ll use your time for the day';

  @override
  String get taskToGoal => 'Task to Goal';

  @override
  String get youCanMarkATaskAsBeingPartOfAchievingAGoal => 'You can mark a task as being part of achieving a goal';

  @override
  String get freeTasks => 'Free tasks';

  @override
  String get notEveryTaskNeedsToAchieveABigGoalLikeDoingTheDishes => 'Not every task needs to achieve a big goal. Like doing the dishes';

  @override
  String get readyToAchieve => 'Ready to achieve?';

  @override
  String get exploreDreamDiscover => 'Explore. Dream. Discover';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get createRoadmap => 'Create Roadmap';

  @override
  String get beDetailedOfYourGoal => 'Be detailed of your goal!';

  @override
  String get tellWhatYourGoalIs => 'Tell your goal is, what can you do so far, and what is the purpose';

  @override
  String get goalDescriptionHintText => 'I wanna learn guitar, i can play most basic chords';

  @override
  String get enter => 'Enter';

  @override
  String get questions => 'Questions';

  @override
  String get send => 'Send';

  @override
  String get roadmap => 'Roadmap';

  @override
  String get beforeYouStart => 'Just so you know...';

  @override
  String get goalStarted => 'Goal started!';

  @override
  String get letSGo => 'LET\'S GO!';

  @override
  String get yourAnswer => 'Your answer...';

  @override
  String get pleaseAnswerThisQuestion => 'Please answer this question';

  @override
  String get orYouCanCreateAFullPlan => 'You can create a full:';
}
