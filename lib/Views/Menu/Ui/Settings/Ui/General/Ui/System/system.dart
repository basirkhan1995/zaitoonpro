import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../Features/Other/cover.dart';
import '../../../../../../../../Features/Other/labled_checkbox.dart';
import '../../../../../../../../Features/Other/responsive.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../../Localizations/locale_selector.dart';
import '../../../../../../../../Themes/Ui/theme_selector.dart';
import '../../../../features/Visibility/bloc/settings_visible_bloc.dart';

class SystemView extends StatelessWidget {
  const SystemView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      tablet: _Desktop(),
      mobile: _Desktop(),
      desktop: _Desktop(),
    );
  }
}

class _Desktop extends StatelessWidget {
  final Map<String, String> dateFormats = {
    //Date
    'yyyy-MM-dd': '2025-05-28',
    'dd-MM-yyyy': '28-05-2025',
    'MM/dd/yyyy': '05/28/2025',
    'dd MMM yyyy': '28 May, 2025',
    //Date With Time
    'dd-MM-yyyy HH:mm': '28-05-2025 14:30',
  };

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<SettingsVisibleBloc, SettingsVisibilityState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  ThemeSelector(
                    width: 330,
                    title: AppLocalizations.of(context)!.theme,
                  ),
                  LanguageSelector(
                    width: 330,
                    title: AppLocalizations.of(context)!.language,
                  ),
                  // DateTypeDrop(),
                  // SizedBox(
                  //   width: 330,
                  //   child: CustomDropdown<String>(
                  //     title: "Date Format",
                  //     items: dateFormats.keys.toList(),
                  //     selectedItem: state.dateFormat,
                  //     itemLabel: (format) =>
                  //         '${dateFormats[format]} ($format)',
                  //     onItemSelected: (format) {
                  //       context.read<SettingsVisibleBloc>().add(
                  //         UpdateSettingsEvent(dateFormat: format),
                  //       );
                  //     },
                  //   ),
                  // ),
                  SizedBox(height: 1),
                  Row(
                    spacing: 5,
                    children: [
                      Icon(Icons.line_axis_rounded),
                      Text(locale.dashboard,style: Theme.of(context).textTheme.titleMedium,)
                    ],
                  ),
                  ZCover(
                    radius: 5,
                      padding: EdgeInsets.all(10),
                      child: Column(
                    children: [

                      //Digital Clock ..........................................
                      LabeledCheckbox(
                        title: locale.dashboardClock,
                        value: state.dashboardClock,
                        onChanged: (e) {
                          context.read<SettingsVisibleBloc>().add(
                            UpdateSettingsEvent(dashboardClock: e),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: bulletPoint(locale.clockHint),
                      ),
                      Divider(indent: 8,endIndent: 8),

                      //Exchange Rate ..........................................
                      LabeledCheckbox(
                        title: locale.exchangeRateTitle,
                        value: state.exchangeRate,
                        onChanged: (e) {
                          context.read<SettingsVisibleBloc>().add(
                            UpdateSettingsEvent(exchangeRate: e),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: bulletPoint(locale.exhangeRateHint),
                      ),

                      Divider(indent: 8,endIndent: 8),
                      // Chart .................................................
                      LabeledCheckbox(
                        title: locale.profitAndLoss,
                        value: state.profitAndLoss,
                        onChanged: (e) {
                          context.read<SettingsVisibleBloc>().add(
                            UpdateSettingsEvent(profitAndLoss: e),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: bulletPoint(locale.profitAndLoss),
                      ),
                      Divider(indent: 8,endIndent: 8),
                      ///Transport..............................................
                      LabeledCheckbox(
                        title: locale.transport,
                        value: state.transport,
                        onChanged: (e) {
                          context.read<SettingsVisibleBloc>().add(
                            UpdateSettingsEvent(transport: e),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            bulletPoint(locale.addShipmentHint),
                            bulletPoint(locale.shipmentExpenseHint),
                            bulletPoint(locale.trackShipmentsHint),
                          ],
                        ),
                      ),
                      Divider(indent: 8,endIndent: 8),
                      ///Orders..............................................
                      LabeledCheckbox(
                        title: locale.inventory,
                        value: state.orders,
                        onChanged: (e) {
                          context.read<SettingsVisibleBloc>().add(
                            UpdateSettingsEvent(orders: e),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            bulletPoint(locale.purchaseInvoice),
                            bulletPoint(locale.salesInvoice),
                            bulletPoint(locale.estimate),
                            bulletPoint(locale.shiftItems),
                            bulletPoint(locale.adjustment),
                          ],
                        ),
                      ),

                    ],
                  ))
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget bulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('• ', style: TextStyle(fontSize: 25)),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
      ],
    );
  }
}


