// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(onboardingApi)
final onboardingApiProvider = OnboardingApiProvider._();

final class OnboardingApiProvider
    extends $FunctionalProvider<OnboardingApi, OnboardingApi, OnboardingApi>
    with $Provider<OnboardingApi> {
  OnboardingApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingApiHash();

  @$internal
  @override
  $ProviderElement<OnboardingApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OnboardingApi create(Ref ref) {
    return onboardingApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingApi>(value),
    );
  }
}

String _$onboardingApiHash() => r'd569743607a25f26b7cf6fef9631ac4eb7f1dce3';
