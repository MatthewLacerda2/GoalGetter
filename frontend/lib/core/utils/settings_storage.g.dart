// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settingsStorage)
final settingsStorageProvider = SettingsStorageProvider._();

final class SettingsStorageProvider
    extends
        $FunctionalProvider<SettingsStorage, SettingsStorage, SettingsStorage>
    with $Provider<SettingsStorage> {
  SettingsStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStorageHash();

  @$internal
  @override
  $ProviderElement<SettingsStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsStorage create(Ref ref) {
    return settingsStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsStorage>(value),
    );
  }
}

String _$settingsStorageHash() => r'11ab36d8bae57fbde33d6be9bff94d4579783429';
