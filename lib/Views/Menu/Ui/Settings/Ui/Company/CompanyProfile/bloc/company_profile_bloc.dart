import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/model/com_model.dart';
import 'dart:typed_data';
part 'company_profile_event.dart';
part 'company_profile_state.dart';

class CompanyProfileBloc extends Bloc<CompanyProfileEvent, CompanyProfileState> {
  final Repositories _repo;
  CompanyProfileBloc(this._repo) : super(CompanyProfileInitial()) {

    on<LoadCompanyProfileEvent>((event, emit) async{
      emit(CompanyProfileLoadingState());
     try{
      final com = await _repo.getCompanyProfile();
      emit(CompanyProfileLoadedState(com));
     }catch(e){
       emit(CompanyProfileErrorState(e.toString()));
     }
    });
    on<UpdateCompanyProfileEvent>((event, emit) async{
      emit(CompanyProfileLoadingState());
      try{
        final res = await _repo.editCompanyProfile(newData: event.company);
        final msg = res['msg'];
        if(msg == "success"){
          emit(CompanyProfileSuccessState());
          add(LoadCompanyProfileEvent());
        }else{
          emit(CompanyProfileErrorState(msg));
        }
      }catch(e){
        emit(CompanyProfileErrorState(e.toString()));
      }
    });
    on<UploadCompanyLogoEvent>((event,emit)async{
      emit(CompanyProfileLoadingState());
      try{
        await _repo.uploadCompanyProfile(image: event.image);
        add(LoadCompanyProfileEvent());
      }catch(e){
        emit(CompanyProfileErrorState(e.toString()));
      }
    });
  }
}
