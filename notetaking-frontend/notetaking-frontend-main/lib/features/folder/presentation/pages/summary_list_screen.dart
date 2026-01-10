import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../summary/presentation/bloc/summary_bloc.dart';
import '../../../summary/presentation/bloc/summary_event.dart';
import '../../../summary/presentation/bloc/summary_state.dart';

import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';

import '../widgets/empty_summary_state.dart';
import '../widgets/user_profile_bar.dart';
import '../widgets/summary_search_bar.dart';
import '../widgets/folders_section.dart';
import '../widgets/recent_transcripts_section.dart';

class SummaryListScreen extends StatefulWidget {
  const SummaryListScreen({super.key});

  @override
  State<SummaryListScreen> createState() => _SummaryListScreenState();
}

class _SummaryListScreenState extends State<SummaryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load summaries list, folders, and profile on init
    _loadSummaries();
    _loadFolders();
    _loadProfile();
  }

  void _loadProfile() {
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  void _loadSummaries() {
    context.read<SummaryBloc>().add(const LoadSummariesListEvent());
  }

  void _loadFolders() {
    context.read<SummaryBloc>().add(const LoadFoldersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    // Navigate back to recording page
    context.go(AppRoutes.recording);
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
                        'Past Transcripts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Placeholder for symmetry
                    // Trash button
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        // Navigate to Trash and wait for result (bool indicating if changes were made)
                        final hasChanges = await context.push<bool>(
                          AppRoutes.trash,
                        );
                        if (hasChanges == true && context.mounted) {
                          // Reload lists if changes occurred in trash
                          context.read<SummaryBloc>().add(
                            const LoadSummariesListEvent(forceRefresh: true),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: BlocBuilder<SummaryBloc, SummaryState>(
                  buildWhen: (previous, current) {
                    // Only rebuild for list-related states
                    // Ignore states related to detail view (SummaryLoading, SummaryLoaded, etc.)
                    return current is SummariesListLoading ||
                        current is SummariesListLoaded ||
                        current is FoldersLoading ||
                        current is FoldersLoaded ||
                        current is SummaryError;
                  },
                  builder: (context, state) {
                    if (state is SummariesListLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      );
                    }

                    if (state is SummariesListLoaded) {
                      // Smart Empty State Logic
                      final folders = state.folders;
                      final bool hasFolders = folders.isNotEmpty;
                      final bool hasSummaries = state.summaries.isNotEmpty;

                      // Only show full empty state if BOTH are empty
                      if (!hasFolders && !hasSummaries) {
                        return const EmptySummaryState();
                      }

                      final folderFileCounts = <String, int>{};

                      // Count recordings per folder
                      for (final folder in folders) {
                        final count =
                            state.recordingsMap.values
                                .where(
                                  (recording) =>
                                      recording.folderId == folder.folderId,
                                )
                                .length;
                        folderFileCounts[folder.folderId] = count;
                      }

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              screenWidth > 600 ? screenWidth * 0.1 : 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            // Search bar
                            SummarySearchBar(controller: _searchController),
                            const SizedBox(height: 24),
                            // Folders section
                            FoldersSection(
                              folders: folders,
                              folderFileCounts: folderFileCounts,
                            ),
                            const SizedBox(height: 32),
                            // Recent Transcripts section or Placeholder
                            if (hasSummaries)
                              RecentTranscriptsSection(
                                summaries: state.summaries,
                                recordingsMap: state.recordingsMap,
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C2128),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.notes_rounded,
                                      size: 48,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No transcripts yet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Record or upload a meeting to get started',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    }

                    if (state is SummaryError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                context.read<SummaryBloc>().add(
                                  const LoadSummariesListEvent(),
                                );
                                _loadFolders();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Loading for initial or other states
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    );
                  },
                ),
              ),
              // Bottom user profile bar
              const UserProfileBar(),
            ],
          ),
        ),
      ),
    );
  }
}
