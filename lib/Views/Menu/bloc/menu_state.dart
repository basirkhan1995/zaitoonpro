part of 'menu_bloc.dart';

enum MenuName {dashboard, finance,journal, hr, stakeholders,stock,settings,report}

final class MenuState extends Equatable {
  final MenuName tabs;
  const MenuState({this.tabs = MenuName.dashboard});
  @override
  List<Object> get props => [tabs];
}

