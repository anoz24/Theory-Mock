import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/categories_repository.dart';
import 'data/repositories/exams_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = AuthRepository();
  final categoriesRepository = CategoriesRepository();
  final examsRepository = ExamsRepository();

  final authBloc = AuthBloc(authRepository: authRepository)
    ..add(const AuthUserSubscriptionRequested());

  final router = AppRouter.create(authBloc);

  runApp(CandidateApp(
    authRepository: authRepository,
    categoriesRepository: categoriesRepository,
    examsRepository: examsRepository,
    authBloc: authBloc,
    router: router,
  ));
}

class CandidateApp extends StatelessWidget {
  final AuthRepository authRepository;
  final CategoriesRepository categoriesRepository;
  final ExamsRepository examsRepository;
  final AuthBloc authBloc;
  final GoRouter router;

  const CandidateApp({
    super.key,
    required this.authRepository,
    required this.categoriesRepository,
    required this.examsRepository,
    required this.authBloc,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: categoriesRepository),
        RepositoryProvider.value(value: examsRepository),
      ],
      child: BlocProvider.value(
        value: authBloc,
        child: MaterialApp.router(
          title: 'Candidate',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
