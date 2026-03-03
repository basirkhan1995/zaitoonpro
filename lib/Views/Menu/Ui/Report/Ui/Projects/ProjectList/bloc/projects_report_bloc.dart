import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Projects/ProjectList/model/projects_report_model.dart';

part 'projects_report_event.dart';
part 'projects_report_state.dart';

class ProjectsReportBloc extends Bloc<ProjectsReportEvent, ProjectsReportState> {
  final Repositories _repo;
  ProjectsReportBloc(this._repo) : super(ProjectsReportInitial()) {

    on<LoadProjectReportEvent>((event, emit)async {
      emit(ProjectsReportLoadingState());
       try{
         final prj = await _repo.getProjectsReport(
           fromDate: event.fromDate,
           toDate: event.toDate,
           customerId: event.customerId,
           status: event.status,
           currency: event.currency
         );
         emit(ProjectsReportLoadedState(prj));
       }catch(e){
         emit(ProjectsReportErrorState(e.toString()));
       }
    });

    on<ResetProjectReportEvent>((event, emit)async {
      emit(ProjectsReportLoadingState());
      try{
        emit(ProjectsReportInitial());
      }catch(e){
        emit(ProjectsReportErrorState(e.toString()));
      }
    });

  }
}
