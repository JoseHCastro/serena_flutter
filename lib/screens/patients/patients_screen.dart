import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/patient_card.dart';
import '../../providers/patients_provider.dart';
import '../../theme/app_theme.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientsProvider);

    return Column(
      children: [
        // Search bar
        Container(
          color: AppTheme.surfaceColor,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, código o correo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(patientSearchProvider.notifier).state = '';
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              ref.read(patientSearchProvider.notifier).state = value;
            },
          ),
        ),

        // Patient list
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () => ref.read(patientsProvider.notifier).refresh(),
            child: patientsState.when(
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
                    Text(
                      e.toString().split('\n').first,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(patientsProvider.notifier).refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (patients) {
                if (patients.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron pacientes'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSm,
                  ),
                  itemCount: patients.length,
                  itemBuilder: (_, i) => PatientCard(
                    patient: patients[i],
                    onTap: () =>
                        context.go('/patients/${patients[i].id}'),
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
