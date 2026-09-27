// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether a session is stored on this device: true once a sign-in stored
/// one, false once a sign-out or a refused refresh cleared it.
///
/// The router listens to this and its `redirect` decides where the student
/// goes when it turns false (#224); nothing in `lib/core/` navigates. The
/// three places that write or clear the tokens call [sync] afterwards:
/// `AuthService.storeSession`, `AuthService.signOut` and the `ApiClient`'s
/// `onSessionExpired`. A refresh that rotates the tokens leaves it true, and
/// only a refresh the backend refuses ends it (#193).

@ProviderFor(SignedIn)
final signedInProvider = SignedInProvider._();

/// Whether a session is stored on this device: true once a sign-in stored
/// one, false once a sign-out or a refused refresh cleared it.
///
/// The router listens to this and its `redirect` decides where the student
/// goes when it turns false (#224); nothing in `lib/core/` navigates. The
/// three places that write or clear the tokens call [sync] afterwards:
/// `AuthService.storeSession`, `AuthService.signOut` and the `ApiClient`'s
/// `onSessionExpired`. A refresh that rotates the tokens leaves it true, and
/// only a refresh the backend refuses ends it (#193).
final class SignedInProvider extends $NotifierProvider<SignedIn, bool> {
  /// Whether a session is stored on this device: true once a sign-in stored
  /// one, false once a sign-out or a refused refresh cleared it.
  ///
  /// The router listens to this and its `redirect` decides where the student
  /// goes when it turns false (#224); nothing in `lib/core/` navigates. The
  /// three places that write or clear the tokens call [sync] afterwards:
  /// `AuthService.storeSession`, `AuthService.signOut` and the `ApiClient`'s
  /// `onSessionExpired`. A refresh that rotates the tokens leaves it true, and
  /// only a refresh the backend refuses ends it (#193).
  SignedInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signedInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signedInHash();

  @$internal
  @override
  SignedIn create() => SignedIn();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$signedInHash() => r'058caab0ca4e8660cf5b8d9a475787dfcaac9b88';

/// Whether a session is stored on this device: true once a sign-in stored
/// one, false once a sign-out or a refused refresh cleared it.
///
/// The router listens to this and its `redirect` decides where the student
/// goes when it turns false (#224); nothing in `lib/core/` navigates. The
/// three places that write or clear the tokens call [sync] afterwards:
/// `AuthService.storeSession`, `AuthService.signOut` and the `ApiClient`'s
/// `onSessionExpired`. A refresh that rotates the tokens leaves it true, and
/// only a refresh the backend refuses ends it (#193).

abstract class _$SignedIn extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
