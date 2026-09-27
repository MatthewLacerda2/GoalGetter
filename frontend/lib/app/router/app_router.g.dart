// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's go_router configuration.
///
/// Signing in and out is routing (#224): the router listens to the session
/// ([signedInProvider]) and to the launch decision
/// ([launchDestinationProvider]), and its redirects decide where the student
/// goes — [_sessionRedirect] for a session that ended, [_launchRedirect] for
/// the `/` splash. Rich objects are passed via `extra` (see route_args.dart),
/// and the routes that need one guard it in their `redirect` (see [_extra]);
/// paths in [AppRoutes] are the single source of truth.

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

/// The app's go_router configuration.
///
/// Signing in and out is routing (#224): the router listens to the session
/// ([signedInProvider]) and to the launch decision
/// ([launchDestinationProvider]), and its redirects decide where the student
/// goes — [_sessionRedirect] for a session that ended, [_launchRedirect] for
/// the `/` splash. Rich objects are passed via `extra` (see route_args.dart),
/// and the routes that need one guard it in their `redirect` (see [_extra]);
/// paths in [AppRoutes] are the single source of truth.

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app's go_router configuration.
  ///
  /// Signing in and out is routing (#224): the router listens to the session
  /// ([signedInProvider]) and to the launch decision
  /// ([launchDestinationProvider]), and its redirects decide where the student
  /// goes — [_sessionRedirect] for a session that ended, [_launchRedirect] for
  /// the `/` splash. Rich objects are passed via `extra` (see route_args.dart),
  /// and the routes that need one guard it in their `redirect` (see [_extra]);
  /// paths in [AppRoutes] are the single source of truth.
  GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'68c8c0381edd806d5ee334bbc6899f7951cb62ed';
