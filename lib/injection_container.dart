import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/services/search_history_service.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/movie_remote_data_source.dart';
import 'data/repositories/movie_repository_impl.dart';
import 'domain/repositories/movie_repository.dart';
import 'domain/usecases/get_categories.dart';
import 'domain/usecases/get_movie_detail.dart';
import 'domain/usecases/get_movies_by_category.dart';
import 'domain/usecases/get_recent_movies.dart';
import 'domain/usecases/get_trending_movies.dart';
import 'domain/usecases/get_top_rated_movies.dart';
import 'domain/usecases/search_movies.dart';
import 'presentation/cubits/home_cubit.dart';
import 'presentation/cubits/movie_detail_cubit.dart';

import 'data/datasources/tv_remote_data_source.dart';
import 'data/repositories/tv_repository_impl.dart';
import 'domain/repositories/tv_repository.dart';
import 'domain/usecases/get_season_episodes.dart';
import 'domain/usecases/get_tv_show_detail.dart';
import 'domain/usecases/get_trending_tv_shows.dart';
import 'domain/usecases/get_top_rated_tv_shows.dart';
import 'domain/usecases/search_tv_shows.dart';
import 'presentation/cubits/tv_shows_cubit.dart';
import 'presentation/cubits/tv_show_detail_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/cubits/settings_cubit.dart';

// Anime imports
import 'data/datasources/anime_remote_data_source.dart';
import 'data/repositories/anime_repository_impl.dart';
import 'domain/repositories/anime_repository.dart';
import 'domain/usecases/get_top_anime.dart';
import 'domain/usecases/search_anime.dart';
import 'domain/usecases/get_anime_detail.dart';
import 'presentation/cubits/anime_cubit.dart';
import 'presentation/cubits/anime_detail_cubit.dart';

// Watch Together imports
import 'data/datasources/room_remote_data_source.dart';
import 'data/datasources/chat_remote_data_source.dart';
import 'presentation/cubits/watch_room_cubit.dart';
import 'presentation/cubits/chat_cubit.dart';
import 'presentation/cubits/call_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Talker Config
  final talker = TalkerFlutter.init();
  sl.registerLazySingleton(() => talker);

  Bloc.observer = TalkerBlocObserver(talker: talker);

  // Cubits
  sl.registerFactory(() => SettingsCubit(sl()));
  sl.registerFactory(
    () => HomeCubit(
      getRecentMovies: sl(),
      getTrendingMovies: sl(),
      getTopRatedMovies: sl(),
      getCategories: sl(),
      getMoviesByCategory: sl(),
      searchMovies: sl(),
      talker: sl(),
    ),
  );
  sl.registerFactory(
    () => MovieDetailCubit(getMovieDetail: sl(), talker: sl()),
  );
  sl.registerFactory(
    () => TvShowsCubit(
      getTrendingTvShows: sl(),
      getTopRatedTvShows: sl(),
      searchTvShows: sl(),
      talker: sl(),
    ),
  );
  sl.registerFactory(
    () => TvShowDetailCubit(
      getTvShowDetail: sl(),
      getSeasonEpisodes: sl(),
      talker: sl(),
    ),
  );
  sl.registerFactory(
    () => AnimeCubit(
      getTopAnime: sl(),
      searchAnime: sl(),
      talker: sl(),
    ),
  );
  sl.registerFactory(
    () => AnimeDetailCubit(
      getAnimeDetail: sl(),
      talker: sl(),
    ),
  );

  // Watch Together Cubits
  sl.registerFactory(
    () => WatchRoomCubit(
      roomDataSource: sl(),
      chatDataSource: sl(),
    ),
  );
  sl.registerFactory(
    () => ChatCubit(chatDataSource: sl()),
  );
  sl.registerFactory(() => CallCubit());

  // Use Cases
  sl.registerLazySingleton(() => GetRecentMovies(sl()));
  sl.registerLazySingleton(() => GetTrendingMovies(sl()));
  sl.registerLazySingleton(() => GetTopRatedMovies(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetMoviesByCategory(sl()));
  sl.registerLazySingleton(() => GetMovieDetail(sl()));
  sl.registerLazySingleton(() => SearchMovies(sl()));
  
  sl.registerLazySingleton(() => GetTrendingTvShows(sl()));
  sl.registerLazySingleton(() => GetTopRatedTvShows(sl()));
  sl.registerLazySingleton(() => GetTvShowDetail(sl()));
  sl.registerLazySingleton(() => GetSeasonEpisodes(sl()));
  sl.registerLazySingleton(() => SearchTvShows(sl()));

  sl.registerLazySingleton(() => GetTopAnime(sl()));
  sl.registerLazySingleton(() => SearchAnime(sl()));
  sl.registerLazySingleton(() => GetAnimeDetail(sl()));

  // Repository
  sl.registerLazySingleton<MovieRepository>(() => MovieRepositoryImpl(sl()));
  sl.registerLazySingleton<TvRepository>(() => TvRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<AnimeRepository>(() => AnimeRepositoryImpl(remoteDataSource: sl()));

  // Data Sources
  sl.registerLazySingleton<MovieRemoteDataSource>(
    () => MovieRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<TvRemoteDataSource>(
    () => TvRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AnimeRemoteDataSource>(
    () => AnimeRemoteDataSourceImpl(sl()),
  );

  // Core
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton(() => SearchHistoryService(sl()));
  sl.registerLazySingleton(() => NotificationService());

  // Watch Together Data Sources
  sl.registerLazySingleton(() => RoomRemoteDataSource());
  sl.registerLazySingleton(() => ChatRemoteDataSource());
}
