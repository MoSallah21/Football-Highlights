
part of 'highlights_cubit.dart';

/// States for highlights loading
abstract class HighlightsState extends Equatable {
  const HighlightsState();

  @override
  List<Object?> get props => [];
}

class HighlightsLoading extends HighlightsState {}

class HighlightsLoaded extends HighlightsState {
  final List<HighlightModel> highlights;
  final bool isLive;

  const HighlightsLoaded(this.highlights, {this.isLive = false});

  @override
  List<Object?> get props => [highlights, isLive];
}

class HighlightsError extends HighlightsState {
  final String message;

  const HighlightsError(this.message);

  @override
  List<Object?> get props => [message];
}
