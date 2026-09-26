// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(goalActions)
final goalActionsProvider = GoalActionsProvider._();

final class GoalActionsProvider
    extends $FunctionalProvider<GoalActions, GoalActions, GoalActions>
    with $Provider<GoalActions> {
  GoalActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalActionsHash();

  @$internal
  @override
  $ProviderElement<GoalActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalActions create(Ref ref) {
    return goalActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalActions>(value),
    );
  }
}

String _$goalActionsHash() => r'96e4a781f80c668fd1645f296a6351ff5ee78be2';
