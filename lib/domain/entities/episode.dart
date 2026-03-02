import 'package:equatable/equatable.dart';

class Episode extends Equatable {
  final int id;
  final String name;
  final String overview;
  final String stillPath;
  final int episodeNumber;
  final int seasonNumber;
  final double voteAverage;
  final String airDate;

  const Episode({
    required this.id,
    required this.name,
    required this.overview,
    required this.stillPath,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.voteAverage,
    required this.airDate,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        overview,
        stillPath,
        episodeNumber,
        seasonNumber,
        voteAverage,
        airDate,
      ];
}
