// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Light, dark, or the phone's own mode — what `MaterialApp.themeMode` reads,
/// so a change repaints the whole app at once, the way [LocaleNotifier] does
/// for the language (#178).

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// Light, dark, or the phone's own mode — what `MaterialApp.themeMode` reads,
/// so a change repaints the whole app at once, the way [LocaleNotifier] does
/// for the language (#178).
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, ThemeMode> {
  /// Light, dark, or the phone's own mode — what `MaterialApp.themeMode` reads,
  /// so a change repaints the whole app at once, the way [LocaleNotifier] does
  /// for the language (#178).
  ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'f58bf40088ab2d8c384e264e60e3f08f6f1bb7ae';

/// Light, dark, or the phone's own mode — what `MaterialApp.themeMode` reads,
/// so a change repaints the whole app at once, the way [LocaleNotifier] does
/// for the language (#178).

abstract class _$ThemeModeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
