enum AnalysisJobStatus { pending, processing, completed, failed }

extension AnalysisJobStatusExtension on AnalysisJobStatus {
  static AnalysisJobStatus fromString(String value) {
    switch (value) {
      case 'processing':
        return AnalysisJobStatus.processing;
      case 'completed':
        return AnalysisJobStatus.completed;
      case 'failed':
        return AnalysisJobStatus.failed;
      default:
        return AnalysisJobStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case AnalysisJobStatus.pending:
        return 'Pendiente';
      case AnalysisJobStatus.processing:
        return 'Procesando';
      case AnalysisJobStatus.completed:
        return 'Completado';
      case AnalysisJobStatus.failed:
        return 'Error';
    }
  }
}

class BiometricJobModel {
  final String id;
  final String sessionId;
  final String? celeryTaskId;
  final AnalysisJobStatus status;
  final Map<String, dynamic>? resultSummary;
  final String? errorMessage;
  final String createdAt;
  final String updatedAt;

  const BiometricJobModel({
    required this.id,
    required this.sessionId,
    this.celeryTaskId,
    required this.status,
    this.resultSummary,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BiometricJobModel.fromJson(Map<String, dynamic> json) =>
      BiometricJobModel(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        celeryTaskId: json['celery_task_id'] as String?,
        status: AnalysisJobStatusExtension.fromString(json['status'] as String),
        resultSummary: json['result_summary'] as Map<String, dynamic>?,
        errorMessage: json['error_message'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
}

class EmotionalSnapshot {
  final String id;
  final String sessionId;
  final double timestampOffset;
  final double happiness;
  final double sadness;
  final double anger;
  final double fear;
  final double disgust;
  final double surprise;
  final double neutral;
  final String dominantEmotion;
  final double confidence;

  const EmotionalSnapshot({
    required this.id,
    required this.sessionId,
    required this.timestampOffset,
    required this.happiness,
    required this.sadness,
    required this.anger,
    required this.fear,
    required this.disgust,
    required this.surprise,
    required this.neutral,
    required this.dominantEmotion,
    required this.confidence,
  });

  factory EmotionalSnapshot.fromJson(Map<String, dynamic> json) =>
      EmotionalSnapshot(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        timestampOffset: (json['timestamp_offset'] as num).toDouble(),
        happiness: (json['happiness'] as num).toDouble(),
        sadness: (json['sadness'] as num).toDouble(),
        anger: (json['anger'] as num).toDouble(),
        fear: (json['fear'] as num).toDouble(),
        disgust: (json['disgust'] as num).toDouble(),
        surprise: (json['surprise'] as num).toDouble(),
        neutral: (json['neutral'] as num).toDouble(),
        dominantEmotion: json['dominant_emotion'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );

  Map<String, double> get allEmotions => {
        'happiness': happiness,
        'sadness': sadness,
        'anger': anger,
        'fear': fear,
        'disgust': disgust,
        'surprise': surprise,
        'neutral': neutral,
      };
}

class MicroexpressionEvent {
  final String id;
  final String sessionId;
  final double timestampOffset;
  final String emotionDetected;
  final double intensity;
  final int durationMs;

  const MicroexpressionEvent({
    required this.id,
    required this.sessionId,
    required this.timestampOffset,
    required this.emotionDetected,
    required this.intensity,
    required this.durationMs,
  });

  factory MicroexpressionEvent.fromJson(Map<String, dynamic> json) =>
      MicroexpressionEvent(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        timestampOffset: (json['timestamp_offset'] as num).toDouble(),
        emotionDetected: json['emotion_detected'] as String,
        intensity: (json['intensity'] as num).toDouble(),
        durationMs: json['duration_ms'] as int,
      );
}
