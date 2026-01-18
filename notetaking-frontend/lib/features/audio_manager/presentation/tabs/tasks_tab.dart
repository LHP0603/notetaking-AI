import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task_monitor_bloc.dart';
import '../bloc/task_monitor_state.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/loading_task_item.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  String _formatStatus(String status) {
    final trimmed = status.trim();
    if (trimmed.isEmpty) {
      return 'In progress';
    }
    final normalized =
        trimmed.replaceAll(RegExp(r'[_-]+'), ' ').toLowerCase();
    final words = normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'In progress';
    }
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskMonitorBloc, TaskMonitorState>(
      builder: (context, state) {
        if (state is TasksLoaded) {
          final totalTasks =
              state.uploadTasks.length +
              state.transcribeTasks.length +
              state.summarizeTasks.length;

          if (totalTasks == 0) {
            return const Center(
              child: Text(
                'No active tasks right now',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CollapsibleSection(
                  title: 'Uploading',
                  count: state.uploadTasks.length,
                  children:
                      state.uploadTasks
                          .map(
                            (task) => LoadingTaskItem(
                              icon: Icons.upload_file,
                              iconColor: Colors.orange,
                              title: task.filename,
                              description:
                                  'Status: ${_formatStatus(task.status)}',
                              onTap: () => _showTaskNotification(
                                context,
                                'Uploading',
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                CollapsibleSection(
                  title: 'Transcribing',
                  count: state.transcribeTasks.length,
                  children:
                      state.transcribeTasks
                          .map(
                            (task) => LoadingTaskItem(
                              icon: Icons.description,
                              iconColor: Colors.blue,
                              title: task.filename,
                              description:
                                  'Status: ${_formatStatus(task.status)}',
                              onTap: () => _showTaskNotification(
                                context,
                                'Transcribing',
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                CollapsibleSection(
                  title: 'Summarizing',
                  count: state.summarizeTasks.length,
                  children:
                      state.summarizeTasks
                          .map(
                            (task) => LoadingTaskItem(
                              icon: Icons.summarize,
                              iconColor: Colors.green,
                              title: task.filename,
                              description:
                                  'Status: ${_formatStatus(task.status)}',
                              onTap: () => _showTaskNotification(
                                context,
                                'Summarizing',
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          );
        }

        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
        );
      },
    );
  }

  void _showTaskNotification(BuildContext context, String taskType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$taskType in progress...'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }
}
