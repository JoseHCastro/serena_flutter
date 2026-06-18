import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/session_card.dart';
import '../../components/alert_card.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/patients_provider.dart';
import '../../providers/sessions_provider.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final patientsState = ref.watch(patientsProvider);
    final sessionsState = ref.watch(sessionsProvider);
    final alertsState = ref.watch(alertsProvider);
    final unreadCount = ref.watch(unacknowledgedCountProvider);

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        await Future.wait([
          ref.read(patientsProvider.notifier).refresh(),
          ref.read(sessionsProvider.notifier).refresh(),
          ref.read(alertsProvider.notifier).refresh(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Bienvenido,',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            Text(
              user?.fullName ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Stats cards
            Row(
              children: [
                _StatCard(
                  label: 'Pacientes',
                  value: patientsState.valueOrNull?.length.toString() ?? '—',
                  icon: Icons.people_outline,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                _StatCard(
                  label: 'Sesiones activas',
                  value: sessionsState.valueOrNull
                          ?.where((s) => s.status == SessionStatus.active)
                          .length
                          .toString() ??
                      '—',
                  icon: Icons.videocam_outlined,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                _StatCard(
                  label: 'Alertas',
                  value: '$unreadCount',
                  icon: Icons.notifications_outlined,
                  color: unreadCount > 0
                      ? AppTheme.errorColor
                      : AppTheme.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Recent sessions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sesiones recientes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.go('/sessions'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            sessionsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => _ErrorTile(message: e.toString()),
              data: (sessions) {
                final recent = sessions.take(5).toList();
                if (recent.isEmpty) {
                  return const _EmptyTile(message: 'Sin sesiones recientes');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  itemBuilder: (_, i) => SessionCard(
                    session: recent[i],
                    onTap: () => context.go('/sessions/${recent[i].id}'),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Critical alerts
            if (unreadCount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alertas pendientes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go('/alerts'),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              alertsState.when(
                loading: () => const SizedBox.shrink(),
                error: (err, st) => const SizedBox.shrink(),
                data: (alerts) {
                  final pending =
                      alerts.where((a) => !a.isAcknowledged).take(3).toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pending.length,
                    itemBuilder: (_, i) => AlertCard(
                      alert: pending[i],
                      onAcknowledge: () => ref
                          .read(alertsProvider.notifier)
                          .acknowledge(pending[i].id),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  final String message;
  const _EmptyTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Center(
        child: Text(message,
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  const _ErrorTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Text(
        'Error al cargar datos',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppTheme.errorColor),
      ),
    );
  }
}
