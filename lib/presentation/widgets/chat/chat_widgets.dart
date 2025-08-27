import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';

AppBar buildChatAppBar({
  required BuildContext context,
  required String groupname,
  required String groupId,
  required bool isAdmin,
  required VoidCallback onSettingsPressed,
  required int pendingCount,
}) {
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
                groupname,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: groups.doc(groupId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
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
    actions: isAdmin
        ? [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: onSettingsPressed,
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
            ),
          ]
        : [],
  );
}
