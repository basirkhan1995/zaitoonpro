import 'package:flutter/material.dart';
import 'package:zaitoon_petroleum/Features/Other/cover.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Widgets/blur_loading.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/IndividualByID/bloc/stakeholder_by_id_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/profile.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/Individuals/Ui/add_edit.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../../../../../Features/Other/image_helper.dart';
import '../../../Individuals/model/individual_model.dart';

class IndividualProfileView extends StatelessWidget {
  final IndividualsModel ind;
  const IndividualProfileView({super.key, required this.ind});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(ind),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Desktop extends StatefulWidget {
  final IndividualsModel ind;
  const _Desktop(this.ind);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  IndividualsModel? individual;
  String? fullName;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      context.read<StakeholderByIdBloc>().add(LoadStakeholderByIdEvent(stkId: widget.ind.perId!));
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocListener<IndividualsBloc, IndividualsState>(
      listener: (context, state) {
        if(state is IndividualSuccessImageState || state is IndividualSuccessState){
          context.read<StakeholderByIdBloc>().add(LoadStakeholderByIdEvent(stkId: widget.ind.perId!));
        }
      },
      child: BlocBuilder<StakeholderByIdBloc, StakeholderByIdState>(
        builder: (context, state) {
          if(state is StakeholderByIdLoadedState){
            individual = state.stk;
            fullName = "${state.stk.perName} ${state.stk.perLastName}";
          }
          return Column(
            children: [
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: BlurLoader(
                  isLoading: state is StakeholderByIdLoadingState,
                  child: Column(
                    children: [
                      Row(
                        spacing: 5,
                        children: [
                          BackButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(color.outline.withValues(alpha: .1))
                            ),
                          ),
                          Text(locale.profileOverview,style: Theme.of(context).textTheme.titleMedium)
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          ImageHelper.stakeholderProfile(
                              shapeStyle: ShapeStyle.roundedRectangle,
                              imageName: individual?.imageProfile,
                              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3)),
                              borderRadius: 5,
                              size: 115),
                          SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName??"",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                                ),
                                ZCover(child: Text(individual?.perPhone ?? "")),
                                SizedBox(height: 5),
                                Row(
                                  spacing: 5,
                                  children: [
                                    ZCover(child: Text(individual?.perEnidNo ?? "")),
                                    ZCover(child: Text(Utils.genderType(gender: individual?.perGender ?? "",locale: locale))),
                                    ZCover(child: Text(individual?.addCity ?? "")),
                                    ZCover(child: Text(individual?.addProvince ?? "")),
                                    ZCover(child: Text(individual?.addCountry ?? "")),
                                    ZCover(child: Text(individual?.addName ?? "")),
                                  ],
                                ),
                                SizedBox(height: 5),
                                ZOutlineButton(
                                  icon: Icons.refresh,
                                  width: 100,
                                  height: 35,
                                  onPressed: (){
                                    showDialog(context: context, builder: (context){
                                      return IndividualAddEditView(model: widget.ind);
                                    });
                                  },
                                  label: Text(locale.edit),
                                ),
                                SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: IndividualsDetailsTabView(ind: widget.ind),
              ),
            ],
          );
        },
      ),
     ),
    );
  }
}
