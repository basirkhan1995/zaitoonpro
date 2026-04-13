import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Orders/model/orders_model.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final Repositories _repo;

  OrdersBloc(this._repo) : super(OrdersInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<UpdateOrdersStatusEvent>(_onUpdateOrdersStatus);
  }

  Future<void> _onLoadOrders(LoadOrdersEvent event, Emitter<OrdersState> emit) async {
    emit(OrdersLoadingState());
    try {
      final orders = await _repo.getOrders(orderId: event.orderId);
      emit(OrdersLoadedState(orders));
    } catch(e) {
      emit(OrdersErrorState(e.toString()));
    }
  }


  Future<void> _onUpdateOrdersStatus(UpdateOrdersStatusEvent event, Emitter<OrdersState> emit,) async {
    emit(OrdersStatusUpdatingState());

    try {
      final response = await _repo.postOrderStatus(event.ordersData);

      final isSuccess =
          response['msg']?.toString().toLowerCase() == 'success';

      final message = response['message']?.toString() ??
          (isSuccess
              ? 'Order status updated successfully'
              : 'Failed to update order status');

      if (isSuccess) {
        // ✅ Emit success FIRST (important for UI)
        emit(OrdersStatusUpdatedState(message));

        add(const LoadOrdersEvent());
      } else {
        emit(OrdersErrorState(message));
      }
    } catch (e) {
      emit(OrdersErrorState(e.toString()));
    }
  }

}