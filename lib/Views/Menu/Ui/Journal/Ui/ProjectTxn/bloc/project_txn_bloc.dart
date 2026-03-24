import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/ProjectTxn/model/project_txn_model.dart';

part 'project_txn_event.dart';
part 'project_txn_state.dart';

class ProjectTxnBloc extends Bloc<ProjectTxnEvent, ProjectTxnState> {
  final Repositories _repo;
  ProjectTxnBloc(this._repo) : super(ProjectTxnInitial()) {

    on<LoadProjectTxnEvent>((event, emit) async{
      emit(ProjectTxnLoadingState());
      try{
       final txn = await _repo.getProjectTxn(ref: event.ref);
       emit(ProjectTxnLoadedState(txn));
      }catch(e){
        emit(ProjectTxnErrorState(e.toString()));
      }
    });

  }
}
