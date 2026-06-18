import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/patient_model.dart';

class PatientService {
  final Dio _dio;

  PatientService(this._dio);

  Future<PaginatedPatients> getPatients({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool activeOnly = true,
  }) async {
    final response = await _dio.get(
      ApiConstants.patients,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        'active_only': activeOnly,
      },
    );
    return PaginatedPatients.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PatientModel> getPatient(String id) async {
    final response = await _dio.get(ApiConstants.patient(id));
    return PatientModel.fromJson(response.data as Map<String, dynamic>);
  }
}
