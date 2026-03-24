import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/StockAvailability/model/product_report_model.dart';

part 'product_report_event.dart';
part 'product_report_state.dart';

class ProductReportBloc extends Bloc<ProductReportEvent, ProductReportState> {
  final Repositories _repo;
  ProductReportBloc(this._repo) : super(ProductReportInitial()) {

    on<LoadProductsReportEvent>((event, emit) async{
      emit(ProductReportLoadingState());
      try{
        final stock = await _repo.stockAvailabilityReport(productId: event.productId, storageId: event.storageId,isNoStock: event.isNoStock,);
        emit(ProductReportLoadedState(stock));
      }catch(e){
        emit(ProductReportErrorState(e.toString()));
      }
    });
    on<ResetProductReportEvent>((event, emit) async{
      try{
        emit(ProductReportInitial());
      }catch(e){
        emit(ProductReportErrorState(e.toString()));
      }
    });

  }
}
