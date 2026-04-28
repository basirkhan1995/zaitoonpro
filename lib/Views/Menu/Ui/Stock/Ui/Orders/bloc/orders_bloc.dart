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
    on<DeleteOrderEvent>(_onDeleteOrder);
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

  Future<void> _onUpdateOrdersStatus(UpdateOrdersStatusEvent event, Emitter<OrdersState> emit) async {
    emit(OrdersStatusUpdatingState());

    try {
      final response = await _repo.postOrderStatus(event.ordersData);

      final isSuccess = response['msg']?.toString().toLowerCase() == 'success';
      final message = response['message']?.toString() ??
          (isSuccess ? 'Order status updated successfully' : 'Failed to update order status');

      if (isSuccess) {
        emit(OrdersStatusUpdatedState(message));
        add(const LoadOrdersEvent()); // Refresh the list
      } else {
        emit(OrdersErrorState(message));
      }
    } catch (e) {
      emit(OrdersErrorState(e.toString()));
    }
  }

  // Add this new delete handler
  Future<void> _onDeleteOrder(DeleteOrderEvent event, Emitter<OrdersState> emit) async {
    // Save current state to revert if needed
    final previousState = state;

    try {
      // Emit deleting state
      emit(OrdersDeletingState(event.orderId));

      // Call the repository delete method
      final success = await _repo.deleteOrder(
        orderId: event.orderId,
        usrName: event.usrName,
        ref: event.ref,
        ordName: event.orderName,
      );

      if (success) {
        // Emit success
        emit(OrdersDeletedState(true, message: '${event.orderName} order deleted successfully'));

        // Refresh the orders list by loading orders again
        add(const LoadOrdersEvent());
      } else {
        // Emit error - order might be verified/authorized
        emit(OrdersDeletedState(false, message: 'Failed to delete ${event.orderName} order. The order may be verified or authorized.'));

        // Restore previous state if it was a loaded state
        if (previousState is OrdersLoadedState) {
          emit(previousState);
        } else {
          // If not loaded, refresh the list
          add(const LoadOrdersEvent());
        }
      }
    } catch (e) {
      String errorMessage;
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('authorized') ||
          errorString.contains('verified') ||
          errorString.contains('cannot delete')) {
        errorMessage = 'Cannot delete order: The transaction is verified and cannot be deleted.';
      } else {
        errorMessage = 'Error deleting order: ${e.toString()}';
      }

      emit(OrdersDeletedState(false, message: errorMessage));

      // Restore previous state
      if (previousState is OrdersLoadedState) {
        emit(previousState);
      } else {
        add(const LoadOrdersEvent());
      }
    }
  }
}