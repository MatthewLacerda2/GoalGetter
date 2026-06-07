# go_router Migration (Implemented)

> Status: **done** — the app now uses go_router. Routes live in
> `lib/app/router/` (`app_routes.dart` paths, `app_router.dart` config,
> `route_args.dart` typed `extra` payloads). The notes below are the original
> plan, kept for context.
>
> Two tweaks were made vs. the original plan, for reliability:
> 1. **Auth entry uses the `AuthGate` splash** (the `/` route, which resolves
>    `AppStartController` and `context.go`s to the destination) instead of an
>    async `redirect`. Redirect-based route guards (blocking deep links to
>    protected routes when signed out) remain a **follow-up**.
> 2. **The lesson "correct your mistakes" interstitial** (`InfoScreen`) stays an
>    imperative `Navigator.push`/`pop` pair — it's an ephemeral overlay with a
>    callback that returns to the same screen. Everything else (incl. the finish
>    screen at `/lesson/finish`) is a real go_router route.
>
> Known limitation: routes that pass rich objects via `extra` (goal detail,
> study plan, goal questions, lesson finish) are not restored on a web refresh
> (`extra` is not serialized). Make them refetch-by-id if deep-linking matters.

## Why

Today the app uses **Navigator 1.0, imperatively**:
- `app/app.dart` has an `onGenerateRoute` with 4 named routes (`/`, `/start`,
  `/goalPrompt`, `/home`), but most navigation bypasses it with hardcoded
  `Navigator.push(MaterialPageRoute(builder: (_) => ConcreteScreen()))` inline
  in widgets (~15 `MaterialPageRoute` + 2 `PageRouteBuilder` call sites).
- Startup/auth is decided by the `AuthGate` widget → `AppStartController` →
  `pushReplacementNamed`, using a `addPostFrameCallback` + `_hasNavigated` flag.

Problems this causes (most acute because we currently ship a **Flutter web** app):
- URLs don't reflect app state; browser back/forward, refresh, deep links, and
  shareable URLs effectively don't work.
- No single source of truth for the route graph; routes are hardcoded at call
  sites. `AppRoutes` constants exist but are mostly unused.
- Widgets import concrete screen classes to navigate → tight feature coupling.
- Auth gating is a gate-widget workaround instead of declarative guards.

**Target:** [`go_router`](https://pub.dev/packages/go_router) (Flutter-team
recommended) — declarative route tree, URL-driven, `redirect`-based auth guards,
`StatefulShellRoute` for the bottom nav, optional typed routes via
`go_router_builder`.

## Dependencies

```yaml
dependencies:
  go_router: ^14.0.0        # check latest compatible with Flutter 3.28
# dev_dependencies (optional, for typed routes later):
#   go_router_builder: ^2.0.0
```

Web: call `usePathUrlStrategy()` (from `package:flutter_web_plugins`) in `main`
to drop the `#` hash from URLs.

## Target route tree

```
/                         -> redirect-only (no screen; decides destination)
/start                    -> StartScreen
/onboarding/goal          -> GoalPromptScreen
/onboarding/questions     -> GoalQuestionsScreen   (extra: prompt/answers)
/onboarding/plan          -> StudyPlan

StatefulShellRoute.indexedStack          (the bottom-nav shell)
  ├─ /home                -> HomeScreen
  ├─ /tutor               -> TutorScreen
  ├─ /resources           -> ResourcesScreen
  └─ /profile             -> ProfileScreen

# Full-screen routes (outside the shell — bottom bar hidden, as today):
/lesson                   -> LessonScreen
/lesson/finish            -> FinishLessonScreen   (extra: result)
/streak                   -> StreakScreen          (extra: descriptionText)
/goals                    -> ListGoalsScreen
/goals/:id                -> GoalsDetailScreen     (extra: goal, or refetch by id)
```

Notes:
- The lesson "now correct your mistakes" `InfoScreen` step can stay an in-screen
  push or become `/lesson/review`. Its custom slide transition maps to a go_router
  `CustomTransitionPage`.
- `home_shell.dart`'s `IndexedStack` + `setState` is replaced by
  `StatefulShellRoute.indexedStack`, which preserves per-tab state for free and
  gives each tab its own navigation stack.

## Auth / onboarding guard (replaces AuthGate)

Keep the existing `AppStartController.evaluate()` logic — it's already a clean,
testable decision function. Move the *decision-to-route* mapping into go_router's
`redirect`:

