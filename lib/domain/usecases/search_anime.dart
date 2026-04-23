import '../entities/anime.dart';
import '../repositories/anime_repository.dart';

class SearchAnime {
  final AnimeRepository repository;

  SearchAnime(this.repository);

  Future<List<Anime>> call(String query, {int page = 1}) {
    return repository.searchAnime(query, page: page);
  }
}
