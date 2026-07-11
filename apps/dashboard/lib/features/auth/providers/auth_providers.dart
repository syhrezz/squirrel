import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the Supabase auth state stream.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Returns true if there is a currently authenticated session.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (state) => state.session != null,
    loading: () =>
        Supabase.instance.client.auth.currentSession != null,
    error: (_, __) => false,
  );
});

/// The current authenticated user. Null if not logged in.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

/// Auth notifier — handles login and logout.
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
    state = result;
    return !result.hasError;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.signOut();
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
