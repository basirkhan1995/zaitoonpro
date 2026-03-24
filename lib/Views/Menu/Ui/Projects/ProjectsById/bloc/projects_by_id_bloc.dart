
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/ProjectsById/model/project_by_id_model.dart';

part 'projects_by_id_event.dart';
part 'projects_by_id_state.dart';

class ProjectsByIdBloc extends Bloc<ProjectsByIdEvent, ProjectsByIdState> {
  final Repositories _repo;

  ProjectsByIdBloc(this._repo) : super(ProjectsByIdInitial()) {
    on<LoadProjectByIdEvent>((event, emit) async {
      emit(ProjectByIdLoadingState());
      try {
        final project = await _repo.getProjectById(prjId: event.prjId);
        emit(ProjectByIdLoadedState(project));
      } catch (e) {
        emit(ProjectByIdErrorState(e.toString()));
      }
    });

    on<ResetProjectByIdEvent>((event, emit) async {
      emit(ProjectsByIdInitial());
    });
  }
}