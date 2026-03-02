import 'package:talker_flutter/talker_flutter.dart';
import '../../core/network/api_client.dart';
import '../models/tv_show_model.dart';
import '../models/tv_show_detail_model.dart';
import '../models/episode_model.dart';

class PaginatedTvShows {
  final List<TvShowModel> shows;
  final int totalPages;

  PaginatedTvShows({required this.shows, required this.totalPages});
}

abstract class TvRemoteDataSource {
  Future<PaginatedTvShows> getTrendingTvShows({int page = 1});
  Future<PaginatedTvShows> getTopRatedTvShows({int page = 1});
  Future<TvShowDetailModel> getTvShowDetail(int id);
  Future<List<EpisodeModel>> getSeasonEpisodes(int tvId, int seasonNumber);
  Future<PaginatedTvShows> searchTvShows(String query, {int page = 1});
}

class TvRemoteDataSourceImpl implements TvRemoteDataSource {
  final ApiClient apiClient;
  final Talker talker;

  TvRemoteDataSourceImpl(this.apiClient, this.talker);

  @override
  Future<PaginatedTvShows> getTrendingTvShows({int page = 1}) async {
    try {
      final response = await apiClient.get(
        '/trending/tv/week',
        queryParameters: {'page': page},
      );
      final List results = response.data['results'];
      final int totalPages = response.data['total_pages'] ?? 1;
      talker.debug(
        'Fetched ${results.length} trending tv shows (page $page/$totalPages)',
      );
      return PaginatedTvShows(
        shows: results.map((e) => TvShowModel.fromJson(e)).toList(),
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching trending tv shows');
      rethrow;
    }
  }

  @override
  Future<PaginatedTvShows> getTopRatedTvShows({int page = 1}) async {
    try {
      final response = await apiClient.get(
        '/tv/top_rated',
        queryParameters: {'page': page},
      );
      final List results = response.data['results'];
      final int totalPages = response.data['total_pages'] ?? 1;
      talker.debug(
        'Fetched ${results.length} top rated tv shows (page $page/$totalPages)',
      );
      return PaginatedTvShows(
        shows: results.map((e) => TvShowModel.fromJson(e)).toList(),
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching top rated tv shows');
      rethrow;
    }
  }

  @override
  Future<TvShowDetailModel> getTvShowDetail(int id) async {
    try {
      talker.debug('Fetching details for tv show ID: $id');
      final response = await apiClient.get('/tv/$id');
      return TvShowDetailModel.fromJson(response.data);
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching tv show detail');
      rethrow;
    }
  }

  @override
  Future<List<EpisodeModel>> getSeasonEpisodes(int tvId, int seasonNumber) async {
    try {
      talker.debug('Fetching episodes for tv show ID: $tvId, season: $seasonNumber');
      final response = await apiClient.get('/tv/$tvId/season/$seasonNumber');
      final List results = response.data['episodes'] ?? [];
      return results.map((e) => EpisodeModel.fromJson(e)).toList();
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching season episodes');
      rethrow;
    }
  }

  @override
  Future<PaginatedTvShows> searchTvShows(String query, {int page = 1}) async {
    try {
      final response = await apiClient.get(
        '/search/tv',
        queryParameters: {'query': query, 'page': page},
      );
      final List results = response.data['results'];
      final int totalPages = response.data['total_pages'] ?? 1;
      talker.debug(
        'Search "$query" returned ${results.length} results (page $page/$totalPages)',
      );
      return PaginatedTvShows(
        shows: results.map((e) => TvShowModel.fromJson(e)).toList(),
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error searching tv shows');
      rethrow;
    }
  }
}
