import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/model/emp_model.dart';

import '../../../../../../../Services/localization_services.dart';

part 'employee_event.dart';
part 'employee_state.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final Repositories _repo;
  EmployeeBloc(this._repo) : super(EmployeeInitial()) {
    on<LoadEmployeeEvent>((event, emit)async {
      emit(EmployeeLoadingState());
     try{
      final emp = await _repo.getEmployees(cat: event.cat);
      emit(EmployeeLoadedState(emp));
     }catch(e){
       emit(EmployeeErrorState(e.toString()));
     }
    });
    on<AddEmployeeEvent>((event, emit) async{
      final tr = localizationService.loc;
      emit(EmployeeLoadingState());
       try{
        final response = await _repo.addEmployee(newEmployee: event.newEmployee);
        final msg = response['msg'];
        if(msg == "success"){
          emit(EmployeeSuccessState());
          add(LoadEmployeeEvent());
        }else if(msg == "exist"){
          emit(EmployeeErrorState(tr.alreadyEmployed));
        }else{
          emit(EmployeeErrorState(msg));
        }
       }catch(e){
         emit(EmployeeErrorState(e.toString()));
       }
    });
    on<UpdateEmployeeEvent>((event, emit) async{
      emit(EmployeeLoadingState());
      try{
        final response = await _repo.updateEmployee(newEmployee: event.newEmployee);
        final msg = response['msg'];
        if(msg == "success"){
          emit(EmployeeSuccessState());
          add(LoadEmployeeEvent());
        }else{
          emit(EmployeeErrorState(msg));
        }
      }catch(e){
        emit(EmployeeErrorState(e.toString()));
      }
    });
  }
}
