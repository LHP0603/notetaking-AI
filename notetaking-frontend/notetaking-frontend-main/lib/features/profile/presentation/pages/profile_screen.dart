import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/subscription_badge.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _onBackPressed(BuildContext context) {
    context.pop();
  }

  void _onDonePressed(BuildContext context) {
    context.pop();
  }

  void _onEditAvatarPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit avatar')));
  }

  void _onEditProfilePressed(BuildContext context) {
    context.push(AppRoutes.editProfile);
  }

  void _onManageSubscriptionPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Manage Subscription')));
  }

  void _onNotificationsPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notifications')));
  }

  void _onAppearancePressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Appearance')));
  }

  void _onHelpSupportPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Help & Support')));
  }

  void _onLogoutPressed(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF282E39),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Dispatch logout event to AuthBloc
                  context.read<AuthBloc>().add(const LogoutRequested());
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Navigate to landing page and clear stack when logout succeeds
          context.go(AppRoutes.landing);
        } else if (state is AuthError) {
          // Show error message if logout fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101822),
        body: SafeArea(
          child: Column(
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
                      onTap: () => _onBackPressed(context),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    // Title
                    const Expanded(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Done button
                    GestureDetector(
                      onTap: () => _onDonePressed(context),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProfileError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (state is ProfileLoaded ||
                        state is ProfileUpdating) {
                      // Use the profile from state
                      // For updating state, we still show the profile
                      final user =
                          (state is ProfileLoaded)
                              ? state.profile
                              : (state as ProfileUpdating).currentProfile;

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              screenWidth > 600 ? screenWidth * 0.1 : 24.0,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            // Avatar
                            ProfileAvatar(
                              imageUrl: user.avatarUrl,
                              size: 120,
                              onEditTap: () => _onEditAvatarPressed(context),
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Subscription badge
                            SubscriptionBadge(
                              label: user.subscriptionLabel,
                              isPremium: user.isPremium,
                            ),
                            const SizedBox(height: 32),
                            // Account Settings section
                            ProfileMenuSection(
                              title: 'Account Settings',
                              items: [
                                ProfileMenuItem(
                                  icon: Icons.person_outline,
                                  title: 'Edit Profile',
                                  onTap: () => _onEditProfilePressed(context),
                                ),
                                ProfileMenuItem(
                                  icon: Icons.credit_card_outlined,
                                  title: 'Manage Subscription',
                                  onTap:
                                      () =>
                                          _onManageSubscriptionPressed(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // App Preferences section
                            ProfileMenuSection(
                              title: 'App Preferences',
                              items: [
                                ProfileMenuItem(
                                  icon: Icons.notifications_outlined,
                                  title: 'Notifications',
                                  onTap: () => _onNotificationsPressed(context),
                                ),
                                ProfileMenuItem(
                                  icon: Icons.contrast,
                                  title: 'Appearance',
                                  onTap: () => _onAppearancePressed(context),
                                ),
                                ProfileMenuItem(
                                  icon: Icons.help_outline,
                                  title: 'Help & Support',
                                  onTap: () => _onHelpSupportPressed(context),
                                ),
                              ],
                            ),
                            // Admin Section (only for admins)
                            if (user.role == UserRole.admin) ...[
                              const SizedBox(height: 24),
                              ProfileMenuSection(
                                title: 'Administration',
                                items: [
                                  ProfileMenuItem(
                                    icon: Icons.admin_panel_settings,
                                    title: 'Admin Dashboard',
                                    onTap:
                                        () => context.push(
                                          AppRoutes.adminDashboard,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    }
                    return const SizedBox(); // Initial state or other
                  },
                ),
              ),
              // Logout button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 600 ? screenWidth * 0.1 : 24.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _onLogoutPressed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B2635),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Logout',
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
          ),
        ),
      ),
    );
  }
}
