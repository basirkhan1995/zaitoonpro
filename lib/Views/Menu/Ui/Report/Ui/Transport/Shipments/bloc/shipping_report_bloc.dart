import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../model/shp_report_model.dart';

part 'shipping_report_event.dart';
part 'shipping_report_state.dart';

class ShippingReportBloc extends Bloc<ShippingReportEvent, ShippingReportState> {
  final Repositories _repo;
  ShippingReportBloc(this._repo) : super(ShippingReportInitial()) {


    on<LoadShippingReportEvent>((event, emit) async{
      emit(ShippingReportLoadingState());
      try{
        final shp = await _repo.getShippingReport(fromDate: event.fromDate, toDate: event.toDate, status: event.status, customer: event.customerId,driverId: event.driverId, vehicle: event.vehicleId);
        emit(ShippingReportLoadedState(shp));
      }catch(e){
        emit(ShippingReportErrorState(e.toString()));
      }
    });


    on<ResetShippingReportEvent>((event, emit) async{
      try{
        emit(ShippingReportInitial());
      }catch(e){
        emit(ShippingReportErrorState(e.toString()));
      }
    });


  }
}
