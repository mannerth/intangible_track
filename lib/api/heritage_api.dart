import 'dart:math';
import 'models/api_models.dart';
import 'http.dart';

/// 强类型 API client：所有 OpenAPI 操作均落在 repository 中调用此类。
class HeritageApi {
  HeritageApi({Http? http}) : _http = http ?? Http.instance;
  final Http _http;

  Future<T> _decode<T>(
    Future<dynamic> request,
    T Function(Json) fromJson,
  ) async {
    final response = await request;
    final body = response.data;
    if (body is! Map || body['data'] is! Map) {
      throw const ApiException('接口返回格式不正确');
    }
    return fromJson(Map<String, Object?>.from(body['data'] as Map));
  }

  Uri ssoAuthorizeUri({String returnPath = '/profile'}) => Uri.parse(
    '${Http.baseUrl}/auth/sso/authorize',
  ).replace(queryParameters: {'returnPath': returnPath});
  Future<LoginData> exchangeLoginTicket(String ticket) => _decode(
    _http.post('/auth/sso/exchange', data: {'loginTicket': ticket}),
    LoginData.fromJson,
  );
  Future<RefreshData> refresh(String origin) => _decode(
    _http.post('/auth/refresh', headers: {'Origin': origin}),
    RefreshData.fromJson,
  );
  Future<void> logout(String origin) async {
    await _http.post('/auth/logout', headers: {'Origin': origin});
    await _http.clearSession();
  }

  Future<RegionList> listRegions({
    required ApiMapMode mapMode,
    String? query,
  }) => _decode(
    _http.get('/regions', query: {'mapMode': mapMode.value, 'q': query}),
    RegionList.fromJson,
  );
  Future<RegionDetail> getRegion(String code) =>
      _decode(_http.get('/regions/$code'), RegionDetail.fromJson);
  Future<SearchResult> search({
    required String query,
    ApiMapMode? mapMode,
    int limit = 10,
  }) => _decode(
    _http.get(
      '/search',
      query: {'q': query, 'mapMode': mapMode?.value, 'limit': limit},
    ),
    SearchResult.fromJson,
  );
  Future<FilterOptions> filterOptions() =>
      _decode(_http.get('/heritage/filter-options'), FilterOptions.fromJson);
  Future<PageData<HeritageCard>> listHeritage({
    String? query,
    String? regionCode,
    List<HeritageLevel>? levels,
    List<String>? categoryCodes,
    String sort = 'DEFAULT',
    int page = 1,
    int pageSize = 20,
  }) => _decode(
    _http.get(
      '/heritage-items',
      query: {
        'q': query,
        'regionCode': regionCode,
        'levels': levels?.map((e) => e.value).join(','),
        'categoryCodes': categoryCodes?.join(','),
        'sort': sort,
        'page': page,
        'pageSize': pageSize,
      },
    ),
    (j) => PageData.fromJson(j, HeritageCard.fromJson),
  );
  Future<HeritageDetail> getHeritage(String id) =>
      _decode(_http.get('/heritage-items/$id'), HeritageDetail.fromJson);
  Future<Me> me() => _decode(_http.get('/me'), Me.fromJson);
  Future<PageData<HeritageCard>> favorites({int page = 1, int pageSize = 20}) =>
      _decode(
        _http.get('/me/favorites', query: {'page': page, 'pageSize': pageSize}),
        (j) => PageData.fromJson(j, HeritageCard.fromJson),
      );
  Future<FavoriteState> favorite(String id) =>
      _decode(_http.put('/me/favorites/$id'), FavoriteState.fromJson);
  Future<void> unfavorite(String id) => _http.delete('/me/favorites/$id');
  Future<PageData<Poster>> posters({int page = 1, int pageSize = 20}) =>
      _decode(
        _http.get('/me/posters', query: {'page': page, 'pageSize': pageSize}),
        (j) => PageData.fromJson(j, Poster.fromJson),
      );
  Future<CreatedPoster> createPoster(String heritageId) => _decode(
    _http.post(
      '/me/posters',
      data: {'heritageId': heritageId},
      headers: {
        'Idempotency-Key':
            'flutter-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}',
      },
    ),
    CreatedPoster.fromJson,
  );
  Future<Poster> poster(String id) =>
      _decode(_http.get('/me/posters/$id'), Poster.fromJson);
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
