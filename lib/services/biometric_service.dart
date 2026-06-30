import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/analysis_model.dart';

class BiometricService {
  final Dio _dio;

  BiometricService(this._dio);

  Future<BiometricJobModel?> getAnalysisJob(String sessionId) async {
    try {
      final response =
          await _dio.get(ApiConstants.biometricAnalysisJob(sessionId));
      return BiometricJobModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<BiometricJobModel> triggerAnalysis(String sessionId) async {
    final response =
        await _dio.post(ApiConstants.biometricAnalyze(sessionId));
    return BiometricJobModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<EmotionalSnapshot>> getSnapshots(String sessionId) async {
    final response =
        await _dio.get(ApiConstants.biometricSnapshots(sessionId));
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => EmotionalSnapshot.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // paginated response
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items
        .map((e) => EmotionalSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ComparativeReport> getPatientEvolution(String patientId) async {
    final response = await _dio.get(ApiConstants.biometricEvolution(patientId));
    return ComparativeReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ComparativeReport> getComparisonReport(
      String patientId, List<String> sessionIds) async {
    final response = await _dio.get(
      ApiConstants.biometricCompare(patientId),
      queryParameters: {
        'session_ids': sessionIds,
      },
    );
    return ComparativeReport.fromJson(response.data as Map<String, dynamic>);
  }
}
