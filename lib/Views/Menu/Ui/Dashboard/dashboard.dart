import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Views/Auth/models/login_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Dashboard/Views/DailyGross/daily_gross.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Dashboard/Views/Stats/stats.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/Ui/dashboard_rate.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/Ui/exchange_rate.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/TotalDailyTxn/column_chart_view.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/TotalDailyTxn/total_daily_txn.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../Reminder/reminder_widget.dart';
import '../Report/Ui/Finance/ExchangeRate/chart.dart';

import '../Settings/features/Visibility/bloc/settings_visible_bloc.dart';
import 'features/clock.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [

            //Dashboard Clock
            if (login.hasPermission(6) ?? false) ...[
              if (visibility.dashboardClock) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: const DigitalClock(),
                ),
              ],
            ],

            //Exchange Rate Widget
            if (login.hasPermission(7) ?? false) ...[
              if (visibility.exchangeRate) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3,
                  ),
                  child: ExchangeRateDashboardView(),
                ),
              ],
            ],

            //Stats Count - Total Accounts, Total Stakeholders ...
            if (login.hasPermission(2) ?? false) ...[
              if (visibility.statsCount) ...[
                DashboardStatsView(),
              ],
            ],

            //Profit & Loss Graph
            if (login.hasPermission(8) ?? false) ...[
              if (visibility.profitAndLoss) ...[DailyGrossView()],
            ],

            //Reminder
            if (login.hasPermission(9) ?? false) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: DashboardAlertReminder(),
              ),
            ],

          ],
        ),
      ),
    );
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [

            //Dashboard Clock
            if (login.hasPermission(6) ?? false) ...[
              if (visibility.dashboardClock) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: const DigitalClock(),
                ),
              ],
            ],

            //Exchange Rate Widget
            if (login.hasPermission(7) ?? false) ...[
              if (visibility.exchangeRate) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13.0,
                    vertical: 3,
                  ),
                  child: ExchangeRateView(
                    settingButton: true,
                    newRateButton: false,
                  ),
                ),
              ],
            ],

            //Stats Count - Total Accounts, Total Stakeholders ...
            if (login.hasPermission(2) ?? false) ...[
              if (visibility.statsCount) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: DashboardStatsView(),
                ),
              ],
            ],

            //Profit & Loss Graph
            if (login.hasPermission(8) ?? false) ...[
              if (visibility.profitAndLoss) ...[DailyGrossView()],
            ],

            //Reminder
            if (login.hasPermission(9) ?? false) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: DashboardAlertReminder(),
              ),
            ],

          ],
        ),
      ),
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  //Stats Count - Total Accounts, Total Stakeholders ...
                  if (login.hasPermission(2) ?? false) ...[
                    if (visibility.statsCount) ...[
                      DashboardStatsView(),
                    ],
                  ],

                    //Exchange Rate Graph
                    if (login.hasPermission(3) ?? false) ...[
                      SizedBox(height: 400, child: FxRateDashboardChart()),
                    ],

                    if (login.hasPermission(4) ?? false) ...[
                      TotalDailyColumnView(),
                    ],

                  if (login.hasPermission(5) ?? false) ...[
                    const TotalDailyTxnView(),
                  ],

                ],
              ),
            ),

            SizedBox(
              width: 500,
              child: Column(
                children: [
                  if (login.hasPermission(6) ?? false) ...[
                    if (visibility.dashboardClock) ...[
                      const DigitalClock(),
                      SizedBox(),
                    ],
                  ],

                  //Exchange Rate Widget
                  if (login.hasPermission(7) ?? false) ...[
                    if (visibility.exchangeRate) ...[
                      ExchangeRateDashboardView(),
                    ],
                  ],

                  //Profit & Loss Graph
                  if (login.hasPermission(8) ?? false) ...[
                    if (visibility.profitAndLoss) ...[
                      SizedBox(height: 3),
                      DailyGrossView(),
                    ],
                  ],

                  //Reminder
                  if (login.hasPermission(9) ?? false) ...[
                    DashboardAlertReminder(),
                  ],
                  SizedBox(height: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
