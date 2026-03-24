import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';

part 'storage_event.dart';
part 'storage_state.dart';

class StorageBloc extends Bloc<StorageEvent, StorageState> {
  final Repositories _repo;
  StorageBloc(this._repo) : super(StorageInitial()) {

    on<LoadStorageEvent>((event, emit)async {
      emit(StorageLoadingState());
      try{
       final storage = await _repo.getStorage();
       emit(StorageLoadedState(storage));
      }catch(e){
        emit(StorageErrorState(e.toString()));
      }
    });

    on<AddStorageEvent>((event, emit)async {
      emit(StorageLoadingState());
      try{
        final storage = await _repo.addStorage(newStorage: event.newStorage);
         if(storage['msg'] == "success"){
          emit(StorageSuccessState());
          add(LoadStorageEvent());
         }else{
           emit(StorageErrorState(storage['msg']));
         }
      }catch(e){
        emit(StorageErrorState(e.toString()));
      }
    });

    on<UpdateStorageEvent>((event, emit)async {
      emit(StorageLoadingState());
      try{
        final storage = await _repo.updateStorage(newStorage: event.newStorage);
        if(storage['msg'] == "success"){
          emit(StorageSuccessState());
          add(LoadStorageEvent());
        }else{
          emit(StorageErrorState(storage['msg']));
        }
      }catch(e){
        emit(StorageErrorState(e.toString()));
      }
    });

  }
}
