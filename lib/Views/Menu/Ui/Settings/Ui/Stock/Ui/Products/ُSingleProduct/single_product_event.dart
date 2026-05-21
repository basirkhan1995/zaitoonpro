part of 'single_product_bloc.dart';

sealed class SingleProductEvent extends Equatable {
  const SingleProductEvent();
}

class LoadSingleProductEvent extends SingleProductEvent {
  final int proId;

  const LoadSingleProductEvent(this.proId);

  @override
  List<Object?> get props => [proId];
}

class ClearSingleProductEvent extends SingleProductEvent {
  const ClearSingleProductEvent();

  @override
  List<Object?> get props => [];
}