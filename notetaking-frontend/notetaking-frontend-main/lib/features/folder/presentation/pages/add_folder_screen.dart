import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/folder.dart';
import '../../domain/usecases/create_folder.dart';
import '../../domain/usecases/get_folders.dart';
import '../../../../injection_container/injection_container.dart' as di;

class AddFolderScreen extends StatefulWidget {
  const AddFolderScreen({super.key});

  @override
  State<AddFolderScreen> createState() => _AddFolderScreenState();
}

class _AddFolderScreenState extends State<AddFolderScreen> {
  final TextEditingController _folderNameController = TextEditingController();
  String? _selectedParentFolderId; // Store folderId instead of name
  List<Folder> _parentFolders = [];
  bool _isLoading = false;
  bool _isCreating = false;

  final CreateFolder _createFolder = di.sl<CreateFolder>();
  final GetFolders _getFolders = di.sl<GetFolders>();

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _getFolders();
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (!failure.message.contains('No folders')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load folders: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      (folders) {
        if (mounted) {
          setState(() {
            _parentFolders = folders;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    context.pop();
  }

  void _onCancelPressed() {
    context.pop();
  }

  Future<void> _onCreateFolderPressed() async {
    final folderName = _folderNameController.text.trim();
    if (folderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a folder name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent double-tap
    if (_isCreating) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final result = await _createFolder(
        name: folderName,
        parentFolderId: _selectedParentFolderId,
      );

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isCreating = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create folder: ${failure.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        (folder) {
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Folder "${folder.name}" created successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // Return folder ID to caller
            context.pop(folder.folderId);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showParentFolderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                  'Select Parent Folder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // None option
              ListTile(
                leading: Icon(
                  Icons.folder_off_outlined,
                  color: Colors.grey[500],
                ),
                title: Text(
                  'None (Root level)',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing:
                    _selectedParentFolderId == null
                        ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                        : null,
                onTap: () {
                  setState(() {
                    _selectedParentFolderId = null;
                  });
                  Navigator.pop(context);
                },
              ),
              // Folder options
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  ),
                )
              else
                ...(_parentFolders.map((folder) {
                  return ListTile(
                    leading: const Icon(Icons.folder, color: Color(0xFF3B82F6)),
                    title: Text(
                      folder.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing:
                        _selectedParentFolderId == folder.folderId
                            ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                            : null,
                    onTap: () {
                      setState(() {
                        _selectedParentFolderId = folder.folderId;
                      });
                      Navigator.pop(context);
                    },
                  );
                })),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
                      'Add New Folder',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Cancel button
                  GestureDetector(
                    onTap: _onCancelPressed,
                    child: const Text(
                      'Cancel',
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 600 ? screenWidth * 0.1 : 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Folder Name Label
                    const Text(
                      'Folder Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Folder Name Input
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF282E39),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _folderNameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Design Sprints',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.add_box_outlined,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Parent Folder Label
                    const Text(
                      'Parent Folder (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Parent Folder Dropdown
                    GestureDetector(
                      onTap: _showParentFolderPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282E39),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedParentFolderId != null
                                    ? _parentFolders
                                        .firstWhere(
                                          (folder) =>
                                              folder.folderId ==
                                              _selectedParentFolderId,
                                        )
                                        .name
                                    : 'Select a parent folder',
                                style: TextStyle(
                                  color:
                                      _selectedParentFolderId != null
                                          ? Colors.white
                                          : Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Create Folder Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? screenWidth * 0.1 : 24.0,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _onCreateFolderPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isCreating
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Create Folder',
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
    );
  }
}
