import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';

class GetTopRatedTvShows {
  final TvRepository repository;

  GetTopRatedTvShows(this.repository);

  Future<List<TvShow>> call({int page = 1}) {
    return repository.getTopRatedTvShows(page: page);
  }
}
