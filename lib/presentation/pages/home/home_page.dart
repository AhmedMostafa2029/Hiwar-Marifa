import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/data/models/groups_model.dart';
import 'package:hiwar_marifa/presentation/pages/chat/chat_page.dart';
import 'package:hiwar_marifa/presentation/pages/home/notifications_page.dart';
import 'package:hiwar_marifa/presentation/pages/home/profile_page.dart';
import 'package:hiwar_marifa/presentation/pages/home/settings_page.dart';
import 'package:hiwar_marifa/presentation/widgets/home/build_home.dart';
import 'package:hiwar_marifa/presentation/widgets/home/dialog_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static String id = "HomePage";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    _pages = [
      BuildHomeWidgets.buildGroupsList(
        currentUserEmail,
        _searchQuery,
        _isDarkMode,
        _searchController,
        (query) => setState(() => _searchQuery = query),
        (group) => _navigateToChatPage(group),
      ),
      SettingsPage(
        onThemeChanged: (value) {
          _saveThemePreference(value);
          setState(() {
            _isDarkMode = value;
          });
        },
        initialDarkMode: _isDarkMode,
      ),
      ProfilePage(
        onThemeChanged: (value) {
          _saveThemePreference(value);
          setState(() {
            _isDarkMode = value;
          });
        },
      ),
      const NotificationsPage(),
    ];
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final isAdmin = adminEmails.contains(currentUserEmail);

    return MaterialApp(
      theme: BuildHomeWidgets.buildThemeData(_isDarkMode),
      home: Scaffold(
        appBar: _selectedIndex == 0
            ? BuildHomeWidgets.buildHomeAppBar(
                isAdmin,
                context,
                () => _showAddGroupDialog(context),
                () => _showDeleteGroupDialog(context),
                () => _showSearchGroupDialog(context),
              )
            : _selectedIndex == 2
            ? AppBar(
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: kPrimaryColor,
              )
            : AppBar(
                title: Text(
                  BuildHomeWidgets.getAppBarTitle(_selectedIndex),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: kPrimaryColor,
              ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BuildHomeWidgets.buildCustomBottomBar(
          _selectedIndex,
          (index) => setState(() => _selectedIndex = index),
        ),
        floatingActionButton: isAdmin && _selectedIndex == 0
            ? BuildHomeWidgets.buildFloatingActionButton(
                context,
                () => _showAddGroupDialog(context),
              )
            : null,
      ),
    );
  }

  Future<void> _navigateToChatPage(GroupsModel group) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    await _firestore.collection(kGroupsCollection).doc(group.id).update({
      'lastReadMessages.$currentUserEmail': FieldValue.serverTimestamp(),
    });

    final groupDoc = await _firestore
        .collection(kGroupsCollection)
        .where('groupname', isEqualTo: group.groupname)
        .get();

    if (groupDoc.docs.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            groupname: group.groupname,
            groupId: groupDoc.docs.first.id,
          ),
        ),
      ).then((_) {
        // عند العودة من صفحة الدردشة، نحدث الواجهة
        setState(() {});
      });
    }
  }

  void _showAddGroupDialog(BuildContext context) {
    GroupDialog.showAddGroupDialog(context);
  }

  void _showDeleteGroupDialog(BuildContext context) {
    GroupDialog.showDeleteGroupDialog(context);
  }

  void _showSearchGroupDialog(BuildContext context) {
    GroupDialog.showSearchGroupDialog(context);
  }
}
