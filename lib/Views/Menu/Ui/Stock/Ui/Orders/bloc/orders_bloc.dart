import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Orders/model/orders_model.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final Repositories _repo;
  OrdersBloc(this._repo) : super(OrdersInitial()) {

    on<LoadOrdersEvent>((event, emit) async{
       emit(OrdersLoadingState());
       try{
        final orders = await _repo.getOrders(orderId: event.orderId);
        emit(OrdersLoadedState(orders));
       }catch(e){
         emit(OrdersErrorState(e.toString()));
       }
    });
  }
}
