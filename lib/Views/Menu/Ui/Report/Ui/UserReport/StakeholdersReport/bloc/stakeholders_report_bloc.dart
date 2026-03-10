import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/UserReport/StakeholdersReport/model/ind_report_model.dart';

part 'stakeholders_report_event.dart';
part 'stakeholders_report_state.dart';

class StakeholdersReportBloc extends Bloc<StakeholdersReportEvent, StakeholdersReportState> {
  final Repositories _repo;
  StakeholdersReportBloc(this._repo) : super(StakeholdersReportInitial()) {

    on<LoadStakeholdersReportEvent>((event, emit) async{
      emit(StakeholdersReportLoadingState());
      try{
       final res = await _repo.getStakeholdersReport(search: event.search, dob: event.dob, gender: event.gender, phone: event.phone);
       emit(StakeholdersReportLoadedState(res));
      }catch(e){
        emit(StakeholdersReportErrorState(e.toString()));
      }
    });

    on<ResetStakeholdersReportEvent>((event, emit) async{
      try{
        emit(StakeholdersReportInitial());
      }catch(e){
        emit(StakeholdersReportErrorState(e.toString()));
      }
    });
  }
}
