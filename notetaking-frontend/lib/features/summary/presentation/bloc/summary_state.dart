import 'package:equatable/equatable.dart';
import '../../domain/entities/summary.dart';

abstract class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object?> get props => [];
}

class SummaryInitial extends SummaryState {}

class SummaryLoading extends SummaryState {}

class SummaryLoaded extends SummaryState {
  final Summary summary;

  const SummaryLoaded(this.summary);

  @override
  List<Object> get props => [summary];
}

class SummarySaved extends SummaryState {
  final Summary summary;

  const SummarySaved(this.summary);

  @override
  List<Object> get props => [summary];
}

class SummaryError extends SummaryState {
  final String message;

  const SummaryError(this.message);

  @override
  List<Object> get props => [message];
}

