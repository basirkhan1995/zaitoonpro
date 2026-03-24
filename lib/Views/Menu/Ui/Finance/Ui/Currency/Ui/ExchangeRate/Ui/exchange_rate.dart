import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/Ui/add_rate.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'package:zaitoonpro/Views/Menu/bloc/menu_bloc.dart';
import '../../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../bloc/financial_tab_bloc.dart';
import '../../../bloc/currency_tab_bloc.dart';

class ExchangeRateView extends StatelessWidget {
  final bool newRateButton;
  final bool settingButton;
  final double? width;
  const ExchangeRateView({
    super.key,
    this.newRateButton = false,
    this.settingButton = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(
        newRateButton: newRateButton,
        settingButton: settingButton,
        width: width,
      ),
      tablet: _Desktop(
        newRateButton: newRateButton,
        settingButton: settingButton,
        width: width,
      ),
      desktop: _Desktop(
        newRateButton: newRateButton,
        settingButton: settingButton,
        width: width,
      ),
    );
  }
}



class _Desktop extends StatefulWidget {
  final bool newRateButton;
  final bool settingButton;
  final double? width;
  const _Desktop({required this.settingButton, required this.newRateButton, this.width});

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  String? myLocale;
  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_){
      onRefresh();
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final currentLocale = context.read<LocalizationBloc>().state.languageCode;
    return Container(
      width: widget.width ?? double.infinity,
      margin: EdgeInsets.symmetric(vertical: 1,horizontal: 3),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  locale.rate,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Spacer(),
                ZOutlineButton(
                    width: 100,
                    height: 35,
                    onPressed: onRefresh,
                    label: Text(locale.refresh),
                    icon: Icons.refresh),
                if(widget.newRateButton)
                SizedBox(width: 5),
                if(widget.newRateButton)
                ZOutlineButton(
                  isActive: true,
                  icon: Icons.add,
                  onPressed: () {
                    showDialog(context: context, builder: (context){
                      return AddRateView();
                    });
                  },
                  label: Text(locale.newKeyword),
                ),
                if(widget.settingButton)
                SizedBox(width: 5),
                if(widget.settingButton)
                ZOutlineButton(
                  isActive: true,
                  icon: Icons.settings,
                  onPressed: () {
                    context.read<MenuBloc>().add(MenuOnChangedEvent(MenuName.finance));
                    context.read<FinanceTabBloc>().add(FinanceOnChangedEvent(FinanceTabName.exchangeRate));
                    context.read<CurrencyTabBloc>().add(CcyOnChangedEvent(CurrencyTabName.rates));
                  },
                  label: Text(locale.settings),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        locale.currencyTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  locale.rate,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          Divider(
            endIndent: 5,
            indent: 5,
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.09),
          ),
          BlocConsumer<ExchangeRateBloc, ExchangeRateState>(
            listener: (context, state) {
              if (state is ExchangeRateSuccessState) {
                Navigator.of(context).pop();
                onRefresh();
              }
            },

            builder: (context, state) {
              if (state is ExchangeRateErrorState) {
                return Center(child: Text(state.message));
              }
              if(state is ExchangeRateLoadingState){
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is ExchangeRateLoadedState) {
                if (state.rates.isEmpty) {
                  return Center(child: Text("No rate"));
                }
                return ListView.builder(
                  itemCount: state.rates.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final ccy = state.rates[index];
                    return Material(
                      borderRadius: BorderRadius.circular(5),
                      child: InkWell(
                        splashColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .2),
                        hoverColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .09),

                        onTap: () {
                          showDialog(context: context, builder: (context){
                            return AddRateView(
                              rate: ccy,
                            );
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: index.isOdd
                                ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .05)
                                : Colors.transparent,
                          ),
                          child: Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      child: Flag.fromString(
                                        ccy.fromCode??"",
                                        height: 20,
                                        width: 30,
                                        borderRadius: 2,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                      child: Text(
                                        "1",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    ZCover(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 3,
                                      ),
                                      child: SizedBox(
                                        width: 35,
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          "${ccy.crFrom}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                      child: Text(
                                        "=",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  ccy.crExchange.toExchangeRate(),
                                  textAlign: currentLocale == "en"? TextAlign.right : TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              ZCover(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                  vertical: 3,
                                ),
                                child: SizedBox(
                                  width: 35,
                                  child: Text(
                                    ccy.crTo ?? "",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                child: Flag.fromString(
                                  ccy.toCode ?? "",
                                  height: 20,
                                  width: 30,
                                  borderRadius: 2,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  void onRefresh() {
    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      context.read<ExchangeRateBloc>().add(
        LoadExchangeRateEvent(""),
      );
    }
  }

}

class _Mobile extends StatefulWidget {
  final bool newRateButton;
  final bool settingButton;
  final double? width;
  const _Mobile({required this.settingButton, required this.newRateButton, this.width});

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  String? myLocale;
  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final currentLocale = context.read<LocalizationBloc>().state.languageCode;
    return Container(
      width: widget.width ?? double.infinity,
      margin: EdgeInsets.symmetric(vertical: 1,horizontal: 3),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  locale.rate,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Spacer(),
                ZCover(
                  child: IconButton(
                      onPressed: onRefresh,
                      icon: Icon(Icons.refresh)),
                ),
                if(widget.newRateButton)
                  SizedBox(width: 5),
                if(widget.newRateButton)
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      showDialog(context: context, builder: (context){
                        return AddRateView();
                      });
                    },
                  ),
                if(widget.settingButton)
                  SizedBox(width: 5),
                if(widget.settingButton)
                  ZCover(
                    child: IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        context.read<MenuBloc>().add(MenuOnChangedEvent(MenuName.finance));
                        context.read<FinanceTabBloc>().add(FinanceOnChangedEvent(FinanceTabName.exchangeRate));
                        context.read<CurrencyTabBloc>().add(CcyOnChangedEvent(CurrencyTabName.rates));
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        locale.currencyTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  locale.rate,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          Divider(
            endIndent: 5,
            indent: 5,
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.09),
          ),
          BlocConsumer<ExchangeRateBloc, ExchangeRateState>(
            listener: (context, state) {
              if (state is ExchangeRateSuccessState) {
                Navigator.of(context).pop();
                onRefresh();
              }
            },

            builder: (context, state) {
              if (state is ExchangeRateErrorState) {
                return Center(child: Text(state.message));
              }
              if(state is ExchangeRateLoadingState){
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is ExchangeRateLoadedState) {
                if (state.rates.isEmpty) {
                  return Center(child: Text("No rate"));
                }
                return ListView.builder(
                  itemCount: state.rates.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final ccy = state.rates[index];
                    return Material(
                      borderRadius: BorderRadius.circular(5),
                      child: InkWell(
                        splashColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .2),
                        hoverColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .09),

                        onTap: () {
                          showDialog(context: context, builder: (context){
                            return AddRateView(
                              rate: ccy,
                            );
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: index.isOdd
                                ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .05)
                                : Colors.transparent,
                          ),
                          child: Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      child: Flag.fromString(
                                        ccy.fromCode??"",
                                        height: 20,
                                        width: 30,
                                        borderRadius: 2,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                      child: Text(
                                        "1",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    ZCover(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 3,
                                      ),
                                      child: SizedBox(
                                        width: 35,
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          "${ccy.crFrom}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                      child: Text(
                                        "=",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  ccy.crExchange.toExchangeRate(),
                                  textAlign: currentLocale == "en"? TextAlign.right : TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              ZCover(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                  vertical: 3,
                                ),
                                child: SizedBox(
                                  width: 35,
                                  child: Text(
                                    ccy.crTo ?? "",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                child: Flag.fromString(
                                  ccy.toCode ?? "",
                                  height: 20,
                                  width: 30,
                                  borderRadius: 2,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  void onRefresh({bool showAll = false}) {
    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      context.read<ExchangeRateBloc>().add(
        LoadExchangeRateEvent(
          companyState.company.comLocalCcy ?? "",
        ),
      );
    }
  }

}