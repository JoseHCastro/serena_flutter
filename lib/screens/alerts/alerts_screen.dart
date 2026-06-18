import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/alert_card.dart';
import '../../providers/alerts_provider.dart';
import '../../theme/app_theme.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _unacknowledgedOnly = false;

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);

    return Column(
      children: [
        // Filter row
        Container(
          color: AppTheme.surfaceColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Text(
                'Alertas clínicas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Sin reconocer'),
                selected: _unacknowledgedOnly,
                onSelected: (value) {
                  setState(() => _unacknowledgedOnly = value);
                },
                selectedColor: AppTheme.secondaryLight,
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: _unacknowledgedOnly
                      ? AppTheme.primaryColor
                      : AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () => ref.read(alertsProvider.notifier).refresh(),
            child: alertsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.errorColor, size: 40),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Text('Error al cargar alertas'),
                    TextButton(
                      onPressed: () =>
                          ref.read(alertsProvider.notifier).refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (alerts) {
                final filtered = _unacknowledgedOnly
                    ? alerts.where((a) => !a.isAcknowledged).toList()
                    : alerts;

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text('Sin alertas pendientes'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSm,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => AlertCard(
                    alert: filtered[i],
                    onAcknowledge: filtered[i].isAcknowledged
                        ? null
                        : () => ref
                            .read(alertsProvider.notifier)
                            .acknowledge(filtered[i].id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
