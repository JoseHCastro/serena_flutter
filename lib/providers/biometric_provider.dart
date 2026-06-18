import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_model.dart';
import '../services/biometric_service.dart';
import 'auth_provider.dart';

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(ref.read(apiClientProvider)),
);

final biometricJobProvider =
    FutureProvider.family<BiometricJobModel?, String>((ref, sessionId) {
  return ref.read(biometricServiceProvider).getAnalysisJob(sessionId);
});

final snapshotsProvider =
    FutureProvider.family<List<EmotionalSnapshot>, String>((ref, sessionId) {
  return ref.read(biometricServiceProvider).getSnapshots(sessionId);
});

class BiometricAnalysisNotifier
    extends FamilyAsyncNotifier<BiometricJobModel?, String> {
  @override
  Future<BiometricJobModel?> build(String sessionId) async {
    return ref.read(biometricServiceProvider).getAnalysisJob(sessionId);
  }

  Future<void> triggerAnalysis() async {
    final sessionId = arg;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(biometricServiceProvider).triggerAnalysis(sessionId),
    );
  }

  Future<void> refresh() async {
    final sessionId = arg;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(biometricServiceProvider).getAnalysisJob(sessionId),
    );
  }
}

final biometricAnalysisProvider = AsyncNotifierProviderFamily<
    BiometricAnalysisNotifier, BiometricJobModel?, String>(
  BiometricAnalysisNotifier.new,
);
