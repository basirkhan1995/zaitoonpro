part of 'subscription_bloc.dart';

sealed class SubscriptionState extends Equatable {
  const SubscriptionState();
}

final class SubscriptionInitial extends SubscriptionState {
  @override
  List<Object> get props => [];
}


final class SubscriptionLoadedState extends SubscriptionState {
  final List<SubscriptionModel> subs;
  const SubscriptionLoadedState(this.subs);
  @override
  List<Object> get props => [subs];
}

final class SubscriptionSuccessState extends SubscriptionState {
  @override
  List<Object> get props => [];
}

final class SubscriptionLoadingState extends SubscriptionState {
  @override
  List<Object> get props => [];
}

final class SubscriptionErrorState extends SubscriptionState {
  final String message;
  const SubscriptionErrorState(this.message);
  @override
  List<Object> get props => [message];
}


