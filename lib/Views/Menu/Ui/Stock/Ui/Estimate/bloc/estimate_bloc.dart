import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Estimate/model/estimate_model.dart';

part 'estimate_event.dart';
part 'estimate_state.dart';

class EstimateBloc extends Bloc<EstimateEvent, EstimateState> {
  final Repositories _repo;

  EstimateBloc(this._repo) : super(EstimateInitial()) {
    on<LoadEstimatesEvent>(_onLoadEstimates);
    on<LoadEstimateByIdEvent>(_onLoadEstimateById);
    on<AddEstimateEvent>(_onAddEstimate);
    on<UpdateEstimateEvent>(_onUpdateEstimate);
    on<DeleteEstimateEvent>(_onDeleteEstimate);
    on<ConvertEstimateToSaleEvent>(_onConvertToSale);
  }

  Future<void> _onLoadEstimates(
      LoadEstimatesEvent event,
      Emitter<EstimateState> emit,
      ) async {
    emit(EstimateLoading());
    try {
      final estimates = await _repo.getAllEstimates();
      emit(EstimatesLoaded(estimates));
    } catch (e) {
      emit(EstimateError(e.toString()));
    }
  }

  Future<void> _onLoadEstimateById(
      LoadEstimateByIdEvent event,
      Emitter<EstimateState> emit,
      ) async {
    // Don't emit loading if we're already in EstimatesLoaded state
    if (state is! EstimateDetailLoading) {
      emit(EstimateDetailLoading());
    }

    try {
      final estimate = await _repo.getEstimateById(orderId: event.orderId);

      if (estimate == null) {
        emit(EstimateError('Estimate not found'));
        // Return to previous state
        if (state is EstimatesLoaded) {
          emit(state as EstimatesLoaded);
        }
        return;
      }

      // Directly emit the EstimateModel, not the records
      emit(EstimateDetailLoaded(estimate));
    } catch (e) {
      emit(EstimateError(e.toString()));
      // Return to previous state
      if (state is EstimatesLoaded) {
        emit(state as EstimatesLoaded);
      }
    }
  }

  Future<void> _onAddEstimate(AddEstimateEvent event, Emitter<EstimateState> emit) async {
    emit(EstimateSaving());
    try {
      final response = await _repo.addEstimate(
        usrName: event.usrName,
        perID: event.perID,
        xRef: event.xRef,
        records: event.records,
      );

      final msg = response['msg']?.toString() ?? '';

      if (msg.toLowerCase().contains('success')) {
        final estimates = await _repo.getAllEstimates();
        emit(EstimatesLoaded(estimates));
        emit(EstimateSaved(message: 'Estimate created successfully'));
      } else {
        emit(EstimateError(msg));
      }
    } catch (e) {
      emit(EstimateError(e.toString()));
    }
  }

  Future<void> _onUpdateEstimate(UpdateEstimateEvent event, Emitter<EstimateState> emit,) async {
    emit(EstimateSaving());

    try {
      final response = await _repo.updateEstimate(
        usrName: event.usrName,
        orderId: event.orderId,
        perID: event.perID,
        xRef: event.xRef,
        records: event.records,
      );

      final msg = response['msg']?.toString() ?? '';

      if (msg.toLowerCase().contains('success')) {
        // After successful update, reload estimates
        final estimates = await _repo.getAllEstimates();
        emit(EstimatesLoaded(estimates));
        emit(EstimateSaved(message: 'Estimate updated successfully'));
      } else {
        emit(EstimateError(msg));
      }
    } catch (e) {
      emit(EstimateError(e.toString()));
    }
  }

  Future<void> _onDeleteEstimate(
      DeleteEstimateEvent event,
      Emitter<EstimateState> emit,
      ) async {
    emit(EstimateDeleting());

    try {
      final response = await _repo.deleteEstimate(
        orderId: event.orderId,
        usrName: event.usrName,
      );

      final msg = response['msg']?.toString() ?? '';

      if (msg.toLowerCase().contains('success')) {
        // After successful delete, reload estimates
        final estimates = await _repo.getAllEstimates();
        emit(EstimatesLoaded(estimates));
        emit(EstimateDeleted(message: 'Estimate deleted successfully'));
      } else {
        emit(EstimateError(msg));
      }
    } catch (e) {
      emit(EstimateError(e.toString()));
    }
  }

  Future<void> _onConvertToSale(
      ConvertEstimateToSaleEvent event,
      Emitter<EstimateState> emit,
      ) async {
    emit(EstimateConverting());

    try {
      // Handle cash vs credit payment
      int accountToSend = 0;
      String amountToSend = "0";

      if (event.isCash) {
        // For cash payment, account = 0, amount = 0
        accountToSend = 0;
        amountToSend = "0";
      } else {
        // For credit/mixed payment, use provided account and amount
        accountToSend = event.account;
        amountToSend = event.amount;
      }

      final response = await _repo.convertEstimateToSale(
        usrName: event.usrName,
        orderId: event.orderId,
        perID: event.perID,
        account: accountToSend,
        amount: amountToSend,
      );

      final msg = response['msg']?.toString() ?? '';

      if (msg.toLowerCase().contains('success') || msg.toLowerCase().contains('authorized')) {
        // After successful conversion, reload estimates
        final estimates = await _repo.getAllEstimates();
        emit(EstimatesLoaded(estimates));
        emit(EstimateConverted(message: 'Estimate converted to sale successfully'));
      } else if (msg.toLowerCase().contains('not enough')) {
        final sp = response['specific']?.toString() ?? '';
        emit(EstimateError('Inventory quantity not enough: $sp'));
      } else if (msg.toLowerCase().contains('large')) {
        emit(EstimateError('Payment amount exceeds total invoice'));
      } else {
        emit(EstimateError(msg));
      }
    } catch (e) {
      emit(EstimateError(e.toString()));
    }
  }
}