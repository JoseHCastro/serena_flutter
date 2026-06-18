class RoleModel {
  final String id;
  final String name;

  const RoleModel({required this.id, required this.name});

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final RoleModel? role;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.role,
    this.isActive = true,
  });

  String get name => fullName;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] != null
            ? RoleModel.fromJson(json['role'] as Map<String, dynamic>)
            : null,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'is_active': isActive,
      };
}
