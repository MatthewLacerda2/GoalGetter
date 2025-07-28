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
}
