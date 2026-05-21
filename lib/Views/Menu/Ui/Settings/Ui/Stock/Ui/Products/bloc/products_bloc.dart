import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_stock_model.dart';

import '../../../../../../../../../Services/localization_services.dart';
import '../model/product_model.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final Repositories _repo;
  ProductsBloc(this._repo) : super(ProductsInitial()) {



    ///Products for sale invoice
    on<LoadProductsStockEvent>((event, emit) async{
      emit(ProductsLoadingState());
      try{
        final products = await _repo.getProductStock(proId: event.proId, noStock: event.noStock, proName: event.input);
        emit(ProductsStockLoadedState(products));
      }catch(e){
        emit(ProductsErrorState(e.toString()));
      }
    });

    ///Product Settings and purchase invoice
    on<LoadProductsEvent>((event, emit) async{
      emit(ProductsLoadingState());
      try{
        final products = await _repo.getProduct(input: event.input);
        emit(ProductsLoadedState(products));
      }catch(e){
        emit(ProductsErrorState(e.toString()));
      }
    });
    on<AddProductEvent>((event, emit) async{
      final tr = localizationService.loc;
      emit(ProductsLoadingState());
      try{
        final response = await _repo.addProduct(newProduct: event.newProduct);

        final msg = response["msg"];
        switch(msg){
          case "success":
            emit(ProductsSuccessState());
            add(LoadProductsEvent());
            return;

          case "exist":
            emit(ProductsErrorState(tr.productAlreadyExist));
            return;

          case "failed":
            emit(ProductsErrorState(msg));
            return;

          default:
            emit(ProductsErrorState(msg));
            return;
        }
      }catch(e){
        emit(ProductsErrorState(e.toString()));
      }
    });
    on<UpdateProductEvent>((event, emit) async{
      emit(ProductsLoadingState());
      try{
        final response = await _repo.updateProduct(newProduct: event.newProduct);
        final msg = response["msg"];
        switch(msg){
          case "success":
            emit(ProductsSuccessState());
            add(LoadProductsEvent());
            return;

          case "empty":
            emit(ProductsErrorState(msg));
            return;

          case "failed":
            emit(ProductsErrorState(msg));
            return;

          default: emit(ProductsErrorState(msg));
          return;
        }
      }catch(e){
        emit(ProductsErrorState(e.toString()));
      }
    });
    on<DeleteProductEvent>((event, emit) async{
      emit(ProductsLoadingState());
      try{
        final response = await _repo.deleteProduct(proId: event.proId);
        final msg = response["msg"];
        switch(msg){
          case "success":
            emit(ProductsSuccessState());
            add(LoadProductsEvent());
            return;

          case "dependent":
            emit(ProductsErrorState(msg));
            return;

          case "failed":
            emit(ProductsErrorState(msg));
            return;

          default: emit(ProductsErrorState(msg));
          return;
        }
      }catch(e){
        emit(ProductsErrorState(e.toString()));
      }
    });


  }
}
