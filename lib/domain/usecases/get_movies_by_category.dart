import '../../data/datasources/movie_remote_data_source.dart';
import '../repositories/movie_repository.dart';

class GetMoviesByCategory {
  final MovieRepository repository;

  GetMoviesByCategory(this.repository);

  Future<PaginatedMovies> execute(int categoryId, {int page = 1}) async {
    return await repository.getMoviesByCategory(categoryId, page: page);
  }
}
