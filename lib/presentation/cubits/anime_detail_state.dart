import 'package:equatable/equatable.dart';
import '../../domain/entities/anime_detail.dart';

abstract class AnimeDetailState extends Equatable {
  const AnimeDetailState();

  @override
  List<Object> get props => [];
}

class AnimeDetailInitial extends AnimeDetailState {}

class AnimeDetailLoading extends AnimeDetailState {}

class AnimeDetailLoaded extends AnimeDetailState {
  final AnimeDetail anime;
  final String subOrDub; // 'sub' or 'dub'

  const AnimeDetailLoaded({
    required this.anime,
    this.subOrDub = 'sub',
  });

  AnimeDetailLoaded copyWith({
    AnimeDetail? anime,
    String? subOrDub,
  }) {
    return AnimeDetailLoaded(
      anime: anime ?? this.anime,
      subOrDub: subOrDub ?? this.subOrDub,
    );
  }

  @override
  List<Object> get props => [anime, subOrDub];
}

class AnimeDetailError extends AnimeDetailState {
  final String message;

  const AnimeDetailError(this.message);

  @override
  List<Object> get props => [message];
}
