import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthState()) {
    on<AuthUserSubscriptionRequested>(_onUserSubscriptionRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onUserSubscriptionRequested(
    AuthUserSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = authRepository.currentUser;
    if (current != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: current,
      ));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }

    await emit.forEach<UserModel?>(
      authRepository.user,
      onData: (user) {
        if (user != null) {
          return state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            formStatus: AuthFormStatus.initial,
            errorMessage: null,
          );
        } else {
          return const AuthState(
            status: AuthStatus.unauthenticated,
          );
        }
      },
      onError: (_, _) => state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: AuthFormStatus.submitting,
      errorMessage: null,
    ));

    try {
      final user = await authRepository.logIn(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        formStatus: AuthFormStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        formStatus: AuthFormStatus.failure,
        errorMessage: _formatAuthError(e),
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: AuthFormStatus.submitting,
      errorMessage: null,
    ));

    try {
      final user = await authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        formStatus: AuthFormStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        formStatus: AuthFormStatus.failure,
        errorMessage: _formatAuthError(e),
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.logOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(
        formStatus: AuthFormStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  String _formatAuthError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('user-not-found')) return 'No account found with this email.';
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'An account already exists for this email.';
    }
    if (msg.contains('weak-password')) {
      return 'Password should be at least 6 characters.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return msg.replaceFirst(RegExp(r'^Exception: '), '');
  }
}
