import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Fetch from environment variables.
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbImageBaseUrlOrig =
      'https://image.tmdb.org/t/p/original';

  static const String vidlinkBaseUrl = 'https://vidlink.pro';

  static const String jikanBaseUrl = 'https://api.jikan.moe/v4';
}
