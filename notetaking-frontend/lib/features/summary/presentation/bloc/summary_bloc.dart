import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_summary.dart';
import '../../domain/usecases/save_summary.dart';
import '../../domain/usecases/resummarize.dart';
import '../../domain/usecases/update_action_item.dart';
import 'summary_event.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final GetSummary getSummary;
  final SaveSummary saveSummary;
  final Resummarize resummarize;
  final UpdateActionItem updateActionItem;

  SummaryBloc({
    required this.getSummary,
    required this.saveSummary,
    required this.resummarize,
    required this.updateActionItem,
  }) : super(SummaryInitial()) {
    on<GetSummaryEvent>(_onGetSummary);
    on<SaveSummaryEvent>(_onSaveSummary);
    on<ResummarizeEvent>(_onResummarize);
    on<UpdateActionItemEvent>(_onUpdateActionItem);
    on<ResetSummaryEvent>(_onReset);
  }

  void _onGetSummary(
    GetSummaryEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    final result = await getSummary(event.transcriptionId);

    result.fold(
      (failure) => emit(SummaryError(failure.message)),
      (summary) => emit(SummaryLoaded(summary)),
    );
  }

  void _onSaveSummary(
    SaveSummaryEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    final result = await saveSummary(event.summary);

    result.fold(
      (failure) => emit(SummaryError(failure.message)),
      (summary) => emit(SummarySaved(summary)),
    );
  }

  void _onResummarize(
    ResummarizeEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    final result = await resummarize(event.transcriptionId);

    result.fold(
      (failure) => emit(SummaryError(failure.message)),
      (summary) => emit(SummaryLoaded(summary)),
    );
  }

  void _onUpdateActionItem(
    UpdateActionItemEvent event,
    Emitter<SummaryState> emit,
  ) async {
    emit(SummaryLoading());

    final result = await updateActionItem(
      summaryId: event.summaryId,
      actionItemId: event.actionItemId,
      isCompleted: event.isCompleted,
    );

    result.fold(
      (failure) => emit(SummaryError(failure.message)),
      (summary) => emit(SummaryLoaded(summary)),
    );
  }

  void _onReset(
    ResetSummaryEvent event,
    Emitter<SummaryState> emit,
  ) {
    emit(SummaryInitial());
  }
}

