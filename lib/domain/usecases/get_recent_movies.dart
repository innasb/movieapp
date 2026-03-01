import '../../data/datasources/movie_remote_data_source.dart';
import '../repositories/movie_repository.dart';

class GetRecentMovies {
  final MovieRepository repository;

  GetRecentMovies(this.repository);

  Future<PaginatedMovies> execute({int page = 1}) async {
    return await repository.getRecentMovies(page: page);
  }
}
