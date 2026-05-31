import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, manager, supervisor, employer, employee }

class UserModel {
  final String id;
  final String name;
  final UserRole role;
  final List<String>? areas; // e.g., ['Area1', 'Area2']
  final String? nationality; // e.g., China, Bangladesh
  final String email;
  final String? password;
  final String? picture;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.areas,
    this.nationality,
    required this.email,
    this.password,
    this.picture,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.toString(),
      'areas': areas,
      'nationality': nationality,
      'email': email,
      'picture': picture,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      role: _parseRole(json['role']),
      areas: json['areas'] != null ? List<String>.from(json['areas']) : (json['area'] != null ? [json['area']] : null),
      nationality: json['nationality'],
      email: json['email'],
      picture: json['picture'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      role: _parseRole(data['role']),
      areas: data['areas'] != null ? List<String>.from(data['areas']) : (data['area'] != null ? [data['area']] : null),
      nationality: data['nationality'],
      email: data['email'] ?? '',
      picture: data['picture'],
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
    );
  }

  static UserRole _parseRole(String? roleStr) {
    switch (roleStr) {
      case 'UserRole.admin':
        return UserRole.admin;
      case 'UserRole.manager':
        return UserRole.manager;
      case 'UserRole.supervisor':
        return UserRole.supervisor;
      case 'UserRole.employer':
        return UserRole.employer;
      case 'UserRole.employee':
      default:
        return UserRole.employee;
    }
  }

  UserModel copyWith({
    String? id,
    String? name,
    UserRole? role,
    List<String>? areas,
    String? nationality,
    String? email,
    String? password,
    String? picture,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      areas: areas ?? this.areas,
      nationality: nationality ?? this.nationality,
      email: email ?? this.email,
      password: password ?? this.password,
      picture: picture ?? this.picture,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
