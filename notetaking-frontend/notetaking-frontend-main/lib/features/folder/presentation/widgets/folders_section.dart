import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../summary/presentation/bloc/summary_bloc.dart';
import '../../../summary/presentation/bloc/summary_event.dart';
import '../../../folder/domain/entities/folder.dart';
import 'folder_card.dart';

class FoldersSection extends StatelessWidget {
  final List<Folder> folders;
  final Map<String, int> folderFileCounts;

  const FoldersSection({
    super.key,
    required this.folders,
    required this.folderFileCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Folders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToAddFolder(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '+ New Folder',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: folders.length + 1, // +1 for Add Folder card
          itemBuilder: (context, index) {
            if (index == folders.length) {
              // Add Folder card
              return AddFolderCard(onTap: () => _navigateToAddFolder(context));
            }

            final folder = folders[index];
            final fileCount = folderFileCounts[folder.folderId] ?? 0;

            return FolderCard(
              name: folder.name,
              fileCount: fileCount,
              onTap: () async {
                await context.push(
                  AppRoutes.folderDetail,
                  extra: {'id': folder.folderId, 'name': folder.name},
                );
                // When coming back, refresh the main list
                if (context.mounted) {
                  context.read<SummaryBloc>().add(
                    const LoadSummariesListEvent(forceRefresh: true),
                  );
                }
              },
              onMoreTap: () => _showFolderOptions(context, folder),
            );
          },
        ),
      ],
    );
  }

  void _showFolderOptions(BuildContext context, Folder folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text(
                    'Rename',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.push(
                      AppRoutes.editFolder,
                      extra: {'id': folder.folderId, 'name': folder.name},
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, folder);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Text(
              'Delete Folder?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "${folder.name}"? This action cannot be undone.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<SummaryBloc>().add(
                    DeleteFolderEvent(folder.folderId),
                  );
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _navigateToAddFolder(BuildContext context) async {
    final result = await context.push(AppRoutes.addFolder);
    if (result != null && context.mounted) {
      context.read<SummaryBloc>().add(
        const LoadSummariesListEvent(forceRefresh: true),
      );
    }
  }
}
