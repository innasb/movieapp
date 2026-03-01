import '../../domain/entities/movie_detail.dart';
import '../../core/utils/config.dart';

class MovieDetailModel extends MovieDetail {
  const MovieDetailModel({
    required super.id,
    required super.title,
    required super.posterPath,
    required super.backdropPath,
    required super.voteAverage,
    required super.releaseDate,
    required super.overview,
    required super.genres,
    required super.runtime,
  });

  factory MovieDetailModel.fromJson(Map<String, dynamic> json) {
    return MovieDetailModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      posterPath: json['poster_path'] != null
          ? '${Config.tmdbImageBaseUrl}${json['poster_path']}'
          : '',
      backdropPath: json['backdrop_path'] != null
          ? '${Config.tmdbImageBaseUrlOrig}${json['backdrop_path']}'
          : '',
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      releaseDate: json['release_date'] ?? '',
      overview: json['overview'] ?? '',
      genres: (json['genres'] as List? ?? [])
          .map((genre) => genre['name'].toString())
          .toList(),
      runtime: json['runtime'] ?? 0,
    );
  }
}
