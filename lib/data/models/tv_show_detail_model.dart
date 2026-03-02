import '../../domain/entities/tv_show_detail.dart';
import '../../core/utils/config.dart';
import 'season_model.dart';

class TvShowDetailModel extends TvShowDetail {
  const TvShowDetailModel({
    required super.id,
    required super.name,
    required super.posterPath,
    required super.backdropPath,
    required super.voteAverage,
    required super.firstAirDate,
    required super.overview,
    required super.genres,
    required super.seasons,
  });

  factory TvShowDetailModel.fromJson(Map<String, dynamic> json) {
    var genreList = json['genres'] as List? ?? [];
    List<String> parsedGenres =
        genreList.map((g) => g['name'] as String).toList();

    var seasonList = json['seasons'] as List? ?? [];
    List<SeasonModel> parsedSeasons =
        seasonList.map((s) => SeasonModel.fromJson(s as Map<String, dynamic>)).toList();

    return TvShowDetailModel(
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
      overview: json['overview'] as String? ?? '',
      genres: parsedGenres,
      seasons: parsedSeasons,
    );
  }
}
