import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session.g.dart';

/// Whether a session is stored on this device: true once a sign-in stored
/// one, false once a sign-out or a refused refresh cleared it.
///
/// The router listens to this and its `redirect` decides where the student
/// goes when it turns false (#224); nothing in `lib/core/` navigates. The
/// three places that write or clear the tokens call [sync] afterwards:
/// `AuthService.storeSession`, `AuthService.signOut` and the `ApiClient`'s
/// `onSessionExpired`. A refresh that rotates the tokens leaves it true, and
/// only a refresh the backend refuses ends it (#193).
@Riverpod(keepAlive: true)
class SignedIn extends _$SignedIn {
  @override
  bool build() => _stored();

  /// Re-reads the stored session after one of the three writers changed it.
  void sync() => state = _stored();

  bool _stored() {
    final token = ref.read(settingsStorageProvider).getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
