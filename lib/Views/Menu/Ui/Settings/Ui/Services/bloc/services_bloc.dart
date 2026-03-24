import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/model/services_model.dart';

part 'services_event.dart';
part 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final Repositories _repo;
  ServicesBloc(this._repo) : super(ServicesInitial()) {

    on<LoadServicesEvent>((event, emit)async {
      emit(ServicesLoadingState());
      try{
        final pjr = await _repo.getServices(search: event.search);
        emit(ServicesLoadedState(pjr));
      }catch(e){
        emit(ServicesErrorState(e.toString()));
      }
    });
    on<AddServicesEvent>((event, emit)async {
      emit(ServicesLoadingState());
      try{
        final res = await _repo.addService(newData: event.newData);
        final response = res['msg'];
        if(response == "success"){
          emit(ServicesSuccessState());
          add(LoadServicesEvent());
        }else{
          emit(ServicesErrorState(response));
        }
      }catch(e){
        emit(ServicesErrorState(e.toString()));
      }
    });
    on<UpdateServicesEvent>((event, emit)async {
      emit(ServicesLoadingState());
      try{
        final res = await _repo.updateService(newData: event.newData);
        final response = res['msg'];
        if(response == "success"){
          emit(ServicesSuccessState());
          add(LoadServicesEvent());
        }else{
          emit(ServicesErrorState(response));
        }
      }catch(e){
        emit(ServicesErrorState(e.toString()));
      }
    });
    on<DeleteServicesEvent>((event, emit)async {
      emit(ServicesLoadingState());
      try{
        final res = await _repo.deleteService(servicesId: event.pjrId,usrName: event.usrName);
        final response = res['msg'];
        if(response == "success"){
          emit(ServicesSuccessState());
          add(LoadServicesEvent());
        }else{
          emit(ServicesErrorState(response));
        }
      }catch(e){
        emit(ServicesErrorState(e.toString()));
      }
    });

  }
}
