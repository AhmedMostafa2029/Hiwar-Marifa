import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static String id = "NotificationsPage";

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('isBroadcast', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;

              final recipientEmails = List<String>.from(
                data['recipientEmails'] ?? [],
              );
              final isRecipient = recipientEmails.contains(currentUserEmail);

              if (!isRecipient) {
                return const SizedBox.shrink();
              }

              final readBy = List<String>.from(data['readBy'] ?? []);
              final isRead = readBy.contains(currentUserEmail);

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteNotificationForUser(notification.id, currentUserEmail);
                },
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: isRead ? Colors.grey : kPrimaryColor,
                  ),
                  title: Text(
                    data['message'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: ${data['senderName']}'),
                      if (data['createdAt'] != null)
                        Text(
                          _formatDate(data['createdAt'].toDate()),
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: !isRead
                      ? IconButton(
                          icon: const Icon(Icons.mark_email_read),
                          onPressed: () =>
                              _markAsRead(notification.id, currentUserEmail),
                          tooltip: 'Mark as read',
                        )
                      : null,
                  onTap: () {
                    if (!isRead) {
                      _markAsRead(notification.id, currentUserEmail);
                    }
                    _showNotificationDetails(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message: ${data['message']}'),
            const SizedBox(height: 10),
            Text('Group: ${data['groupName']}'),
            const SizedBox(height: 10),
            Text('Sender: ${data['senderName']}'),
            const SizedBox(height: 10),
            if (data['createdAt'] != null)
              Text('Time: ${_formatDate(data['createdAt'].toDate())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(String notificationId, String userEmail) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({
          'readBy': FieldValue.arrayUnion([userEmail]),
        });
  }

  // Future<void> _markAllAsRead(String userEmail) async {
  //   final notifications = await FirebaseFirestore.instance
  //       .collection('notifications')
  //       .where('isBroadcast', isEqualTo: true)
  //       .where('recipientEmails', arrayContains: userEmail)
  //       .get();

  //   final batch = FirebaseFirestore.instance.batch();
  //   for (final doc in notifications.docs) {
  //     batch.update(doc.reference, {
  //       'readBy': FieldValue.arrayUnion([userEmail]),
  //     });
  //   }
  //   await batch.commit();
  // }

  Future<void> _deleteNotificationForUser(
    String notificationId,
    String userEmail,
  ) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({
          'recipientEmails': FieldValue.arrayRemove([userEmail]),
        });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
