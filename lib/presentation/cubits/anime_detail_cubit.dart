import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../domain/usecases/get_anime_detail.dart';
import 'anime_detail_state.dart';

class AnimeDetailCubit extends Cubit<AnimeDetailState> {
  final GetAnimeDetail getAnimeDetail;
  final Talker talker;

  AnimeDetailCubit({
    required this.getAnimeDetail,
    required this.talker,
  }) : super(AnimeDetailInitial());

  Future<void> loadAnimeDetail(int malId) async {
    emit(AnimeDetailLoading());
    try {
      final anime = await getAnimeDetail.call(malId);
      emit(AnimeDetailLoaded(anime: anime));
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load anime detail');
      emit(AnimeDetailError(e.toString()));
    }
  }

  void toggleSubDub(String value) {
    final currentState = state;
    if (currentState is AnimeDetailLoaded) {
      emit(currentState.copyWith(subOrDub: value));
    }
  }
}
