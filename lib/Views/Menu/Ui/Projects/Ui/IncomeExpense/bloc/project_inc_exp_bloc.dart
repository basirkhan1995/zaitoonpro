import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/IncomeExpense/model/prj_inc_exp_model.dart';

part 'project_inc_exp_event.dart';
part 'project_inc_exp_state.dart';

class ProjectIncExpBloc extends Bloc<ProjectIncExpEvent, ProjectIncExpState> {
  final Repositories _repo;
  ProjectIncExpBloc(this._repo) : super(ProjectIncExpInitial()) {

    on<LoadProjectIncExpEvent>((event, emit) async {
      emit(ProjectIncExpLoadingState());
      try {
        final inOut = await _repo.getProjectIncomeExpense(projectId: event.projectId);
        if (inOut != null) {
          emit(ProjectIncExpLoadedState(inOut));
        } else {
          // Handle case with no data - emit loaded state with empty payments
          emit(ProjectIncExpLoadedState(
            ProjectInOutModel(
              prjId: event.projectId,
              payments: [],
            ),
          ));
        }
      } catch (e) {
        emit(ProjectIncExpErrorState(e.toString()));
      }
    });

    on<AddProjectIncExpEvent>((event, emit) async {
      emit(ProjectIncExpLoadingState());
      try {
        final result = await _repo.addProjectIncomeExpense(newData: event.newData);

        // Check the response message
        if (result['msg'] == 'success') {
          // Reload the data
          add(LoadProjectIncExpEvent(event.newData.prjId!));
          emit(ProjectIncExpSuccessState());
        } else if (result['msg'] == 'blocked') {
          // Handle blocked account case
          emit(ProjectIncExpErrorState(
              'This account is blocked. Please use a different account.'
          ));
        } else {
          emit(ProjectIncExpErrorState(
              result['msg'] ?? 'Failed to add transaction'
          ));
        }
      } catch (e) {
        emit(ProjectIncExpErrorState(e.toString()));
      }
    });

    on<UpdateProjectIncExpEvent>((event, emit) async {
      emit(ProjectIncExpLoadingState());
      try {
        final result = await _repo.updateProjectIncomeExpense(newData: event.newData);

        // Check the response message
        if (result['msg'] == 'success') {
          // Reload the data
          add(LoadProjectIncExpEvent(event.newData.prjId!));
          emit(ProjectIncExpSuccessState());
        } else if (result['msg'] == 'blocked') {
          // Handle blocked account case
          emit(ProjectIncExpErrorState(
              'This account is blocked. Please use a different account.'
          ));
        } else {
          emit(ProjectIncExpErrorState(
              result['msg'] ?? 'Failed to add transaction'
          ));
        }
      } catch (e) {
        emit(ProjectIncExpErrorState(e.toString()));
      }
    });

    on<DeleteProjectIncExpEvent>((event, emit) async {
      emit(ProjectIncExpLoadingState());
      try {
        final result = await _repo.deleteProjectIncomeExpense(usrName: event.usrName, ref: event.reference);

        // Check the response message
        if (result['msg'] == 'success') {
          // Reload the data
          add(LoadProjectIncExpEvent(event.projectId!));
          emit(ProjectIncExpSuccessState());
        } else if (result['msg'] == 'blocked') {
          // Handle blocked account case
          emit(ProjectIncExpErrorState(
              'This account is blocked. Please use a different account.'
          ));
        } else {
          emit(ProjectIncExpErrorState(
              result['msg'] ?? 'Failed to add transaction'
          ));
        }
      } catch (e) {
        emit(ProjectIncExpErrorState(e.toString()));
      }
    });
  }
}
