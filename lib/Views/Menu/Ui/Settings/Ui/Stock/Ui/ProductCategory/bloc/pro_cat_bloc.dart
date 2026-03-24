import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/ProductCategory/model/pro_cat_model.dart';

part 'pro_cat_event.dart';
part 'pro_cat_state.dart';

class ProCatBloc extends Bloc<ProCatEvent, ProCatState> {
  final Repositories _repo;
  ProCatBloc(this._repo) : super(ProCatInitial()) {
    on<LoadProCatEvent>((event, emit) async{
      emit(ProCatLoadingState());
      try{
       final proCat = await _repo.getProCategory(catId: event.catId);
       emit(ProCatLoadedState(proCat));
      }catch(e){
        emit(ProCatErrorState(e.toString()));
      }
    });
    on<AddProCatEvent>((event, emit) async{
      emit(ProCatLoadingState());
      try{
        final response = await _repo.addProCategory(newCategory: event.newProCat);
         final msg = response["msg"];

         switch(msg){

           case "success":
             emit(ProCatSuccessState());
             add(LoadProCatEvent());
             return;

             case "exist":
             emit(ProCatErrorState(msg));
             return;

             case "failed":
             emit(ProCatErrorState(msg));
             return;

             default: emit(ProCatErrorState(msg));
             return;
         }
      }catch(e){
        emit(ProCatErrorState(e.toString()));
      }
    });
    on<UpdateProCatEvent>((event, emit) async{
      emit(ProCatLoadingState());
      try{
        final response = await _repo.updateProCategory(newCategory: event.newProCat);
        final msg = response["msg"];

        switch(msg){

          case "success":
            emit(ProCatSuccessState());
            add(LoadProCatEvent());
            return;

          case "exist":
            emit(ProCatErrorState(msg));
            return;

          case "failed":
            emit(ProCatErrorState(msg));
            return;

          default: emit(ProCatErrorState(msg));
          return;
        }
      }catch(e){
        emit(ProCatErrorState(e.toString()));
      }
    });
  }
}
