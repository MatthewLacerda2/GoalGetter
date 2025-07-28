// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get language => 'Idioma';

  @override
  String get options => 'Opções';

  @override
  String get goals => 'Metas';

  @override
  String get agenda => 'Agenda';

  @override
  String get profile => 'Perfil';

  @override
  String get howToUse => 'Como usar';

  @override
  String get about => 'Sobre';

  @override
  String get name => 'Nome';

  @override
  String get time => 'Tempo';

  @override
  String get setUpYourGoals => 'Configure suas Metas';

  @override
  String get createFirstGoalMessage => 'Crie sua primeira meta para começar!';

  @override
  String goalDeleted(String goalTitle) {
    return 'Meta \"$goalTitle\" excluída';
  }

  @override
  String get undo => 'Desfazer';
}
