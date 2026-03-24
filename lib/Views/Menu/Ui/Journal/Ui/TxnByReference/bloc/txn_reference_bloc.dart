import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/TxnByReference/model/txn_ref_model.dart';

part 'txn_reference_event.dart';
part 'txn_reference_state.dart';

class TxnReferenceBloc extends Bloc<TxnReferenceEvent, TxnReferenceState> {
  final Repositories _repo;
  TxnReferenceBloc(this._repo) : super(TxnReferenceInitial()) {

    on<FetchTxnByReferenceEvent>((event, emit)async {
      emit(TxnReferenceLoadingState());
    try{
     final txn = await _repo.getTxnByReference(reference: event.reference);
     emit(TxnReferenceLoadedState(txn));
    }catch(e){
     emit(TxnReferenceErrorState(e.toString()));
    }
    });
  }
}
