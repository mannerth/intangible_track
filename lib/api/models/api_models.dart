typedef Json = Map<String, Object?>;

String _string(Json json, String key) => json[key]?.toString() ?? '';
int _int(Json json, String key) => (json[key] as num?)?.toInt() ?? 0;
bool _bool(Json json, String key) => json[key] as bool? ?? false;
Json _object(Object? value) => Map<String, Object?>.from(value! as Map);
List<Json> _objects(Object? value) =>
    (value as List? ?? const []).map((e) => _object(e)).toList();

class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    required this.requestId,
    required this.data,
  });
  final String code, message, requestId;
  final T data;
}

class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    required this.requestId,
  });
  final String code, message, requestId;
  factory ApiError.fromJson(Json j) => ApiError(
    code: _string(j, 'code'),
    message: _string(j, 'message'),
    requestId: _string(j, 'requestId'),
  );
}

class User {
  const User({required this.id, required this.campusId, required this.name});
  final String id, campusId, name;
  factory User.fromJson(Json j) => User(
    id: _string(j, 'id'),
    campusId: _string(j, 'campusId'),
    name: _string(j, 'name'),
  );
}

class LoginData {
  const LoginData({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });
  final String accessToken, tokenType;
  final int expiresIn;
  final User user;
  factory LoginData.fromJson(Json j) => LoginData(
    accessToken: _string(j, 'accessToken'),
    tokenType: _string(j, 'tokenType'),
    expiresIn: _int(j, 'expiresIn'),
    user: User.fromJson(_object(j['user'])),
  );
}

class RefreshData {
  const RefreshData({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });
  final String accessToken, tokenType;
  final int expiresIn;
  factory RefreshData.fromJson(Json j) => RefreshData(
    accessToken: _string(j, 'accessToken'),
    tokenType: _string(j, 'tokenType'),
    expiresIn: _int(j, 'expiresIn'),
  );
}

enum ApiMapMode {
  china('CHINA'),
  world('WORLD');

  const ApiMapMode(this.value);
  final String value;
}

enum HeritageLevel {
  world('WORLD'),
  national('NATIONAL'),
  provincial('PROVINCIAL');

  const HeritageLevel(this.value);
  final String value;
  static HeritageLevel from(String value) =>
      values.firstWhere((e) => e.value == value, orElse: () => national);
}

class LevelCounts {
  const LevelCounts({
    required this.world,
    required this.national,
    required this.provincial,
  });
  final int world, national, provincial;
  factory LevelCounts.fromJson(Json j) => LevelCounts(
    world: _int(j, 'WORLD'),
    national: _int(j, 'NATIONAL'),
    provincial: _int(j, 'PROVINCIAL'),
  );
}

class Region {
  const Region({
    required this.code,
    required this.type,
    required this.nameZh,
    required this.nameEn,
    this.description,
    this.mapKey,
    this.totalCount,
    this.levelCounts,
  });
  final String code, type, nameZh;
  final String? nameEn, description, mapKey;
  final int? totalCount;
  final LevelCounts? levelCounts;
  factory Region.fromJson(Json j) => Region(
    code: _string(j, 'code'),
    type: _string(j, 'type'),
    nameZh: _string(j, 'nameZh'),
    nameEn: j['nameEn']?.toString(),
    description: j['description']?.toString(),
    mapKey: j['mapKey']?.toString(),
    totalCount: (j['totalCount'] as num?)?.toInt(),
    levelCounts: j['levelCounts'] == null
        ? null
        : LevelCounts.fromJson(_object(j['levelCounts'])),
  );
}

class RegionList {
  const RegionList({required this.mapMode, required this.regions});
  final ApiMapMode mapMode;
  final List<Region> regions;
  factory RegionList.fromJson(Json j) => RegionList(
    mapMode: ApiMapMode.values.firstWhere(
      (v) => v.value == _string(j, 'mapMode'),
      orElse: () => ApiMapMode.china,
    ),
    regions: _objects(j['regions']).map(Region.fromJson).toList(),
  );
}

class RegionDetail {
  const RegionDetail({
    required this.region,
    required this.parent,
    required this.breadcrumb,
  });
  final Region region;
  final Region? parent;
  final List<Region> breadcrumb;
  factory RegionDetail.fromJson(Json j) => RegionDetail(
    region: Region.fromJson(j),
    parent: j['parent'] == null ? null : Region.fromJson(_object(j['parent'])),
    breadcrumb: _objects(j['breadcrumb']).map(Region.fromJson).toList(),
  );
}

class Location {
  const Location({
    required this.countryCode,
    this.provinceCode,
    this.cityCode,
    required this.displayText,
  });
  final String countryCode, displayText;
  final String? provinceCode, cityCode;
  factory Location.fromJson(Json j) => Location(
    countryCode: _string(j, 'countryCode'),
    provinceCode: j['provinceCode']?.toString(),
    cityCode: j['cityCode']?.toString(),
    displayText: _string(j, 'displayText'),
  );
}

