import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/presentation/pages/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  const ProfilePage({super.key, required this.onThemeChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();
  bool _isEditingUsername = false;
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore
          .collection(kUsersCollection)
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _currentUsername =
              userDoc.data()?['username'] ?? user.email!.split('@')[0];
          _usernameController.text = _currentUsername;
        });
      } else {
        setState(() {
          _currentUsername = user.email!.split('@')[0];
          _usernameController.text = _currentUsername;
        });
      }
    }
  }

  Future<void> _updateUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _usernameController.text.isNotEmpty) {
      await _firestore.collection(kUsersCollection).doc(user.uid).set({
        'username': _usernameController.text,
        'email': user.email,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _currentUsername = _usernameController.text;
        _isEditingUsername = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildUsernameSection(),
            const SizedBox(height: 24),
            _buildGroupsStatsSection(),
            const SizedBox(height: 24),
            _buildPendingRequestsSection(),
            const SizedBox(height: 16),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUsername.isNotEmpty ? _currentUsername : 'Username is user',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? 'unavailable',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isEditingUsername
                ? TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _updateUsername,
                      ),
                    ),
                  )
                : ListTile(
                    leading: const Icon(Icons.person, color: kAccentColor),
                    title: const Text('Username'),
                    subtitle: Text(_currentUsername),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: kAccentColor),
                      onPressed: () {
                        setState(() {
                          _isEditingUsername = true;
                        });
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsStatsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _getGroupsStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  );
                }

                final joinedCount = snapshot.data?['joined'] ?? 0;
                final pendingCount = snapshot.data?['pending'] ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Joined groups', joinedCount, Icons.group),
                    _buildStatItem(
                      'Sent Join Requests',
                      pendingCount,
                      Icons.pending_actions,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kAccentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kAccentColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kAccentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPendingRequestsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending membership applications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<QuerySnapshot>(
              future: _getPendingRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Failed to load pending requests',
                    style: TextStyle(color: Colors.red.shade400),
                  );
                }

                final pendingGroups = snapshot.data?.docs ?? [];

                if (pendingGroups.isEmpty) {
                  return const Center(
                    child: Text(
                      'There are no pending join requests',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: pendingGroups.map((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final groupName =
                        data?['groupname']?.toString() ?? 'Unknown Group';
                    return ListTile(
                      leading: const Icon(Icons.group, color: Colors.orange),
                      title: Text(groupName),
                      subtitle: const Text('Pending approval'),
                      trailing: const Icon(Icons.pending, color: Colors.orange),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getGroupsStats() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    try {
      final joinedSnapshot = await _firestore
          .collection(kGroupsCollection)
          .where('members', arrayContains: currentUserEmail)
          .get();

      final pendingSnapshot = await _firestore
          .collection(kGroupsCollection)
          .where('pendingMembers', arrayContains: currentUserEmail)
          .get();

      return {
        'joined': joinedSnapshot.docs.length,
        'pending': pendingSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting groups stats: $e');
      return {'joined': 0, 'pending': 0};
    }
  }

  Future<QuerySnapshot> _getPendingRequests() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    return await _firestore
        .collection(kGroupsCollection)
        .where('pendingMembers', arrayContains: currentUserEmail)
        .get();
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, LoginPage.id);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 26, color: Colors.white),
            SizedBox(width: 20),
            const Text(
              "Logout",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
