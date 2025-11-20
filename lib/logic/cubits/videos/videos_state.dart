part of 'videos_cubit.dart';




/// States for highlights loading
abstract class VideosState  extends Equatable {
  const VideosState();

  @override
  List<Object?> get props => [];
}
    class VideosInit extends VideosState {}

class HighlightsLoading extends VideosState {}

class HighlightsLoaded extends VideosState {
  final List<dynamic> items;
  final bool isLive;
  final String? source; // youtube, majid, majid_single...

  const HighlightsLoaded(
      this.items, {
        this.isLive = false,
        this.source = "youtube",
      });

  @override
  List<Object?> get props => [items, isLive, source];
}


class HighlightsError extends VideosState {
  final String message;

  const HighlightsError(this.message);

  @override
  List<Object?> get props => [message];
}
