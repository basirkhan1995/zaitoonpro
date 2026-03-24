// goods_shift_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/GoodsShift/model/shift_model.dart';

part 'goods_shift_event.dart';
part 'goods_shift_state.dart';

class GoodsShiftBloc extends Bloc<GoodsShiftEvent, GoodsShiftState> {
  final Repositories _repo;

  // Keep track of loaded shifts
  List<GoodShiftModel> _cachedShifts = [];

  GoodsShiftBloc(this._repo) : super(GoodsShiftInitial()) {
    on<LoadGoodsShiftsEvent>(_onLoadGoodsShifts);
    on<LoadGoodsShiftByIdEvent>(_onLoadGoodsShiftById);
    on<AddGoodsShiftEvent>(_onAddGoodsShift);
    on<DeleteGoodsShiftEvent>(_onDeleteGoodsShift);
    on<ReturnToShiftsListEvent>(_onReturnToList);
  }

  Future<void> _onLoadGoodsShifts(LoadGoodsShiftsEvent event, Emitter<GoodsShiftState> emit) async {
    emit(GoodsShiftLoadingState());
    try {
      final shifts = await _repo.getShifts();
      _cachedShifts = shifts; // Cache the shifts
      emit(GoodsShiftLoadedState(shifts));
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
    }
  }

  Future<void> _onLoadGoodsShiftById(LoadGoodsShiftByIdEvent event, Emitter<GoodsShiftState> emit) async {
    try {
      emit(GoodsShiftDetailLoadingState());
      final shifts = await _repo.getShifts(orderId: event.orderId);
      if (shifts.isEmpty) {
        emit(GoodsShiftErrorState('Shift not found'));
        // Return to list if shift not found
        if (_cachedShifts.isNotEmpty) {
          emit(GoodsShiftLoadedState(_cachedShifts));
        }
        return;
      }
      emit(GoodsShiftDetailLoadedState(shifts.first));
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
      // Return to list on error
      if (_cachedShifts.isNotEmpty) {
        emit(GoodsShiftLoadedState(_cachedShifts));
      }
    }
  }

  Future<void> _onAddGoodsShift(AddGoodsShiftEvent event, Emitter<GoodsShiftState> emit) async {
    emit(GoodsShiftSavingState());
    try {
      final response = await _repo.addShift(
        usrName: event.usrName,
        account: event.account,
        amount: event.amount,
        records: event.records,
      );

      final msg = response['msg']?.toString() ?? '';

      if (msg.toLowerCase().contains('success')) {
        // First emit saved state
        emit(GoodsShiftSavedState(message: 'Goods shift created successfully'));

        // Then reload the shifts list
        final shifts = await _repo.getShifts();
        _cachedShifts = shifts;
        emit(GoodsShiftLoadedState(shifts));
      } else {
        emit(GoodsShiftErrorState(msg));
        // Return to cached list on error
        if (_cachedShifts.isNotEmpty) {
          emit(GoodsShiftLoadedState(_cachedShifts));
        }
      }
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
      // Return to cached list on error
      if (_cachedShifts.isNotEmpty) {
        emit(GoodsShiftLoadedState(_cachedShifts));
      }
    }
  }

  Future<void> _onDeleteGoodsShift(DeleteGoodsShiftEvent event, Emitter<GoodsShiftState> emit) async {
    emit(GoodsShiftDeletingState());
    try {
      final response = await _repo.deleteShift(
        orderId: event.orderId,
        usrName: event.usrName,
      );

      final msg = response['msg']?.toString() ?? '';

      if (msg.toLowerCase().contains('success')) {
        // Just emit deleted state
        emit(GoodsShiftDeletedState(message: 'Goods shift deleted successfully'));
      } else {
        emit(GoodsShiftErrorState(msg));
      }
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
    }
  }

  void _onReturnToList(ReturnToShiftsListEvent event, Emitter<GoodsShiftState> emit) {
    // Return to cached list state
    if (_cachedShifts.isNotEmpty) {
      emit(GoodsShiftLoadedState(_cachedShifts));
    } else {
      // If no cache, load fresh data
      add(LoadGoodsShiftsEvent());
    }
  }
}