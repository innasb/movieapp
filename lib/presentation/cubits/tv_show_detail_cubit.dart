import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../domain/usecases/get_tv_show_detail.dart';
import '../../domain/usecases/get_season_episodes.dart';
import 'tv_show_detail_state.dart';

class TvShowDetailCubit extends Cubit<TvShowDetailState> {
  final GetTvShowDetail getTvShowDetail;
  final GetSeasonEpisodes getSeasonEpisodes;
  final Talker talker;

  TvShowDetailCubit({
    required this.getTvShowDetail,
    required this.getSeasonEpisodes,
    required this.talker,
  }) : super(TvShowDetailInitial());

  Future<void> loadTvShowDetail(int id) async {
    emit(TvShowDetailLoading());
    try {
      final tvShow = await getTvShowDetail.call(id);
      
      // Select the first valid season (usually 1, but could be 0 for specials)
      int defaultSeason = 1;
      if (tvShow.seasons.isNotEmpty) {
        // Try to find season 1, or use the first available
        final s1 = tvShow.seasons.where((s) => s.seasonNumber == 1).toList();
        defaultSeason = s1.isNotEmpty ? 1 : tvShow.seasons.first.seasonNumber;
      }

      emit(
        TvShowDetailLoaded(
          tvShow: tvShow,
          selectedSeasonNumber: defaultSeason,
          isEpisodesLoading: true,
        ),
      );

      // fetch default season episodes
      await loadSeasonEpisodes(id, defaultSeason);
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load tv show details for ID $id');
      emit(TvShowDetailError(e.toString()));
    }
  }

  Future<void> loadSeasonEpisodes(int tvId, int seasonNumber) async {
    final currentState = state;
    if (currentState is TvShowDetailLoaded) {
      emit(currentState.copyWith(
        selectedSeasonNumber: seasonNumber,
        isEpisodesLoading: true,
      ));

      try {
        final episodes = await getSeasonEpisodes.call(tvId, seasonNumber);
        emit(currentState.copyWith(
          selectedSeasonNumber: seasonNumber,
          currentSeasonEpisodes: episodes,
          isEpisodesLoading: false,
        ));
      } catch (e, st) {
        talker.handle(e, st, 'Failed to load episodes for season $seasonNumber');
        // keep old episodes or clear them? We can clear them or keep old
        emit(currentState.copyWith(isEpisodesLoading: false, currentSeasonEpisodes: []));
      }
    }
  }
}
