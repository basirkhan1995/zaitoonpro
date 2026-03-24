import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import '../model/reminder_model.dart';

part 'reminder_event.dart';
part 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final Repositories _repo;
  int? _currentAlertFilter; 

  ReminderBloc(this._repo) : super(ReminderInitial()) {

    /// LOAD ALERT REMINDERS
    on<LoadAlertReminders>((event, emit) async {
      emit(state.copyWith(loading: true, error: null));
      try {
        final data = await _repo.getAlertReminders(alert: event.alert);
        _currentAlertFilter = event.alert;

        emit(state.copyWith(
          reminders: data,
          loading: false,
        ));
      } catch (e) {
        emit(state.copyWith(
          loading: false,
          error: e.toString(),
        ));
      }
    });

    /// ADD REMINDER
    on<AddReminderEvent>((event, emit) async {
      emit(state.copyWith(loading: true, error: null));

      try {
        final res = await _repo.addNewReminder(newData: event.model);

        if (res['msg'] == "success") {
          // Reload with current filter if exists, otherwise use alert: 1
          final alertToLoad = _currentAlertFilter ?? 1;

          final data = await _repo.getAlertReminders(alert: alertToLoad);

          emit(state.copyWith(
            reminders: data,
            loading: false,
            successMsg: "Reminder Added",
          ));
        } else {
          emit(state.copyWith(
            loading: false,
            error: res['msg'],
          ));
        }
      } catch (e) {
        emit(state.copyWith(
          loading: false,
          error: e.toString(),
        ));
      }
    });

    /// UPDATE REMINDER
    on<UpdateReminderEvent>((event, emit) async {

      /// ⭐ STEP 1 — Update UI immediately
      final updatedList = state.reminders.where((r) {

        if (r.rmdId == event.model.rmdId) {

          /// If reminder is completed and filter = alert list
          if ((_currentAlertFilter ?? 1) == 1 &&
              event.model.rmdStatus == 1) {
            return false; // remove from list
          }
        }

        return true;

      }).map((r) {

        if (r.rmdId == event.model.rmdId) {
          return event.model;
        }

        return r;

      }).toList();

      emit(state.copyWith(
        reminders: updatedList,
        loading: true,
      ));

      /// ⭐ STEP 2 — Call API in background
      try {

        final res = await _repo.updateReminder(newData: event.model);

        if (res['msg'] != "success") {
          throw Exception(res['msg']);
        }

        /// OPTIONAL silent sync
        final data = await _repo.getAlertReminders(
            alert: _currentAlertFilter ?? 1);

        emit(state.copyWith(
          reminders: data,
          loading: false,
        ));

      } catch (e) {

        emit(state.copyWith(
          loading: false,
          error: e.toString(),
        ));

      }
    });

  }
}