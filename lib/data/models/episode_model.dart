import '../../domain/entities/episode.dart';
import '../../core/utils/config.dart';

class EpisodeModel extends Episode {
  const EpisodeModel({
    required super.id,
    required super.name,
    required super.overview,
    required super.stillPath,
    required super.episodeNumber,
    required super.seasonNumber,
    required super.voteAverage,
    required super.airDate,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Episode ${json['episode_number']}',
      overview: json['overview'] as String? ?? '',
      stillPath: json['still_path'] != null 
          ? '${Config.tmdbImageBaseUrl}${json['still_path']}' 
          : '',
      episodeNumber: json['episode_number'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      airDate: json['air_date'] as String? ?? '',
    );
  }
}
