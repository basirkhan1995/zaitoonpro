import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/localization_services.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/model/transaction_model.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final Repositories _repo;
  TransactionsBloc(this._repo) : super(TransactionsInitial()) {
    on<LoadAllTransactionsEvent>((event, emit) async{
      emit(TxnLoadingState());
      try{
        final txn = await _repo.getTransactionsByStatus(status: event.status);
        emit(TransactionLoadedState(txn: txn));
      }catch(e){
        emit(TransactionErrorState(e.toString()));
      }
    });
    on<OnCashTransactionEvent>((event, emit) async {
      final locale = localizationService.loc;

      emit(TxnLoadingState());

      try {
        final response = await _repo.cashFlowOperations(
          newTransaction: event.transaction,
        );

        final msg = response['msg']; // may exist only for error cases

        // If msg exists => it's always an error
        if (msg != null) {
          switch (msg) {
            case "over limit":
              emit(TransactionErrorState(locale.accountLimitMessage));
              return;

            case "blocked":
              emit(TransactionErrorState(locale.blockedMessage));
              return;

            default:
              emit(TransactionErrorState(msg.toString()));
              return;
          }
        }

        // SUCCESS → msg is null
        emit(TransactionSuccessState());

        // Convert response to model
        final txn = TransactionsModel.fromMap(response);
        emit(TransactionLoadedState(txn: [] ,printTxn: txn));

      } catch (e) {
        emit(TransactionErrorState(e.toString()));
      }
    });
    on<OnACTATTransactionEvent>((event, emit) async{
      final locale = localizationService.loc;
      emit(TxnLoadingState());
      try{
        final response = await _repo.fundTransfer(newTransaction: event.transaction);
        final msg = response['msg'];
        switch (msg) {
          case "success":
            emit(TransactionSuccessState());
            break;

          case "currency unmatch":
            emit(TransactionErrorState(locale.sameCurrencyOnlyAllowed));
            break;

          case "no limit":
            emit(TransactionErrorState(locale.accountLimitMessage));
            break;

          case "same account":
            emit(TransactionErrorState(locale.sameAccountMessage));
            break;

          case "failed":
            emit(TransactionErrorState(locale.operationFailedMessage));
            break;

          case "blocked":
            emit(TransactionErrorState(locale.blockedMessage));
            break;

          default:
            emit(TransactionErrorState(msg));
        }

      }catch(e){
        emit(TransactionErrorState(e.toString()));
      }
    });
    on<UpdatePendingTransactionEvent>((event, emit) async{
      final locale = localizationService.loc;
      emit(TxnUpdateLoadingState());
      try{
        final response = await _repo.updateTxn(newTxn: event.transaction);
        final msg = response['msg'];
        switch (msg) {
          case "success":
            emit(TransactionSuccessState());
            break;
          case "invalid user":
            emit(TransactionErrorState(locale.editInvalidMessage));
            break;
          case "invalid action":
            emit(TransactionErrorState(locale.editInvalidAction));
            break;
          case "failed":
            emit(TransactionErrorState(locale.editFailedMessage));
            break;

          default: emit(TransactionErrorState(msg));
        }
      }catch(e){
        emit(TransactionErrorState(e.toString()));
      }
    });
    on<DeletePendingTxnEvent>((event, emit) async{
      final locale = localizationService.loc;
      emit(TxnDeleteLoadingState());
      try{
        final response = await _repo.deleteTxn(usrName: event.usrName,reference: event.reference);
        final msg = response['msg'];
        switch (msg) {
          case "deleted":
            emit(TransactionSuccessState());
            break;

          case "authorized":
            emit(TransactionErrorState(locale.deleteAuthorizedMessage));
            break;

          case "invalid":
            emit(TransactionErrorState(locale.deleteInvalidMessage));
            break;

          default:
            emit(TransactionErrorState(msg));
        }
      }catch(e){
        emit(TransactionErrorState(e.toString()));
      }
    });
    on<AuthorizeTxnEvent>((event, emit) async{
      final locale = localizationService.loc;
      emit(TxnAuthorizeLoadingState());
      try{
        final response = await _repo.authorizeTxn(reference: event.reference,usrName: event.usrName);

        final msg = response['msg'];
        switch (msg) {
          case "authorized":
            emit(TransactionSuccessState());
            break;

          case "invalid":
            emit(TransactionErrorState(locale.authorizeInvalidMessage));
            break;

          default:
            emit(TransactionErrorState(msg));
        }
      }catch(e){
        emit(TransactionErrorState(e.toString()));
      }
    });
    on<ReverseTxnEvent>((event, emit) async{
      final locale = localizationService.loc;
      emit(TxnReverseLoadingState());
      try{
        final response = await _repo.reverseTxn(reference: event.reference,usrName: event.usrName);

        final msg = response['msg'];
        switch (msg) {
          case "success":
            emit(TransactionSuccessState());
            break;

          case "invalid":
            emit(TransactionErrorState(locale.reverseInvalidMessage));
            break;

          case "pending":
            emit(TransactionErrorState(locale.reversePendingMessage));
            break;

          case "already reversed":
            emit(TransactionErrorState(locale.reverseAlreadyMessage));
            break;

          default:
            emit(TransactionErrorState(msg));
        }
      }catch(e){
        emit(TransactionErrorState(e.toString()));
      }
    });
  }
}
