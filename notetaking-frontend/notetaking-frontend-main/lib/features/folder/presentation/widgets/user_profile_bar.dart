import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';

class UserProfileBar extends StatelessWidget {
  const UserProfileBar({super.key});

  void _onProfilePressed(BuildContext context) {
    context.push(AppRoutes.profile);
  }

  void _onLogoutPressed(BuildContext context) {
    // Dispatch logout event to AuthBloc
    context.read<AuthBloc>().add(const LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        String name = 'Guest';
        String subscription = '';
        String? avatarUrl;

        if (state is ProfileLoaded) {
          name = state.profile.name;
          subscription = state.profile.subscriptionLabel;
          avatarUrl = state.profile.avatarUrl;
        } else if (state is ProfileLoading) {
          name = 'Loading...';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF101822),
            border: Border(
              top: BorderSide(color: Colors.grey[800]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _onProfilePressed(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8D5B7),
                  ),
                  child: ClipOval(
                    child:
                        avatarUrl != null
                            ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  color: Colors.brown[400],
                                  size: 32,
                                );
                              },
                            )
                            : Icon(
                              Icons.person,
                              color: Colors.brown[400],
                              size: 32,
                            ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User info
              Expanded(
                child: GestureDetector(
                  onTap: () => _onProfilePressed(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subscription.isNotEmpty)
                        Text(
                          subscription,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Logout button
              GestureDetector(
                onTap: () => _onLogoutPressed(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282E39),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
