import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/section_title.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Accounts/accounts.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/BalanceSheet/balance_sheet.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/GLStatement/gl_statement.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/cash_branch.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/HR/AttendanceReport/attendance_report.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/Cardx/Ui/cardx.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/OrdersReport/Ui/order_report.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/UserReport/StakeholdersReport/ind_report.dart';
import '../../../../Features/Other/utils.dart';
import '../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../../../Auth/models/login_model.dart';
import 'Ui/Finance/AccountStatement/acc_statement.dart';
import 'Ui/Finance/AllBalances/Ui/all_balances.dart';
import 'Ui/Finance/ArApReport/Payables/payables.dart';
import 'Ui/Finance/ArApReport/Receivables/receivables.dart';
import 'Ui/Finance/ExchangeRate/exchange_rate.dart';
import 'Ui/Finance/Treasury/all_cash.dart';
import 'Ui/Finance/TrialBalance/trial_balance.dart';
import 'Ui/Stock/StockAvailability/product_report.dart';
import 'Ui/TransactionRef/transaction_ref.dart';
import 'Ui/TxnReport/txn_report.dart';
import 'Ui/UserReport/user_log_report.dart';
import 'Ui/UserReport/users_report.dart';

enum ActionKey {

  //Finance
  accStatement,
  glStatement,
  glStatementSingleDate,
  payable,
  receivable,
  accountsReport,
  trialBalance,

  //Transactions
  balanceSheet,
  activities,
  transactionByRef,
  transactionReport,
  allBalances,
  allCashBalances,
  cashBalanceBranchWise,
  exchangeRate,

  //Stock
  products,
  stockRecord,
  purchase,
  sale,
  estimate,

