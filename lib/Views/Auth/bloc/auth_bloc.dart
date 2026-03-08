import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Auth/models/login_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/model/com_model.dart';
import '../../../Services/localization_services.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Repositories _repo;
  AuthBloc(this._repo) : super(AuthInitial()) {

    on<LoginEvent>((event, emit) async {
      final tr = localizationService.loc;
      emit(AuthLoadingState());

      try {
        final response = await _repo.login(
          username: event.usrName,
          password: event.usrPassword,
        );

        if (response.containsKey("msg") && response["msg"] != null) {
          final String result = response["msg"];

          switch (result) {
            case "incorrect":
              emit(AuthErrorState(tr.incorrectCredential));
              return;

            case "blocked":
              emit(AuthErrorState(tr.blockedMessage));
              return;

            case "unverified":
              emit(AuthErrorState(tr.unverified));
              return;

            case "fcp":
              emit(ForceChangePasswordState());
              return;

            case "nosub":
              emit(NoSubscriptionState());
              return;

            case "fev":
              emit(EmailVerificationState());
              return;

            default:
              emit(AuthErrorState(result));
              return;
          }
        }

        // Success
        final loginData = LoginData.fromMap(response);
        emit(AuthenticatedState(loginData));

      } catch (e) {
        emit(AuthErrorState(e.toString()));
      }
    });

    on<OnLogoutEvent>((event, emit){
      emit(UnAuthenticatedState());
    });

    on<OnResetAuthState>((event, emit){
      emit(AuthInitial());
    });
  }
}
