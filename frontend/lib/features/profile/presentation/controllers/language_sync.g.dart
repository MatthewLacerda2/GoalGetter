// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(languageSync)
final languageSyncProvider = LanguageSyncProvider._();

final class LanguageSyncProvider
    extends $FunctionalProvider<LanguageSync, LanguageSync, LanguageSync>
    with $Provider<LanguageSync> {
  LanguageSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageSyncHash();

  @$internal
  @override
  $ProviderElement<LanguageSync> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LanguageSync create(Ref ref) {
    return languageSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LanguageSync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LanguageSync>(value),
    );
  }
}

String _$languageSyncHash() => r'baeea45589f60521b5488920097f89e51a792b2f';
