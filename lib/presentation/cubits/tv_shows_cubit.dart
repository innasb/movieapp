import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../domain/usecases/get_trending_tv_shows.dart';
import '../../domain/usecases/get_top_rated_tv_shows.dart';
import '../../domain/usecases/search_tv_shows.dart';
import 'tv_shows_state.dart';

class TvShowsCubit extends Cubit<TvShowsState> {
  final GetTrendingTvShows getTrendingTvShows;
  final GetTopRatedTvShows getTopRatedTvShows;
  final SearchTvShows searchTvShows;
  final Talker talker;

  Timer? _debounce;

  TvShowsCubit({
    required this.getTrendingTvShows,
    required this.getTopRatedTvShows,
    required this.searchTvShows,
    required this.talker,
  }) : super(TvShowsInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> loadTvShowsData() async {
    emit(TvShowsLoading());
    try {
      final trendingResult = await getTrendingTvShows.call();
      final topRatedResult = await getTopRatedTvShows.call();

      emit(
        TvShowsLoaded(
          trendingTvShows: trendingResult,
          topRatedTvShows: topRatedResult,
          shows: trendingResult, // default list
          currentPage: 1,
          totalPages: 1000, // Approximate for pagination if needed
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load tv shows data');
      emit(TvShowsError(e.toString()));
    }
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final currentState = state;
    if (currentState is! TvShowsLoaded) return;

    emit(TvShowsLoading());
    try {
      final result = await searchTvShows.call(query);
      emit(
        TvShowsLoaded(
          trendingTvShows: currentState.trendingTvShows,
          topRatedTvShows: currentState.topRatedTvShows,
          shows: result,
          currentPage: 1,
          totalPages: 1000,
          searchQuery: query,
          isSearchMode: true,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to search tv shows');
      emit(TvShowsError(e.toString()));
    }
  }

  void clearSearch() {
    _debounce?.cancel();
    final currentState = state;
    if (currentState is TvShowsLoaded) {
      // Reload default data
      loadTvShowsData();
    }
  }

  Future<void> loadMoreTvShows() async {
    final currentState = state;
    if (currentState is! TvShowsLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = currentState.isSearchMode
          ? await searchTvShows.call(currentState.searchQuery, page: nextPage)
          : await getTrendingTvShows.call(page: nextPage);

      emit(
        currentState.copyWith(
          shows: [...currentState.shows, ...result],
          currentPage: nextPage,
          totalPages: 1000,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load more tv shows');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
