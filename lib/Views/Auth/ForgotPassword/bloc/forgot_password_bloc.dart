import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final Repositories _repo;

  ForgotPasswordBloc(this._repo) : super(ForgotPasswordInitial()) {

    on<RequestResetEvent>(_onRequestReset);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResetPasswordEvent>(_onResetPassword);
    on<ResendOtpEvent>(_onResendOtp);
    on<ResetForgotPasswordStateEvent>((event, emit) {
      emit(ForgotPasswordInitial());
    });
  }

  Future<void> _onRequestReset(
      RequestResetEvent event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(ForgotPasswordLoadingState());
    try {
      final response = await _repo.requestResetPassword(identity: event.identity);

      if (response['msg'] == 'success') {
        emit(IdentityVerifiedState(
          email: response['email'],
          timeLimit: response['timeLimit'],
        ));
      } else {
        emit(IdentityNotFoundState(message: response['msg'] ?? 'User not found'));
      }
    } catch (e) {
      emit(ForgotPasswordErrorState(message: e.toString()));
    }
  }

  Future<void> _onVerifyOtp(
      VerifyOtpEvent event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(ForgotPasswordLoadingState());
    try {
      final response = await _repo.verifyOtp(otp: event.otp);

      if (response.containsKey('rstStatus')) {
        // Check if OTP is expired
        final expiryTime = DateTime.parse(response['rstExpiry']);
        if (expiryTime.isBefore(DateTime.now())) {
          emit(OtpExpiredState(message: 'OTP has expired'));
          return;
        }

        emit(OtpVerifiedState(
          usrName: response['usrName'],
          usrEmail: response['usrEmail'],
          fullName: response['fullName'],
          rstExpiry: response['rstExpiry'],
          rstStatus: response['rstStatus'],
        ));
      } else {
        emit(OtpInvalidState(message: response['msg'] ?? 'Invalid OTP'));
      }
    } catch (e) {
      emit(ForgotPasswordErrorState(message: e.toString()));
    }
  }

  Future<void> _onResetPassword(
      ResetPasswordEvent event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(ForgotPasswordLoadingState());
    try {
      final response = await _repo.resetPasswordMethod(
        usrName: event.usrName,
        usrPass: event.usrPass,
        otp: event.otp,
      );

      if (response['msg'] == 'success') {
        emit(PasswordResetSuccessState(message: 'Password reset successfully'));
      } else {
        emit(PasswordResetFailedState(message: response['msg'] ?? 'Failed to reset password'));
      }
    } catch (e) {
      emit(ForgotPasswordErrorState(message: e.toString()));
    }
  }

  Future<void> _onResendOtp(
      ResendOtpEvent event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    emit(ForgotPasswordLoadingState());
    try {
      final response = await _repo.requestResetPassword(identity: event.identity);

      if (response['msg'] == 'success') {
        emit(IdentityVerifiedState(
          email: response['email'],
          timeLimit: response['timeLimit'],
        ));
      } else {
        emit(ForgotPasswordErrorState(message: response['msg'] ?? 'Failed to resend OTP'));
      }
    } catch (e) {
      emit(ForgotPasswordErrorState(message: e.toString()));
    }
  }
}