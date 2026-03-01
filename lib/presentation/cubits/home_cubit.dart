import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../domain/usecases/get_recent_movies.dart';
import '../../domain/usecases/get_trending_movies.dart';
import '../../domain/usecases/get_top_rated_movies.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_movies_by_category.dart';
import '../../domain/usecases/search_movies.dart';
import '../../domain/entities/category.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetRecentMovies getRecentMovies;
  final GetTrendingMovies getTrendingMovies;
  final GetTopRatedMovies getTopRatedMovies;
  final GetCategories getCategories;
  final GetMoviesByCategory getMoviesByCategory;
  final SearchMovies searchMovies;
  final Talker talker;

  Timer? _debounce;

  HomeCubit({
    required this.getRecentMovies,
    required this.getTrendingMovies,
    required this.getTopRatedMovies,
    required this.getCategories,
    required this.getMoviesByCategory,
    required this.searchMovies,
    required this.talker,
  }) : super(HomeInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> loadHomeData() async {
    emit(HomeLoading());
    try {
      final recentResult = await getRecentMovies.execute();
      final trendingResult = await getTrendingMovies.execute();
      final topRatedResult = await getTopRatedMovies.execute();
      final categories = await getCategories.execute();

      // Add 'All' category at index 0
      final allCategory = [
        const Category(id: 0, name: 'All Movies'),
        ...categories,
      ];

      emit(
        HomeLoaded(
          recentMovies: recentResult.movies,
          trendingMovies: trendingResult.movies,
          topRatedMovies: topRatedResult.movies,
          movies: recentResult.movies,
          categories: allCategory,
          selectedCategoryId: 0,
          currentPage: 1,
          totalPages: recentResult.totalPages,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load home data');
      emit(HomeError(e.toString()));
    }
  }

  Future<void> loadMoviesByCategory(int categoryId) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      emit(HomeLoading());
      try {
        final result = categoryId == 0
            ? await getRecentMovies.execute()
            : await getMoviesByCategory.execute(categoryId);

        emit(
          HomeLoaded(
            recentMovies: currentState.recentMovies,
            trendingMovies: currentState.trendingMovies,
            topRatedMovies: currentState.topRatedMovies,
            movies: result.movies,
            categories: currentState.categories,
            selectedCategoryId: categoryId,
            currentPage: 1,
            totalPages: result.totalPages,
            searchQuery: '',
            isSearchMode: false,
          ),
        );
      } catch (e, st) {
        talker.handle(e, st, 'Failed to load movies for category $categoryId');
        emit(HomeError(e.toString()));
      }
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
    if (currentState is! HomeLoaded) return;

    emit(HomeLoading());
    try {
      final result = await searchMovies.execute(query);
      emit(
        HomeLoaded(
          recentMovies: currentState.recentMovies,
          trendingMovies: currentState.trendingMovies,
          topRatedMovies: currentState.topRatedMovies,
          movies: result.movies,
          categories: currentState.categories,
          selectedCategoryId: currentState.selectedCategoryId,
          currentPage: 1,
          totalPages: result.totalPages,
          searchQuery: query,
          isSearchMode: true,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to search movies');
      emit(HomeError(e.toString()));
    }
  }

  void clearSearch() {
    _debounce?.cancel();
    final currentState = state;
    if (currentState is HomeLoaded) {
      // Reload current category
      loadMoviesByCategory(currentState.selectedCategoryId);
    }
  }

  Future<void> loadMoreMovies() async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = currentState.isSearchMode
          ? await searchMovies.execute(currentState.searchQuery, page: nextPage)
          : currentState.selectedCategoryId == 0
          ? await getRecentMovies.execute(page: nextPage)
          : await getMoviesByCategory.execute(
              currentState.selectedCategoryId,
              page: nextPage,
            );

      emit(
        currentState.copyWith(
          movies: [...currentState.movies, ...result.movies],
          currentPage: nextPage,
          totalPages: result.totalPages,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load more movies');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
