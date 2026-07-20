import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── EVENTS ──────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String role;
  const SendOtpEvent({required this.phoneNumber, required this.role});
  @override
  List<Object?> get props => [phoneNumber, role];
}

class PhoneCodeSentEvent extends AuthEvent {
  final String verificationId;
  final int? resendToken;
  final String phoneNumber;
  final String role;
  const PhoneCodeSentEvent({
    required this.verificationId,
    required this.resendToken,
    required this.phoneNumber,
    required this.role,
  });
  @override
  List<Object?> get props => [verificationId, resendToken, phoneNumber, role];
}

class PhoneAuthErrorEvent extends AuthEvent {
  final String message;
  const PhoneAuthErrorEvent(this.message);
  @override
  List<Object?> get props => [message];
}

class AutoVerifyCredentialEvent extends AuthEvent {
  final PhoneAuthCredential credential;
  final String role;
  const AutoVerifyCredentialEvent({required this.credential, required this.role});
  @override
  List<Object?> get props => [credential, role];
}

class VerifyOtpEvent extends AuthEvent {
  final String verificationId;
  final String smsCode;
  final String role;
  final String phoneNumber;

  const VerifyOtpEvent({
    required this.verificationId,
    required this.smsCode,
    required this.role,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [verificationId, smsCode, role, phoneNumber];
}

class SignupEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String location;
  final String password;
  final String role;

  const SignupEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [name, email, phone, location, password, role];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  final String role;

  const LoginEvent({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, role];
}

class CheckAuthStatusEvent extends AuthEvent {}
class LogoutEvent extends AuthEvent {}

// ─── STATES ──────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class OtpSentSuccess extends AuthState {
  final String verificationId;
  final int? resendToken;
  final String phoneNumber;
  final String role;

  const OtpSentSuccess({
    required this.verificationId,
    required this.resendToken,
    required this.phoneNumber,
    required this.role,
  });

  @override
  List<Object?> get props => [verificationId, resendToken, phoneNumber, role];
}

class OtpVerificationSuccess extends AuthState {
  final String token;
  final String role;
  final String profileStatus;

  const OtpVerificationSuccess({
    required this.token,
    required this.role,
    required this.profileStatus,
  });

  @override
  List<Object?> get props => [token, role, profileStatus];
}

class AuthAuthenticated extends AuthState {
  final String token;
  final String role;
  final String profileStatus;
  const AuthAuthenticated(this.token, this.role, {this.profileStatus = 'complete'});
  @override
  List<Object?> get props => [token, role, profileStatus];
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
    on<SendOtpEvent>(_onSendOtp);
    on<PhoneCodeSentEvent>(_onPhoneCodeSent);
    on<PhoneAuthErrorEvent>(_onPhoneAuthError);
    on<AutoVerifyCredentialEvent>(_onAutoVerifyCredential);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SignupEvent>(_onSignup);
    on<LoginEvent>(_onLogin);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final formattedPhone = event.phoneNumber.startsWith('+')
          ? event.phoneNumber
          : '+92${event.phoneNumber.replaceAll(RegExp(r'^0+'), '')}';

      final isDemo = formattedPhone == '+923001234567' ||
          formattedPhone == '+923007654321' ||
          formattedPhone == '+923009876543' ||
          formattedPhone == '+923001111111';

      bool firebaseInitialized = true;
      try {
        FirebaseAuth.instance;
      } catch (_) {
        firebaseInitialized = false;
      }

      if (!firebaseInitialized || isDemo) {
        // Simulated code sent for demo accounts
        await Future.delayed(const Duration(milliseconds: 800));
        emit(OtpSentSuccess(
          verificationId: 'mock_verification_id_12345',
          resendToken: 12345,
          phoneNumber: formattedPhone,
          role: event.role,
        ));
        return;
      }

