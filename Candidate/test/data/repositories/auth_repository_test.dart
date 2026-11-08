import 'package:candidate/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late AuthRepository authRepository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    authRepository = AuthRepository(firebaseAuth: mockFirebaseAuth);
  });

  group('AuthRepository', () {
    test('currentUser returns UserModel when user exists', () {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid_123');
      when(() => mockUser.email).thenReturn('candidate@test.com');
      when(() => mockUser.displayName).thenReturn('Candidate One');
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

      final user = authRepository.currentUser;

      expect(user?.id, equals('uid_123'));
      expect(user?.email, equals('candidate@test.com'));
      expect(user?.displayName, equals('Candidate One'));
    });

    test('logIn signs in with email and password', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid_123');
      when(() => mockUser.email).thenReturn('candidate@test.com');
      when(() => mockUser.displayName).thenReturn('Candidate One');
      when(() => mockCredential.user).thenReturn(mockUser);

      when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'candidate@test.com',
            password: 'password123',
          )).thenAnswer((_) async => mockCredential);

      final result = await authRepository.logIn(
        email: 'candidate@test.com',
        password: 'password123',
      );

      expect(result.id, equals('uid_123'));
      verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'candidate@test.com',
            password: 'password123',
          )).called(1);
    });

    test('register creates user and updates display name', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid_123');
      when(() => mockUser.email).thenReturn('candidate@test.com');
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockCredential.user).thenReturn(mockUser);

      when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'candidate@test.com',
            password: 'password123',
          )).thenAnswer((_) async => mockCredential);

      final result = await authRepository.register(
        name: 'Candidate One',
        email: 'candidate@test.com',
        password: 'password123',
      );

      expect(result.id, equals('uid_123'));
      expect(result.displayName, equals('Candidate One'));
      verify(() => mockUser.updateDisplayName('Candidate One')).called(1);
    });

    test('logOut calls signOut', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      await authRepository.logOut();
      verify(() => mockFirebaseAuth.signOut()).called(1);
    });
  });
}

