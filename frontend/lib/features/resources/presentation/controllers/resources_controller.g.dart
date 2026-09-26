// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resources_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active goal's resources. Refresh with `ref.invalidate`.

@ProviderFor(resources)
final resourcesProvider = ResourcesProvider._();

/// The active goal's resources. Refresh with `ref.invalidate`.

final class ResourcesProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoalResources>,
          GoalResources,
          FutureOr<GoalResources>
        >
    with $FutureModifier<GoalResources>, $FutureProvider<GoalResources> {
  /// The active goal's resources. Refresh with `ref.invalidate`.
  ResourcesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resourcesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourcesHash();

  @$internal
  @override
  $FutureProviderElement<GoalResources> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GoalResources> create(Ref ref) {
    return resources(ref);
  }
}

String _$resourcesHash() => r'675751c8b6a2535782d071120e72f99dacdbafa3';
