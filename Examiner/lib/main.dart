import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/attempts_repository.dart';
import 'data/repositories/categories_repository.dart';
import 'data/repositories/exams_repository.dart';
import 'features/notifications/cubit/notifications_cubit.dart';
import 'features/notifications/cubit/notifications_state.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = AuthRepository();
  try {
    await authRepository.ensureSignedInAnonymously();
  } catch (e) {
    debugPrint('Anonymous sign-in error: $e');
  }

  final categoriesRepository = CategoriesRepository();
  final examsRepository = ExamsRepository();
  final attemptsRepository = AttemptsRepository();

  runApp(ExaminerApp(
    authRepository: authRepository,
    categoriesRepository: categoriesRepository,
    examsRepository: examsRepository,
    attemptsRepository: attemptsRepository,
  ));
}

class ExaminerApp extends StatelessWidget {
  final AuthRepository authRepository;
  final CategoriesRepository categoriesRepository;
  final ExamsRepository examsRepository;
  final AttemptsRepository attemptsRepository;

  const ExaminerApp({
    super.key,
    required this.authRepository,
    required this.categoriesRepository,
    required this.examsRepository,
    required this.attemptsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: categoriesRepository),
        RepositoryProvider.value(value: examsRepository),
        RepositoryProvider.value(value: attemptsRepository),
      ],
      child: BlocProvider(
        create: (context) => NotificationsCubit(
          attemptsRepository: attemptsRepository,
        ),
        child: MaterialApp.router(
          title: 'Examiner',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return BlocListener<NotificationsCubit, NotificationsState>(
              listener: (context, state) {
                final notification = state.latestNotification;
                if (notification != null) {
                  rootScaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${notification.candidateName} ${notification.status} exam!\nScore: ${notification.score} (${notification.formattedDuration})',
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'View',
                        textColor: Colors.amber,
                        onPressed: () {
                          AppRouter.router.push(
                            '/exams/${notification.examId}/results',
                          );
                        },
                      ),
                    ),
                  );
                }
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
