// import '../entities/movie.dart';
import '../entities/movie_detail.dart';
import '../entities/category.dart';
import '../../data/datasources/movie_remote_data_source.dart';

abstract class MovieRepository {
  Future<PaginatedMovies> getRecentMovies({int page = 1});
  Future<PaginatedMovies> getTrendingMovies({int page = 1});
  Future<PaginatedMovies> getTopRatedMovies({int page = 1});
  Future<List<Category>> getCategories();
  Future<PaginatedMovies> getMoviesByCategory(int categoryId, {int page = 1});
  Future<MovieDetail> getMovieDetail(int id);
  Future<PaginatedMovies> searchMovies(String query, {int page = 1});
}
