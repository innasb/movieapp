import '../entities/anime.dart';
import '../entities/anime_detail.dart';

abstract class AnimeRepository {
  Future<List<Anime>> getTopAnime({int page = 1});
  Future<List<Anime>> searchAnime(String query, {int page = 1});
  Future<AnimeDetail> getAnimeDetail(int malId);
}
