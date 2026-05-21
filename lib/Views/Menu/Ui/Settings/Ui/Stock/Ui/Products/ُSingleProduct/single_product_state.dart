part of 'single_product_bloc.dart';

sealed class SingleProductState extends Equatable {}
final class SingleProductInitial extends SingleProductState {
  @override List<Object> get props => [];
}
final class SingleProductLoadingState extends SingleProductState {
  @override List<Object> get props => [];
}
final class SingleProductLoadedState extends SingleProductState {
  final ProductsModel product;
  SingleProductLoadedState(this.product);
  @override List<Object> get props => [product];
}
final class SingleProductErrorState extends SingleProductState {
  final String message;
  SingleProductErrorState(this.message);
  @override List<Object> get props => [message];
}