import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/subscription_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Mock user data - in real app, this would come from a bloc/provider
  UserProfile get _mockUser => const UserProfile(
    id: 'user_001',
    name: 'Duy Pham',
    email: 'duypham@email.com',
    subscriptionType: SubscriptionType.premium,
  );

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
                  Navigator.pop(context); // Close dialog
                  // Trigger logout event
                  context.read<AuthBloc>().add(LogoutRequested());
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
    final user = _mockUser;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Navigate to landing page and clear stack
          context.go(AppRoutes.landing);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101822),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF101822),
                elevation: 0,
                centerTitle: true,
                automaticallyImplyLeading: false,
                floating: true,
                snap: true,
                pinned: false,
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => _onLogoutPressed(context),
                    icon: const Icon(
                      Icons.logout,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 600 ? screenWidth * 0.1 : 24.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    ProfileAvatar(
                      imageUrl: user.avatarUrl,
                      size: 120,
                      onEditTap: () => _onEditAvatarPressed(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SubscriptionBadge(
                      label: user.subscriptionLabel,
                      isPremium: user.isPremium,
                    ),
                    const SizedBox(height: 32),
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
                          onTap: () => _onManageSubscriptionPressed(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
