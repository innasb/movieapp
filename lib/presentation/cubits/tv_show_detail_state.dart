import 'package:equatable/equatable.dart';
import '../../domain/entities/tv_show_detail.dart';
import '../../domain/entities/episode.dart';

abstract class TvShowDetailState extends Equatable {
  const TvShowDetailState();

  @override
  List<Object> get props => [];
}

class TvShowDetailInitial extends TvShowDetailState {}

class TvShowDetailLoading extends TvShowDetailState {}

class TvShowDetailLoaded extends TvShowDetailState {
  final TvShowDetail tvShow;
  final int selectedSeasonNumber;
  final List<Episode> currentSeasonEpisodes;
  final bool isEpisodesLoading;

  const TvShowDetailLoaded({
    required this.tvShow,
    required this.selectedSeasonNumber,
    this.currentSeasonEpisodes = const [],
    this.isEpisodesLoading = false,
  });

  TvShowDetailLoaded copyWith({
    TvShowDetail? tvShow,
    int? selectedSeasonNumber,
    List<Episode>? currentSeasonEpisodes,
    bool? isEpisodesLoading,
  }) {
    return TvShowDetailLoaded(
      tvShow: tvShow ?? this.tvShow,
      selectedSeasonNumber: selectedSeasonNumber ?? this.selectedSeasonNumber,
      currentSeasonEpisodes: currentSeasonEpisodes ?? this.currentSeasonEpisodes,
      isEpisodesLoading: isEpisodesLoading ?? this.isEpisodesLoading,
    );
  }

  @override
  List<Object> get props => [
    tvShow, 
    selectedSeasonNumber, 
    currentSeasonEpisodes, 
    isEpisodesLoading
  ];
}

class TvShowDetailError extends TvShowDetailState {
  final String message;

  const TvShowDetailError(this.message);

  @override
  List<Object> get props => [message];
}
