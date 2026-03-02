import 'package:dio/dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../utils/config.dart';

class ApiClient {
  final Dio _dio;
  final Talker _talker;

  ApiClient(this._talker)
      : _dio = Dio(BaseOptions(
          baseUrl: Config.tmdbBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    // Add API key interceptor so it's fetched at request time, not instantiate time
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.queryParameters['api_key'] = Config.tmdbApiKey;
          return handler.next(options);
        },
      ),
    );
    _dio.interceptors.add(TalkerDioLogger(
        talker: _talker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printResponseMessage: true,
        ),
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
}
