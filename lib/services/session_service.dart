import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/session_model.dart';

class SessionService {
  final Dio _dio;

  SessionService(this._dio);

  Future<PaginatedSessions> getSessions({
    int page = 1,
    int pageSize = 20,
    String? patientId,
    String? status,
  }) async {
    final response = await _dio.get(
      ApiConstants.sessions,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (patientId != null) 'patient_id': patientId,
        if (status != null) 'status': status,
      },
    );
    return PaginatedSessions.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SessionModel> getSession(String id) async {
    final response = await _dio.get(ApiConstants.session(id));
    return SessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SessionModel> scheduleSession({
    required String patientId,
    required String scheduledAt,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiConstants.sessions,
      data: {
        'patient_id': patientId,
        'scheduled_at': scheduledAt,
        if (notes != null) 'notes': notes,
      },
    );
    return SessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SessionModel> startSession(String id) async {
    final response = await _dio.post(ApiConstants.startSession(id));
    return SessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SessionModel> endSession(String id, {String? notes}) async {
    final response = await _dio.post(
      ApiConstants.endSession(id),
      data: notes != null ? {'notes': notes} : null,
    );
    return SessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SessionModel> uploadVideo(
    String sessionId,
    File videoFile, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final fileName = videoFile.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        videoFile.path,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      ApiConstants.uploadSessionVideo(sessionId),
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      onSendProgress: onProgress,
    );
    return SessionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
