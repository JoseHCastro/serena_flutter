import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final SecureStorage _storage;
  final Dio _dio;
  Dio? _refreshDio;

  AuthInterceptor({required SecureStorage storage, required Dio dio})
      : _storage = storage,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final newToken = await _tryRefresh();
      if (newToken != null) {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {
          // Fall through to forward the original error
        }
      }
    }
    handler.next(err);
  }

  Future<String?> _tryRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return null;

    _refreshDio ??= Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

    try {
      final response = await _refreshDio!.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );
      final newAccess = response.data['access_token'] as String;
      final newRefresh = response.data['refresh_token'] as String;
      await _storage.saveTokens(newAccess, newRefresh);
      return newAccess;
    } catch (_) {
      await _storage.clearTokens();
      return null;
    }
  }
}
