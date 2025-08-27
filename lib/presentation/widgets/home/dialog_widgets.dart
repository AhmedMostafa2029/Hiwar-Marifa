import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/core/helper/show_snackbar.dart';
import 'package:hiwar_marifa/data/models/groups_model.dart';

class GroupDialog {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void showAddGroupDialog(BuildContext context) {
    final groupNameController = TextEditingController();
    final emailController = TextEditingController();
    final members = [FirebaseAuth.instance.currentUser!.email!];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: groupNameController,
                decoration: const InputDecoration(hintText: 'Group Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: 'Add Member Email'),
              ),
              TextButton(
                onPressed: () =>
                    _addGroupMember(emailController, members, context),
                child: const Text('Add Member'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  _createGroup(groupNameController, members, context),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _addGroupMember(
    TextEditingController emailController,
    List<String> members,
    BuildContext context,
  ) async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    try {
      final userDoc = await _firestore
          .collection(kUsersCollection)
          .doc(email)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      if (members.contains(email)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User already in group')));
        return;
      }

      members.add(email);
      emailController.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$email added to group')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  static Future<void> _createGroup(
    TextEditingController groupNameController,
    List<String> members,
    BuildContext context,
  ) async {
    final groupName = groupNameController.text.trim();
    if (groupName.isEmpty) return;

    try {
      final groupId = _firestore.collection(kGroupsCollection).doc().id;

      await _firestore.collection(kGroupsCollection).doc(groupId).set({
        'groupname': groupName,
        'id': groupId,
        'members': members,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context);
        ShowSnackBar.show(
          context,
          'Group "$groupName" created successfully',
          Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: ${e.toString()}')),
        );
      }
    }
  }

  static void showDeleteGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Group'),
          content: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(kGroupsCollection)
                .where(
                  'members',
                  arrayContains: FirebaseAuth.instance.currentUser!.email!,
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading groups'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final groups = snapshot.data!.docs
                  .map(
                    (doc) => GroupsModel.fromJson({
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id,
                    }),
                  )
                  .toList();

              if (groups.isEmpty) {
                return const Center(child: Text('No groups to delete'));
              }

              return SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(groups[index].groupname),
                      onTap: () => _deleteGroup(
                        snapshot.data!.docs[index].id,
                        groups[index].groupname,
                        context,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _deleteGroup(
    String groupId,
    String groupName,
    BuildContext context,
  ) async {
    try {
      await _firestore.collection(kGroupsCollection).doc(groupId).delete();

      if (context.mounted) {
        ShowSnackBar.show(
          context,
          'Group "$groupName" deleted successfully',
          Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ShowSnackBar.show(
          context,
          'Error deleting group: ${e.toString()}',
          Colors.red,
        );
      }
    }
  }

  static void showSearchGroupDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Search for groups'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter group name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Note: You can search for groups to join',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _joinGroup(searchController.text.trim(), context);
                  },
                  child: const Text('Join'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _joinGroup(String groupName, BuildContext context) async {
    if (groupName.isEmpty) return;

    try {
      final groupQuery = await _firestore
          .collection(kGroupsCollection)
          .where('groupname', isEqualTo: groupName)
          .get();

      if (groupQuery.docs.isEmpty) {
        throw Exception('Group not found');
      }

      final groupDoc = groupQuery.docs.first;
      final groupId = groupDoc.id;
      final groupData = groupDoc.data() as Map<String, dynamic>;
      final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

      final List<dynamic> members = groupData['members'] ?? [];
      if (members.contains(currentUserEmail)) {
        ShowSnackBar.show(
          context,
          'You are already a member of "$groupName"',
          Colors.blue,
        );
        return;
      }

      final List<dynamic> pendingMembers = groupData['pendingMembers'] ?? [];
      if (pendingMembers.contains(currentUserEmail)) {
        ShowSnackBar.show(
          context,
          'You already have a pending request to join "$groupName"',
          Colors.orange,
        );
        return;
      }

      if (!adminEmails.contains(currentUserEmail)) {
        await _firestore.collection(kGroupsCollection).doc(groupId).update({
          'pendingMembers': FieldValue.arrayUnion([currentUserEmail]),
        });

        ShowSnackBar.show(
          context,
          'Join request sent to "$groupName"',
          Colors.green,
        );
      } else {
        await _firestore.collection(kGroupsCollection).doc(groupId).update({
          'members': FieldValue.arrayUnion([currentUserEmail]),
        });

        ShowSnackBar.show(
          context,
          'You have joined "$groupName"',
          Colors.green,
        );
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ShowSnackBar.show(context, 'Error: ${e.toString()}', Colors.red);
      }
    }
  }
}
