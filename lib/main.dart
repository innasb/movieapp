import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;
import 'presentation/cubits/settings_cubit.dart';
import 'presentation/cubits/settings_state.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/detail_page.dart';
import 'presentation/pages/player_page.dart';
import 'presentation/pages/main_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/tv_shows_page.dart';
import 'presentation/pages/tv_show_detail_page.dart';
import 'presentation/pages/anime_page.dart';
import 'presentation/pages/anime_detail_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: BlocProvider(
        create: (context) => di.sl<SettingsCubit>(),
        child: const WatchyApp(),
      ),
    ),
  );
}

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tv_shows',
              builder: (context, state) => const TvShowsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/anime',
              builder: (context, state) => const AnimePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return DetailPage(movieId: id);
      },
    ),
    GoRoute(
      path: '/tv_detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return TvShowDetailPage(tvShowId: id);
      },
    ),
    GoRoute(
      path: '/anime_detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return AnimeDetailPage(malId: id);
      },
    ),
    GoRoute(
      path: '/player/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return PlayerPage(id: id, isMovie: true);
      },
    ),
    GoRoute(
      path: '/player/tv/:id/:s/:e',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final s = int.tryParse(state.pathParameters['s'] ?? '') ?? 1;
        final e = int.tryParse(state.pathParameters['e'] ?? '') ?? 1;
        return PlayerPage(id: id, isMovie: false, season: s, episode: e);
      },
    ),
    GoRoute(
      path: '/player/anime/:id/:ep/:subOrDub',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final ep = int.tryParse(state.pathParameters['ep'] ?? '') ?? 1;
        final subOrDub = state.pathParameters['subOrDub'] ?? 'sub';
        return PlayerPage(
          id: id,
          isAnime: true,
          episodeNumber: ep,
          subOrDub: subOrDub,
        );
      },
    ),
  ],
);

class WatchyApp extends StatelessWidget {
  const WatchyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return MaterialApp.router(
          title: 'Watchy',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale:
              context.locale, // Or state.locale if overriding EasyLocalization
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
