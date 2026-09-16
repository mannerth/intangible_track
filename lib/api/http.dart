import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用 HTTP 客户端。默认通过 adb reverse 连接电脑上的本地后端；发布或
/// 真机/iOS 联调时以
/// `--dart-define=API_BASE_URL=https://host/api/v1` 覆盖。
class Http {
  Http._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
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
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 ||
              error.requestOptions.path.endsWith('/auth/refresh') ||
              _refreshToken == null ||
              _refreshToken!.isEmpty ||
              error.requestOptions.extra['authRetry'] == true) {
            handler.next(error);
            return;
          }
          try {
            await refreshAccessToken();
            final request = error.requestOptions;
            request.extra['authRetry'] = true;
            request.headers['Authorization'] = 'Bearer $_accessToken';
            handler.resolve(await _dio.fetch(request));
          } catch (_) {
            await clearSession();
            handler.next(error);
          }
        },
      ),
    );
  }

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:9100/api/v1',
  );

  /// 接口返回的资源地址可能是相对 API 根路径的相对地址（以 `/` 开头，
  /// 例如海报签名地址），这里统一补全为可直接访问的绝对地址。
  static String resolveAssetUrl(String value) {
    if (value.isEmpty) return value;
    final parsed = Uri.tryParse(value);
    if (parsed == null || parsed.hasScheme) return value;
    final base = Uri.parse(baseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: parsed.path,
      query: parsed.hasQuery ? parsed.query : null,
    ).toString();
  }

  static final Http instance = Http._();

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  Future<void>? _refreshFuture;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken?.isNotEmpty ?? false;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await (await SharedPreferences.getInstance()).setString(_tokenKey, token);
  }

  Future<void> setSession({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessToken = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    if (_refreshToken != null) {
      await prefs.setString(_refreshTokenKey, _refreshToken!);
    }
  }

  Future<void> refreshAccessToken() {
    return _refreshFuture ??= _performRefresh().whenComplete(
      () => _refreshFuture = null,
    );
  }

  Future<void> _performRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('登录会话已失效');
    }
    final response = await _dio.post(
      '/auth/refresh',
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
    final body = response.data;
    final data = Map<String, Object?>.from(body['data'] as Map);
    await setSession(
      accessToken: data['accessToken'].toString(),
      refreshToken: data['refreshToken']?.toString(),
    );
  }

  Future<void> clearSession() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    _refreshToken = null;
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
  static const _refreshTokenKey = 'api_refresh_token';
  static Map<String, dynamic>? _withoutNulls(Map<String, dynamic>? map) {
    if (map == null) return null;
    return {...map}..removeWhere((_, value) => value == null || value == '');
  }
}
