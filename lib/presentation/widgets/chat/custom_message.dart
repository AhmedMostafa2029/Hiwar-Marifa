import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/data/models/messages_model.dart';
import 'package:hiwar_marifa/provider/chat_provider.dart';
import 'package:provider/provider.dart';

class CustomMessage extends StatelessWidget {
  final Message message;
  final String currentUserEmail;
  final String useName;

  const CustomMessage({
    Key? key,
    required this.message,
    required this.currentUserEmail,
    required this.useName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final isAdmin = adminEmails.contains(currentUserEmail);

    if (message.isDeleted) {
      return _buildDeletedMessage();
    }

    if (message.messageType == 'notification') {
      return _buildNotificationMessage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: message.userEmail == currentUserEmail
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (message.repliedToMessageId != null) _buildReplyPreview(context),

          // ====================================================================
          if (message.userEmail != currentUserEmail && isAdmin)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.senderName,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          //========================================================================
          GestureDetector(
            onLongPress: () => _showMessageOptions(context, chatProvider),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.userEmail == currentUserEmail
                    ? kPrimaryColor
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  _buildMessageFooter(context),
                ],
              ),
            ),
          ),
          _buildReactionsBar(context),
        ],
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text(
            'Message deleted',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.message,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: kPrimaryColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replying to ${message.repliedToSender}',
            style: TextStyle(
              color: kPrimaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            message.repliedToContent ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt.toDate()),
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
        ),
        if (message.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'edited',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReactionsBar(BuildContext context) {
    if (message.reactions.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions.entries.map((entry) {
          return GestureDetector(
            onTap: () => _showReactingUsers(context, entry.key, entry.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getReactionEmoji(entry.key),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    entry.value.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getReactionEmoji(String reactionType) {
    switch (reactionType) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'haha':
        return '😂';
      case 'wow':
        return '😁';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return '👍';
    }
  }

  void _showMessageOptions(BuildContext context, ChatProvider chatProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  chatProvider.setReplyingToMessage(message);
                },
              ),
              if (message.userEmail == currentUserEmail && message.canBeEdited)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context);
                    chatProvider.setEditingMessage(message);
                    _showEditDialog(context, chatProvider);
                  },
                ),
              if (message.canDelete(currentUserEmail))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(context, chatProvider);
                  },
                ),
              _buildReactionOptions(context, chatProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReactionOptions(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    final reactions = ['like', 'love', 'haha', 'wow', 'sad', 'angry'];
    final currentReaction = message.getUserReaction(currentUserEmail);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((reaction) {
          return IconButton(
            icon: Text(
              _getReactionEmoji(reaction),
              style: TextStyle(
                fontSize: 24,
                color: currentReaction == reaction ? kPrimaryColor : null,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              chatProvider.toggleReaction(message.id, reaction);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ChatProvider chatProvider) {
    final textController = TextEditingController(text: message.message);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Edit your message...',
                ),
              ),
              if (message.editExpiryTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Time remaining: ${_getTimeRemaining(message.editExpiryTime!)}',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  chatProvider.updateMessage(message.id, textController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _getTimeRemaining(DateTime expiryTime) {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);

    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ${difference.inSeconds.remainder(60)}s';
    } else {
      return '${difference.inSeconds}s';
    }
  }

  void _confirmDeleteMessage(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                chatProvider.deleteMessage(message.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showReactingUsers(
    BuildContext context,
    String reactionType,
    List<String> usernames,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(_getReactionEmoji(reactionType)),
              const SizedBox(width: 8),
              Text('${usernames.length} reactions'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: usernames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(usernames[index]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
