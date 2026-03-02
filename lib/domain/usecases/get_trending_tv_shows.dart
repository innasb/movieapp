import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';

class GetTrendingTvShows {
  final TvRepository repository;

  GetTrendingTvShows(this.repository);

  Future<List<TvShow>> call({int page = 1}) {
    return repository.getTrendingTvShows(page: page);
  }
}
