import 'package:go_router/go_router.dart';
import 'package:pint26pmd/screens/about_page.dart';
import 'package:pint26pmd/screens/badge_detail_page.dart';
import 'screens/login_page.dart';
import 'screens/main_page.dart';
import 'screens/profile_page.dart';
import 'screens/notifications_page.dart';
import 'screens/help_page.dart';
import 'screens/ranking_page.dart';
import 'screens/candidaturas.dart';
import 'screens/badges_page.dart';
import 'screens/options_page.dart';
import 'screens/change_password.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainPage(),
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
      builder: (context, state) => const RankingPage(),
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
      builder: (context, state) => const BadgesPage(),
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