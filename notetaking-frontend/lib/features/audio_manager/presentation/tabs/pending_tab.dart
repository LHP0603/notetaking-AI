import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/audio_file.dart';
import '../bloc/audio_manager_bloc.dart';
import '../bloc/audio_manager_event.dart';
import '../bloc/audio_manager_state.dart';
import '../bloc/pending_audio_type.dart';
import '../pages/audio_detail_screen.dart';
import '../pages/pending_audio_detail_screen.dart';
import '../widgets/audio_file_list_item.dart';
import '../widgets/audio_player_dialog.dart';

class PendingTab extends StatefulWidget {
  const PendingTab({super.key});

  @override
  State<PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends State<PendingTab> {
  @override
  void initState() {
    super.initState();
    context.read<AudioManagerBloc>().add(const LoadPendingAudios());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioManagerBloc, AudioManagerState>(
      builder: (context, state) {
        final isEmpty =
            state.pendingUntranscribedAudios.isEmpty &&
            state.pendingUnsummarizedAudios.isEmpty;

        if (state.pendingErrorMessage != null && isEmpty) {
          return _buildErrorState(context, state.pendingErrorMessage!);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AudioManagerBloc>().add(const LoadPendingAudios());
          },
          child: state.isLoadingPendingAudios && isEmpty
              ? ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PendingSection(
                        title: 'Untranscribed Audios',
                        audios: state.pendingUntranscribedAudios,
                        totalCount: state.pendingUntranscribedCount,
                        type: PendingAudioType.untranscribed,
                        onSeeAll: _openSeeAll,
                        onTapAudio: _showAudioPlayer,
                        onChevronTap: _openDetail,
                      ),
                      const SizedBox(height: 24),
                      _PendingSection(
                        title: 'Unsummarized Audios',
                        audios: state.pendingUnsummarizedAudios,
                        totalCount: state.pendingUnsummarizedCount,
                        type: PendingAudioType.unsummarized,
                        onSeeAll: _openSeeAll,
                        onTapAudio: _showAudioPlayer,
                        onChevronTap: _openDetail,
                      ),
                      if (isEmpty && !state.isLoadingPendingAudios)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text(
                              'No pending audios',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
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
              onPressed: () {
                context.read<AudioManagerBloc>().add(const LoadPendingAudios());
              },
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

  void _openSeeAll(
    PendingAudioType type,
    String title,
  ) {
    final bloc = context.read<AudioManagerBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: bloc,
              child: PendingAudioDetailScreen(type: type, title: title),
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

class _PendingSection extends StatelessWidget {
  final String title;
  final List<AudioFile> audios;
  final int totalCount;
  final PendingAudioType type;
  final void Function(PendingAudioType, String) onSeeAll;
  final void Function(BuildContext, AudioFile) onTapAudio;
  final void Function(BuildContext, AudioFile) onChevronTap;

  const _PendingSection({
    required this.title,
    required this.audios,
    required this.totalCount,
    required this.type,
    required this.onSeeAll,
    required this.onTapAudio,
    required this.onChevronTap,
  });

  @override
  Widget build(BuildContext context) {
    final showSeeAll = totalCount > 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showSeeAll)
              TextButton(
                onPressed: () => onSeeAll(type, title),
                child: Text(
                  'See All ($totalCount)',
                  style: const TextStyle(color: Color(0xFF3B82F6)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (audios.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No pending audios',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          ...audios.take(3).map(
                (audio) => AudioFileListItem(
                  audioFile: audio,
                  onTap: () => onTapAudio(context, audio),
                  onChevronTap: () => onChevronTap(context, audio),
                  showPendingStatus: true,
                ),
              ),
      ],
    );
  }
}
