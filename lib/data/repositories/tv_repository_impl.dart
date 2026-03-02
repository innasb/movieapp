import '../../domain/entities/tv_show.dart';
import '../../domain/entities/tv_show_detail.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/tv_repository.dart';
import '../datasources/tv_remote_data_source.dart';

class TvRepositoryImpl implements TvRepository {
  final TvRemoteDataSource remoteDataSource;

  TvRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<TvShow>> getTrendingTvShows({int page = 1}) async {
    final result = await remoteDataSource.getTrendingTvShows(page: page);
    return result.shows;
  }

  @override
  Future<List<TvShow>> getTopRatedTvShows({int page = 1}) async {
    final result = await remoteDataSource.getTopRatedTvShows(page: page);
    return result.shows;
  }

  @override
  Future<TvShowDetail> getTvShowDetail(int id) async {
    return await remoteDataSource.getTvShowDetail(id);
  }

  @override
  Future<List<Episode>> getSeasonEpisodes(int tvId, int seasonNumber) async {
    return await remoteDataSource.getSeasonEpisodes(tvId, seasonNumber);
  }

  @override
  Future<List<TvShow>> searchTvShows(String query, {int page = 1}) async {
    final result = await remoteDataSource.searchTvShows(query, page: page);
    return result.shows;
  }
}
