import 'package:equatable/equatable.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';

class AppUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? avatarUrl,
    String? phone,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['full_name'] as String? ?? json['name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'customer'),
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'role': role.toJson(),
      'avatar_url': avatarUrl,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, name, role, avatarUrl, phone, createdAt];
}
