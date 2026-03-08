part of 'subscription_bloc.dart';

sealed class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
}


class LoadSubscriptionEvent extends SubscriptionEvent{
  @override
  List<Object?> get props => [];
}

class AddOrUpdateSubscriptionEvent extends SubscriptionEvent{
  final String newKey;
  final String oldKey;
  final String expireDate;
  const AddOrUpdateSubscriptionEvent(this.newKey, this.oldKey, this.expireDate);
  @override
  List<Object?> get props => [oldKey, newKey, expireDate];
}

