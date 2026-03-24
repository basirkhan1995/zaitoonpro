import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchTRPT/model/trtp_model.dart';
part 'trpt_event.dart';
part 'trpt_state.dart';

class TrptBloc extends Bloc<TrptEvent, TrptState> {
  final Repositories _repo;
  TrptBloc(this._repo) : super(TrptInitial()) {

    on<LoadTrptEvent>((event, emit) async{
      emit(TrptLoadingState());
       try{
       final trpt = await _repo.getTrpt(reference: event.reference);
       emit(TrptLoadedState(trpt));
       }catch(e){
         emit(TrptErrorState(e.toString()));
       }
    });
  }
}
