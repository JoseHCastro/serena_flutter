import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';
import 'auth_provider.dart';

final patientServiceProvider = Provider<PatientService>(
  (ref) => PatientService(ref.read(apiClientProvider)),
);

final patientSearchProvider = StateProvider<String>((_) => '');

class PatientsNotifier extends AsyncNotifier<List<PatientModel>> {
  @override
  Future<List<PatientModel>> build() async {
    final search = ref.watch(patientSearchProvider);
    return _fetchPatients(search: search);
  }

  Future<List<PatientModel>> _fetchPatients({String search = ''}) async {
    final service = ref.read(patientServiceProvider);
    final result = await service.getPatients(
      search: search.isEmpty ? null : search,
      pageSize: 50,
    );
    return result.items;
  }

  Future<void> refresh() async {
    final search = ref.read(patientSearchProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPatients(search: search));
  }

  Future<PatientModel> updatePatient(String id, Map<String, dynamic> data) async {
    final service = ref.read(patientServiceProvider);
    final updated = await service.updatePatient(id, data);
    ref.invalidate(patientDetailProvider(id));
    await refresh();
    return updated;
  }

  Future<PatientModel> createPatient(Map<String, dynamic> data) async {
    final service = ref.read(patientServiceProvider);
    final created = await service.createPatient(data);
    await refresh();
    return created;
  }
}

final patientsProvider =
    AsyncNotifierProvider<PatientsNotifier, List<PatientModel>>(
  PatientsNotifier.new,
);

final patientDetailProvider =
    FutureProvider.family<PatientModel, String>((ref, id) {
  return ref.read(patientServiceProvider).getPatient(id);
});
