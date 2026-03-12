import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Stock/Cardx/model/cardx_model.dart';

part 'stock_record_event.dart';
part 'stock_record_state.dart';

class StockRecordBloc extends Bloc<StockRecordEvent, StockRecordState> {
  final Repositories _repo;
  StockRecordBloc(this._repo) : super(StockRecordInitial()) {

    on<LoadStockRecordEvent>((event, emit) async{
      emit(StockRecordLoadingState());
       try{
         final cardX = await _repo.stockRecord(fromDate: event.fromDate, toDate: event.toDate, proId: event.productId,storageId: event.storageId,partyId: event.partyId,inOut: event.inOut);
         emit(StockRecordLoadedState(cardX));
       }catch(e){
         emit(StockRecordErrorState(e.toString()));
       }
    });
    on<ResetStockRecordEvent>((event, emit) async{
      try{
        emit(StockRecordInitial());
      }catch(e){
        emit(StockRecordErrorState(e.toString()));
      }
    });
  }
}
