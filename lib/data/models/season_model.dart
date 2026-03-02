import '../../domain/entities/season.dart';
import '../../core/utils/config.dart';

class SeasonModel extends Season {
  const SeasonModel({
    required super.id,
    required super.name,
    required super.overview,
    required super.posterPath,
    required super.seasonNumber,
    required super.episodeCount,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Season',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] != null 
          ? '${Config.tmdbImageBaseUrl}${json['poster_path']}' 
          : '',
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeCount: json['episode_count'] as int? ?? 0,
    );
  }
}
