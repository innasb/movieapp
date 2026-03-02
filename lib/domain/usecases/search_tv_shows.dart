import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';

class SearchTvShows {
  final TvRepository repository;

  SearchTvShows(this.repository);

  Future<List<TvShow>> call(String query, {int page = 1}) {
    return repository.searchTvShows(query, page: page);
  }
}
