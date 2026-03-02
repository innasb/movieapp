import '../../domain/entities/tv_show.dart';
import '../../core/utils/config.dart';

class TvShowModel extends TvShow {
  const TvShowModel({
    required super.id,
    required super.name,
    required super.posterPath,
    required super.backdropPath,
    required super.voteAverage,
    required super.firstAirDate,
  });

  factory TvShowModel.fromJson(Map<String, dynamic> json) {
    return TvShowModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['original_name'] as String? ?? 'Unknown TV Show',
      posterPath: json['poster_path'] != null 
          ? '${Config.tmdbImageBaseUrl}${json['poster_path']}' 
          : '',
      backdropPath: json['backdrop_path'] != null 
          ? '${Config.tmdbImageBaseUrl}${json['backdrop_path']}' 
          : '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      firstAirDate: json['first_air_date'] as String? ?? '',
    );
  }
}
