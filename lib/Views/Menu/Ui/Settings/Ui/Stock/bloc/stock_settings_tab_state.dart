part of 'stock_settings_tab_bloc.dart';

enum StockSettingsTabName {products, proCategory, proUnit, proModel, brands, grade, vehicleType}

class StockSettingsTabState extends Equatable {
  final StockSettingsTabName tab;
  const StockSettingsTabState({this.tab = StockSettingsTabName.products});
  @override
  List<Object?> get props => [tab];
}

