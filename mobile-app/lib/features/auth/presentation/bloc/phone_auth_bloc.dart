import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/auth_repository.dart';

// --- EVENTS ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RequestOtpEvent extends AuthEvent {
  final String phoneNumber;
  const RequestOtpEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otp;
  const VerifyOtpEvent(this.phoneNumber, this.otp);

  @override
  List<Object?> get props => [phoneNumber, otp];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}


// --- STATES ---
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {}

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


// --- BLOC ---
class PhoneAuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  PhoneAuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<RequestOtpEvent>(_onRequestOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onRequestOtp(RequestOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.requestOtp(event.phoneNumber);
      emit(AuthOtpSent());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await authRepository.verifyOtp(event.phoneNumber, event.otp);
      emit(AuthAuthenticated(token));
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
}
