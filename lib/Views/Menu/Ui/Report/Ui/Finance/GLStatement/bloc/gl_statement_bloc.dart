import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/GLStatement/model/gl_statement_model.dart';

part 'gl_statement_event.dart';
part 'gl_statement_state.dart';

class GlStatementBloc extends Bloc<GlStatementEvent, GlStatementState> {
  final Repositories _repo;
  GlStatementBloc(this._repo) : super(GlStatementInitial()) {

    on<LoadGlStatementEvent>((event, emit) async{
      emit(GlStatementLoadingState());
      try{
        final stmt = await _repo.getGlStatement(
            branchCode: event.branchCode,
            currency: event.currency,
            account: event.accountNumber,
            fromDate: event.fromDate,
            toDate: event.toDate);
        emit(GlStatementLoadedState(stmt: stmt));
      }catch(e){
        emit(GlStatementErrorState(e.toString()));
      }
    });
    on<ResetGlStmtEvent>((event,emit){
      emit(GlStatementInitial());
    });
  }
}
