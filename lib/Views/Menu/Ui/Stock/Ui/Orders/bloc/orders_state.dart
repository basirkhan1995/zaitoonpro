part of 'orders_bloc.dart';

sealed class OrdersState extends Equatable {
  const OrdersState();
}

final class OrdersInitial extends OrdersState {
  @override
  List<Object> get props => [];
}

final class OrdersLoadingState extends OrdersState {
  @override
  List<Object> get props => [];
}

final class OrdersSuccessState extends OrdersState {
  @override
  List<Object> get props => [];
}

final class OrdersErrorState extends OrdersState {
  final String message;
  const OrdersErrorState(this.message);

  @override
  List<Object> get props => [message];
}

final class OrdersLoadedState extends OrdersState {
  final List<OrdersModel> order;
  const OrdersLoadedState(this.order);

  @override
  List<Object> get props => [order];
}

final class OrdersStatusUpdatingState extends OrdersState {
  @override
  List<Object> get props => [];
}

final class OrdersStatusUpdatedState extends OrdersState {
  final String message;
  const OrdersStatusUpdatedState(this.message);

  @override
  List<Object> get props => [message];
}

final class OrdersDeletingState extends OrdersState {
  final int orderId;
  const OrdersDeletingState(this.orderId);

  @override
  List<Object> get props => [orderId];
}

final class OrdersDeletedState extends OrdersState {
  final bool success;
  final String message;
  const OrdersDeletedState(this.success, {required this.message});

  @override
  List<Object> get props => [success, message];
}