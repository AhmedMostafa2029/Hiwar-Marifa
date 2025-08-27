import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool initialDarkMode;

  const SettingsPage({
    Key? key,
    required this.onThemeChanged,
    required this.initialDarkMode,
  }) : super(key: key);

  static String id = "SettingsPage";

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDarkMode;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
    _loadThemePreference();
  }

  // دالة لتحميل تفضيلات الوضع المظلم
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? widget.initialDarkMode;
    });
  }

  // دالة لإرسال الملاحظات
  Future<void> _sendFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    final feedback = _feedbackController.text.trim();

    if (feedback.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter your feedback')));
      return;
    }

    try {
      await _firestore.collection('feedback').add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new', // new, read, resolved
      });

      _feedbackController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Thank you for your feedback!')));

      // إغلاق الـ BottomSheet بعد الإرسال
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending feedback: ${e.toString()}')),
      );
    }
  }

  // دالة لعرض نافذة إدخال الملاحظات
  void _showFeedbackDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send Feedback',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feedbackController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Enter your feedback, suggestions, or issues...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _sendFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 8),
          _buildHeaderSection(),
          const SizedBox(height: 16),
          _buildThemeSwitch(),
          const SizedBox(height: 16),
          _buildAppInfoSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // // أضف هذه الدوال الجديدة
  // Widget _buildFeedbackSection() {
  //   return Card(
  //     elevation: 4,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Feedback & Rating',
  //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 12),
  //           ListTile(
  //             contentPadding: EdgeInsets.zero,
  //             leading: const Icon(Icons.star_rate, color: Colors.amber),
  //             title: const Text('Rate our App'),
  //             subtitle: const Text('Share your experience with us'),
  //             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  //             onTap: () {
  //               // يمكنك إضافة دالة لتقييم التطبيق هنا
  //             },
  //           ),
  //           ListTile(
  //             contentPadding: EdgeInsets.zero,
  //             leading: const Icon(Icons.feedback, color: Colors.green),
  //             title: const Text('Send Feedback'),
  //             subtitle: const Text('Tell us how we can improve'),
  //             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  //             onTap: _showFeedbackDialog,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildHeaderSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'uesing',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitch() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dark_mode, color: kPrimaryColor),
              title: const Text('Dark Mode'),
              subtitle: Text(
                _isDarkMode ? 'Enabled' : 'Disabled',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) async {
                  // حفظ التفضيل في الذاكرة المحلية
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isDarkMode', value);

                  setState(() => _isDarkMode = value);
                  widget.onThemeChanged(value);
                },
                activeColor: kPrimaryColor,
                activeTrackColor: kPrimaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.green.withOpacity(0.1)
                    : Colors.brown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isDarkMode ? Icons.check_circle : Icons.info,
                    color: _isDarkMode ? Colors.green : Colors.brown,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isDarkMode ? 'Dark Mode Enabled' : 'Dark Mode Disabled',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.green : Colors.brown,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.update, color: Colors.orange),
              title: const Text('Last updated'),
              subtitle: const Text('August 2025'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.feedback, color: Colors.green),
              title: const Text('Feedback & Suggestions'),
              subtitle: const Text('Share your thoughts with us'),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: _showFeedbackDialog,
              ),
              onTap: _showFeedbackDialog,
            ),
          ],
        ),
      ),
    );
  }
}
