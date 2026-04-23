import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../domain/usecases/get_top_anime.dart';
import '../../domain/usecases/search_anime.dart';
import 'anime_state.dart';

class AnimeCubit extends Cubit<AnimeState> {
  final GetTopAnime getTopAnime;
  final SearchAnime searchAnime;
  final Talker talker;

  Timer? _debounce;

  AnimeCubit({
    required this.getTopAnime,
    required this.searchAnime,
    required this.talker,
  }) : super(AnimeInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> loadAnimeData() async {
    emit(AnimeLoading());
    try {
      final topResult = await getTopAnime.call();

      emit(
        AnimeLoaded(
          topAnime: topResult,
          animeList: topResult,
          currentPage: 1,
          totalPages: 1000,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load anime data');
      emit(AnimeError(e.toString()));
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
    if (currentState is! AnimeLoaded) return;

    emit(AnimeLoading());
    try {
      final result = await searchAnime.call(query);
      emit(
        AnimeLoaded(
          topAnime: currentState.topAnime,
          animeList: result,
          currentPage: 1,
          totalPages: 1000,
          searchQuery: query,
          isSearchMode: true,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to search anime');
      emit(AnimeError(e.toString()));
    }
  }

  void clearSearch() {
    _debounce?.cancel();
    final currentState = state;
    if (currentState is AnimeLoaded) {
      loadAnimeData();
    }
  }

  Future<void> loadMoreAnime() async {
    final currentState = state;
    if (currentState is! AnimeLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = currentState.isSearchMode
          ? await searchAnime.call(currentState.searchQuery, page: nextPage)
          : await getTopAnime.call(page: nextPage);

      emit(
        currentState.copyWith(
          animeList: [...currentState.animeList, ...result],
          currentPage: nextPage,
          totalPages: 1000,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load more anime');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
