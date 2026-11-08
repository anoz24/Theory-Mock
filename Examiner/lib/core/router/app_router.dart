import 'package:go_router/go_router.dart';
import '../../data/models/category_model.dart';
import '../../data/models/exam_model.dart';
import '../../features/categories/view/categories_screen.dart';
import '../../features/exam_form/view/exam_form_screen.dart';
import '../../features/exams/view/exams_screen.dart';
import '../../features/live_monitor/view/live_monitor_screen.dart';
import '../../features/results/view/results_screen.dart';

class AppRouter {
  static const String categories = '/';

  static final GoRouter router = GoRouter(
    initialLocation: categories,
    routes: [
      GoRoute(
        path: categories,
        name: 'categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/categories/:categoryId/exams',
        name: 'exams',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final category = state.extra as CategoryModel?;
          return ExamsScreen(
            categoryId: categoryId,
            category: category,
          );
        },
      ),
      GoRoute(
        path: '/categories/:categoryId/exams/create',
        name: 'create_exam',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final categoryName = state.extra as String?;
          return ExamFormScreen(
            categoryId: categoryId,
            categoryName: categoryName,
          );
        },
      ),
      GoRoute(
        path: '/exams/:examId/monitor',
        name: 'live_monitor',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final exam = state.extra as ExamModel?;
          return LiveMonitorScreen(
            examId: examId,
            exam: exam,
          );
        },
      ),
      GoRoute(
        path: '/exams/:examId/results',
        name: 'results',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final examTitle = state.extra as String?;
          return ResultsScreen(
            examId: examId,
            examTitle: examTitle,
          );
        },
      ),
    ],
  );
}
