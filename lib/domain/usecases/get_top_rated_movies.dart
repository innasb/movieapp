import '../../data/datasources/movie_remote_data_source.dart';
import '../repositories/movie_repository.dart';

class GetTopRatedMovies {
  final MovieRepository repository;

  GetTopRatedMovies(this.repository);

  Future<PaginatedMovies> execute({int page = 1}) async {
    return await repository.getTopRatedMovies(page: page);
  }
}
