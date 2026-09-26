// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's profile header (GET /me). A finished lesson
/// invalidates it (LessonController): the streak may have moved.

@ProviderFor(profileController)
final profileControllerProvider = ProfileControllerProvider._();

/// The signed-in user's profile header (GET /me). A finished lesson
/// invalidates it (LessonController): the streak may have moved.

final class ProfileControllerProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile>,
          UserProfile,
          FutureOr<UserProfile>
        >
    with $FutureModifier<UserProfile>, $FutureProvider<UserProfile> {
  /// The signed-in user's profile header (GET /me). A finished lesson
  /// invalidates it (LessonController): the streak may have moved.
  ProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileControllerHash();

  @$internal
  @override
  $FutureProviderElement<UserProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile> create(Ref ref) {
    return profileController(ref);
  }
}

String _$profileControllerHash() => r'091b485b45c1db94038b095db07d0292feb03c3d';
