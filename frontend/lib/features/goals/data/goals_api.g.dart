// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(goalsApi)
final goalsApiProvider = GoalsApiProvider._();

final class GoalsApiProvider
    extends $FunctionalProvider<GoalsApi, GoalsApi, GoalsApi>
    with $Provider<GoalsApi> {
  GoalsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalsApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalsApiHash();

  @$internal
  @override
  $ProviderElement<GoalsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalsApi create(Ref ref) {
    return goalsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalsApi>(value),
    );
  }
}

String _$goalsApiHash() => r'b7bc2898144b77bbf98d7f2959e7698688c3df1b';
