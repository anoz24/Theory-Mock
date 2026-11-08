import 'package:examiner/data/repositories/auth_repository.dart';
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
    test('signInAnonymously calls FirebaseAuth.signInAnonymously', () async {
      final mockCredential = MockUserCredential();
      when(() => mockFirebaseAuth.signInAnonymously())
          .thenAnswer((_) async => mockCredential);

      final result = await authRepository.signInAnonymously();

      expect(result, equals(mockCredential));
      verify(() => mockFirebaseAuth.signInAnonymously()).called(1);
    });

    test('ensureSignedInAnonymously signs in when currentUser is null', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);
      final mockCredential = MockUserCredential();
      when(() => mockFirebaseAuth.signInAnonymously())
          .thenAnswer((_) async => mockCredential);

      await authRepository.ensureSignedInAnonymously();

      verify(() => mockFirebaseAuth.signInAnonymously()).called(1);
    });

    test('ensureSignedInAnonymously does nothing when currentUser exists', () async {
      final mockUser = MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

      await authRepository.ensureSignedInAnonymously();

      verifyNever(() => mockFirebaseAuth.signInAnonymously());
    });
  });
}

