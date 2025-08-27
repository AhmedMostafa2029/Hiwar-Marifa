import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/data/models/groups_model.dart';

class GroupSettingsPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupSettingsPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  GroupsModel? _group;
  bool _isLoading = true;
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final groupDoc = await _firestore
          .collection(kGroupsCollection)
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        final groupData = groupDoc.data() as Map<String, dynamic>;
        setState(() {
          _group = GroupsModel.fromJson({...groupData, 'id': groupDoc.id});
        });

        await _loadUserNames(groupData);

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading group data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserNames(Map<String, dynamic> groupData) async {
    try {
      final allEmails = [
        ...List<String>.from(groupData['members'] ?? []),
        ...List<String>.from(groupData['pendingMembers'] ?? []),
      ];

      if (allEmails.isEmpty) return;

      final usersSnapshot = await _firestore
          .collection(kUsersCollection)
          .where('email', whereIn: allEmails)
          .get();

      final Map<String, String> userNames = {};
      for (final doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final email = userData['email'] as String?;
        final username = userData['username'] as String?;

        if (email != null && username != null) {
          userNames[email] = username;
        }
      }

      setState(() {
        _userNames = userNames;
      });
    } catch (e) {
      debugPrint('Error loading user names: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Group Settings'),
          backgroundColor: kPrimaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        backgroundColor: kPrimaryColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Info Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _group!.groupname,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  //--------------------------------------------------------------
                  const SizedBox(height: 8),
                  _buildInfoRow('Admin', adminEmails[0]),
                  const SizedBox(height: 8),
                  //-----------------------------------------------------------------
                  _buildInfoRow(
                    'Created',
                    _group!.createdAt != null
                        ? _group!.createdAt!.toDate().toString().split(' ')[0]
                        : "Unknown",
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Members', '${_group!.members.length} members'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Members Section
          Text(
            'Group Members (${_group!.members.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Members List
          _buildMembersList(),

          const SizedBox(height: 20),

          // Pending Requests
          if (_group!.pendingMembers.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Requests (${_group!.pendingMembers.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPendingRequestsList(),
              ],
            ),
          const SizedBox(height: 115),
          // Admin Controls
          _buildAdminControls(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMembersList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection(kGroupsCollection)
          .doc(widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> members = groupData['members'] ?? [];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final memberEmail = members[index];
            return _buildMemberTile(memberEmail);
          },
        );
      },
    );
  }

  Widget _buildMemberTile(String memberEmail) {
    final userName = _userNames[memberEmail] ?? memberEmail;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(memberEmail),
        trailing: adminEmails.contains(memberEmail)
            ? const Chip(
                label: Text('Admin'),
                backgroundColor: kPrimaryColor,
                labelStyle: TextStyle(color: Colors.white),
              )
            : IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removeMember(memberEmail),
              ),
      ),
    );
  }

  Widget _buildPendingRequestsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection(kGroupsCollection)
          .doc(widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> pendingMembers = groupData['pendingMembers'] ?? [];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingMembers.length,
          itemBuilder: (context, index) {
            final pendingEmail = pendingMembers[index];
            return _buildPendingRequestTile(pendingEmail);
          },
        );
      },
    );
  }

  Widget _buildPendingRequestTile(String pendingEmail) {
    final userName = _userNames[pendingEmail] ?? pendingEmail;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.orange[50],
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.person_add, color: Colors.white),
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(pendingEmail),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _approveMember(pendingEmail),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectMember(pendingEmail),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminControls() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Admin Controls',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Member', style: TextStyle(fontSize: 14)),
              onPressed: _showAddMemberDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40, // حجم أصغر للأزرار
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 18, color: Colors.white),
              label: const Text(
                'Delete Group',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              onPressed: _confirmDeleteGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.notifications, size: 18),
              label: const Text(
                'Send Notification',
                style: TextStyle(fontSize: 14),
              ),
              onPressed: _sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              hintText: 'Enter user email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  _addMember(email);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMember(String email) async {
    try {
      await _firestore.collection(kGroupsCollection).doc(widget.groupId).update(
        {
          'members': FieldValue.arrayUnion([email]),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$email added to group'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeMember(String email) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $email from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeMemberFromGroup(email);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMemberFromGroup(String email) async {
    try {
      await _firestore.collection(kGroupsCollection).doc(widget.groupId).update(
        {
          'members': FieldValue.arrayRemove([email]),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$email removed from group'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveMember(String email) async {
    try {
      await _firestore.collection(kGroupsCollection).doc(widget.groupId).update(
        {
          'pendingMembers': FieldValue.arrayRemove([email]),
          'members': FieldValue.arrayUnion([email]),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$email approved and added to group'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectMember(String email) async {
    try {
      await _firestore.collection(kGroupsCollection).doc(widget.groupId).update(
        {
          'pendingMembers': FieldValue.arrayRemove([email]),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request from $email rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteGroup();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    try {
      // Delete group
      await _firestore
          .collection(kGroupsCollection)
          .doc(widget.groupId)
          .delete();

      // Delete all messages in the group
      final messages = await _firestore
          .collection(kMessagesCollection)
          .where('groupId', isEqualTo: widget.groupId)
          .get();

      for (final doc in messages.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNotificationToGroup(String message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final groupDoc = await FirebaseFirestore.instance
          .collection(kGroupsCollection)
          .doc(_group!.id)
          .get();

      if (!groupDoc.exists) return;

      final data = groupDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(data['members'] ?? []);

      final notificationId =
          'group_${_group!.id}_${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'type': 'group_notification',
            'groupId': _group!.id,
            'groupName': _group!.groupname,
            'message': message,
            'senderEmail': user.email,
            'senderName': user.displayName ?? user.email!.split('@')[0],
            'recipientEmails': members
                .where((email) => email != user.email)
                .toList(),
            'createdAt': FieldValue.serverTimestamp(),
            'isBroadcast': true,
            'readBy': [],
          });

      // إضافة رسالة في الدردشة
      await FirebaseFirestore.instance.collection(kMessagesCollection).add({
        'message': '🔔 Notification: $message',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'groupId': _group!.id,
        'senderName': user.displayName ?? user.email!.split('@')[0],
        'userEmail': user.email,
        'messageType': 'notification',
        'reactions': {},
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendNotification() {
    showDialog(
      context: context,
      builder: (context) {
        final messageController = TextEditingController();

        return AlertDialog(
          title: const Text('Send Notification'),
          content: TextField(
            controller: messageController,
            decoration: const InputDecoration(
              labelText: 'Notification Message',
              border: OutlineInputBorder(),
              hintText: 'Enter your notification message',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final message = messageController.text.trim();
                if (message.isNotEmpty) {
                  _sendNotificationToGroup(message);
                  Navigator.pop(context);
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
