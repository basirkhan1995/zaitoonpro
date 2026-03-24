import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/GlCategories/model/cat_model.dart';

part 'gl_category_event.dart';
part 'gl_category_state.dart';

class GlCategoryBloc extends Bloc<GlCategoryEvent, GlCategoryState> {
  final Repositories _repo;
  GlCategoryBloc(this._repo) : super(GlCategoryInitial()) {

    on<LoadGlCategoriesEvent>((event, emit) async{
      emit(GlCategoryLoadingState());
      try{
        final cat = await _repo.getGlSubCategories(catId: event.catId);
        emit(GlCategoryLoadedState(cat));
      }catch(e){
         emit(GlCategoryErrorState(e.toString()));
       }
    });
  }
}
