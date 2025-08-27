import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? bio;
  final DateTime? createdAt;
  final bool isAdmin;
  final bool emailVerified;
  final List<String> tracks;
  final List<String> specializations;
  final bool isAcademic;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.bio,
    this.createdAt,
    this.isAdmin = false,
    this.emailVerified = false,
    this.tracks = const [],
    this.specializations = const [],
    this.isAcademic = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'bio': bio,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'isAdmin': isAdmin,
      'emailVerified': emailVerified,
      'tracks': tracks,
      'specializations': specializations,
      'isAcademic': isAcademic,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? json['email']?.split('@')[0] ?? '',
      bio: json['bio'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      isAdmin: json['isAdmin'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      tracks: List<String>.from(json['tracks'] ?? []),
      specializations: List<String>.from(json['specializations'] ?? []),
      isAcademic: json['isAcademic'] ?? true,
    );
  }
}
