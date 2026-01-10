import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import '../bloc/profile_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/edit_profile_fields.dart';
import '../widgets/change_password_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      _nameController.text = state.profile.name;
      _emailController.text = state.profile.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    context.pop();
  }

  void _onEditAvatarPressed() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Change profile photo')));
  }

  void _onChangePasswordPressed() {
    showChangePasswordDialog(context);
  }

  void _onSaveChangesPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(
        UpdateProfileRequested(name: _nameController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) {
              if (_isLoading) {
                // Came back from updating
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              }
            } else if (state is ProfileUpdating) {
              setState(() => _isLoading = true);
            } else if (state is ProfileError) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: _onBackPressed,
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      // Title
                      const Expanded(
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Placeholder for symmetry
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth > 600 ? screenWidth * 0.1 : 24.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Avatar
                          Center(
                            child: ProfileAvatar(
                              size: 120,
                              onEditTap: _onEditAvatarPressed,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const SizedBox(height: 32),
                          // Full Name Label
                          const ProfileLabel('FULL NAME'),
                          const SizedBox(height: 8),
                          // Full Name Input
                          ProfileTextField(
                            controller: _nameController,
                            hintText: 'Enter your full name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Email Address Label
                          const ProfileLabel('EMAIL ADDRESS'),
                          const SizedBox(height: 8),
                          // Email Input - READ ONLY
                          ProfileTextField(
                            controller: _emailController,
                            hintText: 'Enter your email',
                            readOnly: true, 
                            keyboardType: TextInputType.emailAddress,
                            validator:
                                null, 
                          ),
                          const SizedBox(height: 24),
                          // Password Label
                          const ProfileLabel('PASSWORD'),
                          const SizedBox(height: 8),
                          ChangePasswordField(
                            onChangePressed: _onChangePasswordPressed,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                // Save Changes Button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? screenWidth * 0.1 : 24.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onSaveChangesPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFF3B82F6,
                        ).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}
