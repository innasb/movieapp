import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../domain/usecases/get_movie_detail.dart';
import 'movie_detail_state.dart';

class MovieDetailCubit extends Cubit<MovieDetailState> {
  final GetMovieDetail getMovieDetail;
  final Talker talker;

  MovieDetailCubit({required this.getMovieDetail, required this.talker}) : super(MovieDetailInitial());

  Future<void> loadMovieDetail(int id) async {
    emit(MovieDetailLoading());
    try {
      final movie = await getMovieDetail.execute(id);
      emit(MovieDetailLoaded(movie));
    } catch (e, st) {
      talker.handle(e, st, 'Failed to load movie details for ID $id');
      emit(MovieDetailError(e.toString()));
    }
  }
}
