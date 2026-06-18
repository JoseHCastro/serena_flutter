enum AlertSeverity { low, medium, high, critical }

extension AlertSeverityExtension on AlertSeverity {
  static AlertSeverity fromString(String value) {
    switch (value) {
      case 'medium':
        return AlertSeverity.medium;
      case 'high':
        return AlertSeverity.high;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.low;
    }
  }

  String get label {
    switch (this) {
      case AlertSeverity.low:
        return 'Baja';
      case AlertSeverity.medium:
        return 'Media';
      case AlertSeverity.high:
        return 'Alta';
      case AlertSeverity.critical:
        return 'Crítica';
    }
  }
}

class AlertModel {
  final String id;
  final String sessionId;
  final String patientId;
  final String alertType;
  final AlertSeverity severity;
  final String message;
  final bool isAcknowledged;
  final String? acknowledgedAt;
  final String createdAt;
  final String? patientName;

  const AlertModel({
    required this.id,
    required this.sessionId,
    required this.patientId,
    required this.alertType,
    required this.severity,
    required this.message,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    required this.createdAt,
    this.patientName,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    String? patientName;
    if (json['patient'] != null) {
      final p = json['patient'] as Map<String, dynamic>;
      patientName = '${p['first_name']} ${p['last_name']}';
    }
    return AlertModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      patientId: json['patient_id'] as String,
      alertType: json['alert_type'] as String,
      severity: AlertSeverityExtension.fromString(json['severity'] as String),
      message: json['message'] as String,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledged_at'] as String?,
      createdAt: json['created_at'] as String,
      patientName: patientName,
    );
  }

  AlertModel copyWith({bool? isAcknowledged, String? acknowledgedAt}) =>
      AlertModel(
        id: id,
        sessionId: sessionId,
        patientId: patientId,
        alertType: alertType,
        severity: severity,
        message: message,
        isAcknowledged: isAcknowledged ?? this.isAcknowledged,
        acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
        createdAt: createdAt,
        patientName: patientName,
      );
}

class PaginatedAlerts {
  final List<AlertModel> items;
  final int total;

  const PaginatedAlerts({required this.items, required this.total});

  factory PaginatedAlerts.fromJson(Map<String, dynamic> json) =>
      PaginatedAlerts(
        items: (json['items'] as List)
            .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
      );
}
