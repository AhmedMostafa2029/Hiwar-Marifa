import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/data/models/messages_model.dart';

class ChatProvider with ChangeNotifier {
  final String groupId;
  bool _isSending = false;
  String? _lastError;
  Message? _replyingToMessage;
  Message? _editingMessage;

  ChatProvider(this.groupId) {
    debugPrint('ChatProvider initialized for group: $groupId');
  }

  bool get isSending => _isSending;
  String? get lastError => _lastError;
  Message? get replyingToMessage => _replyingToMessage;
  Message? get editingMessage => _editingMessage;

  void setReplyingToMessage(Message? message) {
    _replyingToMessage = message;
    notifyListeners();
  }

  void setEditingMessage(Message? message) {
    _editingMessage = message;
    notifyListeners();
  }

  void clearReply() {
    _replyingToMessage = null;
    notifyListeners();
  }

  void clearEdit() {
    _editingMessage = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (text.trim().isEmpty || user == null) return;

      _isSending = true;
      notifyListeners();

      final userDoc = await FirebaseFirestore.instance
          .collection(kUsersCollection)
          .doc(user.uid)
          .get();

      final username = userDoc.exists
          ? userDoc.data()!['username'] ??
                user.displayName ??
                user.email!.split('@')[0]
          : user.displayName ?? user.email!.split('@')[0];

      final messageData = {
        'message': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'groupId': groupId,
        'senderName': username,
        'userEmail': user.email,
        'messageType': 'text',
        'reactions': {},
        'canEdit': true,
        'editExpiryTime': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      };

      // Add reply data if replying to a message
      if (_replyingToMessage != null) {
        messageData['repliedToMessageId'] = _replyingToMessage!.id;
        messageData['repliedToSender'] = _replyingToMessage!.senderName;
        messageData['repliedToContent'] = _replyingToMessage!.message;
      }

      await FirebaseFirestore.instance
          .collection(kMessagesCollection)
          .add(messageData);

      _lastError = null;
      _replyingToMessage = null;
    } on FirebaseException catch (e) {
      _lastError = 'Failed to send message: ${e.message}';
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> updateMessage(String messageId, String newText) async {
    try {
      await FirebaseFirestore.instance
          .collection(kMessagesCollection)
          .doc(messageId)
          .update({
            'message': newText.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _editingMessage = null;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to update message: ${e.toString()}';
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection(kMessagesCollection)
          .doc(messageId)
          .update({
            'isDeleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      _lastError = 'Failed to delete message: ${e.toString()}';
      rethrow;
    }
  }

  Future<void> toggleReaction(String messageId, String reactionType) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection(kUsersCollection)
          .doc(user.uid)
          .get();

      final username = userDoc.exists
          ? userDoc.data()!['username'] ??
                user.displayName ??
                user.email!.split('@')[0]
          : user.displayName ?? user.email!.split('@')[0];

      final messageDoc = FirebaseFirestore.instance
          .collection(kMessagesCollection)
          .doc(messageId);

      final messageSnapshot = await messageDoc.get();
      if (!messageSnapshot.exists) return;

      final currentData = messageSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> currentReactions = Map<String, dynamic>.from(
        currentData['reactions'] ?? {},
      );

      // Convert reactions to proper format if needed
      Map<String, List<String>> convertedReactions = {};
      currentReactions.forEach((key, value) {
        if (value is List<dynamic>) {
          convertedReactions[key] = value.map((e) => e.toString()).toList();
        } else if (value is List<String>) {
          convertedReactions[key] = List<String>.from(value);
        }
      });

      // Remove user from all other reactions
      for (var entry in convertedReactions.entries) {
        convertedReactions[entry.key] = entry.value
            .where((usernameInList) => usernameInList != username)
            .toList();
        if (convertedReactions[entry.key]!.isEmpty) {
          convertedReactions.remove(entry.key);
        }
      }

      // Add user to the selected reaction
      if (!convertedReactions.containsKey(reactionType)) {
        convertedReactions[reactionType] = [];
      }

      if (!convertedReactions[reactionType]!.contains(username)) {
        convertedReactions[reactionType]!.add(username);
      } else {
        // Remove if already reacted with same type
        convertedReactions[reactionType]!.remove(username);
        if (convertedReactions[reactionType]!.isEmpty) {
          convertedReactions.remove(reactionType);
        }
      }

      await messageDoc.update({'reactions': convertedReactions});
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
      _lastError = 'Failed to toggle reaction: ${e.toString()}';
      rethrow;
    }
  }
}
