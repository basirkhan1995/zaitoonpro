import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../../../Services/repositories.dart';
import '../model/product_model.dart';

part 'single_product_event.dart';
part 'single_product_state.dart';

class SingleProductBloc extends Bloc<SingleProductEvent, SingleProductState> {
  final Repositories _repo;

  SingleProductBloc(this._repo) : super(SingleProductInitial()) {
    on<LoadSingleProductEvent>((event, emit) async {
      emit(SingleProductLoadingState());
      try {
        final product = await _repo.getProductById(proId: event.proId);
        emit(SingleProductLoadedState(product));
      } catch (e) {
        emit(SingleProductErrorState(e.toString()));
      }
    });

    on<ClearSingleProductEvent>((event, emit) async {
      try {
        emit(SingleProductInitial());
      } catch (e) {
        emit(SingleProductErrorState(e.toString()));
      }
    });
  }
}
