// adjustment_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../../../../../../../Services/localization_services.dart';
import '../model/adj_items.dart';
import '../model/adjustment_model.dart';

part 'adjustment_event.dart';
part 'adjustment_state.dart';

class AdjustmentBloc extends Bloc<AdjustmentEvent, AdjustmentState> {
  final Repositories _repo;

  // Keep track of loaded adjustments
  List<AdjustmentModel> _cachedAdjustments = [];

  AdjustmentBloc(this._repo) : super(AdjustmentInitial()) {
    on<InitializeAdjustmentEvent>(_onInitialize);
    on<LoadAdjustmentsEvent>(_onLoadAdjustments);
    on<LoadAdjustmentDetailsEvent>(_onLoadAdjustmentDetails);
    on<AddAdjustmentEvent>(_onAddAdjustment);
    on<DeleteAdjustmentEvent>(_onDeleteAdjustment);
    on<ResetAdjustmentFormEvent>(_onResetForm);
    on<ReturnToListEvent>(_onReturnToList);
  }

  Future<void> _onLoadAdjustments(LoadAdjustmentsEvent event, Emitter<AdjustmentState> emit) async {
    emit(AdjustmentLoadingState());
    try {
      final adjustments = await _repo.allAdjustments();
      _cachedAdjustments = adjustments; // Cache the adjustments
      emit(AdjustmentLoadedState(adjustments));
    } catch (e) {
      emit(AdjustmentErrorState(e.toString()));
    }
  }

  Future<void> _onLoadAdjustmentDetails(LoadAdjustmentDetailsEvent event, Emitter<AdjustmentState> emit) async {
    final tr = localizationService.loc;
    try {
      emit(AdjustmentDetailLoadingState());
      final adjustment = await _repo.getAdjustmentById(orderId: event.orderId);
      if (adjustment != null) {
        // Convert records to AdjustmentItem list for display
        final items = adjustment.records?.map((record) => AdjustmentItem.fromRecord(record)).toList() ?? [];
        emit(AdjustmentDetailLoadedState(adjustment: adjustment, items: items));
      } else {
        emit(AdjustmentErrorState(tr.noDataFound));
        // Return to list if adjustment not found
        if (_cachedAdjustments.isNotEmpty) {
          emit(AdjustmentLoadedState(_cachedAdjustments));
        }
      }
    } catch (e) {
      emit(AdjustmentErrorState(e.toString()));
      // Return to list on error
      if (_cachedAdjustments.isNotEmpty) {
        emit(AdjustmentLoadedState(_cachedAdjustments));
      }
    }
  }

  Future<void> _onAddAdjustment(AddAdjustmentEvent event, Emitter<AdjustmentState> emit) async {
    final tr = localizationService.loc;
    emit(AdjustmentSavingState());
    try {
      final response = await _repo.addAdjustment(
        usrName: event.usrName,
        xReference: event.xReference,
        xAccount: event.xAccount,
        records: event.records,
      );

      final msg = response['msg'];
      if (msg == "success") {
        // First emit saved state
        emit(AdjustmentSavedState(message: tr.successMessage));

        // Then reload the adjustments list
        final adjustments = await _repo.allAdjustments();
        _cachedAdjustments = adjustments;
        emit(AdjustmentLoadedState(adjustments));
      }if(msg == "not enough"){
        emit(AdjustmentErrorState(tr.notEnoughMsg));
        // Return to cached list on error
        if (_cachedAdjustments.isNotEmpty) {
          emit(AdjustmentLoadedState(_cachedAdjustments));
        }
      }if(msg == "not allowed"){
        emit(AdjustmentErrorState(tr.notAllowedError));
        // Return to cached list on error
        if (_cachedAdjustments.isNotEmpty) {
          emit(AdjustmentLoadedState(_cachedAdjustments));
        }
      } else {
        emit(AdjustmentErrorState(msg));
        // Return to cached list on error
        if (_cachedAdjustments.isNotEmpty) {
          emit(AdjustmentLoadedState(_cachedAdjustments));
        }
      }
    } catch (e) {
      emit(AdjustmentErrorState(e.toString()));
      // Return to cached list on error
      if (_cachedAdjustments.isNotEmpty) {
        emit(AdjustmentLoadedState(_cachedAdjustments));
      }
    }
  }

  Future<void> _onDeleteAdjustment(DeleteAdjustmentEvent event, Emitter<AdjustmentState> emit) async {
    final tr = localizationService.loc;
    emit(AdjustmentDeletingState());
    try {
      final response = await _repo.deleteShift(
        orderId: event.orderId,
        usrName: event.usrName,
      );

      final msg = response['msg']?.toString() ?? '';

      if (msg.toLowerCase().contains('success')) {
        // Just emit deleted state
        emit(AdjustmentDeletedState(message: tr.deleteSuccessMessage));
      } else {
        emit(AdjustmentErrorState(msg));
      }
    } catch (e) {
      emit(AdjustmentErrorState(e.toString()));
    }
  }

  void _onInitialize(InitializeAdjustmentEvent event, Emitter<AdjustmentState> emit) {
    // Initialize form with one empty item
    emit(AdjustmentFormLoadedState(
      items: [AdjustmentItem.empty()],
    ));
  }

  void _onResetForm(ResetAdjustmentFormEvent event, Emitter<AdjustmentState> emit) {
    emit(AdjustmentFormLoadedState(
      items: [AdjustmentItem.empty()],
    ));
  }

  void _onReturnToList(ReturnToListEvent event, Emitter<AdjustmentState> emit) {
    // Return to cached list state
    if (_cachedAdjustments.isNotEmpty) {
      emit(AdjustmentLoadedState(_cachedAdjustments));
    } else {
      // If no cache, load fresh data
      add(LoadAdjustmentsEvent());
    }
  }
}