import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/blur_loading.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualByID/bloc/stakeholder_by_id_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/profile.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/Ui/add_edit.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
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
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(locale.profileOverview,style: Theme.of(context).textTheme.titleMedium),
      ),
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
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(
                width: 400,
                child: ZCover(
                  radius: 12,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(8),
                  child: BlurLoader(
                    isLoading: state is StakeholderByIdLoadingState,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        // 🔥 PROFILE IMAGE (FOCUS)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 15,
                                color: Colors.black.withValues(alpha: .1),
                              )
                            ],
                          ),
                          child: ImageHelper.stakeholderProfile(
                            onImageTap: () => ImageHelper.showImageViewer(
                              context: context,
                              imageName: individual?.imageProfile,
                              heroTag: 'profile_image_${individual!.perId}',
                            ),
                            shapeStyle: ShapeStyle.roundedRectangle,
                            imageName: individual?.imageProfile,
                            borderRadius: 12,
                            size: 130,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🧑 NAME
                        Text(
                          fullName ?? "",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        // 📞 PHONE (SUBTLE)
                        Text(
                          individual?.perPhone ?? "",
                          style: TextStyle(
                            color: color.outline.withValues(alpha: .6),
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Divider(color: Colors.grey.shade300),

                        const SizedBox(height: 12),

                        // 🧾 INFO CHIPS (BETTER UI)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(context, Utils.genderType(
                                gender: individual?.perGender ?? "", locale: locale)),
                            _chip(context, individual?.addCity),
                            _chip(context, individual?.addProvince),
                            _chip(context, individual?.addCountry),
                            _chip(context, individual?.addName),
                            _chip(context, individual?.perEnidNo),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ✏️ EDIT BUTTON (FULL WIDTH)
                        SizedBox(
                          width: double.infinity,
                          child: ZOutlineButton(
                            icon: Icons.edit,
                            height: 42,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return IndividualAddEditView(model: individual);
                                },
                              );
                            },
                            label: Text(locale.edit),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tabs on the LEFT side
              Expanded(
                child: ZCover(
                    padding: const EdgeInsets.all(5),
                    margin: const EdgeInsets.all(8),
                    radius: 12,
                    child: IndividualsDetailsTabView(ind: widget.ind)),
              ),
            ],
          );
        },
      ),
     ),
    );
  }

  Widget _chip(BuildContext context, String? text) {
    if (text == null || text.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

}
