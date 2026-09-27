import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/services/shared_preferences_provider.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_onboarding_api.dart';
import '../onboarding_harness.dart' show signedIn;

/// The onboarding controllers over [api], with no widget: a container whose
/// preferences start as [prefs] (a session, unless told otherwise).
Future<(ProviderContainer, SharedPreferences)> onboardingContainer(
  FakeOnboardingApi api, {
  Map<String, Object> prefs = signedIn,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(prefs);
  final stored = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [
      onboardingApiProvider.overrideWithValue(api),
      sharedPreferencesProvider.overrideWithValue(stored),
    ],
  );
  addTearDown(container.dispose);
  return (container, stored);
}

extension KeepAlive on ProviderContainer {
  /// Listens to [provider] for the rest of the test, as the screen would, so
  /// an auto-disposed controller keeps its state between reads.
  void keep(ProviderListenable<Object?> provider) =>
      listen(provider, (_, __) {});
}
