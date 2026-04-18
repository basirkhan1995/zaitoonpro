import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';

part 'currencies_event.dart';
part 'currencies_state.dart';

class CurrenciesBloc extends Bloc<CurrenciesEvent, CurrenciesState> {
  final Repositories _repo;
  CurrenciesBloc(this._repo) : super(CurrenciesInitial()) {
    on<LoadCurrenciesEvent>((event, emit) async{
      emit(CurrenciesLoadingState());
     try{
      final ccy = await _repo.getCurrencies(status: event.status);
      emit(CurrenciesLoadedState(ccy));
     }catch(e){
       emit(CurrenciesErrorState(e.toString()));
     }
    });
    on<UpdateCcyStatusEvent>((event, emit) async{
      emit(CurrenciesLoadingState());
      try{
        final ccy = await _repo.updateCcyStatus(status: event.status,ccyCode: event.ccyCode);
        if(ccy['msg'] == "success"){
          add(LoadCurrenciesEvent());
        }
      }catch(e){
        emit(CurrenciesErrorState(e.toString()));
      }
    });
  }
}
