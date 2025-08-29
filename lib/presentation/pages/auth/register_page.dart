import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/core/helper/show_snackbar.dart';
import 'package:hiwar_marifa/presentation/pages/auth/email_verification_page.dart';
import 'package:hiwar_marifa/presentation/pages/auth/login_page.dart';
import 'package:hiwar_marifa/presentation/widgets/auth/custom_button.dart';
import 'package:hiwar_marifa/presentation/widgets/auth/custom_text_feild.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const String id = 'RegisterPage';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  List<String> _selectedTracks = [];
  List<String> _selectedSpecializations = [];
  String _userType = 'user';

  final List<String> _tracks = [
    'Web Development',
    'Mobile Development',
    'Software Engineering',
  ];
  final Map<String, List<String>> _specializations = {
    'Web Development': [
      'Frontend Development',
      'Backend Development',
      'Full Stack Development',
    ],
    'Mobile Development': ['Flutter Development', 'Native app development'],
    'Software Engineering': [
      'Native app development',
      'Full Stack Development',
      'Backend Development',
      'Frontend Development',
      'Flutter Development',
      'Data Engineering',
      'Data Science',
      'Data Analysis',
      'Machine Learning',
      'UI/UX Design',
      'Game Development',
      'Cloud Computing',
      'Blockchain Development',
      'Cybersecurity',
      'Artificial Intelligence',
      'DevOps Engineering',
      'Network Administration',
      'Robotics',
      'Software Testing',
    ],
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 14),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildRegisterForm(),
                  const SizedBox(height: 12),
                  _buildLoginLink(),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: kBackgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(kLogo),
        ),
        const SizedBox(height: 24),
        const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join our academic community',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Register new account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          CustomFormTextFeild(
            hintText: 'Username',
            controller: _usernameController,
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your username';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomFormTextFeild(
            hintText: 'Email',
            controller: _emailController,
            prefixIcon: Icons.email,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }

              if (!_isAcademicEmail(value)) {
                return 'Please use an academic email (.edu.eg or university domain)';
              }

              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildUserTypeSelector(),
          const SizedBox(height: 16),
          _buildTracksMultiSelect(),
          const SizedBox(height: 16),
          _buildSpecializationsMultiSelect(),
          const SizedBox(height: 16),
          CustomFormTextFeild(
            hintText: 'Password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade400,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomFormTextFeild(
            hintText: 'Confirm Password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.grey.shade400,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create Account',
            ontap: _handleRegistration,
            backgroundColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Type',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text(
                  'User',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                leading: Radio<String>(
                  value: 'user',
                  groupValue: _userType,
                  onChanged: (String? value) {
                    setState(() {
                      _userType = value ?? 'user';
                    });
                  },
                  activeColor: kPrimaryColor,
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text(
                  'Admin',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                leading: Radio<String>(
                  value: 'admin',
                  groupValue: _userType,
                  onChanged: (String? value) {
                    setState(() {
                      final email = _emailController.text.trim();
                      if (adminEmails.contains(email)) {
                        _userType = value ?? 'user';
                      } else {
                        ShowSnackBar.show(
                          context,
                          'Only authorized emails can register as admin',
                          Colors.orange,
                        );
                      }
                    });
                  },
                  activeColor: kPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTracksMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracks (Max 1)',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tracks.map((track) {
            final isSelected = _selectedTracks.contains(track);
            return FilterChip(
              label: Text(track),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedTracks.isEmpty) {
                      _selectedTracks.add(track);
                    } else {
                      ShowSnackBar.show(
                        context,
                        'You can select up to 1 tracks only',
                        Colors.orange,
                      );
                    }
                  } else {
                    _selectedTracks.remove(track);
                    _selectedSpecializations.removeWhere(
                      (spec) =>
                          _specializations[track]?.contains(spec) ?? false,
                    );
                  }
                });
              },
              selectedColor: kPrimaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
              backgroundColor: kSurfaceColor.withOpacity(0.8),
            );
          }).toList(),
        ),
        if (_selectedTracks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selected: ${_selectedTracks.join(", ")}',
              style: TextStyle(color: Colors.green.shade300, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecializationsMultiSelect() {
    final availableSpecializations =
        _selectedTracks
            .expand((track) => _specializations[track] ?? [])
            .toSet()
            .toList()
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specializations (Max 5)',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
        const SizedBox(height: 8),
        availableSpecializations.isEmpty
            ? Text(
                'Please select tracks first',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSpecializations.map((specialization) {
                  final isSelected = _selectedSpecializations.contains(
                    specialization,
                  );
                  return FilterChip(
                    label: Text(specialization),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedSpecializations.length < 5) {
                            _selectedSpecializations.add(specialization);
                          } else {
                            ShowSnackBar.show(
                              context,
                              'You can select up to 5 specializations only',
                              Colors.orange,
                            );
                          }
                        } else {
                          _selectedSpecializations.remove(specialization);
                        }
                      });
                    },
                    selectedColor: kPrimaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                    ),
                    backgroundColor: kSurfaceColor.withOpacity(0.8),
                  );
                }).toList(),
              ),
        if (_selectedSpecializations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selected: ${_selectedSpecializations.join(", ")}',
              style: TextStyle(color: Colors.green.shade300, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, LoginPage.id);
          },
          child: Text(
            'Login',
            style: TextStyle(
              color: kPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  bool _isAcademicEmail(String email) {
    final academicDomains = [
      'edu.eg',
      'edu',
      'ac.eg',
      'university.edu',
      'college.edu',
      'sch.eg',
      'k12.eg',
    ];

    final universityDomains = [
      'cairo.edu.eg',
      'auc.edu.eg',
      'aucegypt.edu',
      'aast.edu',
      'alexu.edu.eg',
      'helwan.edu.eg',
      'mans.edu.eg',
      'su.edu.eg',
    ];

    final domain = email.toLowerCase().split('@').last;

    for (var academicDomain in academicDomains) {
      if (domain.endsWith(academicDomain)) {
        return true;
      }
    }

    for (var universityDomain in universityDomains) {
      if (domain == universityDomain || domain.endsWith('.$universityDomain')) {
        return true;
      }
    }

    return false;
  }

  Future<void> _createSpecializationGroupsIfNeeded() async {
    try {
      for (var specialization in _selectedSpecializations) {
        final existingGroup = await FirebaseFirestore.instance
            .collection(kGroupsCollection)
            .where('groupname', isEqualTo: specialization)
            .get();
        if (existingGroup.docs.isEmpty) {
          await FirebaseFirestore.instance.collection(kGroupsCollection).add({
            'groupname': specialization,
            'specialization': specialization,
            'members': [_emailController.text.trim()],
            'pendingMembers': [],
            'createdAt': FieldValue.serverTimestamp(),
            'lastReadMessages': {},
          });
          debugPrint('Created new group for specialization: $specialization');
        }
      }
    } catch (e) {
      debugPrint('Error creating specialization groups: $e');
    }
  }

  Future<void> _addUserToSpecializationGroups(String userEmail) async {
    try {
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection(kGroupsCollection)
          .get();
      for (var groupDoc in groupsSnapshot.docs) {
        final groupData = groupDoc.data() as Map<String, dynamic>;
        final groupName = groupData['groupname'] ?? '';
        final groupSpecialization = groupData['specialization'] ?? '';

        if (groupSpecialization.isNotEmpty &&
            _selectedSpecializations.contains(groupSpecialization)) {
          await FirebaseFirestore.instance
              .collection(kGroupsCollection)
              .doc(groupDoc.id)
              .update({
                'members': FieldValue.arrayUnion([userEmail]),
              });
          debugPrint(
            'User $userEmail added to group: $groupName ($groupSpecialization)',
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding user to specialization groups: $e');
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userType == 'admin' &&
        !adminEmails.contains(_emailController.text.trim())) {
      ShowSnackBar.show(
        context,
        'You are not authorized to register as admin',
        Colors.red,
      );
      return;
    }

    if (_selectedTracks.isEmpty) {
      ShowSnackBar.show(
        context,
        'Please select at least one track',
        Colors.red,
      );
      return;
    }

    if (_selectedSpecializations.isEmpty) {
      ShowSnackBar.show(
        context,
        'Please select at least one specialization',
        Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await userCredential.user!.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection(kUsersCollection)
          .doc(userCredential.user?.uid)
          .set({
            'email': _emailController.text.trim(),
            'username': _usernameController.text.trim(),
            'tracks': _selectedTracks,
            'specializations': _selectedSpecializations,
            'userType': _userType,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'isAcademic': true,
            'emailVerified': false,
          }, SetOptions(merge: true));

      final userEmail = _emailController.text.trim();
      await _createSpecializationGroupsIfNeeded();
      await _addUserToSpecializationGroups(userEmail);
      if (!mounted) return;

      ShowSnackBar.show(
        context,
        'Registration successful! Verification email sent.',
        Colors.green,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationPage(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email is already in use';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }

      ShowSnackBar.show(context, errorMessage, Colors.red);
    } catch (e) {
      if (!mounted) return;
      ShowSnackBar.show(context, 'An unexpected error occurred', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
