import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/session_card.dart';
import '../../providers/sessions_provider.dart';
import '../../theme/app_theme.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(sessionsProvider);
    final currentFilter = ref.watch(sessionStatusFilterProvider);

    return Column(
      children: [
        // Filter chips
        Container(
          color: AppTheme.surfaceColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: currentFilter == null,
                  onTap: () =>
                      ref.read(sessionStatusFilterProvider.notifier).state =
                          null,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _FilterChip(
                  label: 'Programadas',
                  selected: currentFilter == 'scheduled',
                  onTap: () =>
                      ref.read(sessionStatusFilterProvider.notifier).state =
                          'scheduled',
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _FilterChip(
                  label: 'Activas',
                  selected: currentFilter == 'active',
                  onTap: () =>
                      ref.read(sessionStatusFilterProvider.notifier).state =
                          'active',
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _FilterChip(
                  label: 'Completadas',
                  selected: currentFilter == 'completed',
                  onTap: () =>
                      ref.read(sessionStatusFilterProvider.notifier).state =
                          'completed',
                ),
              ],
            ),
          ),
        ),

        // Session list
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () => ref.read(sessionsProvider.notifier).refresh(),
            child: sessionsState.when(
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
                    const Text('Error al cargar sesiones'),
                    TextButton(
                      onPressed: () =>
                          ref.read(sessionsProvider.notifier).refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_camera_front_outlined,
                            size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text('Sin sesiones'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSm,
                  ),
                  itemCount: sessions.length,
                  itemBuilder: (_, i) => SessionCard(
                    session: sessions[i],
                    onTap: () => context.go('/sessions/${sessions[i].id}'),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primaryContrast : AppTheme.textMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
