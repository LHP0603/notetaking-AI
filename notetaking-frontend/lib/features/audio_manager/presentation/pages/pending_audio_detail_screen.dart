import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/audio_file.dart';
import '../bloc/audio_manager_bloc.dart';
import '../bloc/audio_manager_event.dart';
import '../bloc/audio_manager_state.dart';
import '../bloc/pending_audio_type.dart';
import 'audio_detail_screen.dart';
import '../widgets/audio_file_list_item.dart';
import '../widgets/audio_player_dialog.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/search_filter_bar.dart';

class PendingAudioDetailScreen extends StatefulWidget {
  final PendingAudioType type;
  final String title;

  const PendingAudioDetailScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  State<PendingAudioDetailScreen> createState() =>
      _PendingAudioDetailScreenState();
}

class _PendingAudioDetailScreenState extends State<PendingAudioDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitial() {
    final query = _searchController.text.trim();
    context.read<AudioManagerBloc>().add(
          SearchPendingAudios(
            type: widget.type,
            searchQuery: query.isEmpty ? null : query,
            fromDate: _fromDate,
            toDate: _toDate,
          ),
        );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxScroll * 0.8) {
      context.read<AudioManagerBloc>().add(LoadMorePendingAudios(widget.type));
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      _loadInitial();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FilterDialog(
            initialFromDate: _fromDate,
            initialToDate: _toDate,
            onApply: (fromDate, toDate) {
              setState(() {
                _fromDate = fromDate;
                _toDate = toDate;
              });
              _loadInitial();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _fromDate != null || _toDate != null;

    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF101822),
        elevation: 0,
      ),
      body: Column(
        children: [
          SearchFilterBar(
            searchController: _searchController,
            hasActiveFilters: hasActiveFilters,
            onFilterPressed: _showFilterDialog,
            onSearchChanged: _onSearchChanged,
          ),
          Expanded(
            child: BlocBuilder<AudioManagerBloc, AudioManagerState>(
              builder: (context, state) {
                final isActiveType = state.pendingDetailType == widget.type;
                final audios =
                    isActiveType ? state.pendingDetailAudios : const <AudioFile>[];
                final isLoading =
                    isActiveType ? state.pendingDetailIsLoading : false;
                final isLoadingMore =
                    isActiveType ? state.pendingDetailIsLoadingMore : false;
                final hasMore =
                    isActiveType ? state.pendingDetailHasMore : false;
                final error = state.pendingErrorMessage;

                if (isLoading && audios.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  );
                }

                if (error != null && audios.isEmpty) {
                  return _buildErrorState(error);
                }

                if (audios.isEmpty) {
                  return const Center(
                    child: Text(
                      'No audios found',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadInitial(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: audios.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= audios.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: isLoadingMore
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF3B82F6),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      final audio = audios[index];
                      return AudioFileListItem(
                        audioFile: audio,
                        onTap: () => _showAudioPlayer(context, audio),
                        onChevronTap: () => _openDetail(context, audio),
                        showPendingStatus: true,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitial,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
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
}
