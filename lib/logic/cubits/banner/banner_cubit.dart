import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/repositories/firestore_repository.dart';
part 'banner_state.dart';



/// Cubit managing banner ads data and state
class BannerCubit extends Cubit<BannerState> {
  final FirestoreRepository _repository;

  BannerCubit(this._repository) : super(BannerLoading());

  /// Load banners from Firestore
  Future<void> loadBanners() async {
    emit(BannerLoading());
    try {
      final banners = await _repository.fetchBanners();
      emit(BannerLoaded(banners));
    } catch (e) {
      emit(BannerError(e.toString()));
    }
  }
}