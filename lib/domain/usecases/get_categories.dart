import '../entities/category.dart';
import '../repositories/movie_repository.dart';

class GetCategories {
  final MovieRepository repository;

  GetCategories(this.repository);

  Future<List<Category>> execute() async {
    return await repository.getCategories();
  }
}
