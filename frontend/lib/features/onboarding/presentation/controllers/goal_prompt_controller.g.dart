// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_prompt_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GoalPromptController)
final goalPromptControllerProvider = GoalPromptControllerProvider._();

final class GoalPromptControllerProvider
    extends $NotifierProvider<GoalPromptController, GoalPromptState> {
  GoalPromptControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalPromptControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalPromptControllerHash();

  @$internal
  @override
  GoalPromptController create() => GoalPromptController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalPromptState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalPromptState>(value),
    );
  }
}

String _$goalPromptControllerHash() =>
    r'83da1ae609e2198e9821c1f1c70863c8872080dc';

abstract class _$GoalPromptController extends $Notifier<GoalPromptState> {
  GoalPromptState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoalPromptState, GoalPromptState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoalPromptState, GoalPromptState>,
              GoalPromptState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
