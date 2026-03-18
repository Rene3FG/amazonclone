import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/exceptions.dart';
import '../../repositories/auth_repository.dart';

abstract class AppAuthEvent extends Equatable {
  const AppAuthEvent();
  @override List<Object?> get props => [];
}

class CheckSession    extends AppAuthEvent {}
class LogoutRequested extends AppAuthEvent {}

class LoginRequested extends AppAuthEvent {
  final String email, password;
  final bool   rememberMe;
  const LoginRequested({required this.email, required this.password, this.rememberMe = false});
  @override List<Object?> get props => [email, password, rememberMe];
}

class RegisterRequested extends AppAuthEvent {
  final String email, password;
  const RegisterRequested({required this.email, required this.password});
  @override List<Object?> get props => [email, password];
}

abstract class AppAuthState extends Equatable {
  const AppAuthState();
  @override List<Object?> get props => [];
}

class AppAuthInitial         extends AppAuthState {}
class AppAuthLoading         extends AppAuthState {}
class AppAuthUnauthenticated extends AppAuthState {}

class AppAuthAuthenticated extends AppAuthState {
  final String  userId;
  final String? email;
  const AppAuthAuthenticated({required this.userId, this.email});
  @override List<Object?> get props => [userId];
}

class AppAuthFailure extends AppAuthState {
  final String message;
  const AppAuthFailure(this.message);
  @override List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AppAuthEvent, AppAuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AppAuthInitial()) {
    on<CheckSession>(_onCheckSession);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  void _onCheckSession(CheckSession event, Emitter<AppAuthState> emit) {
    final user = _repository.currentUser;
    emit(user != null
        ? AppAuthAuthenticated(userId: user.id, email: user.email)
        : AppAuthUnauthenticated());
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AppAuthState> emit) async {
    emit(AppAuthLoading());
    try {
      await _repository.signIn(event.email, event.password);
      if (event.rememberMe) {
        await _repository.saveCredentials(event.email, event.password);
      }
      final user = _repository.currentUser!;
      emit(AppAuthAuthenticated(userId: user.id, email: user.email));
    } on AppException catch (e) {
      emit(AppAuthFailure(e.message));
    } catch (e) {
      emit(AppAuthFailure('Error inesperado: $e'));
    }
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AppAuthState> emit) async {
    emit(AppAuthLoading());
    try {
      await _repository.signUp(event.email, event.password);
      await _repository.signIn(event.email, event.password);
      final user = _repository.currentUser!;
      emit(AppAuthAuthenticated(userId: user.id, email: user.email));
    } on AppException catch (e) {
      emit(AppAuthFailure(e.message));
    } catch (e) {
      emit(AppAuthFailure('Error al registrar: $e'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AppAuthState> emit) async {
    await _repository.signOut();
    emit(AppAuthUnauthenticated());
  }
}
