import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualByID/bloc/stakeholder_by_id_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/profile.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/Ui/add_edit.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../../../../../Features/Generic/shimmer.dart';
import '../../../../../../../../Features/Other/image_helper.dart';
import '../../../Individuals/model/individual_model.dart';

class IndividualProfileView extends StatelessWidget {
  final IndividualsModel ind;
  const IndividualProfileView({super.key, required this.ind});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Desktop(ind),
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
        title: Text(locale.profileOverview, style: Theme.of(context).textTheme.titleMedium),
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

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT SIDE - PROFILE CARD (Full height)
                  SizedBox(
                    width: 380,
                    child: Column(
                      children: [
                        Expanded(
                          child: ZCover(
                            radius: 16,
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                            child: state is StakeholderByIdLoadingState
                                ? UniversalShimmer.profileDetails(
                              showImage: true,
                              showName: true,
                              showContact: true,
                              showInfoSections: true,
                              numberOfInfoSections: 6,
                              imageSize: 120,
                            )
                                : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: _buildProfileContent(context, color, locale),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // RIGHT SIDE - TABS (Full height)
                  Expanded(
                    child: ZCover(
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      radius: 16,
                      child: state is StakeholderByIdLoadingState
                          ? UniversalShimmer.dataList(
                        itemCount: 5,
                        numberOfColumns: 4,
                        showAvatar: false,
                        showCheckbox: false,
                        showActions: true,
                      )
                          : IndividualsDetailsTabView(ind: widget.ind),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, ColorScheme color, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // PROFILE IMAGE WITH BADGE
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    spreadRadius: 2,
                    color: color.primary.withValues(alpha: .15),
                  ),
                ],
              ),
              child: ImageHelper.stakeholderProfile(
                onImageTap: () => ImageHelper.showImageViewer(
                  context: context,
                  imageName: individual?.imageProfile,
                  heroTag: 'profile_image_${individual!.perId}',
                ),
                shapeStyle: ShapeStyle.circle,
                imageName: individual?.imageProfile,
                size: 120,
              ),
            ),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return IndividualAddEditView(model: individual);
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.surface, width: 2),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // NAME SECTION
        Text(
          fullName ?? "",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        // PHONE WITH ICON
        if (individual?.perPhone != null && individual!.perPhone!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone, size: 14, color: color.primary),
                const SizedBox(width: 6),
                Text(
                  individual!.perPhone!,
                  style: TextStyle(
                    color: color.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // DIVIDER WITH TEXT
        Row(
          children: [
            Expanded(child: Divider(color: color.outline.withValues(alpha: .2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                locale.profile.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: color.outline.withValues(alpha: .6),
                ),
              ),
            ),
            Expanded(child: Divider(color: color.outline.withValues(alpha: .2))),
          ],
        ),

        const SizedBox(height: 16),

        // INFO SECTIONS
        _infoSection(
          context,
          icon: Icons.person_outline,
          title: locale.gender,
          value: Utils.genderType(gender: individual?.perGender ?? "", locale: locale),
        ),

        if (individual?.perEnidNo != null && individual!.perEnidNo!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.badge_outlined,
            title: locale.nationalId,
            value: individual!.perEnidNo!,
          ),

        // ADDRESS SECTION
        if (individual?.addName != null && individual!.addName!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.location_on_outlined,
            title: locale.address,
            value: individual!.addName!,
          ),

        if (individual?.addCity != null && individual!.addCity!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.location_city_outlined,
            title: locale.city,
            value: individual!.addCity!,
          ),

        if (individual?.addProvince != null && individual!.addProvince!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.map_outlined,
            title: locale.province,
            value: individual!.addProvince!,
          ),

        if (individual?.addCountry != null && individual!.addCountry!.isNotEmpty)
          _infoSection(
            context,
            icon: Icons.public_outlined,
            title: locale.country,
            value: individual!.addCountry!,
          ),

        // Add some bottom padding to ensure content doesn't touch the edge
        const SizedBox(height: 24),
      ],
    );
  }

  // Improved info section widget
  Widget _infoSection(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final color = Theme.of(context).colorScheme;

    if (value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: color.outline.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
