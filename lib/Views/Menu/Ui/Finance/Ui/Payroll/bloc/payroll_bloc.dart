import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Payroll/model/payroll_model.dart';

import '../../../../../../../Services/localization_services.dart';

part 'payroll_event.dart';
part 'payroll_state.dart';

class PayrollBloc extends Bloc<PayrollEvent, PayrollState> {
  final Repositories _repo;
  String? _currentDate;
  List<PayrollModel>? _cachedPayroll;
  PayrollBloc(this._repo) : super(PayrollInitial()) {

    on<LoadPayrollEvent>((event, emit) async {
      // Only show loading if it's initial load or date changed
      if (state is PayrollInitial ||
          state is PayrollErrorState ||
          _currentDate != event.date) {
        emit(PayrollLoadingState());
      } else {
        // Silent loading - maintain current state
        emit(PayrollSilentLoadingState(
            _cachedPayroll ?? []
        ));
      }

      try {
        final res = await _repo.getPayroll(date: event.date);
        _currentDate = event.date;
        _cachedPayroll = res;
        emit(PayrollLoadedState(res));
      } catch (e) {
        emit(PayrollErrorState(e.toString()));
      }
    });

    on<PostPayrollEvent>((event, emit) async {
      final tr = localizationService.loc;

      // Keep current UI (silent loading)
      if (_cachedPayroll != null) {
        emit(PayrollSilentLoadingState(_cachedPayroll!));
      }

      try {
        final res = await _repo.postPayroll(usrName: event.usrName, records: event.records);
        final msg = res["msg"];

        if (msg == "success") {
          // Emit success first
          emit(PayrollSuccessState(tr.successMessage));
          // Reload Payroll
          add(LoadPayrollEvent(_currentDate ?? ""));
        } else {
          final errorMsg = res["message"] ?? tr.operationFailedMessage;
          emit(PayrollErrorState(errorMsg));
          if (_cachedPayroll != null) {
            emit(PayrollLoadedState(_cachedPayroll!));
          }
        }
      } catch (e) {
        emit(PayrollErrorState(e.toString()));
        if (_cachedPayroll != null) {
          emit(PayrollLoadedState(_cachedPayroll!));
        }
      }
    });
  }
}