- `AppStartDestination.unauthenticated`        -> `/start`
- `AppStartDestination.authenticatedNeedsGoal` -> `/onboarding/goal`
- `AppStartDestination.authenticatedReady`     -> `/home`

Implementation sketch (Riverpod-integrated):
- A `goRouterProvider` builds the `GoRouter`, with `refreshListenable` tied to an
  auth-state `Listenable` (e.g. a small `ChangeNotifier` or
  `ValueNotifier` updated by `auth_service`), so route guards re-run on
  login/logout.
- `redirect` is `async`-friendly via a resolved startup state; since `evaluate()`
  is async, cache its result in a provider (e.g. `appStartStateProvider`) and have
  `redirect` read the cached value, triggering a refresh when auth changes.
- Delete `auth_gate.dart` and the `onGenerateRoute` switch once the router covers
  all destinations.

This removes the double loading-spinner flash and the `addPostFrameCallback`
workaround.

## Mapping current navigation calls

| Today | go_router |
|---|---|
| `Navigator.pushReplacementNamed(AppRoutes.home)` | `context.go('/home')` |
| `Navigator.push(MaterialPageRoute(builder: (_) => LessonScreen()))` | `context.push('/lesson')` |
| `Navigator.push(... => StreakScreen(descriptionText: x))` | `context.push('/streak', extra: x)` |
| `Navigator.push(... => GoalsDetailScreen(goal: g))` returning a result | `final r = await context.push<GoalsDetailResult>('/goals/${g.id}', extra: g)` |
| `Navigator.pushAndRemoveUntil(... StreakScreen ..., (r)=>false)` | `context.go('/streak', extra: x)` |
| Bottom-nav `setState(selectedIndex)` | `shell.goBranch(index)` in `StatefulShellRoute` |

Key nuance — **return values**: screens that pop a result (e.g.
`GoalsDetailScreen` returns `GoalsDetailResult.deleted/activated`) must use
`context.push` (returns a `Future<T?>`), **not** `context.go` (no return value).
Audit each `Navigator.pop(result)` before converting its caller.

Args: prefer path params + refetch by id for deep-linkability; use `extra` for
rich objects that aren't worth refetching (note: `extra` is not preserved across
a web refresh, so anything reachable by URL should be refetchable by id).

## Incremental migration steps (keep app working throughout)

1. **Add dep + router scaffold.** Add `go_router`; create `app/router/app_router.dart`
   (a `goRouterProvider`) with the full route tree above, but don't switch the app
   over yet.
2. **Switch the app shell.** `MaterialApp` → `MaterialApp.router` wired to
   `goRouterProvider`; add `usePathUrlStrategy()` in `main`. Mirror current
   top-level routes first.
3. **Convert the bottom nav** to `StatefulShellRoute.indexedStack`; retire
   `home_shell.dart`'s `IndexedStack`/`setState` (keep the visual
   `BottomNavigationBar` in the shell's builder).
4. **Convert imperative pushes** file-by-file to `context.push/go` with route name
   constants; remove concrete-screen imports from widgets. Start with leaf flows
   (lesson, streak, goals), end with onboarding.
5. **Replace AuthGate** with the `redirect` guard; delete `auth_gate.dart` and the
   `onGenerateRoute` switch. Keep `AppStartController`.
6. **Cleanup.** Replace/trim `AppRoutes` into route-name constants used by the
   router; delete dead navigation code.
7. **(Optional) Typed routes.** Add `go_router_builder` + `@TypedGoRoute` for
   compile-time-safe navigation and params.

## Risks / edge cases to watch

- **Pop-with-result screens** (`GoalsDetailScreen`) — must stay on `push`.
- **`extra` lost on web refresh** — deep-linkable screens must refetch by id.
- **Custom transitions** (lesson's `PageRouteBuilder` slide) — port to
  `CustomTransitionPage`.
- **Auth redirect race** — ensure the startup `evaluate()` result is resolved/
  cached before the first `redirect` runs; show a splash while pending.
- **Back button on web** — verify the lesson → finish → streak chain doesn't let
  the user navigate "back" into a completed lesson (use `go`/replace where the
  history shouldn't be revisitable, as the current `pushAndRemoveUntil` intends).

## Testing

- Manual golden path: cold start (signed out / needs-goal / ready), full
  onboarding, start→answer→review→finish→streak, tab switching, goal
  select/delete, sign out.
- Widget tests for `redirect` given each `AppStartDestination`.
- Web: verify URLs update, refresh keeps you on the right screen, back/forward
  behave.
