part of 'gl_accounts_bloc.dart';

sealed class GlAccountsEvent extends Equatable {
  const GlAccountsEvent();
}

class LoadGlAccountEvent extends GlAccountsEvent{
  final String? query;
  const LoadGlAccountEvent({this.query});
  @override
  List<Object?> get props => [query];
}

class AddGlEvent extends GlAccountsEvent{
  final GlAccountsModel newGl;
  const AddGlEvent(this.newGl);
  @override
  List<Object?> get props => [newGl];
}

class UpdateGlEvent extends GlAccountsEvent{
  final GlAccountsModel newGl;
  const UpdateGlEvent(this.newGl);
  @override
  List<Object?> get props => [newGl];
}

class DeleteGlEvent extends GlAccountsEvent{
  final int accNumber;
  const DeleteGlEvent(this.accNumber);
  @override
  List<Object?> get props => [accNumber];
}