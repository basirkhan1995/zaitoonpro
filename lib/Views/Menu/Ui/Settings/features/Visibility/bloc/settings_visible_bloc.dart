import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'settings_visible_event.dart';
part 'settings_visible_state.dart';

class SettingsVisibleBloc extends Bloc<SettingsVisibleEvent, SettingsVisibilityState> {
  static const String _key = 'visibility_settings';

  SettingsVisibleBloc() : super(SettingsVisibilityState()) {
   on<LoadSettingsEvent>(loadSettingsEvent);
   on<SaveSettingsEvent>(saveSettingsEvent);
   on<UpdateSettingsEvent>(updateSettingsEvent);
  }

  Future<void> loadSettingsEvent(LoadSettingsEvent event, Emitter<SettingsVisibilityState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);


    if (jsonString != null) {
      try {
        final map = json.decode(jsonString) as Map<String, dynamic>;
        final newState = SettingsVisibilityState.fromMap(map);
        emit(newState);
      } catch (e) {
        emit(const SettingsVisibilityState());
      }
    } else {
      emit(const SettingsVisibilityState());
    }
  }

  Future<void> saveSettingsEvent(SaveSettingsEvent event, Emitter<SettingsVisibilityState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(event.value.toMap());
    await prefs.setString(_key, jsonString);
    emit(event.value);
  }

  Future<void> updateSettingsEvent(UpdateSettingsEvent event, Emitter<SettingsVisibilityState> emit) async {

    final updated = SettingsVisibilityState(
      stock: event.stock ?? state.stock,
      benefit: event.benefit ?? state.benefit,
      attendance: event.attendance ?? state.attendance,
      exchangeRate: event.exchangeRate ?? state.exchangeRate,
      currencyRates: event.currencyRates ?? state.currencyRates, // Changed parameter name
      dashboardClock: event.dashboardClock ?? state.dashboardClock,
      quickAccess: event.quickAccess ?? state.quickAccess,
      recentTransactions: event.recentTransactions ?? state.recentTransactions,
      dateType: event.dateType ?? state.dateType,
      isDateExpiry: event.isDateExpiry ?? state.isDateExpiry,
      dateFormat: event.dateFormat ?? state.dateFormat,
      profitAndLoss: event.profitAndLoss ?? state.profitAndLoss,
      transport: event.transport ?? state.transport,
      orders: event.orders ?? state.orders,
      todayTotalTransactions: event.todayTotalTransactions ?? state.todayTotalTransactions,
      statsCount: event.statsCount ?? state.statsCount,
      todayTotalTxnChart: event.todayTotalTxnChart ?? state.todayTotalTxnChart,
      isWholeSale: event.isWholeSale ?? state.isWholeSale
    );


    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(updated.toMap());
    await prefs.setString(_key, jsonString);

    // Verify what was saved
    prefs.getString(_key);

    emit(updated);
  }

}
