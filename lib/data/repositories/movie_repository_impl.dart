import '../../domain/entities/movie_detail.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_data_source.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;

  MovieRepositoryImpl(this.remoteDataSource);

  @override
  Future<PaginatedMovies> getRecentMovies({int page = 1}) async {
    return await remoteDataSource.getRecentMovies(page: page);
  }

  @override
  Future<PaginatedMovies> getTrendingMovies({int page = 1}) async {
    return await remoteDataSource.getTrendingMovies(page: page);
  }

  @override
  Future<PaginatedMovies> getTopRatedMovies({int page = 1}) async {
    return await remoteDataSource.getTopRatedMovies(page: page);
  }

  @override
  Future<List<Category>> getCategories() async {
    return await remoteDataSource.getCategories();
  }

  @override
  Future<PaginatedMovies> getMoviesByCategory(
    int categoryId, {
    int page = 1,
  }) async {
    return await remoteDataSource.getMoviesByCategory(categoryId, page: page);
  }

  @override
  Future<MovieDetail> getMovieDetail(int id) async {
    return await remoteDataSource.getMovieDetail(id);
  }

  @override
  Future<PaginatedMovies> searchMovies(String query, {int page = 1}) async {
    return await remoteDataSource.searchMovies(query, page: page);
  }
}
