import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/OrdersReport/model/order_report_model.dart';

part 'order_report_event.dart';
part 'order_report_state.dart';

class OrderReportBloc extends Bloc<OrderReportEvent, OrderReportState> {
  final Repositories _repo;
  OrderReportBloc(this._repo) : super(OrderReportInitial()) {
    on<LoadOrderReportEvent>((event, emit) async{
      emit(OrderReportLoadingState());
      try{
        final orders = await _repo.ordersReport(fromDate: event.fromDate, toDate: event.toDate, orderName: event.orderName, ordID: event.orderId, customerId: event.customerId, branchId: event.branchId);
        emit(OrderReportLoadedSate(orders));
      }catch(e){
        emit(OrderReportErrorState(e.toString()));
      }
    });

    on<ResetOrderReportEvent>((event, emit) async{
      try{
        emit(OrderReportInitial());
      }catch(e){
        emit(OrderReportErrorState(e.toString()));
      }
    });
  }
}
