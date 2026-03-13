import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Transport/Ui/Shipping/Ui/ShippingView/model/shp_details_model.dart';
import '../../../../../../../../../Services/localization_services.dart';
import '../model/shipping_model.dart';
part 'shipping_event.dart';
part 'shipping_state.dart';

class ShippingBloc extends Bloc<ShippingEvent, ShippingState> {
  final Repositories _repo;

  ShippingBloc(this._repo) : super(ShippingInitial()) {
    on<LoadShippingEvent>(_onLoadShipping);
    on<LoadShippingDetailEvent>(_onLoadShippingDetail);
    on<ClearDetailLoadingEvent>(_onClearDetailLoading);
    on<UpdateStepperStepEvent>(_onUpdateStepperStep);
    on<AddShippingEvent>(_onAddShipping);
    on<UpdateShippingEvent>(_onUpdateShipping);
    on<ClearShippingDetailEvent>(_onClearShippingDetail);
    on<ClearShippingSuccessEvent>(_onClearShippingSuccess);
    on<AddShippingExpenseEvent>(_onAddShippingExpense);
    on<UpdateShippingExpenseEvent>(_onUpdateShippingExpense);
    on<AddShippingPaymentEvent>(_onAddShippingPayment);
    on<EditShippingPaymentEvent>(_onEditShippingPayment);
  }

  Future<void> _onLoadShipping(
      LoadShippingEvent event,
      Emitter<ShippingState> emit,
      ) async {
    emit(ShippingListLoadingState(
      shippingList: state.shippingList,
      currentShipping: state.currentShipping,
      loadingShpId: state.loadingShpId,
      isLoading: true,
    ));

    try {
      final shippingList = await _repo.getAllShipping();
      emit(ShippingListLoadedState(
        shippingList: shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: state.loadingShpId,
      ));
    } catch (e) {
      emit(ShippingErrorState(
        shippingList: state.shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: state.loadingShpId,
        error: 'Failed to load shipping: $e',
      ));
    }
  }


  Future<void> _onLoadShippingDetail(
      LoadShippingDetailEvent event,
      Emitter<ShippingState> emit,
      ) async {
    // If already loading this shipping or already showing it, do nothing
    if (state.loadingShpId == event.shpId ||
        (state.currentShipping?.shpId == event.shpId && state is! ShippingDetailLoadedState)) {
      return;
    }

    // Start loading for this specific shipping
    emit(ShippingDetailLoadingState(
      shippingList: state.shippingList,
      currentShipping: state.currentShipping,
      loadingShpId: event.shpId,
    ));

    try {
      final shippingDetail = await _repo.getShippingById(shpId: event.shpId);

      // Update the list item if it exists
      final updatedList = state.shippingList.map((shp) {
        if (shp.shpId == event.shpId) {
          return shp.copyWith(
            shpUnloadSize: shippingDetail.shpUnloadSize,
            total: shippingDetail.total,
            shpStatus: shippingDetail.shpStatus,
          );
        }
        return shp;
      }).toList();

      emit(ShippingDetailLoadedState(
        shippingList: updatedList,
        currentShipping: shippingDetail,
        loadingShpId: null, // Clear loading after success
        shouldOpenDialog: true, // Flag to indicate dialog should open
      ));
    } catch (e) {
      // Keep the existing data but show error
      emit(ShippingErrorState(
        shippingList: state.shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: null, // Clear loading on error
        error: 'Failed to load shipping details: $e',
      ));
    }
  }

  void _onClearDetailLoading(
      ClearDetailLoadingEvent event,
      Emitter<ShippingState> emit,
      ) {
    // Return to list loaded state without loading indicator
    emit(ShippingListLoadedState(
      shippingList: state.shippingList,
      currentShipping: state.currentShipping,
      loadingShpId: null,
    ));
  }

  void _onClearShippingDetail(
      ClearShippingDetailEvent event,
      Emitter<ShippingState> emit,
      ) {
    emit(ShippingListLoadedState(
      shippingList: state.shippingList,
      currentShipping: null,
      loadingShpId: null, // Also clear loading ID
    ));
  }

  void _onClearShippingSuccess(
      ClearShippingSuccessEvent event,
      Emitter<ShippingState> emit,
      ) {
    // Clear success state and go back to loaded state
    emit(ShippingListLoadedState(
      shippingList: state.shippingList,
      currentShipping: state.currentShipping,
      loadingShpId: state.loadingShpId,
    ));
  }

  void _onUpdateStepperStep(
      UpdateStepperStepEvent event,
      Emitter<ShippingState> emit,
      ) {
    // If we have current shipping, maintain the state
    if (state.currentShipping != null) {
      emit(state.copyWith());
    }
  }

