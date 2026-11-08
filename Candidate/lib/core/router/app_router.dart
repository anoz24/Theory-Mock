import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/attempt_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/exam_model.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/register_screen.dart';
import '../../features/browse/view/browse_screen.dart';
import '../../features/browse/view/category_exams_screen.dart';
import '../../features/exam_entry/view/exam_detail_screen.dart';
import '../../features/exam_session/view/exam_session_screen.dart';
import '../../features/result/view/result_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter create(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuth = authState.status == AuthStatus.authenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        final isRegistering = state.matchedLocation == '/register';

        if (!isAuth) {
          if (isLoggingIn || isRegistering) return null;
          return '/login';
        }

        if (isLoggingIn || isRegistering) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'browse',
          builder: (context, state) => const BrowseScreen(),
        ),
        GoRoute(
          path: '/categories/:categoryId/exams',
          name: 'category_exams',
          builder: (context, state) {
            final categoryId = state.pathParameters['categoryId']!;
            final category = state.extra as CategoryModel?;
            return CategoryExamsScreen(
              categoryId: categoryId,
              category: category,
            );
          },
        ),
        GoRoute(
          path: '/exams/:examId',
          name: 'exam_detail',
          builder: (context, state) {
            final examId = state.pathParameters['examId']!;
            final exam = state.extra as ExamModel?;
            return ExamDetailScreen(
              examId: examId,
              exam: exam,
            );
          },
        ),
        GoRoute(
          path: '/exams/:examId/session',
          name: 'exam_session',
          builder: (context, state) {
            final examId = state.pathParameters['examId']!;
            final attempt = state.extra as AttemptModel?;
            return ExamSessionScreen(
              examId: examId,
              attempt: attempt,
            );
          },
        ),
        GoRoute(
          path: '/exams/:examId/result',
          name: 'exam_result',
          builder: (context, state) {
            final examId = state.pathParameters['examId']!;
            return ResultScreen(examId: examId);
          },
        ),
      ],
    );
  }
}
