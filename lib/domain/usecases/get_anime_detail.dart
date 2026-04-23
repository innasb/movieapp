import '../entities/anime_detail.dart';
import '../repositories/anime_repository.dart';

class GetAnimeDetail {
  final AnimeRepository repository;

  GetAnimeDetail(this.repository);

  Future<AnimeDetail> call(int malId) {
    return repository.getAnimeDetail(malId);
  }
}
