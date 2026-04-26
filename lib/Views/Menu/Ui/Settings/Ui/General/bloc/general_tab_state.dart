part of 'general_tab_bloc.dart';

enum GeneralTabName {system,roles, permissions, profileSettings, password, shortcuts}

class GeneralTabState extends Equatable {
  final GeneralTabName tab;
  const GeneralTabState({this.tab = GeneralTabName.system});
  @override
  List<Object?> get props => [tab];
}

