import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/recording/presentation/pages/confirmation_screen.dart';
import '../../features/recording/presentation/pages/waiting_screen.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/landing/presentation/pages/landing_page.dart';
import '../../features/recording/presentation/pages/recording_page.dart';
import '../../features/folder/presentation/pages/summary_list_screen.dart';
import '../../features/folder/presentation/pages/add_folder_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/edit_profile_screen.dart';
import '../../features/test/presentation/pages/test_screen.dart';
import '../../features/transcription/presentation/pages/transcription_page.dart';
import '../../features/summary/presentation/pages/summary_page.dart';
import '../../features/summary/presentation/pages/summary_screen.dart';
import '../../features/folder/presentation/pages/folder_detail_screen.dart';
import '../../features/folder/presentation/pages/edit_folder_screen.dart';
import '../../features/summary/presentation/pages/trash_screen.dart';
import '../../features/admin/presentation/pages/admin_dashboard_screen.dart';
import '../../features/admin/presentation/pages/user_management_screen.dart';
import '../../features/admin/presentation/pages/tier_management_screen.dart';
import '../../features/admin/presentation/pages/audit_log_screen.dart';

class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String recording = '/recording';
  static const String transcriptList = '/transcript-list';
  static const String addFolder = '/add-folder';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String test = '/test';
  static const String transcriptionResult = '/transcription-result';
  static const String transcription = '/transcription';
  static const String summary = '/summary';
  static const String folderDetail = '/folder-detail';
  static const String editFolder = '/edit-folder';
  static const String trash = '/trash';
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminTiers = '/admin/tiers';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String confirmation = '/confirmation';
  static const String waiting = '/waiting';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.landing,
  routes: [
    GoRoute(
      path: AppRoutes.landing,
      name: 'landing',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.recording,
      name: 'recording',
      builder: (context, state) => const RecordingPage(),
    ),
    GoRoute(
      path: AppRoutes.transcriptList,
      name: 'transcriptList',
      builder: (context, state) => const SummaryListScreen(),
    ),
    GoRoute(
      path: AppRoutes.addFolder,
      name: 'addFolder',
      builder: (context, state) => const AddFolderScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      name: 'editProfile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.test,
      name: 'test',
      builder: (context, state) => const TestPage(),
    ),
    GoRoute(
      path: AppRoutes.transcription,
      name: 'transcription',
      builder: (context, state) {
        final meetingTitle = state.uri.queryParameters['title'];
        final transcriptId = state.uri.queryParameters['transcriptId'];
        final recordingId = state.uri.queryParameters['recordingId'];
        return TranscriptionPage(
          meetingTitle: meetingTitle,
          transcriptId: transcriptId,
          recordingId: recordingId,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.summary,
      name: 'summary',
      builder: (context, state) {
        final meetingTitle = state.uri.queryParameters['title'];
        final transcriptionId = state.uri.queryParameters['transcriptionId'];
        final recordingId = state.uri.queryParameters['recordingId'];

        // Use new SummaryScreen if recordingId is provided, otherwise use legacy SummaryPage
        if (recordingId != null) {
          return SummaryScreen(
            recordingId: recordingId,
            meetingTitle: meetingTitle,
          );
        } else {
          return SummaryPage(
            meetingTitle: meetingTitle,
            transcriptionId: transcriptionId,
          );
        }
      },
    ),
    GoRoute(
      path: AppRoutes.folderDetail,
      name: 'folderDetail',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        final folderId = extras['id'] as String;
        final folderName = extras['name'] as String;
        return FolderDetailScreen(folderId: folderId, folderName: folderName);
      },
    ),
    GoRoute(
      path: AppRoutes.editFolder,
      name: 'editFolder',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        final folderId = extras['id'] as String;
        final currentName = extras['name'] as String;
        return EditFolderScreen(folderId: folderId, currentName: currentName);
      },
    ),
    GoRoute(
      path: AppRoutes.trash,
      name: 'trash',
      builder: (context, state) => const TrashScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminDashboard,
      name: 'adminDashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminUsers,
      name: 'adminUsers',
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminTiers,
      name: 'adminTiers',
      builder: (context, state) => const TierManagementScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminAuditLogs,
      name: 'adminAuditLogs',
      builder: (context, state) => const AuditLogScreen(),
    ),
    GoRoute(
      path: AppRoutes.confirmation,
      name: 'confirmation',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        final file = extras['file'] as File;
        return ConfirmationScreen(file: file);
      },
    ),
    GoRoute(
      path: AppRoutes.waiting,
      name: 'waiting',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        final file = extras['file'] as File;
        return WaitingScreen(file: file);
      },
    ),
  ],
  errorBuilder:
      (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
);
