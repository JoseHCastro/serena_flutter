import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';
import 'auth_provider.dart';

final alertServiceProvider = Provider<AlertService>(
  (ref) => AlertService(ref.read(apiClientProvider)),
);

class AlertsNotifier extends AsyncNotifier<List<AlertModel>> {
  Timer? _refreshTimer;

  @override
  Future<List<AlertModel>> build() async {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (ref.read(authProvider).valueOrNull != null) {
        _fetchAlerts().then((alerts) {
          state = AsyncValue.data(alerts);
        }).catchError((_) {});
      }
    });

    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    return _fetchAlerts();
  }

  Future<List<AlertModel>> _fetchAlerts({bool unacknowledgedOnly = false}) async {
    final service = ref.read(alertServiceProvider);
    final result = await service.getAlerts(
      pageSize: 50,
      unacknowledgedOnly: unacknowledgedOnly ? true : null,
    );
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAlerts);
  }

  Future<void> acknowledge(String alertId) async {
    final service = ref.read(alertServiceProvider);
    final updated = await service.acknowledgeAlert(alertId);
    state = AsyncData(
      state.valueOrNull
              ?.map((a) => a.id == alertId ? updated : a)
              .toList() ??
          [updated],
    );
  }
}

final alertsProvider =
    AsyncNotifierProvider<AlertsNotifier, List<AlertModel>>(
  AlertsNotifier.new,
);

final unacknowledgedCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsProvider).valueOrNull ?? [];
  return alerts.where((a) => !a.isAcknowledged).length;
});
