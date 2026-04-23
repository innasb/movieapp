import '../../domain/entities/anime.dart';

class AnimeModel extends Anime {
  const AnimeModel({
    required super.malId,
    required super.title,
    required super.imageUrl,
    required super.score,
    required super.episodes,
    required super.type,
    required super.airing,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    return AnimeModel(
      malId: json['mal_id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Unknown Anime',
      imageUrl: json['images']?['jpg']?['large_image_url'] as String? ??
          json['images']?['jpg']?['image_url'] as String? ??
          '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      episodes: json['episodes'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      airing: json['airing'] as bool? ?? false,
    );
  }
}
