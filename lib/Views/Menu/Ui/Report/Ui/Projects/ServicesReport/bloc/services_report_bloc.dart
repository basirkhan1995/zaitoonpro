import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Projects/ServicesReport/model/services_report_model.dart';

part 'services_report_event.dart';
part 'services_report_state.dart';

class ServicesReportBloc extends Bloc<ServicesReportEvent, ServicesReportState> {
  final Repositories _repo;
  ServicesReportBloc(this._repo) : super(ServicesReportInitial()) {
    on<LoadServicesReportEvent>((event, emit)async {
      emit(ServicesReportLoadingState());
      try{
        final services = await _repo.getServicesReport(
          fromDate: event.fromDate,
          toDate: event.toDate,
          projectId: event.projectId,
          serviceId: event.serviceId,
          currency: event.currency
        );
        emit(ServicesReportLoadedState(services??[]));
      }catch(e){
        emit(ServicesReportErrorState(e.toString()));
      }
    });
    on<ResetServicesReportEvent>((event, emit)async {
      emit(ServicesReportLoadingState());
      try{
        emit(ServicesReportInitial());
      }catch(e){
        emit(ServicesReportErrorState(e.toString()));
      }
    });
  }
}
