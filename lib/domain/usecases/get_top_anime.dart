import '../entities/anime.dart';
import '../repositories/anime_repository.dart';

class GetTopAnime {
  final AnimeRepository repository;

  GetTopAnime(this.repository);

  Future<List<Anime>> call({int page = 1}) {
    return repository.getTopAnime(page: page);
  }
}
