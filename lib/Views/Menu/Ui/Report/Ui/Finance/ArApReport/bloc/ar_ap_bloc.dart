import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ArApReport/model/ar_ap_model.dart';

part 'ar_ap_event.dart';
part 'ar_ap_state.dart';

class ArApBloc extends Bloc<ArApEvent, ArApState> {
  final Repositories _repo;

  ArApBloc(this._repo) : super(ArApInitial()) {
    on<LoadArApEvent>(_onLoadArAp);
  }

  Future<void> _onLoadArAp(
      LoadArApEvent event,
      Emitter<ArApState> emit,
      ) async {
    try {
      emit(ArApLoadingState());

      final records = await _repo.getArApReport(
        name: event.name,
        ccy: event.ccy,
      );

      /// =========================
      /// SEPARATE AR / AP HERE
      /// =========================
      final arAccounts = records.where((e) => e.isAR).toList();
      final apAccounts = records.where((e) => e.isAP).toList();

      emit(
        ArApLoadedState(
          arAccounts: arAccounts,
          apAccounts: apAccounts,
        ),
      );
    } catch (e) {
      emit(ArApErrorState(e.toString()));
    }
  }
}
