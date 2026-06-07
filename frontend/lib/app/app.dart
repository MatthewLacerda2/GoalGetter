import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/app/router/app_router.dart';
import 'package:goal_getter/core/utils/locale_provider.dart';

class GoalGetterApp extends ConsumerWidget {
  const GoalGetterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'GoalGetter',
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
