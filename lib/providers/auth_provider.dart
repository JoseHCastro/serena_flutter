import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage(),
);

final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient.create(storage);
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiClientProvider)),
);

// ─── Auth Notifier ──────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return null;
    try {
      return await ref.read(authServiceProvider).getCurrentUser();
    } catch (_) {
      await storage.clearTokens();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final storage = ref.read(secureStorageProvider);
      final tokens = await service.login(email, password);
      await storage.saveTokens(tokens.accessToken, tokens.refreshToken);
      return service.getCurrentUser();
    });
  }

  Future<void> logout() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken != null) {
        await ref.read(authServiceProvider).logout(refreshToken);
      }
    } catch (_) {
      // Ignore errors on logout — always clear local tokens
    }
    await ref.read(secureStorageProvider).clearTokens();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);
