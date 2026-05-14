import 'package:go_router/go_router.dart';
import 'lib/screens/about_page.dart';
import 'lib/screens/badge_detail_page.dart';
import 'lib/screens/login_page.dart';
import 'lib/screens/main_page.dart';
import 'lib/screens/profile_page.dart';
import 'lib/screens/notifications_page.dart';
import 'lib/screens/help_page.dart';
import 'lib/screens/ranking_page.dart';
import 'lib/screens/candidaturas.dart';
import 'lib/screens/badges_page.dart';
import 'lib/screens/options_page.dart';
import 'lib/screens/change_password.dart';
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>  LoginPage(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) =>  MainPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfilePage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationsPage(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const AjudaPage(),
    ),
    GoRoute(
      path: '/ranking',
      builder: (context, state) =>  RankingPage(),
    ),
    GoRoute(
      path: '/options',
      builder: (context, state) => const OptionsPage(),
    ),
    GoRoute(
      path: '/candidaturas',
      builder: (context, state) => const CandidaturasPage(),
    ),
    GoRoute(
      path: '/badges',
      builder: (context, state) =>  BadgesPage(),
    ),
    GoRoute(
      path: '/badge_detail',
      builder: (context, state) => BadgeDetailPage(badge: state.extra as Map<String, dynamic>),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordPage(),
    ),
  ],
);