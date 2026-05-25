part of 'product_report_bloc.dart';

sealed class ProductReportEvent extends Equatable {
  const ProductReportEvent();
}


class LoadProductsReportEvent extends ProductReportEvent{
  final int? productId;
  final int? storageId;
  final int? categoryId;
  final int? isNoStock;
  final int? lowStock;

  const LoadProductsReportEvent({this.productId, this.storageId, this.categoryId, this.isNoStock, this.lowStock});
  @override
  List<Object?> get props => [productId, storageId,categoryId, isNoStock, lowStock];
}

class ResetProductReportEvent extends ProductReportEvent{
  @override
  List<Object?> get props => [];
}