class Badge {
  const Badge({required this.type, required this.code, required this.name});
  final String type, code, name;
  factory Badge.fromJson(Json j) => Badge(
    type: _string(j, 'type'),
    code: _string(j, 'code'),
    name: _string(j, 'name'),
  );
}

class HeritageCard {
  const HeritageCard({
    required this.id,
    required this.code,
    required this.nameZh,
    this.nameEn,
    required this.location,
    required this.summary,
    required this.coverImageUrl,
    required this.badges,
    this.isFavorited,
  });
  final String id, code, nameZh, summary, coverImageUrl;
  final String? nameEn;
  final Location location;
  final List<Badge> badges;
  final bool? isFavorited;
  factory HeritageCard.fromJson(Json j) => HeritageCard(
    id: _string(j, 'id'),
    code: _string(j, 'code'),
    nameZh: _string(j, 'nameZh'),
    nameEn: j['nameEn']?.toString(),
    location: Location.fromJson(_object(j['location'])),
    summary: _string(j, 'summary'),
    coverImageUrl: _string(j, 'coverImageUrl'),
    badges: _objects(j['badges']).map(Badge.fromJson).toList(),
    isFavorited: j['isFavorited'] as bool?,
  );
}

class Designation {
  const Designation({
    required this.level,
    required this.year,
    this.batchName,
    this.authority,
  });
  final HeritageLevel level;
  final int year;
  final String? batchName, authority;
  factory Designation.fromJson(Json j) => Designation(
    level: HeritageLevel.from(_string(j, 'level')),
    year: _int(j, 'year'),
    batchName: j['batchName']?.toString(),
    authority: j['authority']?.toString(),
  );
}

class HeritageCategory {
  const HeritageCategory({required this.code, required this.nameZh});
  final String code, nameZh;
  factory HeritageCategory.fromJson(Json j) =>
      HeritageCategory(code: _string(j, 'code'), nameZh: _string(j, 'nameZh'));
}

class ProcessStep {
  const ProcessStep({
    required this.id,
    required this.sequence,
    required this.title,
    required this.description,
    this.imageUrl,
    this.posterIconUrl,
    this.posterCaption,
  });
  final String id, title, description;
  final int sequence;
  final String? imageUrl, posterIconUrl, posterCaption;
  factory ProcessStep.fromJson(Json j) => ProcessStep(
    id: _string(j, 'id'),
    sequence: _int(j, 'sequence'),
    title: _string(j, 'title'),
    description: _string(j, 'description'),
    imageUrl: j['imageUrl']?.toString(),
    posterIconUrl: j['posterIconUrl']?.toString(),
    posterCaption: j['posterCaption']?.toString(),
  );
}

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    required this.title,
    this.description,
    required this.altText,
    this.durationSeconds,
    required this.sortOrder,
  });
  final String id, type, url, title, altText;
  final String? thumbnailUrl, description;
  final int? durationSeconds;
  final int sortOrder;
  factory MediaAsset.fromJson(Json j) => MediaAsset(
    id: _string(j, 'id'),
    type: _string(j, 'type'),
    url: _string(j, 'url'),
    thumbnailUrl: j['thumbnailUrl']?.toString(),
    title: _string(j, 'title'),
    description: j['description']?.toString(),
    altText: _string(j, 'altText'),
    durationSeconds: (j['durationSeconds'] as num?)?.toInt(),
    sortOrder: _int(j, 'sortOrder'),
  );
}

class HeritageDetail {
  const HeritageDetail({
    required this.card,
    required this.fullDescription,
    required this.heroImageUrl,
    required this.posterQuote,
    required this.posterSummary,
    required this.designations,
    required this.categories,
    required this.processSteps,
    required this.mediaAssets,
    required this.contentVersion,
    required this.updatedAt,
  });
  final HeritageCard card;
  final String fullDescription,
      heroImageUrl,
      posterQuote,
      posterSummary,
      updatedAt;
  final List<Designation> designations;
  final List<HeritageCategory> categories;
  final List<ProcessStep> processSteps;
  final List<MediaAsset> mediaAssets;
  final int contentVersion;
  factory HeritageDetail.fromJson(Json j) => HeritageDetail(
    card: HeritageCard.fromJson(j),
    fullDescription: _string(j, 'fullDescription'),
    heroImageUrl: _string(j, 'heroImageUrl'),
    posterQuote: _string(j, 'posterQuote'),
    posterSummary: _string(j, 'posterSummary'),
    designations: _objects(
      j['designations'],
    ).map(Designation.fromJson).toList(),
    categories: _objects(
      j['categories'],
    ).map(HeritageCategory.fromJson).toList(),
    processSteps: _objects(
      j['processSteps'],
    ).map(ProcessStep.fromJson).toList(),
    mediaAssets: _objects(j['mediaAssets']).map(MediaAsset.fromJson).toList(),
    contentVersion: _int(j, 'contentVersion'),
    updatedAt: _string(j, 'updatedAt'),
  );
}

