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
  String get commited => 'Comprometido';

  @override
  String get reserved => 'Reservado';

  @override
  String get setUpYourGoals => 'Configure suas Metas';

  @override
  String get createFirstGoalMessage => 'Crie uma primeira meta!';

  @override
  String goalDeleted(String goalTitle) {
    return 'Meta \"$goalTitle\" excluída';
  }

  @override
  String taskDeleted(String taskTitle) {
    return 'Atividade \"$taskTitle\" excluída';
  }

  @override
  String get undo => 'Desfazer';

  @override
  String get createNewGoal => 'Criar Nova Meta';

  @override
  String get goalTitle => 'Nome da Meta';

  @override
  String get goalTitleHint => 'ex: Ler um livro';

  @override
  String get pleaseEnterGoalTitle => 'Por favor, insira um nome para a meta';

  @override
  String get description => 'Descrição (Opcional)';

  @override
  String get goalOptional => 'Meta (opcional)';

  @override
  String get descriptionHint => 'Descreva sua meta em detalhes...';

  @override
  String get weeklyTimeCommitment => 'Tempo por Semana';

  @override
  String get pleaseEnterWeeklyTime => 'Por favor, insira o tempo por semana';

  @override
  String get weeklyTimeMustBeGreater => 'O tempo por semana deve ser maior que 0';

  @override
  String weeklyTimeCannotExceed(int maxHours) {
    return 'O tempo por semana não pode exceder $maxHours horas';
  }

  @override
  String get youCanCreateTasksLater => 'Você pode criar atividades para esta meta depois.';

  @override
  String get create => 'Criar';

  @override
  String get goalCreatedSuccessfully => 'Meta criada!';

  @override
  String get thisFieldIsRequired => 'Este campo é obrigatório';

  @override
  String get pleaseEnterValidNumber => 'Por favor, insira um número válido';

  @override
  String get valueMustBeNonNegative => 'O valor deve ser maior que 0';

  @override
  String get hours => 'Horas';

  @override
  String get minutes => 'Minutos';

  @override
  String get minutesMustBeLessThan60 => 'Os minutos devem ser menores que 60';

  @override
  String get save => 'Salvar';

  @override
  String get goalUpdatedSuccessfully => 'Meta atualizada!';

  @override
  String get goalUpdated => 'Meta atualizada';

  @override
  String get timeReserved => 'Tempo reservado';

  @override
  String get deleteGoal => 'Excluir Meta';

  @override
  String areYouSureYouWantToDeleteGoal(String goalTitle) {
    return 'Tem certeza que deseja excluir a meta \"$goalTitle\"?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String goalNeedsTime(String goalTitle, int minutesMissing) {
    return '$goalTitle precisa de +${minutesMissing}min/semana';
  }

  @override
  String get dismiss => 'Descartar';

  @override
  String get pleaseFillAllRequiredFields => 'Por favor, preencha todos os campos obrigatórios.';

  @override
  String get title => 'Título';

  @override
  String get createTask => 'Criar Atividade';

  @override
  String get ifTheTaskHasASpecificGoal => 'Se a atividade tem uma meta específica, você pode selecioná-la aqui.';

  @override
  String get hour => 'Hora';

  @override
  String get pickTime => 'Escolher Horário';

  @override
  String get duration => 'Duração';

  @override
  String get editTask => 'Editar Atividade';

  @override
  String get sunday => 'DOM';

  @override
  String get monday => 'SEG';

  @override
  String get tuesday => 'TER';

  @override
  String get wednesday => 'QUA';

  @override
  String get thursday => 'QUI';

  @override
  String get friday => 'SEX';

  @override
  String get saturday => 'SAB';

  @override
  String get noActivitiesForTheDayYet => 'Nenhuma atividade para o dia (ainda)';

  @override
  String get noGoal => 'Sem meta';

  @override
  String get daysOfTheWeek => 'Dias da semana';

  @override
  String goal(String goalTitle) {
    return 'Meta: $goalTitle';
  }

  @override
  String get deleteTask => 'Excluir Atividade';

  @override
  String areYouSureYouWantToDeleteTask(String taskTitle) {
    return 'Tem certeza que deseja excluir a atividade \"$taskTitle\"?';
  }

  @override
  String get createYourGoal => 'Crie suas metas';

  @override
  String get writeWhatYouWantToDoAndHowMuchYouWillDedicateToItWeekly => 'Diga o que quer fazer e quanto tempo vai dedicar semanalmente';

  @override
  String get createYourTask => 'Crie suas atividades';

  @override
  String get writeDownHowYouWillUseYourTimeForTheDay => 'Anote como vai usar seu tempo para o dia';

  @override
  String get taskToGoal => 'Atividade para alcançar meta';

  @override
  String get youCanMarkATaskAsBeingPartOfAchievingAGoal => 'Você pode marcar uma atividade como sendo parte de uma meta';

  @override
  String get freeTasks => 'Atividades livres';

  @override
  String get notEveryTaskNeedsToAchieveABigGoalLikeDoingTheDishes => 'Nem toda atividade precisa ser parte de uma meta. Lavar as roupas, por exemplo';

  @override
  String get readyToAchieve => 'Pronto para alcançar suas metas?';

  @override
  String get exploreDreamDiscover => 'Explore. Sonhe. Descubra';

  @override
  String get skip => 'Pular';

  @override
  String get next => 'Próximo';

  @override
  String get getStarted => 'Começar';

  @override
  String get createRoadmap => 'Criar Roadmap';

  @override
  String get beDetailedOfYourGoal => 'Seja detalhado sobre sua meta!';

  @override
  String get tellWhatYourGoalIs => 'Diga qual é a sua meta, o que você já sabe fazer e qual sua motivação';

  @override
  String get goalDescriptionHintText => 'Quero aprender violão, já sei tocar as notas mais simples, G, D, E e quero tocar umas músicas que gosto, como \"Hey Jude\"';

  @override
  String get enter => 'Enter';

  @override
  String get questions => 'Perguntas';

  @override
  String get send => 'Send';

  @override
  String get roadmap => 'Roadmap';

  @override
  String get beforeYouStart => 'Ah, e já vou avisando...';

  @override
  String get goalStarted => 'Estrada iniciada!';

  @override
  String get letSGo => 'BORA LÁ!';

  @override
  String get yourAnswer => 'Sua resposta...';

  @override
  String get pleaseAnswerThisQuestion => 'Por favor, responda esta pergunta';
}
