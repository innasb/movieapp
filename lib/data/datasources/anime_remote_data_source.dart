import 'package:dio/dio.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../core/utils/config.dart';
import '../models/anime_model.dart';
import '../models/anime_detail_model.dart';

class PaginatedAnime {
  final List<AnimeModel> anime;
  final int totalPages;

  PaginatedAnime({required this.anime, required this.totalPages});
}

abstract class AnimeRemoteDataSource {
  Future<PaginatedAnime> getTopAnime({int page = 1});
  Future<PaginatedAnime> searchAnime(String query, {int page = 1});
  Future<AnimeDetailModel> getAnimeDetail(int malId);
}

class AnimeRemoteDataSourceImpl implements AnimeRemoteDataSource {
  final Dio _dio;
  final Talker talker;

  AnimeRemoteDataSourceImpl(this.talker)
      : _dio = Dio(BaseOptions(
          baseUrl: Config.jikanBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  @override
  Future<PaginatedAnime> getTopAnime({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/top/anime',
        queryParameters: {
          'page': page, 
          'sfw': true,
          'type': 'tv', // VidLink is most reliable with TV series
        },
      );
      final List results = response.data['data'] ?? [];
      final pagination = response.data['pagination'] ?? {};
      final int totalPages = pagination['last_visible_page'] ?? 1;
      talker.debug(
        'Fetched ${results.length} top anime (page $page/$totalPages)',
      );
      
      final validAnime = results
          .map((e) => AnimeModel.fromJson(e))
          .where((anime) => anime.episodes > 0 || anime.airing)
          .toList();

      return PaginatedAnime(
        anime: validAnime,
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching top anime');
      rethrow;
    }
  }

  @override
  Future<PaginatedAnime> searchAnime(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/anime',
        queryParameters: {
          'q': query, 
          'page': page, 
          'sfw': true,
          'type': 'tv', // Restrict to TV series
        },
      );
      final List results = response.data['data'] ?? [];
      final pagination = response.data['pagination'] ?? {};
      final int totalPages = pagination['last_visible_page'] ?? 1;
      talker.debug(
        'Search "$query" returned ${results.length} anime (page $page/$totalPages)',
      );

      final validAnime = results
          .map((e) => AnimeModel.fromJson(e))
          .where((anime) => anime.episodes > 0 || anime.airing)
          .toList();

      return PaginatedAnime(
        anime: validAnime,
        totalPages: totalPages,
      );
    } catch (e, st) {
      talker.handle(e, st, 'Error searching anime');
      rethrow;
    }
  }

  @override
  Future<AnimeDetailModel> getAnimeDetail(int malId) async {
    try {
      talker.debug('Fetching anime detail for MAL ID: $malId');
      final response = await _dio.get('/anime/$malId/full');
      return AnimeDetailModel.fromJson(response.data['data']);
    } catch (e, st) {
      talker.handle(e, st, 'Error fetching anime detail');
      rethrow;
    }
  }
}
