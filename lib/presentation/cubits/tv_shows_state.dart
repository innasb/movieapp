import 'package:equatable/equatable.dart';
import '../../domain/entities/tv_show.dart';

abstract class TvShowsState extends Equatable {
  const TvShowsState();

  @override
  List<Object> get props => [];
}

class TvShowsInitial extends TvShowsState {}

class TvShowsLoading extends TvShowsState {}

class TvShowsLoaded extends TvShowsState {
  final List<TvShow> trendingTvShows;
  final List<TvShow> topRatedTvShows;
  final List<TvShow> shows; // Search results or main list
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final String searchQuery;
  final bool isSearchMode;

  const TvShowsLoaded({
    required this.trendingTvShows,
    required this.topRatedTvShows,
    required this.shows,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.isSearchMode = false,
  });

  bool get hasMore => currentPage < totalPages;

  TvShowsLoaded copyWith({
    List<TvShow>? trendingTvShows,
    List<TvShow>? topRatedTvShows,
    List<TvShow>? shows,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    String? searchQuery,
    bool? isSearchMode,
  }) {
    return TvShowsLoaded(
      trendingTvShows: trendingTvShows ?? this.trendingTvShows,
      topRatedTvShows: topRatedTvShows ?? this.topRatedTvShows,
      shows: shows ?? this.shows,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchMode: isSearchMode ?? this.isSearchMode,
    );
  }

  @override
  List<Object> get props => [
    trendingTvShows,
    topRatedTvShows,
    shows,
    currentPage,
    totalPages,
    isLoadingMore,
    searchQuery,
    isSearchMode,
  ];
}

class TvShowsError extends TvShowsState {
  final String message;

  const TvShowsError(this.message);

  @override
  List<Object> get props => [message];
}
