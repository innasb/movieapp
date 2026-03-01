import 'package:equatable/equatable.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/category.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Movie> recentMovies;
  final List<Movie> trendingMovies;
  final List<Movie> topRatedMovies;
  final List<Movie> movies; // Categories or Search results
  final List<Category> categories;
  final int selectedCategoryId; // 0 means all recent
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final String searchQuery;
  final bool isSearchMode;

  const HomeLoaded({
    required this.recentMovies,
    required this.trendingMovies,
    required this.topRatedMovies,
    required this.movies,
    required this.categories,
    required this.selectedCategoryId,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.isSearchMode = false,
  });

  bool get hasMore => currentPage < totalPages;

  HomeLoaded copyWith({
    List<Movie>? recentMovies,
    List<Movie>? trendingMovies,
    List<Movie>? topRatedMovies,
    List<Movie>? movies,
    List<Category>? categories,
    int? selectedCategoryId,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    String? searchQuery,
    bool? isSearchMode,
  }) {
    return HomeLoaded(
      recentMovies: recentMovies ?? this.recentMovies,
      trendingMovies: trendingMovies ?? this.trendingMovies,
      topRatedMovies: topRatedMovies ?? this.topRatedMovies,
      movies: movies ?? this.movies,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchMode: isSearchMode ?? this.isSearchMode,
    );
  }

  @override
  List<Object> get props => [
    recentMovies,
    trendingMovies,
    topRatedMovies,
    movies,
    categories,
    selectedCategoryId,
    currentPage,
    totalPages,
    isLoadingMore,
    searchQuery,
    isSearchMode,
  ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}
