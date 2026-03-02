import 'package:equatable/equatable.dart';

import 'season.dart';

class TvShowDetail extends Equatable {
  final int id;
  final String name;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final String firstAirDate;
  final String overview;
  final List<String> genres;
  final List<Season> seasons;

  const TvShowDetail({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.firstAirDate,
    required this.overview,
    required this.genres,
    required this.seasons,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        posterPath,
        backdropPath,
        voteAverage,
        firstAirDate,
        overview,
        genres,
        seasons,
      ];
}
