import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/alert_model.dart';

class AlertService {
  final Dio _dio;

  AlertService(this._dio);

  Future<PaginatedAlerts> getAlerts({
    int page = 1,
    int pageSize = 20,
    String? sessionId,
    String? patientId,
    String? severity,
    bool? unacknowledgedOnly,
  }) async {
    final response = await _dio.get(
      ApiConstants.alerts,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        'session_id': ?sessionId,
        'patient_id': ?patientId,
        'severity': ?severity,
        'unacknowledged_only': ?unacknowledgedOnly,
      },
    );
    return PaginatedAlerts.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AlertModel> acknowledgeAlert(String alertId) async {
    final response =
        await _dio.post(ApiConstants.acknowledgeAlert(alertId));
    return AlertModel.fromJson(response.data as Map<String, dynamic>);
  }
}
