import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../../../../../../../Services/localization_services.dart';
import '../model/pjr_model.dart';

part 'projects_event.dart';
part 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final Repositories _repo;
  ProjectsBloc(this._repo) : super(ProjectsInitial()) {

    on<LoadProjectsEvent>((event, emit)async {
      emit(ProjectsLoadingState());
     try{
      final pjr = await _repo.getProjects(prjId: event.prjId);
      emit(ProjectsLoadedState(pjr));
     }catch(e){
       emit(ProjectsErrorState(e.toString()));
     }
    });
    on<AddProjectEvent>((event, emit)async {
      emit(ProjectsLoadingState());
      try{
        final res = await _repo.addProject(newData: event.newData);
        final response = res['msg'];
        if(response == "success"){
          emit(ProjectSuccessState());
          add(LoadProjectsEvent());
        }else{
          emit(ProjectsErrorState(response));
        }
      }catch(e){
        emit(ProjectsErrorState(e.toString()));
      }
    });
    on<UpdateProjectEvent>((event, emit)async {
      final tr = localizationService.loc;
      emit(ProjectsLoadingState());
      try{
        final res = await _repo.updateProject(newData: event.newData);
        final response = res['msg'];
        if(response == "success"){
          emit(ProjectSuccessState());
          add(LoadProjectsEvent());
        }if(response == "payment mismatch"){
          emit(ProjectsErrorState(tr.paymentNotMatch));
        }else{
          emit(ProjectsErrorState(response));
        }
      }catch(e){
        emit(ProjectsErrorState(e.toString()));
      }
    });
    on<DeleteProjectEvent>((event, emit)async {
      final tr = localizationService.loc;
      emit(ProjectsLoadingState());
      try{
        final res = await _repo.deleteProject(projectId: event.pjrId,usrName: event.usrName);
        final response = res['msg'];
        if(response == "success"){
          emit(ProjectSuccessState());
          add(LoadProjectsEvent());
        }else if(response == "dependency"){
          emit(ProjectsErrorState(tr.projectDependency));
        } else{
          emit(ProjectsErrorState(response));
        }
      }catch(e){
        emit(ProjectsErrorState(e.toString()));
      }
    });

  }
}
