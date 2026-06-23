class ApiConstants {
  // Backend host:
  //  - Android emulator:   http://10.0.2.2:8000  ← activo
  //  - Web/Desktop local:  http://localhost:8000
  //  - Physical device:    http://<your-lan-ip>:8000
  static const String baseUrl = 'https://serena-back.duckdns.org/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String me = '/users/me';

  // Patients
  static const String patients = '/patients';
  static String patient(String id) => '/patients/$id';

  // Sessions
  static const String sessions = '/sessions';
  static String session(String id) => '/sessions/$id';
  static String startSession(String id) => '/sessions/$id/start';
  static String endSession(String id) => '/sessions/$id/end';
  static String uploadSessionVideo(String id) => '/sessions/$id/upload-video';
  static String sessionTimeline(String id) => '/sessions/$id/timeline';

  // Biometric
  static String biometricSnapshots(String sessionId) =>
      '/biometric/sessions/$sessionId/snapshots';
  static String biometricAnalysisJob(String sessionId) =>
      '/biometric/sessions/$sessionId/analysis-job';
  static String biometricAnalyze(String sessionId) =>
      '/biometric/sessions/$sessionId/analyze';
  static String biometricTimeline(String sessionId) =>
      '/biometric/sessions/$sessionId/timeline';
  static String biometricCompare(String patientId) =>
      '/biometric/patients/$patientId/compare';
  static String biometricMicroexpressions(String sessionId) =>
      '/biometric/sessions/$sessionId/microexpressions';

  // Alerts
  static const String alerts = '/alerts';
  static String acknowledgeAlert(String alertId) =>
      '/alerts/$alertId/acknowledge';

  // Reports
  static String sessionPdf(String sessionId) =>
      '/reports/sessions/$sessionId/pdf';
}
