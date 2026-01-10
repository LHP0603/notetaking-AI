import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../folder/domain/entities/folder.dart';
import '../bloc/summary_bloc.dart';
import '../bloc/summary_event.dart';
import '../bloc/summary_state.dart';

class FolderPickerSheet extends StatelessWidget {
  final String recordingId;

  const FolderPickerSheet({super.key, required this.recordingId});

  static Future<void> show(BuildContext context, String recordingId) async {
    // Dispatch event to load folders
    context.read<SummaryBloc>().add(const LoadFoldersEvent());

    if (!context.mounted) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FolderPickerSheet(recordingId: recordingId),
    );

    if (result == 'CREATE_NEW_FOLDER' && context.mounted) {
      final folderId = await context.push(AppRoutes.addFolder);
      if (context.mounted && folderId is String) {
        // Folder was created, auto-select it
        context.read<SummaryBloc>().add(
          FolderCreatedEvent(folderId: folderId, recordingId: recordingId),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SummaryBloc, SummaryState>(
      builder: (context, state) {
        if (state is FoldersLoading) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            ),
          );
        }

        if (state is SummariesListLoaded) {
          return _buildFoldersList(context, state.folders);
        }

        if (state is FoldersLoaded) {
          return _buildFoldersList(context, state.folders);
        }

        if (state is SummaryError) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SummaryBloc>().add(const LoadFoldersEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return const SafeArea(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildFoldersList(BuildContext context, List<Folder> folders) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select Folder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Empty state or folder list
          if (folders.isEmpty)
            _buildEmptyFoldersState(context)
          else
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // None option (Root level)
                  ListTile(
                    leading: Icon(
                      Icons.folder_off_outlined,
                      color: Colors.grey[500],
                    ),
                    title: const Text(
                      'None (Root level)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<SummaryBloc>().add(
                        FolderChosenEvent(
                          recordingId: recordingId,
                          folderId: null,
                        ),
                      );
                    },
                  ),
                  // Folder options
                  ...folders.map((folder) {
                    return ListTile(
                      leading: const Icon(
                        Icons.folder,
                        color: Color(0xFF3B82F6),
                      ),
                      title: Text(
                        folder.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<SummaryBloc>().add(
                          FolderChosenEvent(
                            recordingId: recordingId,
                            folderId: folder.folderId,
                          ),
                        );
                      },
                    );
                  }),
                  // Create new folder option
                  ListTile(
                    leading: const Icon(
                      Icons.add_box_outlined,
                      color: Color(0xFF3B82F6),
                    ),
                    title: const Text(
                      'Create new folder',
                      style: const TextStyle(color: Color(0xFF3B82F6)),
                    ),
                    onTap: () {
                      Navigator.pop(context, 'CREATE_NEW_FOLDER');
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyFoldersState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey[500]),
          const SizedBox(height: 16),
          const Text(
            'No folders yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first folder to organize recordings',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, 'CREATE_NEW_FOLDER');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Create folder',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
