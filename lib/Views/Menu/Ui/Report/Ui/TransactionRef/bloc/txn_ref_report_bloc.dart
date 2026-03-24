import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import '../model/txn_report_model.dart';

part 'txn_ref_report_event.dart';
part 'txn_ref_report_state.dart';

class TxnRefReportBloc extends Bloc<TxnRefReportEvent, TxnRefReportState> {
  final Repositories _repo;
  TxnRefReportBloc(this._repo) : super(TxnRefReportInitial()) {

    on<LoadTxnReportByReferenceEvent>((event, emit) async{
      emit(TxnRefReportLoadingState());
      try{
       final txn = await _repo.getTransactionByRefReport(ref: event.reference);
       emit(TxnRefReportLoadedState(txn));
      }catch(e){
        emit(TxnRefReportErrorState(e.toString()));
      }
    });

    on<ResetTxnReportByReferenceEvent>((event,emit){
      emit(TxnRefReportInitial());
    });
  }
}
