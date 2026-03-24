import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../model/attendance_report_model.dart';

part 'attendance_report_event.dart';
part 'attendance_report_state.dart';

class AttendanceReportBloc extends Bloc<AttendanceReportEvent, AttendanceReportState> {
  final Repositories _repo;
  AttendanceReportBloc(this._repo) : super(AttendanceReportInitial()) {

    on<LoadAttendanceReportEvent>((event, emit) async{
      emit(AttendanceReportLoadingState());
      try{
       final attendance =  await _repo.attendanceReport(fromDate: event.fromDate, toDate: event.toDate, empId: event.empId, status: event.status);
       emit(AttendanceReportLoadedState(attendance));
      }catch(e){
        emit(AttendanceReportErrorState(e.toString()));
      }
    });

    on<ResetAttendanceReportEvent>((event, emit) async{
      try{
        emit(AttendanceReportInitial());
      }catch(e){
        emit(AttendanceReportErrorState(e.toString()));
      }
    });

  }
}