class PageData<T> {
  const PageData({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });
  final List<T> items;
  final int page, pageSize, total, totalPages;
  factory PageData.fromJson(Json j, T Function(Json) decode) => PageData(
    items: _objects(j['items']).map(decode).toList(),
    page: _int(j, 'page'),
    pageSize: _int(j, 'pageSize'),
    total: _int(j, 'total'),
    totalPages: _int(j, 'totalPages'),
  );
}

class FilterOption {
  const FilterOption({
    required this.code,
    required this.nameZh,
    this.description,
    required this.displayOrder,
  });
  final String code, nameZh;
  final String? description;
  final int displayOrder;
  factory FilterOption.fromJson(Json j) => FilterOption(
    code: _string(j, 'code'),
    nameZh: _string(j, 'nameZh'),
    description: j['description']?.toString(),
    displayOrder: _int(j, 'displayOrder'),
  );
}

class FilterOptions {
  const FilterOptions({required this.levels, required this.categories});
  final List<FilterOption> levels, categories;
  factory FilterOptions.fromJson(Json j) => FilterOptions(
    levels: _objects(j['levels']).map(FilterOption.fromJson).toList(),
    categories: _objects(j['categories']).map(FilterOption.fromJson).toList(),
  );
}

class SearchResult {
  const SearchResult({required this.regions, required this.heritageItems});
  final List<Region> regions;
  final List<HeritageCard> heritageItems;
  factory SearchResult.fromJson(Json j) => SearchResult(
    regions: _objects(j['regions']).map(Region.fromJson).toList(),
    heritageItems: _objects(
      j['heritageItems'],
    ).map(HeritageCard.fromJson).toList(),
  );
}

class Me {
  const Me({
    required this.user,
    required this.favoriteCount,
    required this.posterCount,
    required this.lastLoginAt,
  });
  final User user;
  final int favoriteCount, posterCount;
  final String lastLoginAt;
  factory Me.fromJson(Json j) => Me(
    user: User.fromJson(j),
    favoriteCount: _int(j, 'favoriteCount'),
    posterCount: _int(j, 'posterCount'),
    lastLoginAt: _string(j, 'lastLoginAt'),
  );
}

class FavoriteState {
  const FavoriteState({
    required this.heritageId,
    required this.isFavorited,
    required this.favoritedAt,
  });
  final String heritageId, favoritedAt;
  final bool isFavorited;
  factory FavoriteState.fromJson(Json j) => FavoriteState(
    heritageId: _string(j, 'heritageId'),
    isFavorited: _bool(j, 'isFavorited'),
    favoritedAt: _string(j, 'favoritedAt'),
  );
}

class PosterHeritage {
  const PosterHeritage({
    required this.id,
    required this.code,
    required this.nameZh,
    required this.coverImageUrl,
  });
  final String id, code, nameZh, coverImageUrl;
  factory PosterHeritage.fromJson(Json j) => PosterHeritage(
    id: _string(j, 'id'),
    code: _string(j, 'code'),
    nameZh: _string(j, 'nameZh'),
    coverImageUrl: _string(j, 'coverImageUrl'),
  );
}

class Poster {
  const Poster({
    required this.id,
    required this.heritageItem,
    required this.status,
    required this.thumbnailUrl,
    required this.assetUrlExpiresAt,
    required this.templateVersion,
    required this.contentVersion,
    required this.generatedAt,
    this.imageUrl,
  });
  final String id,
      status,
      thumbnailUrl,
      assetUrlExpiresAt,
      templateVersion,
      generatedAt;
  final PosterHeritage heritageItem;
  final int contentVersion;
  final String? imageUrl;
  factory Poster.fromJson(Json j) => Poster(
    id: _string(j, 'id'),
    heritageItem: PosterHeritage.fromJson(_object(j['heritageItem'])),
    status: _string(j, 'status'),
    thumbnailUrl: _string(j, 'thumbnailUrl'),
    assetUrlExpiresAt: _string(j, 'assetUrlExpiresAt'),
    templateVersion: _string(j, 'templateVersion'),
    contentVersion: _int(j, 'contentVersion'),
    generatedAt: _string(j, 'generatedAt'),
    imageUrl: j['imageUrl']?.toString(),
  );
}

class CreatedPoster {
  const CreatedPoster({required this.reused, required this.poster});
  final bool reused;
  final Poster poster;
  factory CreatedPoster.fromJson(Json j) => CreatedPoster(
    reused: _bool(j, 'reused'),
    poster: Poster.fromJson(_object(j['poster'])),
  );
}
