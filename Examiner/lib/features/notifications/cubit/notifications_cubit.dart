import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/attempts_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final AttemptsRepository attemptsRepository;
  StreamSubscription? _subscription;

  NotificationsCubit({required this.attemptsRepository})
      : super(const NotificationsState()) {
    _startListening();
  }

  void _startListening() {
    _subscription = attemptsRepository.onAttemptCompleted.listen(
      (attempt) {
        if (attempt.status == 'finished' || attempt.status == 'timeout') {
          emit(NotificationsState(
            latestNotification: AttemptNotification(
              candidateName: attempt.candidateName,
              examId: attempt.examId,
              score: attempt.score,
              durationSec: attempt.durationSec,
              status: attempt.status,
              timestamp: DateTime.now(),
            ),
          ));
        }
      },
      onError: (_) {},
    );
  }

  void dismiss() {
    emit(const NotificationsState(latestNotification: null));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

