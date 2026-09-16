import 'package:flutter_test/flutter_test.dart';

import 'package:intangible_track/api/http.dart';
import 'package:intangible_track/api/models/api_models.dart' as api;

void main() {
  group('asset url resolution', () {
    test('relative signed url is resolved against the API origin', () {
      const relative =
          '/api/v1/assets/posters/01a0aabd5ff5?expires=1789574280&signature=abc';
      expect(
        Http.resolveAssetUrl(relative),
        'http://localhost:9100/api/v1/assets/posters/01a0aabd5ff5'
        '?expires=1789574280&signature=abc',
      );
    });

    test('absolute and empty urls stay untouched', () {
      expect(
        Http.resolveAssetUrl('https://cdn.example.com/a.png'),
        'https://cdn.example.com/a.png',
      );
      expect(Http.resolveAssetUrl(''), '');
    });

    test('poster json exposes absolute thumbnail and image urls', () {
      final poster = api.Poster.fromJson({
        'id': '01a0aabd-5ff5-70a6-bb28-ad440f4c4c4b',
        'heritageItem': {
          'id': '019c9f00-0000-7000-8000-001000011000',
          'code': 'HAN_EMBROIDERY',
          'nameZh': '汉绣',
          'coverImageUrl': 'https://picsum.photos/seed/han/800/600',
        },
        'status': 'READY',
        'thumbnailUrl': '/api/v1/assets/posters/thumb-id?expires=1&signature=t',
        'assetUrlExpiresAt': '2026-09-16T15:58:00Z',
        'templateVersion': 'heritage-poster-v3',
        'contentVersion': 1,
        'generatedAt': '2026-09-16T15:48:00Z',
        'imageUrl': '/api/v1/assets/posters/original-id?expires=1&signature=o',
      });

      expect(
        poster.thumbnailUrl,
        'http://localhost:9100/api/v1/assets/posters/thumb-id'
        '?expires=1&signature=t',
      );
      expect(
        poster.imageUrl,
        'http://localhost:9100/api/v1/assets/posters/original-id'
        '?expires=1&signature=o',
      );
    });
  });
}
