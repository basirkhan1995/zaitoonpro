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

class DeleteOrderEvent extends OrdersEvent {
  final int orderId;
  final String usrName;
  final String? ref;
  final String orderName;

  const DeleteOrderEvent({
    required this.orderId,
    required this.usrName,
    required this.ref,
    required this.orderName,
  });

  @override
  List<Object?> get props => [orderId, usrName, ref, orderName];
}