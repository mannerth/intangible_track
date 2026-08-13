import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'heritage_api.dart';
import 'http.dart';
import 'models/api_models.dart';
import 'repositories.dart';

final heritageApiProvider = Provider((ref) => HeritageApi());
final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(heritageApiProvider)),
);
final regionRepositoryProvider = Provider(
  (ref) => RegionRepository(ref.watch(heritageApiProvider)),
);
final heritageRepositoryProvider = Provider(
  (ref) => HeritageRepository(ref.watch(heritageApiProvider)),
);
final userRepositoryProvider = Provider(
  (ref) => UserRepository(ref.watch(heritageApiProvider)),
);

class SessionState {
  const SessionState({this.user, this.ready = false});
  final User? user;
  final bool ready;
  bool get signedIn => user != null;
}

class SessionController extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    await Http.instance.restoreSession();
    if (!Http.instance.isAuthenticated) return const SessionState(ready: true);
    try {
      return SessionState(
        user: (await ref.read(userRepositoryProvider).me()).user,
        ready: true,
      );
    } catch (_) {
      await Http.instance.clearSession();
      return const SessionState(ready: true);
    }
  }

  Future<void> completeDeepLink(Uri uri) async {
    final ticket = uri.queryParameters['ticket'];
    if (uri.scheme != 'intangibletrack' ||
        uri.host != 'auth_callback' ||
        ticket == null ||
        ticket.isEmpty) {
      throw const ApiException('登录回调缺少 ticket');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final login = await ref.read(authRepositoryProvider).exchange(ticket);
      await Http.instance.setAccessToken(login.accessToken);
      return SessionState(user: login.user, ready: true);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout(Http.baseUrl);
    state = const AsyncData(SessionState(ready: true));
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
final filterOptionsProvider = FutureProvider<FilterOptions>(
  (ref) => ref.watch(heritageRepositoryProvider).filterOptions(),
);
final meProvider = FutureProvider<Me>(
  (ref) => ref.watch(userRepositoryProvider).me(),
);
final favoritesProvider = FutureProvider<PageData<HeritageCard>>(
  (ref) => ref.watch(userRepositoryProvider).favorites(),
);
final postersProvider = FutureProvider<PageData<Poster>>(
  (ref) => ref.watch(userRepositoryProvider).posters(),
);
final heritageDetailProvider = FutureProvider.family<HeritageDetail, String>(
  (ref, id) => ref.watch(heritageRepositoryProvider).detail(id),
);
