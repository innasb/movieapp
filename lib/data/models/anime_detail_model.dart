import '../../domain/entities/anime_detail.dart';

class AnimeDetailModel extends AnimeDetail {
  const AnimeDetailModel({
    required super.malId,
    required super.title,
    required super.titleJapanese,
    required super.imageUrl,
    required super.bannerUrl,
    required super.score,
    required super.episodes,
    required super.synopsis,
    required super.genres,
    required super.status,
    required super.type,
    required super.airing,
  });

  factory AnimeDetailModel.fromJson(Map<String, dynamic> json) {
    final genreList = (json['genres'] as List<dynamic>?)
            ?.map((g) => g['name'] as String? ?? '')
            .where((g) => g.isNotEmpty)
            .toList() ??
        [];

    return AnimeDetailModel(
      malId: json['mal_id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Unknown Anime',
      titleJapanese: json['title_japanese'] as String? ?? '',
      imageUrl: json['images']?['jpg']?['large_image_url'] as String? ??
          json['images']?['jpg']?['image_url'] as String? ??
          '',
      bannerUrl: json['images']?['jpg']?['large_image_url'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      episodes: json['episodes'] as int? ?? 0,
      synopsis: json['synopsis'] as String? ?? '',
      genres: genreList,
      status: json['status'] as String? ?? '',
      type: json['type'] as String? ?? '',
      airing: json['airing'] as bool? ?? false,
    );
  }
}
