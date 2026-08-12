import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/pages/discover_page.dart';
import '../ui/pages/favorites_page.dart';
import '../ui/pages/heritage_detail_page.dart';
import '../ui/pages/login_page.dart';
import '../ui/pages/map_page.dart';
import '../ui/pages/profile_page.dart';
import '../ui/pages/province_detail_page.dart';
import '../ui/shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/map',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                name: 'map',
                builder: (context, state) => const MapPage(),
                routes: [
                  GoRoute(
                    path: 'province',
                    name: 'provinceDetail',
                    builder: (context, state) => const ProvinceDetailPage(),
                  ),
                  GoRoute(
                    path: 'heritage',
                    name: 'heritageDetail',
                    builder: (context, state) => HeritageDetailPage(
                      title: state.extra as String? ?? '非遗详情',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                name: 'discover',
                builder: (context, state) => const DiscoverPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'favorites',
                    name: 'favorites',
                    builder: (context, state) => const FavoritesPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
});
