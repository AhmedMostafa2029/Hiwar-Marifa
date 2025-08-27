import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';

class Message {
  final String id;
  final String message;
  final String userId;
  final String groupId;
  final String senderName;
  final String userEmail;
  final String messageType;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final bool isDeleted;
  final String? repliedToMessageId;
  final String? repliedToSender;
  final String? repliedToContent;
  final Map<String, List<String>> reactions;
  final bool canEdit;
  final DateTime? editExpiryTime;

  Message({
    required this.id,
    required this.message,
    required this.userId,
    required this.groupId,
    required this.senderName,
    required this.userEmail,
    required this.messageType,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.repliedToMessageId,
    this.repliedToSender,
    this.repliedToContent,
    this.reactions = const {},
    required this.canEdit,
    this.editExpiryTime,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> reactionsMap = {};

    if (json['reactions'] != null && json['reactions'] is Map) {
      final reactionsData = json['reactions'] as Map<String, dynamic>;

      reactionsData.forEach((key, value) {
        if (value is List<dynamic>) {
          reactionsMap[key] = value.map((e) => e.toString()).toList();
        } else if (value is List<String>) {
          reactionsMap[key] = List<String>.from(value);
        }
      });
    }

    return Message(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      userId: json['userId'] ?? '',
      groupId: json['groupId'] ?? '',
      senderName: json['senderName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      messageType: json['messageType'] ?? 'text',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'],
      isDeleted: json['isDeleted'] ?? false,
      repliedToMessageId: json['repliedToMessageId'],
      repliedToSender: json['repliedToSender'],
      repliedToContent: json['repliedToContent'],
      reactions: reactionsMap,
      canEdit: json['canEdit'] ?? false,
      editExpiryTime: json['editExpiryTime'] != null
          ? (json['editExpiryTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'userId': userId,
      'groupId': groupId,
      'senderName': senderName,
      'userEmail': userEmail,
      'messageType': messageType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
      'repliedToMessageId': repliedToMessageId,
      'repliedToSender': repliedToSender,
      'repliedToContent': repliedToContent,
      'reactions': reactions,
      'canEdit': canEdit,
      'editExpiryTime': editExpiryTime != null
          ? Timestamp.fromDate(editExpiryTime!)
          : null,
    };
  }

  bool get canBeEdited {
    if (!canEdit) return false;
    if (editExpiryTime == null) return false;
    return DateTime.now().isBefore(editExpiryTime!);
  }

  bool canDelete(String currentUserEmail) {
    return currentUserEmail == userEmail ||
        adminEmails.contains(currentUserEmail);
  }

  String? getUserReaction(String username) {
    for (var entry in reactions.entries) {
      if (entry.value.contains(username)) {
        return entry.key;
      }
    }
    return null;
  }
}
