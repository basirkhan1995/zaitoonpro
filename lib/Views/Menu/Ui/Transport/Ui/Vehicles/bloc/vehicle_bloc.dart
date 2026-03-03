import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Transport/Ui/Vehicles/model/vehicle_model.dart';


part 'vehicle_event.dart';
part 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final Repositories _repo;
  VehicleBloc(this._repo) : super(VehicleInitial()) {

    on<LoadVehicleEvent>((event, emit) async{
      emit(VehicleLoadingState());
    try{
     final vehicles = await _repo.getVehicles(vehicleId: event.vehicleId);
     emit(VehicleLoadedState(vehicles));
    }catch(e){
      emit(VehicleErrorState(e.toString()));
    }
    });

    on<AddVehicleEvent>((event, emit) async{
      emit(VehicleLoadingState());
      try{
        final response = await _repo.addVehicle(newVehicle: event.newVehicle);
        final msg = response['msg'];
        if(msg == "success"){
          emit(VehicleSuccessState());
          add(LoadVehicleEvent());
        }else if(msg == "failed"){
          emit(VehicleErrorState("Failed operation"));
        }
      }catch(e){
        emit(VehicleErrorState(e.toString()));
      }
    });

    on<UpdateVehicleEvent>((event, emit) async{
      emit(VehicleLoadingState());
      try{
        final response = await _repo.updateVehicle(newVehicle: event.newVehicle);
        final msg = response['msg'];
        if(msg == "success"){
          emit(VehicleSuccessState());
          add(LoadVehicleEvent());
        }else{
          emit(VehicleErrorState(msg));
        }
      }catch(e){
        emit(VehicleErrorState(e.toString()));
      }
    });

    on<LoadVehicleReportEvent>((event, emit) async{
      emit(VehicleLoadingState());
      try{
        final vehicles = await _repo.vehiclesReport(regExpired: event.regExpired);
        emit(VehicleReportLoadedState(vehicles));
      }catch(e){
        emit(VehicleErrorState(e.toString()));
      }
    });


  }
}
