import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用 HTTP 客户端。默认连接 Apifox Mock；发布或局域网联调时以
/// `--dart-define=API_BASE_URL=https://host/api/v1` 覆盖。
class Http {
  Http._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final value = _accessToken;
          if (value != null && value.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $value';
          }
          handler.next(options);
        },
      ),
    );
  }

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4523/m1/8643781-8424770-default',
  );
  static final Http instance = Http._();

  late final Dio _dio;
  String? _accessToken;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken?.isNotEmpty ?? false;

  Future<void> restoreSession() async {
    _accessToken = (await SharedPreferences.getInstance()).getString(_tokenKey);
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await (await SharedPreferences.getInstance()).setString(_tokenKey, token);
  }

  Future<void> clearSession() async {
    _accessToken = null;
    await (await SharedPreferences.getInstance()).remove(_tokenKey);
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: _withoutNulls(query));
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) => _dio.post(
    path,
    data: data,
    queryParameters: _withoutNulls(query),
    options: Options(headers: headers),
  );
  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _dio.put(path, data: data);
  Future<Response<dynamic>> delete(String path) => _dio.delete(path);

  static const _tokenKey = 'api_access_token';
  static Map<String, dynamic>? _withoutNulls(Map<String, dynamic>? map) {
    if (map == null) return null;
    return {...map}..removeWhere((_, value) => value == null || value == '');
  }
}
