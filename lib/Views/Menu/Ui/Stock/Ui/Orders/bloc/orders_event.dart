part of 'orders_bloc.dart';

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();
}

class LoadOrdersEvent extends OrdersEvent {
  final int? orderId;
  const LoadOrdersEvent({this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class UpdateOrdersStatusEvent extends OrdersEvent {
  final List<Map<String, dynamic>> ordersData;
  const UpdateOrdersStatusEvent(this.ordersData);

  @override
  List<Object> get props => [ordersData];
}