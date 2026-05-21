part of 'products_bloc.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();
}

final class ProductsInitial extends ProductsState {
  @override
  List<Object> get props => [];
}


final class ProductsLoadingState extends ProductsState {
  @override
  List<Object> get props => [];
}

final class ProductsLoadedState extends ProductsState {
  final List<ProductsModel> products;
  const ProductsLoadedState(this.products);
  @override
  List<Object> get props => [products];
}

final class ProductsStockLoadedState extends ProductsState {
  final List<ProductsStockModel> products;
  const ProductsStockLoadedState(this.products);
  @override
  List<Object> get props => [products];
}

final class ProductsSuccessState extends ProductsState {
  @override
  List<Object> get props => [];
}

final class ProductsErrorState extends ProductsState {
  final String message;
  const ProductsErrorState(this.message);
  @override
  List<Object> get props => [message];
}


final class ProductSingleLoadedState extends ProductsState {
  final ProductsModel product;
  const ProductSingleLoadedState(this.product);

  @override
  List<Object> get props => [product];
}