      final completer = Completer<void>();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {
          add(AutoVerifyCredentialEvent(credential: credential, role: event.role));
        },
        verificationFailed: (FirebaseAuthException e) {
          add(PhoneAuthErrorEvent(e.message ?? 'Firebase verification failed.'));
          if (!completer.isCompleted) completer.complete();
        },
        codeSent: (String verificationId, int? resendToken) {
          add(PhoneCodeSentEvent(
            verificationId: verificationId,
            resendToken: resendToken,
            phoneNumber: formattedPhone,
            role: event.role,
          ));
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future;
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onPhoneCodeSent(PhoneCodeSentEvent event, Emitter<AuthState> emit) {
    emit(OtpSentSuccess(
      verificationId: event.verificationId,
      resendToken: event.resendToken,
      phoneNumber: event.phoneNumber,
      role: event.role,
    ));
  }

  void _onPhoneAuthError(PhoneAuthErrorEvent event, Emitter<AuthState> emit) {
    emit(AuthError(event.message));
  }

  Future<void> _onAutoVerifyCredential(AutoVerifyCredentialEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(event.credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final phone = firebaseUser.phoneNumber ?? '';
        String token = 'firebase_jwt_token_${firebaseUser.uid}';
        String profileStatus = 'incomplete';

        if (phone == '+923001234567' || phone == '+923007654321' || phone == '+923009876543') {
          profileStatus = 'complete';
          await authRepository.saveToken(token);
          await (authRepository as dynamic).secureStorage.write(key: 'user_role', value: event.role);
          await (authRepository as dynamic).secureStorage.write(key: 'profile_status', value: 'complete');
          await (authRepository as dynamic).secureStorage.write(key: 'user_phone', value: phone);
        } else {
          profileStatus = 'incomplete';
          await (authRepository as dynamic).secureStorage.write(key: 'user_role', value: event.role);
          await (authRepository as dynamic).secureStorage.write(key: 'profile_status', value: 'incomplete');
          await (authRepository as dynamic).secureStorage.write(key: 'user_phone', value: phone);
        }

        emit(OtpVerificationSuccess(
          token: token,
          role: event.role,
          profileStatus: profileStatus,
        ));
      } else {
        emit(const AuthError('Firebase auto-verification failed. User is null.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final isMock = event.verificationId == 'mock_verification_id_12345';

      bool firebaseInitialized = true;
      try {
        FirebaseAuth.instance;
      } catch (_) {
        firebaseInitialized = false;
      }

      if (!firebaseInitialized || isMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (event.smsCode != '123456' && event.smsCode != '111111') {
          emit(const AuthError('Incorrect OTP code. Enter 123456 or 111111 for demo.'));
          return;
        }

        String token = 'mock_jwt_token_${event.phoneNumber}';
        String profileStatus = 'incomplete';

        if (event.phoneNumber == '+923001234567' ||
            event.phoneNumber == '+923007654321' ||
            event.phoneNumber == '+923009876543') {
          profileStatus = 'complete';
          await authRepository.saveToken(token);
          await (authRepository as dynamic).secureStorage.write(key: 'user_role', value: event.role);
          await (authRepository as dynamic).secureStorage.write(key: 'profile_status', value: 'complete');
          await (authRepository as dynamic).secureStorage.write(key: 'user_phone', value: event.phoneNumber);
          if (event.phoneNumber == '+923001234567') {
            await (authRepository as dynamic).secureStorage.write(key: 'user_email', value: 'zeeshan.khan@gmail.com');
            await (authRepository as dynamic).secureStorage.write(key: 'user_name', value: 'Zeeshan Khan');
          } else if (event.phoneNumber == '+923007654321') {
            await (authRepository as dynamic).secureStorage.write(key: 'user_email', value: 'store@foodexpress.com');
            await (authRepository as dynamic).secureStorage.write(key: 'user_name', value: 'Al-Fatah Store');
          } else if (event.phoneNumber == '+923009876543') {
            await (authRepository as dynamic).secureStorage.write(key: 'user_email', value: 'rider@foodexpress.com');
            await (authRepository as dynamic).secureStorage.write(key: 'user_name', value: 'Demo Rider');
          }
        } else {
          profileStatus = 'incomplete';
          await (authRepository as dynamic).secureStorage.write(key: 'user_role', value: event.role);
          await (authRepository as dynamic).secureStorage.write(key: 'profile_status', value: 'incomplete');
          await (authRepository as dynamic).secureStorage.write(key: 'user_phone', value: event.phoneNumber);
        }

        emit(OtpVerificationSuccess(
          token: token,
          role: event.role,
          profileStatus: profileStatus,
        ));
        return;
      }

      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final phone = firebaseUser.phoneNumber ?? event.phoneNumber;
        String token = 'firebase_jwt_token_${firebaseUser.uid}';

        String profileStatus = 'incomplete';
        if (phone == '+923001234567' || phone == '+923007654321' || phone == '+923009876543') {
          profileStatus = 'complete';
          await authRepository.saveToken(token);
          await (authRepository as dynamic).secureStorage.write(key: 'user_role', value: event.role);
          await (authRepository as dynamic).secureStorage.write(key: 'profile_status', value: 'complete');
          await (authRepository as dynamic).secureStorage.write(key: 'user_phone', value: phone);
        } else {
          profileStatus = 'incomplete';
          await (authRepository as dynamic).secureStorage.write(key: 'user_role', value: event.role);
          await (authRepository as dynamic).secureStorage.write(key: 'profile_status', value: 'incomplete');
          await (authRepository as dynamic).secureStorage.write(key: 'user_phone', value: phone);
        }

        emit(OtpVerificationSuccess(
          token: token,
          role: event.role,
          profileStatus: profileStatus,
        ));
      } else {
        emit(const AuthError('Firebase authentication failed. User is null.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
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
        role: event.role,
      );
      final profileStatus = (result['profile_status']?['status'] as String?) ?? 'incomplete';
      emit(AuthAuthenticated(result['token'] as String, event.role, profileStatus: profileStatus));
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
        role: event.role,
      );
      final profileStatus = (result['profile_status']?['status'] as String?) ?? 'incomplete';
      emit(AuthAuthenticated(result['token'] as String, event.role, profileStatus: profileStatus));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await authRepository.getToken();
      final role = await authRepository.getRole() ?? 'customer';
      final profileStatus = await authRepository.getProfileStatusString() ?? 'incomplete';
      if (token != null && token.isNotEmpty) {
        emit(AuthAuthenticated(token, role, profileStatus: profileStatus));
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
