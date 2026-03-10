import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Transport/Ui/Drivers/model/driver_model.dart';

part 'driver_event.dart';
part 'driver_state.dart';

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final Repositories _repo;
  DriverBloc(this._repo) : super(DriverInitial()) {

    on<LoadDriverEvent>((event, emit) async{
      emit(DriverLoadingState());
     try{
      final driver = await _repo.getDrivers(empId: event.empId);
      emit(DriverLoadedState(driver));
     }catch(e){
       emit(DriverErrorState(e.toString()));
     }
    });

  }
}
