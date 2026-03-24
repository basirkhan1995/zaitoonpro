import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Drivers/drivers.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Vehicles/vehicles.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/bloc/transport_tab_bloc.dart';
import '../../../../Features/Generic/tab_bar.dart';
import '../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../../../Auth/models/login_model.dart';
import 'Ui/Shipping/Ui/ShippingView/View/all_shipping.dart';

class TransportView extends StatelessWidget {
  const TransportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(), tablet: _Desktop(), desktop: _Desktop());
  }
}
class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: BlocBuilder<TransportTabBloc, TransportTabState>(
        builder: (context, state) {
          final tabs = <ZTabItem<TransportTabName>>[

            if (login.hasPermission(43) ?? false)
              ZTabItem(
                value: TransportTabName.shipping,
                label: AppLocalizations.of(context)!.shipping,
                screen: const ShippingView(),
              ),
            if (login.hasPermission(44) ?? false)
              ZTabItem(
                value: TransportTabName.drivers,
                label: AppLocalizations.of(context)!.drivers,
                screen: const DriversView(),
              ),
            if (login.hasPermission(45) ?? false)
              ZTabItem(
                value: TransportTabName.vehicles,
                label: AppLocalizations.of(context)!.vehicles,
                screen: const VehiclesView(),
              ),
          ];

          final available = tabs.map((t) => t.value).toList();
          final selected = available.contains(state.tab)
              ? state.tab
              : available.first;

          return ZTabContainer<TransportTabName>(
            title: AppLocalizations.of(context)!.transportTitle,
            tabBarPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
            description: AppLocalizations.of(context)!.shipmentHint,
            borderRadius: 0,
            /// Tab data
            tabs: tabs,
            selectedValue: selected,

            /// Bloc update
            onChanged: (val) => context
                .read<TransportTabBloc>()
                .add(TransportOnChangedEvent(val)),

            /// Colors for underline style
            style: ZTabStyle.rounded,
            selectedColor: Theme.of(context).colorScheme.primary,
            unselectedTextColor: Theme.of(context).colorScheme.secondary,
            selectedTextColor: Theme.of(context).colorScheme.surface,
            tabContainerColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
    );
  }
}
class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BlocBuilder<TransportTabBloc, TransportTabState>(
          builder: (context, state) {
            final tabs = <ZTabItem<TransportTabName>>[

              if (login.hasPermission(43) ?? false)
                ZTabItem(
                  value: TransportTabName.shipping,
                  label: AppLocalizations.of(context)!.shipping,
                  screen: const ShippingView(),
                ),
              if (login.hasPermission(44) ?? false)
                ZTabItem(
                  value: TransportTabName.drivers,
                  label: AppLocalizations.of(context)!.drivers,
                  screen: const DriversView(),
                ),
              if (login.hasPermission(45) ?? false)
                ZTabItem(
                  value: TransportTabName.vehicles,
                  label: AppLocalizations.of(context)!.vehicles,
                  screen: const VehiclesView(),
                ),
            ];

            final available = tabs.map((t) => t.value).toList();
            final selected = available.contains(state.tab)
                ? state.tab
                : available.first;

            return ZTabContainer<TransportTabName>(
              tabBarPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
              borderRadius: 0,
              /// Tab data
              tabs: tabs,
              selectedValue: selected,

              /// Bloc update
              onChanged: (val) => context
                  .read<TransportTabBloc>()
                  .add(TransportOnChangedEvent(val)),

              /// Colors for underline style
              style: ZTabStyle.rounded,
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
