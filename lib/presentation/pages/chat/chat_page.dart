import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/data/models/messages_model.dart';
import 'package:hiwar_marifa/presentation/pages/chat/group_management_page.dart';
import 'package:hiwar_marifa/presentation/widgets/chat/custom_message.dart';
import 'package:hiwar_marifa/provider/chat_provider.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.groupname, required this.groupId});

  static String id = "ChatPage";
  final String groupname;
  final String groupId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  List<Message> _messages = [];

  @override
  void initState() {
    _recordReadTime();
    super.initState();
    _subscribeToMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _subscribeToMessages() {
    _messagesSubscription = FirebaseFirestore.instance
        .collection(kMessagesCollection)
        .where('groupId', isEqualTo: widget.groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (querySnapshot) {
            setState(() {
              _messages = querySnapshot.docs.map((doc) {
                return Message.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                });
              }).toList();
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          },
          onError: (error) {
            debugPrint('Error loading messages: $error');
          },
        );
  }

  Future<void> _recordReadTime() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    try {
      await FirebaseFirestore.instance
          .collection(kGroupsCollection)
          .doc(widget.groupId)
          .update({
            'lastReadMessages.$currentUserEmail': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error recording read time: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final isAdmin = adminEmails.contains(currentUserEmail);

    return ChangeNotifierProvider(
      create: (context) => ChatProvider(widget.groupId),
      child: Scaffold(
        appBar: _buildAppBar(isAdmin, context),
        body: Column(
          children: [
            Expanded(child: _buildMessagesList(currentUserEmail, isAdmin)),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return _buildMessageInput(chatProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool isAdmin, BuildContext context) {
    final CollectionReference groups = FirebaseFirestore.instance.collection(
      kGroupsCollection,
    );

    return AppBar(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group, size: 20, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: groups.doc(widget.groupId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final members = List<String>.from(data['members'] ?? []);
                      final pending = List<String>.from(
                        data['pendingMembers'] ?? [],
                      );

                      return Row(
                        children: [
                          Text(
                            '${members.length} members',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          if (isAdmin && pending.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${pending.length} pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: kPrimaryColor,
      actions: _buildAdminActions(isAdmin, context),
    );
  }

  List<Widget> _buildAdminActions(bool isAdmin, BuildContext context) {
    if (!isAdmin) return [];

    return [
      StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(kGroupsCollection)
            .doc(widget.groupId)
            .snapshots(),
        builder: (context, snapshot) {
          int pendingCount = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final pending = List<String>.from(data['pendingMembers'] ?? []);
            pendingCount = pending.length;
          }

          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _navigateToGroupManagement(context),
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      pendingCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ];
  }

  void _navigateToGroupManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSettingsPage(
          groupId: widget.groupId,
          groupName: widget.groupname,
        ),
      ),
    );
  }

  Widget _buildMessagesList(String currentUserEmail, bool isAdmin) {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet\nStart the conversation!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    //=======================================================================================================
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return CustomMessage(
          message: _messages[index],
          currentUserEmail: currentUserEmail,
          useName: _messages[index].senderName,
        );
      },
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider) {
    return Column(
      children: [
        if (chatProvider.replyingToMessage != null)
          _buildReplyHeader(context, chatProvider),
        if (chatProvider.editingMessage != null)
          _buildEditHeader(context, chatProvider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: chatProvider.editingMessage != null
                        ? 'Edit your message...'
                        : 'Send a message Now...',
                    filled: true,
                    fillColor: kPrimaryColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(chatProvider),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: chatProvider.isSending
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send, color: kPrimaryColor),
                onPressed: chatProvider.isSending
                    ? null
                    : () => _sendMessage(chatProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyHeader(BuildContext context, ChatProvider chatProvider) {
    final message = chatProvider.replyingToMessage!;
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.senderName}',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              chatProvider.clearReply();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditHeader(BuildContext context, ChatProvider chatProvider) {
    final message = chatProvider.editingMessage!;
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blue[50],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editing message',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              chatProvider.clearEdit();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(ChatProvider chatProvider) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      if (chatProvider.editingMessage != null) {
        await chatProvider.updateMessage(
          chatProvider.editingMessage!.id,
          message,
        );
        _messageController.clear();
        chatProvider.clearEdit();
      } else {
        await chatProvider.sendMessage(message);
        _messageController.clear();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: ${e.toString()}')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
