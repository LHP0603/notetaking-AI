import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../widgets/folder_card.dart';
import '../widgets/transcript_card.dart';

class TranscriptListScreen extends StatefulWidget {
  const TranscriptListScreen({super.key});

  @override
  State<TranscriptListScreen> createState() => _TranscriptListScreenState();
}

class _TranscriptListScreenState extends State<TranscriptListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock data for folders
  final List<Map<String, dynamic>> _folders = [
    {'name': 'Project Meetings', 'fileCount': 12, 'icon': Icons.folder},
    {'name': 'User Research', 'fileCount': 8, 'icon': Icons.folder},
    {'name': 'Personal Notes', 'fileCount': 5, 'icon': Icons.folder},
  ];

  // Mock data for recent transcripts
  final List<Map<String, dynamic>> _recentTranscripts = [
    {
      'title': 'Meeting with Design Team',
      'date': 'October 26, 2023',
      'time': '2:45 PM',
    },
    {
      'title': 'Brainstorming session about Q4...',
      'date': 'October 25, 2023',
      'time': '10:15 AM',
    },
    {
      'title': 'User Interview Insights',
      'date': 'October 24, 2023',
      'time': '3:30 PM',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // void _onBackPressed() {
  //   context.pop();
  // }

  void _onNewFolderPressed() {
    context.push(AppRoutes.addFolder);
  }

  void _onAddFolderPressed() {
    context.push(AppRoutes.addFolder);
  }

  void _onFolderTapped(Map<String, dynamic> folder) {
    // TODO: Navigate to folder contents
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Open folder: ${folder['name']}')));
  }

  void _onTranscriptTapped(Map<String, dynamic> transcript) {
    // TODO: Navigate to transcript detail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open transcript: ${transcript['title']}')),
    );
  }

  void _onLogoutPressed() {
    // TODO: Implement logout
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logout pressed')));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
                'Past Transcripts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? screenWidth * 0.1 : 16.0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildFoldersSection(),
                  const SizedBox(height: 24),
                  _buildRecentTranscriptsSection(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF282E39),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search transcripts...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFoldersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
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
            GestureDetector(
              onTap: _onNewFolderPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF282E39),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    const Text(
                      'New Folder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Folders grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: _folders.length + 1, // +1 for "Add Folder" card
          itemBuilder: (context, index) {
            if (index < _folders.length) {
              return _buildFolderCard(_folders[index]);
            } else {
              return _buildAddFolderCard();
            }
          },
        ),
      ],
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    return FolderCard(
      name: folder['name'],
      fileCount: folder['fileCount'],
      onTap: () => _onFolderTapped(folder),
    );
  }

  Widget _buildAddFolderCard() {
    return AddFolderCard(onTap: _onAddFolderPressed);
  }

  Widget _buildRecentTranscriptsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transcripts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentTranscripts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildTranscriptCard(_recentTranscripts[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTranscriptCard(Map<String, dynamic> transcript) {
    return TranscriptCard(
      title: transcript['title'],
      date: transcript['date'],
      time: transcript['time'],
      onTap: () => _onTranscriptTapped(transcript),
    );
  }

  // void _onProfilePressed() {
  //   context.push(AppRoutes.profile);
  // }

  // Widget _buildUserProfileBar() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF101822),
  //       border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
  //     ),
  //     child: Row(
  //       children: [
  //         // Avatar - tappable to go to profile
  //         GestureDetector(
  //           onTap: _onProfilePressed,
  //           child: Container(
  //             width: 48,
  //             height: 48,
  //             decoration: const BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: Color(0xFFE8D5B7),
  //             ),
  //             child: ClipOval(
  //               child: Icon(Icons.person, color: Colors.brown[400], size: 32),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         // User info - also tappable to go to profile
  //         Expanded(
  //           child: GestureDetector(
  //             onTap: _onProfilePressed,
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Text(
  //                   'John Doe',
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 Text(
  //                   'Premium',
  //                   style: TextStyle(color: Colors.grey[500], fontSize: 13),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         // Logout button
  //         GestureDetector(
  //           onTap: _onLogoutPressed,
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //             decoration: BoxDecoration(
  //               color: const Color(0xFF282E39),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: const Text(
  //               'Logout',
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
