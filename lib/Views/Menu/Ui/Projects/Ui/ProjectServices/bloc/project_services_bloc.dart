import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/ProjectServices/model/project_services_model.dart';

part 'project_services_event.dart';
part 'project_services_state.dart';

class ProjectServicesBloc extends Bloc<ProjectServicesEvent, ProjectServicesState> {
  final Repositories _repo;
  ProjectServicesBloc(this._repo) : super(ProjectServicesInitial()) {
    on<LoadProjectServiceEvent>((event, emit)async {
      emit(ProjectServicesLoadingState());
      try{
        final services = await _repo.getProjectServices(projectId: event.projectId);
        emit(ProjectServicesLoadedState(services));
      }catch(e){
        emit(ProjectServicesErrorState(e.toString()));
      }
    });
    on<AddProjectServiceEvent>((event, emit)async {
      emit(ProjectServicesLoadingState());
      try{
        final services = await _repo.addProjectServices(newData: event.newService);
        final msg = services['msg'];
        if(msg == "success"){
          emit(ProjectServicesSuccessState());
          if(event.newService.prjId !=null){
            add(LoadProjectServiceEvent(event.newService.prjId!));
          }
        }else{
          emit(ProjectServicesErrorState(msg));
        }
      }catch(e){
        emit(ProjectServicesErrorState(e.toString()));
      }
    });
    on<UpdateProjectServiceEvent>((event, emit)async {
      emit(ProjectServicesLoadingState());
      try{
        final services = await _repo.updateProjectServices(newData: event.newService);
        final msg = services['msg'];
        if(msg == "success"){
          emit(ProjectServicesSuccessState());
          if(event.newService.prjId !=null){
            add(LoadProjectServiceEvent(event.newService.prjId!));
          }
        }else{
          emit(ProjectServicesErrorState(msg));
        }
      }catch(e){
        emit(ProjectServicesErrorState(e.toString()));
      }
    });
    on<DeleteProjectServiceEvent>((event, emit)async {
      emit(ProjectServicesLoadingState());
      try{
        final services = await _repo.deleteProjectServices(pjdID: event.pjdId, usrName: event.usrName);
        final msg = services['msg'];
        if(msg == "success"){
          emit(ProjectServicesSuccessState());
          add(LoadProjectServiceEvent(event.projectId));
          }else{
          emit(ProjectServicesErrorState(msg));
        }
      }catch(e){
        emit(ProjectServicesErrorState(e.toString()));
      }
    });
  }
}
