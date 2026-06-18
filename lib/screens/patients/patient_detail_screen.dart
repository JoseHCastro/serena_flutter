import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../components/app_top_bar.dart';
import '../../components/session_card.dart';
import '../../providers/patients_provider.dart';
import '../../providers/sessions_provider.dart';
import '../../theme/app_theme.dart';

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientDetailProvider(patientId));
    final sessionsState = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Detalle del paciente'),
      body: patientState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(
          child: Text('Error al cargar paciente: $e'),
        ),
        data: (patient) {
          final patientSessions = sessionsState.valueOrNull
                  ?.where((s) => s.patientId == patientId)
                  .toList() ??
              [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.secondaryLight,
                        child: Text(
                          patient.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        patient.fullName,
                        style: const TextStyle(
                          color: AppTheme.primaryContrast,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.code,
                        style: const TextStyle(
                          color: AppTheme.secondaryLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Info section
                Text(
                  'Información del paciente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _InfoCard(
                  children: [
                    if (patient.birthDate != null)
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        label: 'Fecha de nacimiento',
                        value: _formatDate(patient.birthDate!),
                      ),
                    if (patient.gender != null)
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Género',
                        value: patient.gender!,
                      ),
                    if (patient.phone != null)
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Teléfono',
                        value: patient.phone!,
                      ),
                    if (patient.email != null)
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Correo',
                        value: patient.email!,
                      ),
                    if (patient.address != null)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Dirección',
                        value: patient.address!,
                      ),
                  ],
                ),

                if (patient.emergencyContactName != null) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Contacto de emergencia',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.contact_phone_outlined,
                        label: 'Nombre',
                        value: patient.emergencyContactName!,
                      ),
                      if (patient.emergencyContactPhone != null)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: patient.emergencyContactPhone!,
                        ),
                    ],
                  ),
                ],

                if (patient.medicalNotes != null &&
                    patient.medicalNotes!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Notas clínicas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      patient.medicalNotes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],

                // Sessions
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sesiones (${patientSessions.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                if (patientSessions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingLg),
                      child: Text('Sin sesiones registradas'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: patientSessions.length,
                    itemBuilder: (_, i) => SessionCard(
                      session: patientSessions[i],
                      onTap: () =>
                          context.go('/sessions/${patientSessions[i].id}'),
                    ),
                  ),

                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(height: 1, color: AppTheme.borderColor),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: AppTheme.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
