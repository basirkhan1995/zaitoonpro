import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../model/glat_model.dart';

part 'glat_event.dart';
part 'glat_state.dart';

class GlatBloc extends Bloc<GlatEvent, GlatState> {
  final Repositories _repo;
  GlatBloc(this._repo) : super(GlatInitial()) {

    on<LoadGlatEvent>((event, emit) async{
      emit(GlatLoadingState());
      try{
       final data = await _repo.getGlatTransaction(event.refNumber);
       emit(GlatLoadedState(data));
      }catch(e){
        emit(GlatErrorState(e.toString()));
      }
    });
  }
}
