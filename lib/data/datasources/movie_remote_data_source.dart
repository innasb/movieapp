import 'package:talker_flutter/talker_flutter.dart';
import '../../core/network/api_client.dart';
import '../models/movie_model.dart';
import '../models/category_model.dart';
import '../models/movie_detail_model.dart';

/// Result wrapper for paginated movie responses.
class PaginatedMovies {
  final List<MovieModel> movies;
  final int totalPages;

  PaginatedMovies({required this.movies, required this.totalPages});
}

abstract class MovieRemoteDataSource {
  Future<PaginatedMovies> getRecentMovies({int page = 1});
  Future<PaginatedMovies> getTrendingMovies({int page = 1});
  Future<PaginatedMovies> getTopRatedMovies({int page = 1});
  Future<List<CategoryModel>> getCategories();
  Future<PaginatedMovies> getMoviesByCategory(int categoryId, {int page = 1});
  Future<MovieDetailModel> getMovieDetail(int id);
  Future<PaginatedMovies> searchMovies(String query, {int page = 1});
}

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final ApiClient apiClient;
  final Talker talker;

  MovieRemoteDataSourceImpl(this.apiClient, this.talker);

  @override
  Future<PaginatedMovies> getRecentMovies({int page = 1}) async {
    try {
      final response = await apiClient.get(
        '/movie/now_playing',
        queryParameters: {'page': page},
      );
      final List results = response.data['results'];
      final int totalPages = response.data['total_pages'] ?? 1;
      talker.debug(
        'Fetched ${results.length} recent movies (page $page/$totalPages)',
      );
      return PaginatedMovies(
        movies: results.map((e) => MovieModel.fromJson(e)).toList(),
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching recent movies');
      rethrow;
    }
  }

  @override
  Future<PaginatedMovies> getTrendingMovies({int page = 1}) async {
    try {
      final response = await apiClient.get(
        '/trending/movie/week',
        queryParameters: {'page': page},
      );
      final List results = response.data['results'];
      final int totalPages = response.data['total_pages'] ?? 1;
      talker.debug(
        'Fetched ${results.length} trending movies (page $page/$totalPages)',
      );
      return PaginatedMovies(
        movies: results.map((e) => MovieModel.fromJson(e)).toList(),
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching trending movies');
      rethrow;
    }
  }

  @override
  Future<PaginatedMovies> getTopRatedMovies({int page = 1}) async {
    try {
      final response = await apiClient.get(
        '/movie/top_rated',
        queryParameters: {'page': page},
      );
      final List results = response.data['results'];
      final int totalPages = response.data['total_pages'] ?? 1;
      talker.debug(
        'Fetched ${results.length} top rated movies (page $page/$totalPages)',
      );
      return PaginatedMovies(
        movies: results.map((e) => MovieModel.fromJson(e)).toList(),
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching top rated movies');
      rethrow;
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.get('/genre/movie/list');
      final List results = response.data['genres'];
      talker.debug('Fetched ${results.length} categories');
      return results.map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching categories');
      rethrow;
    }
  }

  @override
  Future<PaginatedMovies> getMoviesByCategory(
    int categoryId, {
    int page = 1,
  }) async {
    try {
      final response = await apiClient.get(
        '/discover/movie',
        queryParameters: {'with_genres': categoryId, 'page': page},
      );
      final List results = response.data['results'];
      final int totalPages = response.data['total_pages'] ?? 1;
      talker.debug(
        'Fetched ${results.length} movies for category $categoryId (page $page/$totalPages)',
      );
      return PaginatedMovies(
        movies: results.map((e) => MovieModel.fromJson(e)).toList(),
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching movies by category');
      rethrow;
    }
  }

  @override
  Future<MovieDetailModel> getMovieDetail(int id) async {
    try {
      talker.debug('Fetching details for movie ID: $id');
      final response = await apiClient.get('/movie/$id');
      return MovieDetailModel.fromJson(response.data);
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching movie detail');
      rethrow;
    }
  }

  @override
  Future<PaginatedMovies> searchMovies(String query, {int page = 1}) async {
    try {
      final response = await apiClient.get(
        '/search/movie',
        queryParameters: {'query': query, 'page': page},
      );
      final List results = response.data['results'];
      final int totalPages = response.data['total_pages'] ?? 1;
      talker.debug(
        'Search "$query" returned ${results.length} results (page $page/$totalPages)',
      );
      return PaginatedMovies(
        movies: results.map((e) => MovieModel.fromJson(e)).toList(),
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error searching movies');
      rethrow;
    }
  }
}
