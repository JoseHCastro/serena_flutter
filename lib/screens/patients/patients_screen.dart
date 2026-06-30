import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePatientDialog(context, ref),
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Registrar nuevo paciente',
        child: const Icon(Icons.add, color: AppTheme.primaryContrast),
      ),
    );
  }
}

void _showCreatePatientDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (_) => const _CreatePatientDialog(),
  );
}

class _CreatePatientDialog extends ConsumerStatefulWidget {
  const _CreatePatientDialog();

  @override
  ConsumerState<_CreatePatientDialog> createState() => _CreatePatientDialogState();
}

class _CreatePatientDialogState extends ConsumerState<_CreatePatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _gender;
  DateTime? _birthDate;
  bool _saving = false;

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

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : 'No especificada';

    return AlertDialog(
      title: const Text('Registrar nuevo paciente'),
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

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake_outlined, color: AppTheme.textMuted),
                  title: const Text('Fecha de nacimiento', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  subtitle: Text(formattedDate, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: _selectBirthDate,
                ),
                const Divider(),
                const SizedBox(height: AppTheme.spacingSm),

                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Género',
                    prefixIcon: Icon(Icons.transgender_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Masculino')),
                    DropdownMenuItem(value: 'F', child: Text('Femenino')),
                  ],
                  onChanged: (val) => setState(() => _gender = val),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Correo electrónico no válido';
                    }
                    return null;
                  },
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
                  keyboardType: TextInputType.phone,
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
                    labelText: 'Notas médicas/clínicas iniciales',
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
              : const Text('Registrar'),
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
        'birth_date': _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : null,
        'gender': _gender,
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'emergency_contact_name':
            _emergencyNameController.text.trim().isEmpty ? null : _emergencyNameController.text.trim(),
        'emergency_contact_phone':
            _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
        'medical_notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      await ref.read(patientsProvider.notifier).createPatient(data);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente registrado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
