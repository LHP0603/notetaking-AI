import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/audio_manager_bloc.dart';
import '../bloc/audio_manager_event.dart';
import '../bloc/audio_manager_state.dart';
import '../bloc/task_monitor_bloc.dart';
import '../bloc/task_monitor_event.dart';
import '../tabs/pending_tab.dart';
import '../tabs/tasks_tab.dart';
import '../tabs/upload_tab.dart';
import '../../../chatbot/presentation/pages/chatbot_screen.dart';
import '../../../chatbot/presentation/widgets/animated_chat_fab.dart';

class AudioManagerPage extends StatefulWidget {
  final String? initialTab;

  const AudioManagerPage({super.key, this.initialTab});

  @override
  State<AudioManagerPage> createState() => _AudioManagerPageState();
}

class _AudioManagerPageState extends State<AudioManagerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = _tabIndexFromParam(widget.initialTab);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMonitoring();
    });
  }

  @override
  void didUpdateWidget(AudioManagerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      final index = _tabIndexFromParam(widget.initialTab);
      if (_tabController.index != index) {
        _tabController.animateTo(index);
      }
    }
  }

  @override
  void dispose() {
    if (_isMonitoring) {
      context.read<TaskMonitorBloc>().add(const StopTaskMonitoring());
    }
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  int _tabIndexFromParam(String? tab) {
    switch (tab) {
      case 'tasks':
        return 1;
      case 'pending':
        return 2;
      default:
        return 0;
    }
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    _updateMonitoring();
  }

  void _updateMonitoring() {
    final isTasksTab = _tabController.index == 1;
    if (isTasksTab && !_isMonitoring) {
      _isMonitoring = true;
      context.read<TaskMonitorBloc>().add(const StartTaskMonitoring());
    } else if (!isTasksTab && _isMonitoring) {
      _isMonitoring = false;
      context.read<TaskMonitorBloc>().add(const StopTaskMonitoring());
    }
  }

  void _openChatbot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => const ChatbotScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioManagerBloc, AudioManagerState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message == null) {
          return;
        }
        final isError = state.errorMessage != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : const Color(0xFF3B82F6),
          ),
        );
        if (!isError && _tabController.index != 1) {
          _tabController.animateTo(1);
        }
        context.read<AudioManagerBloc>().add(const ClearMessage());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101822),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: const Color(0xFF101822),
                  elevation: 0,
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  floating: true,
                  snap: true,
                  pinned: false,
                  title: const Text(
                    'Audio Manager',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF3B82F6),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Upload'),
                        Tab(text: 'Tasks'),
                        Tab(text: 'Pending'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: const [
                UploadTab(),
                TasksTab(),
                PendingTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF101822),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
