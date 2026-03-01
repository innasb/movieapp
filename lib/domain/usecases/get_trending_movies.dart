import '../../data/datasources/movie_remote_data_source.dart';
import '../repositories/movie_repository.dart';

class GetTrendingMovies {
  final MovieRepository repository;

  GetTrendingMovies(this.repository);

  Future<PaginatedMovies> execute({int page = 1}) async {
    return await repository.getTrendingMovies(page: page);
  }
}
