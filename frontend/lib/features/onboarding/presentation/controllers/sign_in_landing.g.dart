// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_landing.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(signInLanding)
final signInLandingProvider = SignInLandingProvider._();

final class SignInLandingProvider
    extends $FunctionalProvider<SignInLanding, SignInLanding, SignInLanding>
    with $Provider<SignInLanding> {
  SignInLandingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInLandingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInLandingHash();

  @$internal
  @override
  $ProviderElement<SignInLanding> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignInLanding create(Ref ref) {
    return signInLanding(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInLanding value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInLanding>(value),
    );
  }
}

String _$signInLandingHash() => r'b29264f93fee5c98bd47f7e5f4d1d2cfbaa473c4';
