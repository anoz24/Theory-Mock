part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }
enum AuthFormStatus { initial, submitting, success, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final AuthFormStatus formStatus;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.formStatus = AuthFormStatus.initial,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    AuthFormStatus? formStatus,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      formStatus: formStatus ?? this.formStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, formStatus, errorMessage];
}

