import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:highlight_matches/data/models/video_model.dart';

import '../../../data/repositories/video_repositry.dart';
part 'videos_state.dart';
class VideosCubit extends Cubit<VideosState> {
  VideosCubit(this._repository) : super(VideosInit());

  final VideoRepository _repository;

  List<VideoModel> videos = [];
  Future<List<VideoModel>> loadVideos() async {
    emit(HighlightsLoading());

    try {
      final videos = await _repository.fetchVideos();
      this.videos=videos;
      emit(HighlightsLoaded(videos, source: "majid"));
      return this.videos;
    } catch (e) {
      return [];
    }
  }
  VideoModel videos1 =  VideoModel(id: 0, title: '', image: '');

  // Future<VideoModel> fetchVideo() async {
  //   emit(HighlightsLoading());
  //
  //   try {
  //     final videos = await _repository.fetchVideos();
  //     this.videos1=videos;
  //     emit(HighlightsLoaded(videos, source: "majid"));
  //     return this.videos1;
  //   } catch (e) {
  //     return [];
  //   }
  // }
}
