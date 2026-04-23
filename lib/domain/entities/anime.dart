import 'package:equatable/equatable.dart';

class Anime extends Equatable {
  final int malId;
  final String title;
  final String imageUrl;
  final double score;
  final int episodes;
  final String type;
  final bool airing;

  const Anime({
    required this.malId,
    required this.title,
    required this.imageUrl,
    required this.score,
    required this.episodes,
    required this.type,
    required this.airing,
  });

  @override
  List<Object?> get props => [malId, title, imageUrl, score, episodes, type, airing];
}
