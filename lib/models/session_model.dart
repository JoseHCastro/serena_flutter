import 'patient_model.dart';

enum SessionStatus { scheduled, active, completed, cancelled }

extension SessionStatusExtension on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.scheduled:
        return 'Programada';
      case SessionStatus.active:
        return 'Activa';
      case SessionStatus.completed:
        return 'Completada';
      case SessionStatus.cancelled:
        return 'Cancelada';
    }
  }

  static SessionStatus fromString(String value) {
    switch (value) {
      case 'active':
        return SessionStatus.active;
      case 'completed':
        return SessionStatus.completed;
      case 'cancelled':
        return SessionStatus.cancelled;
      default:
        return SessionStatus.scheduled;
    }
  }
}

class SessionModel {
  final String id;
  final String patientId;
  final String therapistId;
  final PatientModel? patient;
  final String scheduledAt;
  final String? startedAt;
  final String? endedAt;
  final SessionStatus status;
  final String? videoUrl;
  final String? videoPublicId;
  final String? notes;
  final String createdAt;

  const SessionModel({
    required this.id,
    required this.patientId,
    required this.therapistId,
    this.patient,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.status,
    this.videoUrl,
    this.videoPublicId,
    this.notes,
    required this.createdAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        therapistId: json['therapist_id'] as String,
        patient: json['patient'] != null
            ? PatientModel.fromJson(json['patient'] as Map<String, dynamic>)
            : null,
        scheduledAt: json['scheduled_at'] as String,
        startedAt: json['started_at'] as String?,
        endedAt: json['ended_at'] as String?,
        status: SessionStatusExtension.fromString(json['status'] as String),
        videoUrl: json['video_url'] as String?,
        videoPublicId: json['video_public_id'] as String?,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] as String,
      );

  SessionModel copyWith({
    String? videoUrl,
    String? videoPublicId,
    SessionStatus? status,
    String? startedAt,
    String? endedAt,
    String? notes,
  }) =>
      SessionModel(
        id: id,
        patientId: patientId,
        therapistId: therapistId,
        patient: patient,
        scheduledAt: scheduledAt,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        status: status ?? this.status,
        videoUrl: videoUrl ?? this.videoUrl,
        videoPublicId: videoPublicId ?? this.videoPublicId,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}

class PaginatedSessions {
  final List<SessionModel> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedSessions({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedSessions.fromJson(Map<String, dynamic> json) =>
      PaginatedSessions(
        items: (json['items'] as List)
            .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int? ?? 1,
        pageSize: json['page_size'] as int? ?? 20,
      );
}
