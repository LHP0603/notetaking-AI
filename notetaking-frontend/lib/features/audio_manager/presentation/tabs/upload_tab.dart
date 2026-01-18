import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../recording/presentation/bloc/recording_bloc.dart';
import '../../../recording/presentation/bloc/recording_event.dart';
import '../../../recording/presentation/bloc/recording_state.dart';
import '../../domain/entities/audio_file.dart';
import '../bloc/audio_manager_bloc.dart';
import '../bloc/audio_manager_event.dart';
import '../bloc/audio_manager_state.dart';
import '../pages/audio_detail_screen.dart';
import '../widgets/audio_player_dialog.dart';
import '../widgets/audio_file_list_item.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/search_filter_bar.dart';

class UploadTab extends StatefulWidget {
  const UploadTab({super.key});

  @override
  State<UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<UploadTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUploadPressed() {
    context.read<RecordingBloc>().add(const ImportAudioRequested());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxScroll * 0.8) {
      final bloc = context.read<AudioManagerBloc>();
      final state = bloc.state;
      if (!state.isLoadingMore &&
          !state.isLoadingAudios &&
          state.hasMoreAudios) {
        bloc.add(const LoadMoreAudios());
      }
    }
  }

  void _openDetail(BuildContext context, AudioFile audioFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AudioDetailScreen(audioFile: audioFile),
      ),
    );
  }

  void _showAudioPlayer(BuildContext context, AudioFile audioFile) {
    final filePath = audioFile.filePath ?? '';
    if (filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file path is missing')),
      );
      return;
    }

    final audioUrl = '${AppConstants.baseUrl}/$filePath';

    showDialog(
      context: context,
      builder: (context) => AudioPlayerDialog(
        audioUrl: audioUrl,
        title: audioFile.filename,
      ),
    );
  }

  void _showFilterDialog(AudioManagerState state) {
    showDialog(
      context: context,
      builder:
          (context) => FilterDialog(
            initialFromDate: state.fromDate,
            initialToDate: state.toDate,
            onApply: (fromDate, toDate) {
              context.read<AudioManagerBloc>().add(
                ApplyFilter(fromDate: fromDate, toDate: toDate),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecordingBloc, RecordingState>(
      listener: (context, state) async {
        if (state is RecordingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AudioImported) {
          final validationError = await _validateAudioFile(state.audioFile);
          if (!mounted) {
            return;
          }
          if (validationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(validationError)),
            );
            return;
          }
          context.read<AudioManagerBloc>().add(UploadAudioFile(state.audioFile));
        }
      },
      child: BlocBuilder<AudioManagerBloc, AudioManagerState>(
        builder: (context, state) {
          final hasActiveFilters =
              state.fromDate != null || state.toDate != null;

          if (_searchController.text != state.searchQuery) {
            _searchController.text = state.searchQuery;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          }

          return Column(
            children: [
              SearchFilterBar(
                searchController: _searchController,
                hasActiveFilters: hasActiveFilters,
                onFilterPressed: () => _showFilterDialog(state),
                onSearchChanged: (query) {
                  context.read<AudioManagerBloc>().add(SearchAudios(query));
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<AudioManagerBloc>().add(
                      LoadUploadedAudios(
                        searchQuery: state.searchQuery,
                        fromDate: state.fromDate,
                        toDate: state.toDate,
                      ),
                    );
                  },
                  child: state.isLoadingAudios && state.audios.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF3B82F6),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount:
                              state.audios.length +
                              (state.hasMoreAudios ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.audios.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: state.isLoadingMore
                                      ? const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFF3B82F6),
                                          ),
                                        )
                                      : const Text(
                                          'Load more...',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                ),
                              );
                            }
                            final audio = state.audios[index];
                            return AudioFileListItem(
                              audioFile: audio,
                              onTap: () => _showAudioPlayer(context, audio),
                              onChevronTap: () => _openDetail(context, audio),
                            );
                          },
                        ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: state.isUploading ? null : _onUploadPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF3B82F6).withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.file_upload_outlined),
                      label: Text(
                        state.isUploading ? 'Uploading...' : 'Upload Audio File',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _validateAudioFile(File file) async {
    const maxSizeBytes = 50 * 1024 * 1024;
    final extension = file.path.split('.').last.toLowerCase();
    const allowedExtensions = [
      'mp3',
      'wav',
      'm4a',
      'aac',
      'flac',
      'ogg',
    ];

    if (!allowedExtensions.contains(extension)) {
      return 'Unsupported format. Use MP3, WAV, M4A, AAC, FLAC, or OGG.';
    }

    final length = await file.length();
    if (length > maxSizeBytes) {
      return 'File too large. Max size is 50MB.';
    }

    return null;
  }

}
