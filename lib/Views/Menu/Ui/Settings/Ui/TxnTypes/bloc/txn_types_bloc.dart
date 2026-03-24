import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/TxnTypes/model/txn_types_model.dart';

part 'txn_types_event.dart';
part 'txn_types_state.dart';

class TxnTypesBloc extends Bloc<TxnTypesEvent, TxnTypesState> {
  final Repositories _repo;
  TxnTypesBloc(this._repo) : super(TxnTypesInitial()) {

    on<LoadTxnTypesEvent>((event, emit) async {
      emit(TxnTypeLoadingState());
      try {
        final types = await _repo.getTxnTypes(trnCode: event.trnCode);
        emit(TxnTypesLoadedState(types));
      } catch (e) {
        emit(TxnTypeErrorState(e.toString()));
      }
    });
    on<AddTxnTypeEvent>((event, emit) async {
      emit(TxnTypeLoadingState());
      try {
        final response = await _repo.addTxnType(newType: event.newType);
        final msg = response["msg"];
        switch (msg) {
          case "success":
            emit(TxnTypeSuccessState());
            add(LoadTxnTypesEvent());
            return;
          case "failed":
            emit(TxnTypeErrorState(msg));
            return;
          case "exist":
            emit(TxnTypeErrorState(msg));
            return;
          default:
            emit(TxnTypeErrorState(msg));
            return;
        }
      } catch (e) {
        emit(TxnTypeErrorState(e.toString()));
      }
    });
    on<UpdateTxnTypeEvent>((event, emit) async {
      emit(TxnTypeLoadingState());
      try {
        final response = await _repo.updateTxnType(newType: event.newType);
        final msg = response["msg"];
        switch (msg) {
          case "success":
            emit(TxnTypeSuccessState());
            add(LoadTxnTypesEvent());
            return;
          case "empty":
            emit(TxnTypeErrorState(msg));
            return;
          case "failed":
            emit(TxnTypeErrorState(msg));
            return;
          case "exist":
            emit(TxnTypeErrorState(msg));
            return;
          default:
            emit(TxnTypeErrorState(msg));
            return;
        }
      } catch (e) {
        emit(TxnTypeErrorState(e.toString()));
      }
    });
    on<DeleteTxnTypeEvent>((event, emit) async {
      emit(TxnTypeLoadingState());
      try {
        final response = await _repo.deleteTxnType(trnCode: event.trnCode);
        final msg = response["msg"];
        switch (msg) {
          case "success":
            emit(TxnTypeSuccessState());
            add(LoadTxnTypesEvent());
            return;

          case "failed":
            emit(TxnTypeErrorState(msg));
            return;

          default:
            emit(TxnTypeErrorState(msg));
            return;
        }
      } catch (e) {
        emit(TxnTypeErrorState(e.toString()));
      }
    });
  }
}