  Future<void> _onAddShipping(
      AddShippingEvent event,
      Emitter<ShippingState> emit,
      ) async {
    emit(ShippingListLoadingState(
      shippingList: state.shippingList,
      currentShipping: state.currentShipping,
      loadingShpId: state.loadingShpId,
      isLoading: true,
    ));

    try {
      final res = await _repo.addShipping(newShipping: event.newShipping);

      if (res['msg'] == "success") {
        final updatedList = await _repo.getAllShipping();
        final shpId = res['shpID'];

        ShippingDetailsModel? shippingDetail;
        if (shpId != null) {
          try {
            shippingDetail = await _repo.getShippingById(shpId: shpId);
          } catch (e) {
            // If can't get detail, continue with null
          }
        }

        emit(ShippingSuccessState(
          shippingList: updatedList,
          currentShipping: shippingDetail,
          loadingShpId: null,
          message: 'Shipping added successfully',
        ));
      } else {
        throw Exception(res['msg'] ?? 'Failed to add shipping');
      }
    } catch (e) {
      emit(ShippingErrorState(
        shippingList: state.shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: null,
        error: 'Failed to add shipping: $e',
      ));
    }
  }

  Future<void> _onUpdateShipping(
      UpdateShippingEvent event,
      Emitter<ShippingState> emit,
      ) async {
    emit(ShippingListLoadingState(
      shippingList: state.shippingList,
      currentShipping: state.currentShipping,
      loadingShpId: state.loadingShpId,
      isLoading: true,
    ));

    try {
      final res = await _repo.updateShipping(newShipping: event.updatedShipping);

      if (res['msg'] == "success") {
        final updatedList = await _repo.getAllShipping();

        ShippingDetailsModel? updatedCurrentShipping = state.currentShipping;
        if (state.currentShipping?.shpId == event.updatedShipping.shpId) {
          updatedCurrentShipping = ShippingDetailsModel(
            shpId: event.updatedShipping.shpId ?? 0,
            vehicle: event.updatedShipping.vehicle,
            vclId: event.updatedShipping.vehicleId,
            proName: event.updatedShipping.proName,
            proId: event.updatedShipping.productId,
            customer: event.updatedShipping.customer,
            shpFrom: event.updatedShipping.shpFrom,
            shpMovingDate: event.updatedShipping.shpMovingDate,
            shpLoadSize: event.updatedShipping.shpLoadSize,
            shpUnit: event.updatedShipping.shpUnit,
            shpTo: event.updatedShipping.shpTo,
            shpArriveDate: event.updatedShipping.shpArriveDate,
            shpUnloadSize: event.updatedShipping.shpUnloadSize,
            shpRent: event.updatedShipping.shpRent,
            total: event.updatedShipping.total,
            shpStatus: event.updatedShipping.shpStatus,
            pyment: state.currentShipping?.pyment ?? [],
            expenses: state.currentShipping?.expenses ?? [],
          );
        }

        emit(ShippingSuccessState(
          shippingList: updatedList,
          currentShipping: updatedCurrentShipping,
          loadingShpId: null,
          message: 'Shipping updated successfully',
        ));
      } else {
        throw Exception(res['msg'] ?? 'Failed to update shipping');
      }
    } catch (e) {
      emit(ShippingErrorState(
        shippingList: state.shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: null,
        error: 'Failed to update shipping: $e',
      ));
    }
  }

  Future<void> _onAddShippingExpense(
      AddShippingExpenseEvent event,
      Emitter<ShippingState> emit,
      ) async {
    if (state.currentShipping == null) return;

    // Show loading for this specific operation
    emit(state.copyWith(
      loadingShpId: event.shpId,
    ));

    try {
      final res = await _repo.addShippingExpense(
        shpId: event.shpId,
        accNumber: event.accNumber,
        amount: event.amount,
        narration: event.narration,
        usrName: event.usrName,
      );

      if (res['msg'] == "success") {
        // Get ONLY the updated expenses for this shipping
        final updatedShipping = await _repo.getShippingById(shpId: event.shpId);

        // Update the current state with new shipping details
        emit(ShippingDetailLoadedState(
          shippingList: state.shippingList,
          currentShipping: updatedShipping,
          loadingShpId: null, // Clear loading
          shouldOpenDialog: false, // Don't reopen dialog
        ));
      } else if (res['msg'] == "delivered") {
        emit(ShippingErrorState(
          shippingList: state.shippingList,
          currentShipping: state.currentShipping,
          loadingShpId: null,
          error: 'Cannot add expense to delivered shipping',
        ));
      } else {
        throw Exception(res['msg'] ?? 'Failed to add expense');
      }
    } catch (e) {
      emit(ShippingErrorState(
        shippingList: state.shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: null,
        error: 'Failed to add expense: $e',
      ));
    }
  }

