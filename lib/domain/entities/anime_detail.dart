import 'package:equatable/equatable.dart';

class AnimeDetail extends Equatable {
  final int malId;
  final String title;
  final String titleJapanese;
  final String imageUrl;
  final String bannerUrl;
  final double score;
  final int episodes;
  final String synopsis;
  final List<String> genres;
  final String status;
  final String type;
  final bool airing;

  const AnimeDetail({
    required this.malId,
    required this.title,
    required this.titleJapanese,
    required this.imageUrl,
    required this.bannerUrl,
    required this.score,
    required this.episodes,
    required this.synopsis,
    required this.genres,
    required this.status,
    required this.type,
    required this.airing,
  });

  @override
  List<Object?> get props => [
    malId, title, titleJapanese, imageUrl, bannerUrl,
    score, episodes, synopsis, genres, status, type, airing,
  ];
}
