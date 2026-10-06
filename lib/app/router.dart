import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../core/supabase/supabase_client.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/shell/presentation/shell_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(
    SupabaseConfig.isConfigured ? SupabaseConfig.client.auth.onAuthStateChange : const Stream.empty(),
  ),
  redirect: (context, state) {
    final loggedIn = SupabaseConfig.isConfigured && SupabaseConfig.client.auth.currentSession != null;
    final authRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    if (!SupabaseConfig.isConfigured) return state.matchedLocation;
    if (!loggedIn && !authRoute) return '/login';
    if (loggedIn && authRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ShellPage()),
    GoRoute(path: '/login', builder: (context, state) => const AuthPage()),
    GoRoute(path: '/register', builder: (context, state) => const AuthPage(register: true)),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _sub;
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}
