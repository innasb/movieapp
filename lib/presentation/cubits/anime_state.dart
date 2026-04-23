import 'package:equatable/equatable.dart';
import '../../domain/entities/anime.dart';

abstract class AnimeState extends Equatable {
  const AnimeState();

  @override
  List<Object> get props => [];
}

class AnimeInitial extends AnimeState {}

class AnimeLoading extends AnimeState {}

class AnimeLoaded extends AnimeState {
  final List<Anime> topAnime;
  final List<Anime> animeList; // Search results or main list
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final String searchQuery;
  final bool isSearchMode;

  const AnimeLoaded({
    required this.topAnime,
    required this.animeList,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.isSearchMode = false,
  });

  bool get hasMore => currentPage < totalPages;

  AnimeLoaded copyWith({
    List<Anime>? topAnime,
    List<Anime>? animeList,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    String? searchQuery,
    bool? isSearchMode,
  }) {
    return AnimeLoaded(
      topAnime: topAnime ?? this.topAnime,
      animeList: animeList ?? this.animeList,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchMode: isSearchMode ?? this.isSearchMode,
    );
  }

  @override
  List<Object> get props => [
    topAnime, animeList, currentPage, totalPages,
    isLoadingMore, searchQuery, isSearchMode,
  ];
}

class AnimeError extends AnimeState {
  final String message;

  const AnimeError(this.message);

  @override
  List<Object> get props => [message];
}
