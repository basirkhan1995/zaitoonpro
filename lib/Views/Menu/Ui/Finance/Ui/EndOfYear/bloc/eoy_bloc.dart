import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/EndOfYear/model/eoy_model.dart';

part 'eoy_event.dart';
part 'eoy_state.dart';

class EoyBloc extends Bloc<EoyEvent, EoyState> {
  final Repositories _repo;
  EoyBloc(this._repo) : super(EoyInitial()) {

    on<LoadPLEvent>((event, emit) async {
      emit(EoyLoadingState());
      try{
       final eoy = await _repo.getProfitAndLoss();
       emit(EoyLoadedState(eoy));
      }catch(e){
       emit(EoyErrorState(e.toString()));
      }
    });

    on<ProcessPLEvent>((event, emit) async {
      emit(EoyLoadingState());

      try {
        final response = await _repo.eoyOperationProcess(
          usrName: event.usrName,
          remark: event.remark,
          branchCode: event.branchCode,
        );

        final String msg = (response['msg'] ?? '').toString();

        switch (msg.toLowerCase()) {
          case "pending":
            emit(EoyErrorState("P&L closing failed. Please check pending transactions."),);
            break;

          case "failed":
            emit(EoyErrorState("Operation failed, try again later."),);
            break;

          case "no record":
            emit(EoyErrorState("No Profit & Loss record found to proceed."),);
            break;

          case "success":
            add(LoadPLEvent());
            emit(EoySuccessState());
            break;

          default:
            emit(
              EoyErrorState("Unexpected response from server: $msg"),
            );
        }
      } catch (e) {
        emit(EoyErrorState(e.toString()));
      }
    });

  }
}
