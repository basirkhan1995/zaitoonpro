import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../Services/repositories.dart';
part 'stakeholder_by_id_event.dart';
part 'stakeholder_by_id_state.dart';

class StakeholderByIdBloc extends Bloc<StakeholderByIdEvent, StakeholderByIdState> {
  final Repositories repo;
  StakeholderByIdBloc(this.repo) : super(StakeholderByIdInitial()) {

    on<LoadStakeholderByIdEvent>((event, emit) async{
       emit(StakeholderByIdLoadingState());
       try{
         final stk = await repo.getPersonProfileById(perId: event.stkId);
         emit(StakeholderByIdLoadedState(stk));
       }catch(e){
         emit(StakeholderByIdErrorState(e.toString()));
       }
    });
  }
}
