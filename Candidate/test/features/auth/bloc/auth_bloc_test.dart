import 'package:bloc_test/bloc_test.dart';
import 'package:candidate/data/models/user_model.dart';
import 'package:candidate/data/repositories/auth_repository.dart';
import 'package:candidate/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  const sampleUser = UserModel(
    id: 'uid_1',
    email: 'test@candidate.com',
    displayName: 'Test User',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthBloc', () {
    test('initial state has unknown status', () {
      final bloc = AuthBloc(authRepository: mockAuthRepository);
      expect(bloc.state.status, equals(AuthStatus.unknown));
    });

    blocTest<AuthBloc, AuthState>(
      'emits authenticated when user stream emits a user',
      build: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
        when(() => mockAuthRepository.user)
            .thenAnswer((_) => Stream.value(sampleUser));
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const AuthUserSubscriptionRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
        const AuthState(
          status: AuthStatus.authenticated,
          user: sampleUser,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [submitting, success] on successful login',
      build: () {
        when(() => mockAuthRepository.logIn(
              email: 'test@candidate.com',
              password: 'password123',
            )).thenAnswer((_) async => sampleUser);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'test@candidate.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthState(formStatus: AuthFormStatus.submitting),
        const AuthState(
          status: AuthStatus.authenticated,
          user: sampleUser,
          formStatus: AuthFormStatus.success,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [submitting, failure] on failed login',
      build: () {
        when(() => mockAuthRepository.logIn(
              email: 'test@candidate.com',
              password: 'wrong',
            )).thenThrow(Exception('invalid-credential'));
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'test@candidate.com',
        password: 'wrong',
      )),
      expect: () => [
        const AuthState(formStatus: AuthFormStatus.submitting),
        isA<AuthState>()
            .having((s) => s.formStatus, 'formStatus', AuthFormStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('Invalid email or password')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [submitting, success] on successful registration',
      build: () {
        when(() => mockAuthRepository.register(
              name: 'Test User',
              email: 'test@candidate.com',
              password: 'password123',
            )).thenAnswer((_) async => sampleUser);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        name: 'Test User',
        email: 'test@candidate.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthState(formStatus: AuthFormStatus.submitting),
        const AuthState(
          status: AuthStatus.authenticated,
          user: sampleUser,
          formStatus: AuthFormStatus.success,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when logout requested',
      build: () {
        when(() => mockAuthRepository.logOut()).thenAnswer((_) async {});
        return AuthBloc(authRepository: mockAuthRepository);
      },
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        user: sampleUser,
      ),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthState(
          status: AuthStatus.unauthenticated,
          user: null,
        ),
      ],
    );
  });
}

