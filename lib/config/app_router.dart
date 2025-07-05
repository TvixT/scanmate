import 'package:go_router/go_router.dart';
import '../ui/screens/main_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/history_screen.dart';
import '../ui/screens/scan_card_screen.dart';
import '../ui/screens/review_contact_screen.dart';
import '../ui/screens/success_screen.dart';
import '../ui/screens/contact_detail_screen.dart';
import '../ui/screens/onboarding_screen.dart';
import '../services/onboarding_service.dart';

class AppRouter {
  static const String home = '/';
  static const String history = '/history';
  static const String scanCard = '/scan-card';
  static const String reviewContact = '/review-contact';
  static const String editContact = '/edit-contact';
  static const String success = '/success';
  static const String contactDetail = '/contact-detail';
  static const String onboarding = '/onboarding';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    redirect: (context, state) async {
      final onboardingCompleted = await OnboardingService.hasCompletedOnboarding();
      
      // If not onboarded and not already on onboarding screen, redirect to onboarding
      if (!onboardingCompleted && state.fullPath != onboarding) {
        return onboarding;
      }
      
      // If onboarded and on onboarding screen, redirect to home
      if (onboardingCompleted && state.fullPath == onboarding) {
        return home;
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: history,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
        ],
      ),
      
      // Full-screen routes (outside bottom navigation)
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: scanCard,
        builder: (context, state) => const ScanCardScreen(),
      ),
      GoRoute(
        path: reviewContact,
        builder: (context, state) {
          final contactData = state.extra as Map<String, dynamic>?;
          return ReviewContactScreen(contactData: contactData);
        },
      ),
      GoRoute(
        path: success,
        builder: (context, state) {
          final message = state.extra as String?;
          return SuccessScreen(message: message);
        },
      ),
      GoRoute(
        path: '$contactDetail/:id',
        builder: (context, state) {
          final contactId = state.pathParameters['id'];
          return ContactDetailScreen(contactId: contactId);
        },
      ),
      GoRoute(
        path: '$editContact/:id',
        builder: (context, state) {
          final contactId = state.pathParameters['id'];
          return ReviewContactScreen(
            contactData: null,
            editingContactId: contactId,
          );
        },
      ),
    ],
  );
}
