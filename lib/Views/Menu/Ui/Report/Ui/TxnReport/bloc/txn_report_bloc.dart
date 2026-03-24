import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../model/txn_report_model.dart';

part 'txn_report_event.dart';
part 'txn_report_state.dart';

class TxnReportBloc extends Bloc<TxnReportEvent, TxnReportState> {
  final Repositories _repo;
  TxnReportBloc(this._repo) : super(TxnReportInitial()) {

    on<LoadTxnReportEvent>((event, emit) async{
      emit(TxnReportLoadingState());
       try{
       final txn = await _repo.transactionReport(fromDate: event.fromDate, toDate: event.toDate,status: event.status,checker: event.checker,maker: event.maker,currency: event.currency,txnType: event.txnType);
       emit(TxnReportLoadedState(txn));
       }catch(e){
         emit(TxnReportErrorState(e.toString()));
       }
    });

    on<ResetTxnReportEvent>((event, emit) async{
      emit(TxnReportLoadingState());
      try{
        emit(TxnReportInitial());
      }catch(e){
        emit(TxnReportErrorState(e.toString()));
      }
    });
  }
}
