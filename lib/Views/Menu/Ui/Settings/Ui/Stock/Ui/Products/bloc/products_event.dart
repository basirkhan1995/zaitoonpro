part of 'products_bloc.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();
}

class LoadProductsEvent extends ProductsEvent{
  final int? proId;
  final String? input;
  const LoadProductsEvent({this.proId,this.input});
  @override
  List<Object?> get props => [proId, input];
}

class LoadProductsStockEvent extends ProductsEvent{
  final int? proId;
  final int? noStock;
  final String? input;
  const LoadProductsStockEvent({this.proId,this.noStock,this.input});
  @override
  List<Object?> get props => [proId, noStock,input];
}

class AddProductEvent extends ProductsEvent{
  final ProductsModel newProduct;
  const AddProductEvent(this.newProduct);
  @override
  List<Object?> get props => [newProduct];
}

class UpdateProductEvent extends ProductsEvent{
  final ProductsModel newProduct;
  const UpdateProductEvent(this.newProduct);
  @override
  List<Object?> get props => [newProduct];
}

class DeleteProductEvent extends ProductsEvent{
  final int proId;
  const DeleteProductEvent(this.proId);
  @override
  List<Object?> get props => [proId];
}
