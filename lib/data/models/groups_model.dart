import 'package:cloud_firestore/cloud_firestore.dart';

class GroupsModel {
  final String groupname;
  final String id;
  final List<String> members;
  final List<String> pendingMembers;
  final Timestamp? createdAt;
  final Map<String, dynamic>? lastReadMessages;
  final String adminEmail;

  GroupsModel({
    required this.groupname,
    required this.id,
    required this.members,
    this.pendingMembers = const [],
    this.createdAt,
    this.lastReadMessages,
    required this.adminEmail,
  });

  factory GroupsModel.fromJson(Map<String, dynamic> jsonData) {
    return GroupsModel(
      groupname: jsonData['groupname'] ?? '',
      id: jsonData['id'] ?? '',
      members: List<String>.from(jsonData['members'] ?? []),
      pendingMembers: List<String>.from(jsonData['pendingMembers'] ?? []),
      createdAt: jsonData['createdAt'] as Timestamp?,
      lastReadMessages: Map<String, dynamic>.from(
        jsonData['lastReadMessages'] ?? {},
      ),
      adminEmail: jsonData['adminEmail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupname': groupname,
      'id': id,
      'members': members,
      'pendingMembers': pendingMembers,
      'createdAt': createdAt,
      'lastReadMessages': lastReadMessages,
      'adminEmail': adminEmail,
    };
  }
}
