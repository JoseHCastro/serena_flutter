import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import 'auth_provider.dart';

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(ref.read(apiClientProvider)),
);

final sessionStatusFilterProvider = StateProvider<String?>((_) => null);

class SessionsNotifier extends AsyncNotifier<List<SessionModel>> {
  @override
  Future<List<SessionModel>> build() async {
    final statusFilter = ref.watch(sessionStatusFilterProvider);
    return _fetchSessions(status: statusFilter);
  }

  Future<List<SessionModel>> _fetchSessions({String? status}) async {
    final service = ref.read(sessionServiceProvider);
    final result = await service.getSessions(
      status: status,
      pageSize: 50,
    );
    return result.items;
  }

  Future<void> refresh() async {
    final status = ref.read(sessionStatusFilterProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchSessions(status: status));
  }

  Future<SessionModel> scheduleSession({
    required String patientId,
    required String scheduledAt,
    String? notes,
  }) async {
    final service = ref.read(sessionServiceProvider);
    final newSession = await service.scheduleSession(
      patientId: patientId,
      scheduledAt: scheduledAt,
      notes: notes,
    );
    state = AsyncData(
      [newSession, ...state.valueOrNull ?? []],
    );
    return newSession;
  }

  Future<SessionModel> startSession(String sessionId) async {
    final service = ref.read(sessionServiceProvider);
    final updated = await service.startSession(sessionId);
    state = AsyncData(
      state.valueOrNull
              ?.map((s) => s.id == sessionId ? updated : s)
              .toList() ??
          [updated],
    );
    return updated;
  }

  Future<SessionModel> endSession(String sessionId, {String? notes}) async {
    final service = ref.read(sessionServiceProvider);
    final updated = await service.endSession(sessionId, notes: notes);
    state = AsyncData(
      state.valueOrNull
              ?.map((s) => s.id == sessionId ? updated : s)
              .toList() ??
          [updated],
    );
    return updated;
  }

  Future<SessionModel> uploadVideo(
    String sessionId,
    File file, {
    void Function(int, int)? onProgress,
  }) async {
    final service = ref.read(sessionServiceProvider);
    final updated = await service.uploadVideo(
      sessionId,
      file,
      onProgress: onProgress,
    );
    state = AsyncData(
      state.valueOrNull
              ?.map((s) => s.id == sessionId ? updated : s)
              .toList() ??
          [updated],
    );
    return updated;
  }
}

final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<SessionModel>>(
  SessionsNotifier.new,
);

final sessionDetailProvider =
    FutureProvider.family<SessionModel, String>((ref, id) {
  return ref.read(sessionServiceProvider).getSession(id);
});

// Separate notifier for per-session upload progress
final uploadProgressProvider =
    StateProvider.family<double?, String>((_, id) => null);
