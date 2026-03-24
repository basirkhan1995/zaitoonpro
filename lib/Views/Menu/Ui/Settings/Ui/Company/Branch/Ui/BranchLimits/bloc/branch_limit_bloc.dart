import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/Ui/BranchLimits/model/limit_model.dart';

part 'branch_limit_event.dart';
part 'branch_limit_state.dart';

class BranchLimitBloc extends Bloc<BranchLimitEvent, BranchLimitState> {
  final Repositories _repo;
  BranchLimitBloc(this._repo) : super(BranchLimitInitial()) {

    on<LoadBranchLimitEvent>((event, emit) async{
      emit(BranchLimitLoadingState());
     try{
      final limits = await _repo.getBranchLimits(brcCode: event.brcId);
      emit(BranchLimitLoadedState(limits));
     }catch(e){
       emit(BranchLimitErrorState(e.toString()));
     }
    });

    on<AddBranchLimitEvent>((event, emit) async{
      emit(BranchLimitLoadingState());
      try{
        final response = await _repo.addEditBranchLimit(newLimit: event.newLimit);
        if(response['msg'] == "added"){
          emit(BranchLimitSuccessState());
        }
      }catch(e){
        emit(BranchLimitErrorState(e.toString()));
      }
    });

    on<EditBranchLimitEvent>((event, emit) async{
      emit(BranchLimitLoadingState());
      try{
        final response = await _repo.addEditBranchLimit(newLimit: event.newLimit);
        if(response['msg'] == "updated"){
          emit(BranchLimitSuccessState());
        }
      }catch(e){
        emit(BranchLimitErrorState(e.toString()));
      }
    });

  }
}
