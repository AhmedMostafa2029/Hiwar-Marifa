import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/data/models/groups_model.dart';
import 'package:hiwar_marifa/presentation/widgets/home/custim_group.dart';

class BuildHomeWidgets {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static AppBar buildHomeAppBar(
    bool isAdmin,
    BuildContext context,
    VoidCallback onAddGroup,
    VoidCallback onDeleteGroup,
    VoidCallback onSearch,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(kLogo, height: 50),
          const Text(
            '  Hiwar Marifa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pacifico',
            ),
          ),
        ],
      ),
      backgroundColor: kPrimaryColor,
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: onAddGroup,
          ),
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDeleteGroup,
          ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: onSearch,
        ),
      ],
    );
  }

  static Widget buildCustomBottomBar(int selectedIndex, Function(int) onTap) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: kPrimaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomBarItemWithElevation(
            Icons.home,
            'Home',
            0,
            selectedIndex,
            onTap,
          ),
          _buildBottomBarItemWithElevation(
            Icons.settings,
            'Settings',
            1,
            selectedIndex,
            onTap,
          ),
          _buildBottomBarItemWithElevation(
            Icons.person,
            'Profile',
            2,
            selectedIndex,
            onTap,
          ),
          _buildBottomBarItemWithElevation(
            Icons.notifications,
            'Notifications',
            3,
            selectedIndex,
            onTap,
          ),
        ],
      ),
    );
  }

  // 2. دالة بناء عنصر في شريط التنقل السفلي
  static Widget _buildBottomBarItemWithElevation(
    IconData icon,
    String label,
    int index,
    int selectedIndex,
    Function(int) onTap,
  ) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? kBackgroundColor : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: kBackgroundColor.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ]
                  : null,
            ),
            transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
            child: Icon(
              icon,
              color: isSelected ? kPrimaryColor : Colors.grey[620],
              size: 24,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? kBackgroundColor : Colors.grey[620],
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // 3. دالة بناء زر الفعل العائم
  static FloatingActionButton buildFloatingActionButton(
    BuildContext context,
    VoidCallback onPressed,
  ) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: kPrimaryColor,
      child: const Icon(Icons.add, color: Colors.white, size: 30),
    );
  }

  // 4. دالة بناء سمة التطبيق
  static ThemeData buildThemeData(bool isDarkMode) {
    return isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: kPrimaryColor,
            scaffoldBackgroundColor: Colors.grey[850],
          )
        : ThemeData.light().copyWith(
            primaryColor: kPrimaryColor,
            scaffoldBackgroundColor: Colors.grey[200],
          );
  }

  // 5. دالة بناء قائمة المجموعات
  static Widget buildGroupsList(
    String currentUserEmail,
    String searchQuery,
    bool isDarkMode,
    TextEditingController searchController,
    Function(String) onSearchChanged,
    Function(GroupsModel) onGroupTap,
  ) {
    return Column(
      children: [
        if (searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Search results for: "$searchQuery"',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    onSearchChanged('');
                    searchController.clear();
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(kGroupsCollection)
                .where('members', arrayContains: currentUserEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading groups',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                  ),
                );
              }

              final groups = snapshot.data!.docs
                  .map(
                    (doc) => GroupsModel.fromJson({
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id,
                    }),
                  )
                  .toList();

              final filteredGroups = searchQuery.isEmpty
                  ? groups
                  : groups
                        .where(
                          (group) => group.groupname.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();

              if (filteredGroups.isEmpty) {
                return _buildEmptyState(searchQuery);
              }

              return FutureBuilder(
                future: Future.wait(
                  filteredGroups.map((group) async {
                    final unreadCount = await _getUnreadCount(
                      group.id,
                      currentUserEmail,
                    );
                    return {'group': group, 'unreadCount': unreadCount};
                  }),
                ),
                builder: (context, asyncSnapshot) {
                  if (!asyncSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final groupsWithUnread = asyncSnapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: groupsWithUnread.length,
                    itemExtent: 80,
                    itemBuilder: (context, index) {
                      final item = groupsWithUnread[index];
                      final group = item['group'] as GroupsModel;
                      final unreadCount = item['unreadCount'] as int;

                      return CustomGroup(
                        model: group,
                        ontap: () => onGroupTap(group),
                        unreadCount: unreadCount,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 6. دالة مساعدة لبناء الحالة الفارغة
  static Widget _buildEmptyState(String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No groups yet'
                : 'No groups found for "$searchQuery"',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Create a new group to get started!'
                : 'Try a different search term',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 7. دالة مساعدة للحصول على عدد الرسائل غير المقروءة
  static Future<int> _getUnreadCount(String groupId, String userEmail) async {
    try {
      final groupDoc = await _firestore
          .collection(kGroupsCollection)
          .doc(groupId)
          .get();
      if (!groupDoc.exists) return 0;

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final lastReadMessages = Map<String, dynamic>.from(
        groupData['lastReadMessages'] ?? {},
      );
      final lastReadTime = lastReadMessages[userEmail] != null
          ? (lastReadMessages[userEmail] as Timestamp).toDate()
          : DateTime(0); // تاريخ قديم جداً إذا لم يكن موجود

      // جلب عدد الرسائل بعد آخر وقت قراءة
      final messagesQuery = await _firestore
          .collection(kMessagesCollection)
          .where('groupId', isEqualTo: groupId)
          .where('createdAt', isGreaterThan: lastReadTime)
          .get();

      return messagesQuery.size;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // 8. دالة الحصول على عنوان شريط التطبيق
  static String getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Hiwar Marifa';
      case 1:
        return 'Settings';
      case 2:
        return 'Profile';
      case 3:
        return 'Notifications';
      default:
        return '';
    }
  }
}
