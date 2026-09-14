import 'heritage_api.dart';
import 'models/api_models.dart';

class AuthRepository {
  AuthRepository(this._api);
  final HeritageApi _api;
  Uri authorizeUri() => _api.mobileSsoAuthorizeUri();
  Future<RefreshData> refresh(String origin) => _api.refresh(origin);

  /// SSO 回调本身由认证服务处理；客户端只负责校验并消费这个 deep link。
  ({String accessToken, String refreshToken})? tokensFromCallback(Uri uri) {
    if (uri.scheme != 'intangibletrack' || uri.host != 'auth_callback') {
      return null;
    }
    final accessToken = uri.queryParameters['accessToken'];
    final refreshToken = uri.queryParameters['refreshToken'];
    if (accessToken == null || accessToken.isEmpty || refreshToken == null || refreshToken.isEmpty) return null;
    return (accessToken: accessToken, refreshToken: refreshToken);
  }
}

class RegionRepository {
  RegionRepository(this._api);
  final HeritageApi _api;
  Future<RegionList> list(ApiMapMode mode, {String? query}) =>
      _api.listRegions(mapMode: mode, query: query);
  Future<RegionDetail> detail(String code) => _api.getRegion(code);
  Future<SearchResult> search(
    String query, {
    ApiMapMode? mapMode,
    int limit = 10,
  }) => _api.search(query: query, mapMode: mapMode, limit: limit);
}

class HeritageRepository {
  HeritageRepository(this._api);
  final HeritageApi _api;
  Future<FilterOptions> filterOptions() => _api.filterOptions();
  Future<PageData<HeritageCard>> list({
    String? query,
    String? regionCode,
    List<HeritageLevel>? levels,
    List<String>? categories,
    String sort = 'DEFAULT',
    int page = 1,
    int pageSize = 20,
  }) => _api.listHeritage(
    query: query,
    regionCode: regionCode,
    levels: levels,
    categoryCodes: categories,
    sort: sort,
    page: page,
    pageSize: pageSize,
  );
  Future<HeritageDetail> detail(String id) => _api.getHeritage(id);
}

class UserRepository {
  UserRepository(this._api);
  final HeritageApi _api;
  Future<Me> me() => _api.me();
  Future<PageData<HeritageCard>> favorites({int page = 1, int pageSize = 20}) =>
      _api.favorites(page: page, pageSize: pageSize);
  Future<FavoriteState> favorite(String id) => _api.favorite(id);
  Future<void> unfavorite(String id) => _api.unfavorite(id);
  Future<PageData<Poster>> posters({int page = 1, int pageSize = 20}) =>
      _api.posters(page: page, pageSize: pageSize);
  Future<CreatedPoster> createPoster(String id) => _api.createPoster(id);
  Future<Poster> poster(String id) => _api.poster(id);
}
