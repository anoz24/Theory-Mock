import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:examiner/data/models/attempt_model.dart';
import 'package:examiner/data/repositories/attempts_repository.dart';
import 'package:examiner/features/notifications/cubit/notifications_cubit.dart';
import 'package:examiner/features/notifications/cubit/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttemptsRepository extends Mock implements AttemptsRepository {}

void main() {
  late MockAttemptsRepository mockAttemptsRepository;
  late StreamController<AttemptModel> controller;

  final sampleAttempt = AttemptModel(
    id: 'exam_1_user_1',
    examId: 'exam_1',
    candidateId: 'user_1',
    candidateName: 'Jane Doe',
    status: 'finished',
    startedAt: DateTime(2026, 11, 8, 10, 0),
    endsAt: DateTime(2026, 11, 8, 10, 15),
    score: 9,
    durationSec: 300,
  );

  setUp(() {
    mockAttemptsRepository = MockAttemptsRepository();
    controller = StreamController<AttemptModel>.broadcast();
    when(() => mockAttemptsRepository.onAttemptCompleted)
        .thenAnswer((_) => controller.stream);
  });

  tearDown(() {
    controller.close();
  });

  group('NotificationsCubit', () {
    test('initial state has null latestNotification', () {
      final cubit =
          NotificationsCubit(attemptsRepository: mockAttemptsRepository);
      expect(cubit.state.latestNotification, isNull);
      cubit.close();
    });

    blocTest<NotificationsCubit, NotificationsState>(
      'emits new state when completed attempt arrives',
      build: () =>
          NotificationsCubit(attemptsRepository: mockAttemptsRepository),
      act: (cubit) {
        controller.add(sampleAttempt);
      },
      expect: () => [
        isA<NotificationsState>().having(
          (s) => s.latestNotification?.candidateName,
          'candidateName',
          'Jane Doe',
        ),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'dismiss clears latestNotification',
      build: () =>
          NotificationsCubit(attemptsRepository: mockAttemptsRepository),
      seed: () => NotificationsState(
        latestNotification: AttemptNotification(
          candidateName: 'Jane Doe',
          examId: 'exam_1',
          score: 9,
          durationSec: 300,
          status: 'finished',
          timestamp: DateTime.now(),
        ),
      ),
      act: (cubit) => cubit.dismiss(),
      expect: () => [
        const NotificationsState(latestNotification: null),
      ],
    );
  });
}

