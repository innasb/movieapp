import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_detail.dart';
import '../../domain/repositories/anime_repository.dart';
import '../datasources/anime_remote_data_source.dart';

class AnimeRepositoryImpl implements AnimeRepository {
  final AnimeRemoteDataSource remoteDataSource;

  AnimeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Anime>> getTopAnime({int page = 1}) async {
    final result = await remoteDataSource.getTopAnime(page: page);
    return result.anime;
  }

  @override
  Future<List<Anime>> searchAnime(String query, {int page = 1}) async {
    final result = await remoteDataSource.searchAnime(query, page: page);
    return result.anime;
  }

  @override
  Future<AnimeDetail> getAnimeDetail(int malId) async {
    return await remoteDataSource.getAnimeDetail(malId);
  }
}
