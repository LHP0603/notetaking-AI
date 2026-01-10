import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/bloc/admin_bloc.dart';
import '../../presentation/bloc/admin_event.dart';
import '../../presentation/bloc/admin_state.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadAuditLogsEvent());
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF1F2937),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      context.read<AdminBloc>().add(
        LoadAuditLogsEvent(startDate: picked.start, endDate: picked.end),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      appBar: AppBar(
        title: const Text('Audit Logs', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF101822),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AuditLogsLoaded) {
            if (state.logs.isEmpty) {
              return const Center(
                child: Text(
                  'No logs found',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length,
              separatorBuilder: (c, i) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final log = state.logs[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.description_outlined,
                    color: Colors.white54,
                  ),
                  title: Text(
                    log.action,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'User: ${log.userEmail ?? log.userId} • IP: ${log.ipAddress}\n${_formatDateTime(log.createdAt)}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  isThreeLine: true,
                );
              },
            );
          } else if (state is AdminError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
