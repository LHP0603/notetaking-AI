import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../summary/presentation/bloc/summary_bloc.dart';
import '../../../summary/presentation/bloc/summary_event.dart';
import '../../../summary/presentation/bloc/summary_state.dart';
import '../widgets/summary_search_bar.dart';
import '../widgets/recent_transcripts_section.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load summaries specific to this folder
    context.read<SummaryBloc>().add(
      LoadSummariesListEvent(
        folderId: widget.folderId,
        forceRefresh: true, // Force refresh to ensure we get filtered list
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Reload full list when going back 
                      context.read<SummaryBloc>().add(
                        const LoadSummariesListEvent(), 
                      );
                      context.pop();
                    },
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BlocBuilder<SummaryBloc, SummaryState>(
                      buildWhen:
                          (previous, current) => current is SummariesListLoaded,
                      builder: (context, state) {
                        String displayTitle = widget.folderName;
                        if (state is SummariesListLoaded) {
                          try {
                            final folder = state.folders.firstWhere(
                              (f) => f.folderId == widget.folderId,
                            );
                            displayTitle = folder.name;
                          } catch (_) {}
                        }
                        return Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      String currentName = widget.folderName;
                      final state = context.read<SummaryBloc>().state;
                      if (state is SummariesListLoaded) {
                        try {
                          final folder = state.folders.firstWhere(
                            (f) => f.folderId == widget.folderId,
                          );
                          currentName = folder.name;
                        } catch (_) {}
                      }

                      context.pushNamed(
                        'editFolder',
                        extra: {'id': widget.folderId, 'name': currentName},
                      );
                    },
                  ),
                ],
              ),
            ),
            // Search Bar (reused)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: SummarySearchBar(controller: _searchController),
            ),
            // Content
            Expanded(
              child: BlocBuilder<SummaryBloc, SummaryState>(
                builder: (context, state) {
                  if (state is SummariesListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SummaryError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (state is SummariesListLoaded) {
                    if (state.summaries.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recordings in this folder',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: RecentTranscriptsSection(
                          summaries: state.summaries,
                          recordingsMap: state.recordingsMap,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
