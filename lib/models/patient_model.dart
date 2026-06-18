class PatientModel {
  final String id;
  final String code;
  final String firstName;
  final String lastName;
  final String? birthDate;
  final String? gender;
  final String? phone;
  final String? email;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? medicalNotes;
  final String? therapistId;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const PatientModel({
    required this.id,
    required this.code,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.gender,
    this.phone,
    this.email,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.medicalNotes,
    this.therapistId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  // Handles both full patient response and the minimal embedded schema
  // (which only has full_name instead of first_name + last_name)
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    String firstName;
    String lastName;

    if (json.containsKey('first_name')) {
      firstName = json['first_name'] as String;
      lastName = json['last_name'] as String;
    } else {
      // Minimal embedded schema: "full_name": "Nelly Lara Olivo"
      final parts = (json['full_name'] as String? ?? '').split(' ');
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return PatientModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      firstName: firstName,
      lastName: lastName,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      therapistId: json['therapist_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class PaginatedPatients {
  final List<PatientModel> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedPatients({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedPatients.fromJson(Map<String, dynamic> json) =>
      PaginatedPatients(
        items: (json['items'] as List)
            .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int? ?? 1,
        pageSize: json['page_size'] as int? ?? 20,
      );
}
