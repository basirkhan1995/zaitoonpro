import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import '../model/individual_model.dart';
part 'individuals_event.dart';
part 'individuals_state.dart';

class IndividualsBloc extends Bloc<IndividualsEvent, IndividualsState> {
  final Repositories _repo;
  IndividualsBloc(this._repo) : super(IndividualsInitial()) {
    List<IndividualsModel> allIndividuals = [];

    on<LoadIndividualsEvent>((event, emit)async {
      emit(IndividualLoadingState());
      try{
         final stk = await _repo.getStakeholders(indId: event.indId, query: event.search);
         emit(IndividualLoadedState(stk));
       }catch(e){
         emit(IndividualErrorState(e.toString()));
       }
    });
    on<AddIndividualEvent>((event, emit)async {
      emit(IndividualLoadingState());
      try{
       final response = await _repo.addStakeholder(stk: event.newStk);
       final String result = response["msg"];
       if(result == "success"){
         add(LoadIndividualsEvent());
         emit(IndividualSuccessState());
       }
      }catch(e){
        emit(IndividualErrorState(e.toString()));
      }
    });
    on<EditIndividualEvent>((event, emit)async {
      emit(IndividualLoadingState());
      try{
        final response = await _repo.editStakeholder(stk: event.newStk);
        final String result = response["msg"];
        if(result == "success"){
          add(LoadIndividualsEvent(indId: event.newStk.perId));
          emit(IndividualSuccessState());
        }
      }catch(e){
        emit(IndividualErrorState(e.toString()));
      }
    });
    on<SearchIndividualsEvent>((event,emit)async{
      final query = event.query.toLowerCase().trim();

      if (query.isEmpty) {
        emit(IndividualLoadedState(allIndividuals));
      } else {
        final filtered = allIndividuals.where((i) {
          final name = i.perName?.toLowerCase() ?? '';
          final phone = i.perLastName?.toLowerCase() ?? '';
          return name.contains(query) || phone.contains(query);
        }).toList();

        emit(IndividualLoadedState(filtered));
      }
    });

    on<UploadIndProfileImageEvent>((event,emit)async{
      try{
       final res = await _repo.uploadPersonalPhoto(perID: event.perId, image: event.image);
       final msg = res['msg'];
       if(msg == "success"){
         emit(IndividualSuccessState());
       }else{
         emit(IndividualErrorState(msg));
       }
      }catch(e){
        emit(IndividualErrorState(e.toString()));
      }
    });

  }


}