  Future<void> _onAddShippingPayment(AddShippingPaymentEvent event, Emitter<ShippingState> emit) async {
    final tr = localizationService.loc;
    if (state.currentShipping == null) return;

    // Show loading for this specific operation
    emit(state.copyWith(
      loadingShpId: event.shpId,
    ));

    try {
      final res = await _repo.addShippingPayment(
        shpId: event.shpId,
        accNumber: event.accNumber,
        paymentType: event.paymentType,
        cashAmount: event.cashAmount,
        accountAmount: event.accountAmount,
        usrName: event.usrName,
      );

      if (res['msg'] == "success") {
        // Get ONLY the updated expenses for this shipping
        final updatedShipping = await _repo.getShippingById(shpId: event.shpId);

        // Update the current state with new shipping details
        emit(ShippingDetailLoadedState(
          shippingList: state.shippingList,
          currentShipping: updatedShipping,
          loadingShpId: null, // Clear loading
          shouldOpenDialog: false, // Don't reopen dialog
        ));
      } else if (res['msg'] == "delivered") {
        emit(ShippingErrorState(
          shippingList: state.shippingList,
          currentShipping: state.currentShipping,
          loadingShpId: null,
          error: 'Cannot add payment to delivered shipping',
        ));
      }else if (res['msg'] == "over limit") {
        emit(ShippingErrorState(
          shippingList: state.shippingList,
          currentShipping: state.currentShipping,
          loadingShpId: null,
          error: tr.overLimitMessage,
        ));
      }else if (res['msg'] == "blocked") {
        emit(ShippingErrorState(
          shippingList: state.shippingList,
          currentShipping: state.currentShipping,
          loadingShpId: null,
          error: tr.blockedAccountMessage,
        ));
      } else {
        throw Exception(res['msg'] ?? 'Failed to add payment');
      }
    } catch (e) {
      emit(ShippingErrorState(
        shippingList: state.shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: null,
        error: 'Failed to add payment: $e',
      ));
    }
  }
  Future<void> _onEditShippingPayment(EditShippingPaymentEvent event, Emitter<ShippingState> emit) async {
    final tr = localizationService.loc;
    if (state.currentShipping == null) return;

    // Show loading for this specific operation
    emit(state.copyWith(
      loadingShpId: event.shpId,
    ));

    try {
      final res = await _repo.editShippingPayment(
        reference: event.reference,
        shpId: event.shpId,
        accNumber: event.accNumber,
        paymentType: event.paymentType,
        cashAmount: event.cashAmount,
        accountAmount: event.accountAmount,
        usrName: event.usrName,
      );

      if (res['msg'] == "success") {
        // Get ONLY the updated expenses for this shipping
        final updatedShipping = await _repo.getShippingById(shpId: event.shpId);

        // Update the current state with new shipping details
        emit(ShippingDetailLoadedState(
          shippingList: state.shippingList,
          currentShipping: updatedShipping,
          loadingShpId: null, // Clear loading
          shouldOpenDialog: false, // Don't reopen dialog
        ));
      } else if (res['msg'] == "delivered") {
        emit(ShippingErrorState(
          shippingList: state.shippingList,
          currentShipping: state.currentShipping,
          loadingShpId: null,
          error: 'Cannot add payment to delivered shipping',
        ));
      }else if (res['msg'] == "over limit") {
        emit(ShippingErrorState(
          shippingList: state.shippingList,
          currentShipping: state.currentShipping,
          loadingShpId: null,
          error: tr.overLimitMessage,
        ));
      }else if (res['msg'] == "blocked") {
        emit(ShippingErrorState(
          shippingList: state.shippingList,
          currentShipping: state.currentShipping,
          loadingShpId: null,
          error: tr.blockedAccountMessage,
        ));
      } else {
        throw Exception(res['msg'] ?? 'Failed to add payment');
      }
    } catch (e) {
      emit(ShippingErrorState(
        shippingList: state.shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: null,
        error: 'Failed to add payment: $e',
      ));
    }
  }

  Future<void> _onUpdateShippingExpense(
      UpdateShippingExpenseEvent event,
      Emitter<ShippingState> emit,
      ) async {
    if (state.currentShipping == null) return;

    // Show loading for this specific operation
    emit(state.copyWith(
      loadingShpId: event.shpId,
    ));

    try {
      final res = await _repo.updateShippingExpense(
        shpId: event.shpId,
        reference: event.trnReference,
        amount: event.amount,
        narration: event.narration,
        usrName: event.usrName,
      );

      if (res['msg'] == "success") {
        // Get ONLY the updated expenses
        final updatedShipping = await _repo.getShippingById(shpId: event.shpId);

        // Update the current state
        emit(ShippingDetailLoadedState(
          shippingList: state.shippingList,
          currentShipping: updatedShipping,
          loadingShpId: null,
          shouldOpenDialog: false, // Don't reopen dialog
        ));
      } else if (res['msg'] == "delivered") {
        emit(ShippingErrorState(
          shippingList: state.shippingList,
          currentShipping: state.currentShipping,
          loadingShpId: null,
          error: 'Cannot update expense of delivered shipping',
        ));
      } else {
        throw Exception(res['msg'] ?? 'Failed to update expense');
      }
    } catch (e) {
      emit(ShippingErrorState(
        shippingList: state.shippingList,
        currentShipping: state.currentShipping,
        loadingShpId: null,
        error: 'Failed to update expense: $e',
      ));
    }
  }


}