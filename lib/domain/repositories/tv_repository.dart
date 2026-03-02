import '../entities/tv_show.dart';
import '../entities/tv_show_detail.dart';
import '../entities/episode.dart';

abstract class TvRepository {
  Future<List<TvShow>> getTrendingTvShows({int page = 1});
  Future<List<TvShow>> getTopRatedTvShows({int page = 1});
  Future<TvShowDetail> getTvShowDetail(int id);
  Future<List<Episode>> getSeasonEpisodes(int tvId, int seasonNumber);
  Future<List<TvShow>> searchTvShows(String query, {int page = 1});
}
