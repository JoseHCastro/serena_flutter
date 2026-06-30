import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../components/app_top_bar.dart';
import '../../components/session_card.dart';
import '../../providers/patients_provider.dart';
import '../../providers/sessions_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/patient_model.dart';
import '../../models/session_model.dart';
import '../../models/analysis_model.dart';
import '../../components/emotion_chart.dart';
import '../../providers/biometric_provider.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedSessionIds = {};

  @override
  Widget build(BuildContext context) {
    final patientId = widget.patientId;
    final patientState = ref.watch(patientDetailProvider(patientId));
    final sessionsState = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Detalle del paciente',
        actions: [
          patientState.maybeWhen(
            data: (patient) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditPatientDialog(context, ref, patient),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryContrast,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${patient.code}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryContrast.withOpacity(0.7),
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
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Fecha de nacimiento',
                      value: patient.birthDate != null ? _formatDate(patient.birthDate!) : 'No especificada',
                    ),
                    _InfoRow(
                      icon: Icons.transgender_outlined,
                      label: 'Género',
                      value: patient.gender == 'M' ? 'Masculino' : 'Femenino',
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

                // Evolución clínica
                const SizedBox(height: AppTheme.spacingLg),
                _buildEvolutionSection(context, ref, patient.id),

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

                if (patient.medicalNotes != null) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Notas médicas',
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppTheme.spacingMd,
                  runSpacing: AppTheme.spacingXs,
                  children: [
                    Text(
                      'Sesiones (${patientSessions.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            final completedCount = patientSessions.where((s) => s.status == SessionStatus.completed).length;
                            if (completedCount >= 2) {
                              setState(() {
                                _isSelectionMode = !_isSelectionMode;
                                _selectedSessionIds.clear();
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Se requieren al menos 2 sesiones completadas para realizar una comparación.'),
                                ),
                              );
                            }
                          },
                          icon: Icon(_isSelectionMode ? Icons.close : Icons.compare_arrows),
                          label: Text(_isSelectionMode ? 'Cancelar' : 'Comparar'),
                          style: TextButton.styleFrom(
                            foregroundColor: _isSelectionMode
                                ? AppTheme.errorColor
                                : (patientSessions.where((s) => s.status == SessionStatus.completed).length >= 2
                                    ? AppTheme.primaryColor
                                    : AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        TextButton.icon(
                          onPressed: () => _showCreateSessionDialog(context, ref, patient.id),
                          icon: const Icon(Icons.add),
                          label: const Text('Nueva sesión'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
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
                    itemBuilder: (_, i) {
                      final session = patientSessions[i];
                      final isCompleted = session.status == SessionStatus.completed;

                      if (_isSelectionMode) {
                        final isSelected = _selectedSessionIds.contains(session.id);
                        return Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: AppTheme.primaryColor,
                              onChanged: isCompleted
                                  ? (val) {
                                      setState(() {
                                        if (val == true) {
                                          if (_selectedSessionIds.length < 3) {
                                            _selectedSessionIds.add(session.id);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Solo puedes seleccionar hasta 3 sesiones.')),
                                            );
                                          }
                                        } else {
                                          _selectedSessionIds.remove(session.id);
                                        }
                                      });
                                    }
                                  : null,
                            ),
                            Expanded(
                              child: Opacity(
                                opacity: isCompleted ? 1.0 : 0.5,
                                child: SessionCard(
                                  session: session,
                                  onTap: isCompleted
                                      ? () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedSessionIds.remove(session.id);
                                            } else {
                                              if (_selectedSessionIds.length < 3) {
                                                _selectedSessionIds.add(session.id);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Solo puedes seleccionar hasta 3 sesiones.')),
                                                );
                                              }
                                            }
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return SessionCard(
                        session: session,
                        onTap: () =>
                            context.go('/sessions/${session.id}'),
                      );
                    },
                  ),

                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _isSelectionMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceColor,
                  border: Border(top: BorderSide(color: AppTheme.borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedSessionIds.length} seleccionadas (Máx. 3)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    ElevatedButton(
                      onPressed: _selectedSessionIds.length >= 2
                          ? () => _showComparisonDialog(context, patientId, _selectedSessionIds.toList())
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.primaryContrast,
                      ),
                      child: const Text('Ver Comparación'),
                    ),
                  ],
                ),
              ),
            )
          : null,
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

  Widget _buildEvolutionSection(
      BuildContext context, WidgetRef ref, String patientId) {
    final evolutionState = ref.watch(patientEvolutionProvider(patientId));

    return evolutionState.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
          child: Text('Error al cargar evolución: $e',
              style: const TextStyle(color: AppTheme.errorColor)),
        ),
      ),
      data: (report) {
        if (report.sessions.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: PatientEvolutionChart(points: report.sessions),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: children,
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
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showEditPatientDialog(
    BuildContext context, WidgetRef ref, PatientModel patient) {
  showDialog(
    context: context,
    builder: (_) => _EditPatientDialog(patient: patient),
  );
}

class _EditPatientDialog extends ConsumerStatefulWidget {
  final PatientModel patient;

  const _EditPatientDialog({required this.patient});

  @override
  ConsumerState<_EditPatientDialog> createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends ConsumerState<_EditPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.patient.firstName);
    _lastNameController = TextEditingController(text: widget.patient.lastName);
    _phoneController = TextEditingController(text: widget.patient.phone);
    _emailController = TextEditingController(text: widget.patient.email);
    _addressController = TextEditingController(text: widget.patient.address);
    _emergencyNameController = TextEditingController(text: widget.patient.emergencyContactName);
    _emergencyPhoneController = TextEditingController(text: widget.patient.emergencyContactPhone);
    _notesController = TextEditingController(text: widget.patient.medicalNotes);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar paciente'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _emergencyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Contacto de Emergencia (Nombre)',
                    prefixIcon: Icon(Icons.contact_phone_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _emergencyPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contacto de Emergencia (Teléfono)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas médicas/clínicas',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.primaryContrast,
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'emergency_contact_name':
            _emergencyNameController.text.trim().isEmpty ? null : _emergencyNameController.text.trim(),
        'emergency_contact_phone':
            _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
        'medical_notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      await ref.read(patientsProvider.notifier).updatePatient(widget.patient.id, data);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

void _showCreateSessionDialog(
    BuildContext context, WidgetRef ref, String patientId) {
  showDialog(
    context: context,
    builder: (_) => _CreateSessionDialog(patientId: patientId),
  );
}

class _CreateSessionDialog extends ConsumerStatefulWidget {
  final String patientId;

  const _CreateSessionDialog({required this.patientId});

  @override
  ConsumerState<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends ConsumerState<_CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return AlertDialog(
      title: const Text('Programar nueva sesión'),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor),
                  title: const Text('Fecha'),
                  subtitle: Text(formattedDate),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: _selectDate,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_outlined, color: AppTheme.primaryColor),
                  title: const Text('Hora'),
                  subtitle: Text(formattedTime),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: _selectTime,
                ),
                const Divider(),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas iniciales o motivo',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.primaryContrast,
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Programar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final notesText = _notesController.text.trim();

      await ref.read(sessionsProvider.notifier).scheduleSession(
            patientId: widget.patientId,
            scheduledAt: scheduledDateTime.toUtc().toIso8601String(),
            notes: notesText.isEmpty ? null : notesText,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión programada con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al programar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

void _showComparisonDialog(
    BuildContext context, String patientId, List<String> sessionIds) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _SessionComparisonDialog(
        patientId: patientId,
        sessionIds: sessionIds,
      ),
    ),
  );
}

class _SessionComparisonDialog extends ConsumerWidget {
  final String patientId;
  final List<String> sessionIds;

  const _SessionComparisonDialog({
    required this.patientId,
    required this.sessionIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = '${patientId}_${sessionIds.join(',')}';
    final comparisonState = ref.watch(sessionComparisonProvider(arg));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparación de Sesiones'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.primaryContrast,
      ),
      body: comparisonState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              'Error al cargar comparación: $e',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ),
        data: (report) {
          if (report.sessions.length < 2) {
            return const Center(
              child: Text('No hay datos suficientes para realizar la comparación.'),
            );
          }

          final sortedSessions = List<SessionComparePoint>.from(report.sessions)
            ..sort((a, b) => DateTime.parse(a.scheduledAt).compareTo(DateTime.parse(b.scheduledAt)));

          final sessionA = sortedSessions.first;
          final sessionB = sortedSessions.last;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sortedSessions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final pt = entry.value;
                      final title = sortedSessions.length == 3
                          ? (idx == 0 ? 'Sesión Inicial' : (idx == 1 ? 'Sesión Intermedia' : 'Sesión Reciente'))
                          : (idx == 0 ? 'Sesión Anterior' : 'Sesión Posterior');
                      return Container(
                        width: 175,
                        margin: const EdgeInsets.only(right: AppTheme.spacingMd),
                        child: _buildSessionSummaryCard(context, title, pt),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: EmotionComparisonChart(
                    sessions: sortedSessions,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                Text(
                  sortedSessions.length == 3
                      ? 'Análisis de Cambio Emocional (Inicial → Reciente)'
                      : 'Análisis de Cambio Emocional',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildDeltaList(context, sortedSessions),
                const SizedBox(height: AppTheme.spacingLg),

                _buildClinicalEvolutionCard(context, sessionA, sessionB),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionSummaryCard(
      BuildContext context, String title, SessionComparePoint pt) {
    final date = _formatDateHeader(pt.scheduledAt);
    final dominantSp = _translateEmotion(pt.dominantOverall);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.psychology_outlined, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Dominante: $dominantSp',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaList(
      BuildContext context, List<SessionComparePoint> sortedSessions) {
    final emotions = ['happiness', 'sadness', 'anger', 'fear', 'neutral'];
    final labels = {
      'happiness': 'Felicidad',
      'sadness': 'Tristeza',
      'anger': 'Ira',
      'fear': 'Miedo',
      'neutral': 'Neutral',
    };

    final first = sortedSessions.first;
    final last = sortedSessions.last;

    return Column(
      children: emotions.map((emotion) {
        final valFirst = first.allAverages[emotion] ?? 0.0;
        final valLast = last.allAverages[emotion] ?? 0.0;
        final diff = valLast - valFirst;
        final percentDiff = (diff * 100).toStringAsFixed(1);
        final label = labels[emotion] ?? emotion;

        final sequenceStr = sortedSessions
            .map((s) => '${((s.allAverages[emotion] ?? 0.0) * 100).toInt()}%')
            .join(' → ');

        Color diffColor = Colors.grey;
        String sign = '';
        if (diff > 0.01) {
          sign = '+';
          diffColor = (emotion == 'happiness' || emotion == 'neutral') ? Colors.green : Colors.red;
        } else if (diff < -0.01) {
          diffColor = (emotion == 'happiness' || emotion == 'neutral') ? Colors.red : Colors.green;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text(
                    sequenceStr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: diffColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$sign$percentDiff%',
                      style: TextStyle(
                        color: diffColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClinicalEvolutionCard(
      BuildContext context, SessionComparePoint a, SessionComparePoint b) {
    final hapA = a.avgHappiness;
    final hapB = b.avgHappiness;
    final negativeA = a.avgSadness + a.avgAnger + a.avgFear;
    final negativeB = b.avgSadness + b.avgAnger + b.avgFear;

    String advice;
    IconData icon;
    MaterialColor color;

    if (hapB > hapA && negativeB < negativeA) {
      advice = 'El paciente muestra una clara mejoría clínica. Las emociones positivas han aumentado y las expresiones de estrés o malestar han disminuido significativamente.';
      icon = Icons.trending_up;
      color = Colors.green;
    } else if (hapB < hapA && negativeB > negativeA) {
      advice = 'Se observa un incremento en el malestar emocional (tristeza/ira/miedo) y una disminución del afecto positivo. Se recomienda explorar factores estresantes recientes.';
      icon = Icons.trending_down;
      color = Colors.red;
    } else {
      advice = 'La evolución emocional se mantiene estable. Las variaciones observadas están dentro de los rangos clínicos habituales para el paciente.';
      icon = Icons.trending_flat;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnóstico de Evolución',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: TextStyle(color: color.shade900, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _translateEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happiness':
        return 'Felicidad';
      case 'sadness':
        return 'Tristeza';
      case 'anger':
        return 'Ira';
      case 'fear':
        return 'Miedo';
      case 'disgust':
        return 'Asco';
      case 'surprise':
        return 'Sorpresa';
      case 'neutral':
        return 'Neutral';
      default:
        return emotion;
    }
  }
}
