import 'package:go_router/go_router.dart';
import 'pages/examples_tabs_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ExamplesTabsPage(),
    ),
  ],
);