  userLog,
  users,
  individualsReport,
  attendance,

}
class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Desktop(), tablet: _Desktop(), desktop: _Desktop());
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    final List<Map<String, dynamic>> financeButtons = [
      if(login.hasPermission(79) ?? false)
      {"title": tr.accountStatement, "icon": FontAwesomeIcons.buildingColumns, "action": ActionKey.accStatement},
      if(login.hasPermission(81) ?? false)
      {"title": tr.glStatement, "icon": FontAwesomeIcons.buildingColumns, "action": ActionKey.glStatement},
      if(login.hasPermission(80) ?? false)
      {"title": tr.glStatementSingleDate, "icon": FontAwesomeIcons.buildingColumns, "action": ActionKey.glStatementSingleDate},
      if(login.hasPermission(82) ?? false)
      {"title": tr.creditors, "icon": FontAwesomeIcons.arrowTrendUp, "action": ActionKey.payable},
      if(login.hasPermission(83) ?? false)
      {"title": tr.debtors, "icon": FontAwesomeIcons.arrowTrendDown, "action": ActionKey.receivable},
      {"title": tr.accounts, "icon": Icons.account_circle, "action": ActionKey.accountsReport},
    ];

    final List<Map<String, dynamic>> stockButtons = [
      if(login.hasPermission(84) ?? false)
      {"title": tr.stockAvailability, "icon": Icons.storage, "action": ActionKey.products},
      if(login.hasPermission(85) ?? false)
      {"title": tr.productMovement, "icon": Icons.shopping_bag_outlined, "action": ActionKey.stockRecord},
      if(login.hasPermission(86) ?? false)
      {"title": tr.purchaseInvoice, "icon": Icons.add_shopping_cart_sharp, "action": ActionKey.purchase},
      if(login.hasPermission(87) ?? false)
      {"title": tr.salesInvoice, "icon": Icons.add_shopping_cart_sharp, "action": ActionKey.sale},
      if(login.hasPermission(88) ?? false)
      {"title": tr.estimateTitle, "icon": Icons.file_copy_outlined, "action": ActionKey.estimate},
    ];

    final List<Map<String, dynamic>> transactionsButtons = [
      if(login.hasPermission(92) ?? false)
      {"title": "${tr.treasury} (${tr.all} ${tr.branches})", "icon":  FontAwesomeIcons.sackDollar, "action": ActionKey.allCashBalances},
      if(login.hasPermission(93) ?? false)
      {"title": "${tr.treasury} (${tr.branch} Wise)", "icon": FontAwesomeIcons.sackDollar, "action": ActionKey.cashBalanceBranchWise},
      if(login.hasPermission(94) ?? false)
      {"title": tr.exchangeRate, "icon": Icons.price_change_outlined, "action": ActionKey.exchangeRate},
      if(login.hasPermission(113) ?? false)
      {"title": tr.balanceSheet, "icon": Icons.balance_rounded, "action": ActionKey.balanceSheet},
      if(login.hasPermission(95) ?? false)
      {"title": tr.trialBalance, "icon": Icons.balance_rounded, "action": ActionKey.trialBalance},
      if(login.hasPermission(96) ?? false)
      {"title": tr.transactionDetails, "icon": Icons.qr_code_2_rounded, "action": ActionKey.transactionByRef},
      if(login.hasPermission(97) ?? false)
      {"title": "${tr.transactions} ${tr.report}", "icon": Icons.line_axis_sharp, "action": ActionKey.transactionReport},
      if(login.hasPermission(98) ?? false)
      {"title": tr.allBalancesTitle, "icon": Icons.money, "action": ActionKey.allBalances},
    ];

    final List<Map<String, dynamic>> activitiesButtons = [
      {"title": tr.individuals, "icon": Icons.people, "action": ActionKey.individualsReport},
      if(login.hasPermission(99) ?? false)
      {"title": tr.users, "icon": FontAwesomeIcons.users, "action": ActionKey.users},
      if(login.hasPermission(101) ?? false)
      {"title": tr.userLog, "icon": Icons.scale_rounded, "action": ActionKey.userLog},
      if(login.hasPermission(110) ?? false)
        {"title": tr.attendance, "icon": Icons.timer, "action": ActionKey.attendance},
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: tr.finance),
              SizedBox(height: 8),
              _buildButtonGroup(financeButtons, color),
              const SizedBox(height: 15),

              SectionTitle(title: tr.inventory),
              SizedBox(height: 8),
              _buildButtonGroup(stockButtons, color),

              const SizedBox(height: 15),
              SectionTitle(title: tr.cashFlow),
              SizedBox(height: 8),
              _buildButtonGroup(transactionsButtons, color),

              const SizedBox(height: 15),

              //_buildSectionTitle(title: "${tr.users} & ${tr.activities}",icon: Icons.supervised_user_circle_sharp),
              SectionTitle(title: "${tr.users} & ${tr.activities}"),
              SizedBox(height: 8),
              _buildButtonGroup(activitiesButtons, color),

            ],
          ),
        ),
      ),
    );
  }

  /// Wrap-based button layout for compact and responsive placement
  Widget _buildButtonGroup(List<Map<String, dynamic>> buttons, ColorScheme color) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: buttons.map((btn) => _buildButton(btn)).toList(),
        ),
      ),
    );
  }

  Widget _buildButton(Map<String, dynamic> button) {
    final color = Theme.of(context).colorScheme;
    final hoverNotifier = ValueNotifier(false);
    return MouseRegion(
      onEnter: (_) => hoverNotifier.value = true,
      onExit: (_) => hoverNotifier.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: hoverNotifier,
        builder: (context, isHovered, _) {
          return InkWell(
            onTap: () => reportAction(button['action'] as ActionKey),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              width: 110,
              height: 120,
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: isHovered
                      ? color.primary
                      : color.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(button['icon'], size: 30, color: isHovered
                      ? color.surface
                      : color.primary.withValues(alpha: .9),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    button['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHovered
                          ? color.surface
                          : color.outline.withValues(alpha: .9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  void reportAction(ActionKey action) {
    switch (action) {

      //Finance
      case ActionKey.accStatement: Utils.goto(context, AccountStatementView());
      case ActionKey.glStatement: Utils.goto(context, GlStatementView());
      case ActionKey.payable: Utils.goto(context, PayablesView());
      case ActionKey.receivable: Utils.goto(context, ReceivablesView());
      case ActionKey.exchangeRate: Utils.goto(context, FxRateReportView());
      case ActionKey.allCashBalances: Utils.goto(context, TreasuryView());
      case ActionKey.cashBalanceBranchWise: Utils.goto(context, CashBalancesBranchWiseView());
      case ActionKey.accountsReport: Utils.goto(context, AccountsReportView());
      case ActionKey.trialBalance: Utils.goto(context, TrialBalanceView());
      case ActionKey.glStatementSingleDate: Utils.goto(context, GlStatementView(isSingleDate: true));

      //Transactions
      case ActionKey.balanceSheet: Utils.goto(context, BalanceSheetView());
      case ActionKey.activities:  Utils.goto(context, TransactionReportView());
      case ActionKey.transactionByRef:  Utils.goto(context, TransactionByReferenceView());
      case ActionKey.transactionReport: Utils.goto(context, TransactionReportView());
      case ActionKey.allBalances: Utils.goto(context, AllBalancesView());

      // Stock
      case ActionKey.products:  Utils.goto(context, ProductReportView());
      case ActionKey.stockRecord:  Utils.goto(context, StockRecordReportView());
      case ActionKey.purchase: Utils.goto(context, OrderReportView(orderName: "Purchase"));
      case ActionKey.sale: Utils.goto(context, OrderReportView(orderName: "Sale"));
      case ActionKey.estimate: Utils.goto(context, OrderReportView(orderName: "Estimate"));

      // Activity
      case ActionKey.individualsReport: Utils.goto(context, StakeholdersReportView());
      case ActionKey.users: Utils.goto(context, UsersReportView());
      case ActionKey.userLog: Utils.goto(context, UserLogReportView());
      case ActionKey.attendance: Utils.goto(context, AttendanceReportView());

    }
  }
}

