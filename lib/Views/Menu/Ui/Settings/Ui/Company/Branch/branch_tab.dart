import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/Ui/Overview/branch_overview.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/bloc/brc_tab_bloc.dart';
import '../../../../../../../Features/Generic/tab_bar.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../Branches/model/branch_model.dart';
import 'Ui/BranchLimits/Ui/limits.dart';

class BranchTabsView extends StatelessWidget {
  final BranchModel selectedBranch;
  const BranchTabsView({super.key, required this.selectedBranch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: BlocBuilder<BranchTabBloc, BranchTabState>(
          builder: (context, state) {
            final tabs = <ZTabItem<BranchTabName>>[
              ZTabItem(
                value: BranchTabName.overview,
                label: AppLocalizations.of(context)!.overview,
                screen: BranchOverviewView(selectedBranch: selectedBranch),
              ),
              ZTabItem(
                value: BranchTabName.limits,
                label: AppLocalizations.of(context)!.branchLimits,
                screen: BranchLimitsView(branch: selectedBranch),
              ),
            ];

            final available = tabs.map((t) => t.value).toList();
            final selected = available.contains(state.tab)
                ? state.tab
                : available.first;

            return ZTabContainer<BranchTabName>(
              icon: Icons.location_city_rounded,
              title: "${selectedBranch.brcName} (${selectedBranch.brcId})",
              closeButton: true,
              /// Tab data
              tabs: tabs,
              selectedValue: selected,

              /// Bloc update
              onChanged: (val) => context
                  .read<BranchTabBloc>()
                  .add(BrcOnChangedEvent(val)),

              /// Colors for underline style
              style: ZTabStyle.underline,
              selectedColor: Theme.of(context).colorScheme.primary,
              unselectedTextColor: Theme.of(context).colorScheme.secondary,
              selectedTextColor: Theme.of(context).colorScheme.surface,
              tabContainerColor: Theme.of(context).colorScheme.surface,
            );
          },
        ),
      ),
    );
  }
}
