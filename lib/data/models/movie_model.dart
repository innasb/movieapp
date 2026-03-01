import '../../domain/entities/movie.dart';
import '../../core/utils/config.dart';

class MovieModel extends Movie {
  const MovieModel({
    required super.id,
    required super.title,
    required super.posterPath,
    required super.backdropPath,
    required super.voteAverage,
    required super.releaseDate,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
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
    );
  }
}
