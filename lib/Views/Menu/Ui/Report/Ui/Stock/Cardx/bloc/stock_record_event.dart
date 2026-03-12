part of 'stock_record_bloc.dart';

sealed class StockRecordEvent extends Equatable {
  const StockRecordEvent();
}


class LoadStockRecordEvent extends StockRecordEvent{
  final String? fromDate;
  final String? toDate;
  final int? productId;
  final int? storageId;
  final int? partyId;
  final String? inOut;
  const LoadStockRecordEvent({this.fromDate, this.toDate, this.productId, this.storageId,this.partyId,this.inOut});
  @override
  List<Object?> get props => [fromDate, toDate, productId, storageId,partyId,inOut];
}

class ResetStockRecordEvent extends StockRecordEvent{
  @override
  List<Object?> get props => [];
}