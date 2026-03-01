import '../../data/datasources/movie_remote_data_source.dart';
import '../repositories/movie_repository.dart';

class SearchMovies {
  final MovieRepository repository;

  SearchMovies(this.repository);

  Future<PaginatedMovies> execute(String query, {int page = 1}) async {
    return await repository.searchMovies(query, page: page);
  }
}
