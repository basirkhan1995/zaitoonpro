import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../model/all_balances_model.dart';

part 'all_balances_event.dart';
part 'all_balances_state.dart';

class AllBalancesBloc extends Bloc<AllBalancesEvent, AllBalancesState> {
  final Repositories _repo;
  AllBalancesBloc(this._repo) : super(AllBalancesInitial()) {
    on<LoadAllBalancesEvent>((event, emit) async{
      emit(AllBalancesLoadingState());
      try{
        final balances = await _repo.allBalances(catId: event.catId);
        emit(AllBalancesLoadedState(balances));
      }catch(e){
        emit(AllBalancesErrorState(e.toString()));
      }
    });

    on<ResetAllBalancesEvent>((event, emit) async{
      try{
        emit(AllBalancesInitial());
      }catch(e){
        emit(AllBalancesErrorState(e.toString()));
      }
    });
  }
}
