import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Auth/Subscription/model/sub_model.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final Repositories _repo;
  SubscriptionBloc(this._repo) : super(SubscriptionInitial()) {

    on<LoadSubscriptionEvent>((event, emit) async{
      emit(SubscriptionLoadingState());
      try{
       final res = await _repo.getSubscriptions();
       emit(SubscriptionLoadedState(res));
      }catch(e){
        emit(SubscriptionErrorState(e.toString()));
      }
    });

    on<AddOrUpdateSubscriptionEvent>((event, emit) async{
      emit(SubscriptionLoadingState());
      try{
        final res = await _repo.addSubscription(oldKey: event.oldKey, newKey: event.newKey, expireDate: event.expireDate);
        final msg = res["msg"];
        if(msg == "mismatch"){
          emit(SubscriptionErrorState("Old key not matched"));
        }else{
          emit(SubscriptionErrorState(msg));
        }
        emit(SubscriptionSuccessState());
      }catch(e){
        emit(SubscriptionErrorState(e.toString()));
      }
    });

  }
}
