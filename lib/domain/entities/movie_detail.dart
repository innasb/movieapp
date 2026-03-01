import 'package:equatable/equatable.dart';

class MovieDetail extends Equatable {
  final int id;
  final String title;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final String releaseDate;
  final String overview;
  final List<String> genres;
  final int runtime;

  const MovieDetail({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.overview,
    required this.genres,
    required this.runtime,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        posterPath,
        backdropPath,
        voteAverage,
        releaseDate,
        overview,
        genres,
        runtime,
      ];
}
