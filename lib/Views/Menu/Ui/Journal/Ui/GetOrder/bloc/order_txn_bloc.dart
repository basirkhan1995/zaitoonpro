import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import '../model/get_order_model.dart';
part 'order_txn_event.dart';
part 'order_txn_state.dart';

class OrderTxnBloc extends Bloc<OrderTxnEvent, OrderTxnState> {
  final Repositories _repo;

  OrderTxnBloc(this._repo) : super(OrderTxnInitial()) {
    on<FetchOrderTxnEvent>((event, emit) async {
      emit(OrderTxnLoadingState());
      try {
        final data = await _repo.fetchOrderTxn(reference: event.reference);
        emit(OrderTxnLoadedState(data: data));
      } catch (e) {
        emit(OrderTxnErrorState(message: e.toString()));
      }
    });
  }
}