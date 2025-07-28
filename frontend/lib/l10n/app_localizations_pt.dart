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

  @override
  String get createNewGoal => 'Criar Nova Meta';

  @override
  String get goalTitle => 'Título da Meta';

  @override
  String get goalTitleHint => 'ex: Ler um livro';

  @override
  String get pleaseEnterGoalTitle => 'Por favor, insira um título para a meta';

  @override
  String get description => 'Descrição (Opcional)';

  @override
  String get descriptionHint => 'Descreva sua meta em detalhes...';

  @override
  String get weeklyTimeCommitment => 'Compromisso Semanal de Tempo';

  @override
  String get pleaseEnterWeeklyTime => 'Por favor, insira o compromisso semanal de tempo';

  @override
  String get weeklyTimeMustBeGreater => 'O tempo semanal deve ser maior que 0';

  @override
  String weeklyTimeCannotExceed(int maxHours) {
    return 'O tempo semanal não pode exceder $maxHours horas';
  }

  @override
  String get youCanCreateTasksLater => 'Você pode criar tarefas para esta meta depois';

  @override
  String get create => 'Criar';

  @override
  String get goalCreatedSuccessfully => 'Meta criada com sucesso!';

  @override
  String get thisFieldIsRequired => 'Este campo é obrigatório';

  @override
  String get pleaseEnterValidNumber => 'Por favor, insira um número válido';

  @override
  String get valueMustBeNonNegative => 'O valor deve ser não negativo';

  @override
  String get hours => 'Horas';

  @override
  String get minutes => 'Minutos';

  @override
  String get minutesMustBeLessThan60 => 'Os minutos devem ser menores que 60';

  @override
  String get save => 'Salvar';

  @override
  String get goalUpdatedSuccessfully => 'Meta atualizada com sucesso!';

  @override
  String get goalUpdated => 'Meta atualizada';

  @override
  String get timeReserved => 'Tempo reservado';

  @override
  String get deleteGoal => 'Excluir Meta';

  @override
  String areYouSureYouWantToDeleteGoal(String goalTitle) {
    return 'Tem certeza que deseja excluir a meta \"$goalTitle\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get commited => 'Comprometido';

  @override
  String get reserved => 'Reservado';

  @override
  String goalNeedsTime(String goalTitle, int minutesMissing) {
    return '$goalTitle precisa de ${minutesMissing}min/w';
  }

  @override
  String get dismiss => 'Descartar';

  @override
  String get pleaseFillAllRequiredFields => 'Please fill all required fields.';

  @override
  String get title => 'Título';

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
  String get editTask => 'Editar Tarefa';
}
