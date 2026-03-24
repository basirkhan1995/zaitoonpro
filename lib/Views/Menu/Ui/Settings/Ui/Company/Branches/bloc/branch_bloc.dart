import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../model/branch_model.dart';


part 'branch_event.dart';
part 'branch_state.dart';

class BranchBloc extends Bloc<BranchEvent, BranchState> {
  final Repositories _repo;
  BranchBloc(this._repo) : super(BranchInitial()) {

    on<LoadBranchesEvent>((event, emit) async{
      emit(BranchLoadingState());
      try{
       final brc = await _repo.getBranches(brcId: event.brcId);
       emit(BranchLoadedState(brc));
      }catch(e){
       emit(BranchErrorState(e.toString()));
      }
    });

    on<AddBranchEvent>((event, emit) async{
      emit(BranchLoadingState());
      try{
        final brc = await _repo.addBranch(newBranch: event.newBranch);
        if(brc['msg'] == "success"){
          emit(BranchSuccessState());
          add(LoadBranchesEvent());
        }
      }catch(e){
        emit(BranchErrorState(e.toString()));
      }
    });

    on<EditBranchEvent>((event, emit) async{
      emit(BranchLoadingState());
      try{
        final brc = await _repo.updateBranch(newBranch: event.newBranch);
        if(brc['msg'] == "success"){
          emit(BranchSuccessState());
          add(LoadBranchesEvent());
        }
      }catch(e){
        emit(BranchErrorState(e.toString()));
      }
    });

  }
}
