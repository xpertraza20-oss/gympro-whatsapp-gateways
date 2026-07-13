import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── EVENTS ──────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class SignupEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String location;
  final String password;

  const SignupEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, location, password];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class VerifyOtpEvent extends AuthEvent {
  final String email;
  final String otp;
  const VerifyOtpEvent({required this.email, required this.otp});
  @override
  List<Object?> get props => [email, otp];
}

class CheckAuthStatusEvent extends AuthEvent {}
class LogoutEvent extends AuthEvent {}

// Legacy phone event
class RequestOtpEvent extends AuthEvent {
  final String phoneNumber;
  const RequestOtpEvent(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

// ─── STATES ──────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String email;
  const AuthOtpSent({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthAuthenticated extends AuthState {
  final String token;
  const AuthAuthenticated(this.token);
  @override
  List<Object?> get props => [token];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────

class PhoneAuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  PhoneAuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<SignupEvent>(_onSignup);
    on<LoginEvent>(_onLogin);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
    on<RequestOtpEvent>(_onRequestOtpLegacy);
  }

  Future<void> _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await authRepository.signup(
        name: event.name,
        email: event.email,
        phone: event.phone,
        location: event.location,
        password: event.password,
      );
      if (result['requiresOtp'] == true) {
        emit(AuthOtpSent(email: result['email'] as String));
      } else {
        emit(AuthAuthenticated(result['token'] as String));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      if (result['requiresOtp'] == true) {
        emit(AuthOtpSent(email: result['email'] as String));
      } else {
        emit(AuthAuthenticated(result['token'] as String));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await authRepository.verifyOtp(
        email: event.email,
        otp: event.otp,
      );
      emit(AuthAuthenticated(result['token'] as String));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await authRepository.getToken();
      if (token != null && token.isNotEmpty) {
        emit(AuthAuthenticated(token));
      } else {
        emit(AuthInitial());
      }
    } catch (_) {
      emit(AuthInitial());
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.clearToken();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRequestOtpLegacy(RequestOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.requestOtp(event.phoneNumber);
      emit(AuthOtpSent(email: event.phoneNumber));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
