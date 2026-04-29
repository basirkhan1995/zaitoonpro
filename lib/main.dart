import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:zaitoonpro/Features/Other/shortcut.dart';
import 'package:zaitoonpro/Features/Other/znavigator.dart';
import 'package:zaitoonpro/Features/PrintSettings/bloc/Language/print_language_cubit.dart';
import 'package:zaitoonpro/Features/PrintSettings/bloc/PageSize/paper_size_cubit.dart';
import 'package:zaitoonpro/Features/PrintSettings/bloc/Printer/printer_cubit.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Services/api_services.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Auth/ForgotPassword/bloc/forgot_password_bloc.dart';
import 'package:zaitoonpro/Views/Auth/Subscription/bloc/subscription_bloc.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Auth/Ui/login.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Dashboard/Views/DailyGross/bloc/daily_gross_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Dashboard/Views/Stats/bloc/dashboard_stats_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/bloc/currencies_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/bloc/currency_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/EndOfYear/bloc/eoy_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/GlCategories/bloc/gl_category_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/bloc/gl_accounts_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Payroll/bloc/payroll_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/bloc/financial_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Attendance/bloc/attendance_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/bloc/employee_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Log/bloc/user_log_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/bloc/user_details_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/bloc/users_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/bloc/hrtab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchATAT/bloc/fetch_atat_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchGLAT/bloc/glat_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FundTransfer/BulkTransfer/bloc/transfer_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FxTransaction/bloc/fx_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/GetOrder/bloc/order_txn_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/ProjectTxn/bloc/project_txn_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/TxnByReference/bloc/txn_reference_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/bloc/transactions_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/bloc/transaction_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/ProjectsById/bloc/projects_by_id_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/IncomeExpense/bloc/project_inc_exp_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/ProjectServices/bloc/project_services_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/bloc/project_tabs_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/AccountStatement/acc_statement.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/AccountStatement/bloc/acc_statement_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Accounts/bloc/accounts_report_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ArApReport/bloc/ar_ap_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/BalanceSheet/balance_sheet.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/BalanceSheet/bloc/balance_sheet_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ExchangeRate/bloc/fx_rate_report_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/GLStatement/bloc/gl_statement_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/GLStatement/gl_statement.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/bloc/cash_balances_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/cash_branch.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/TrialBalance/bloc/trial_balance_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/TrialBalance/trial_balance.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/Cardx/Ui/cardx.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/Cardx/bloc/stock_record_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/OrdersReport/bloc/order_report_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/StockAvailability/bloc/product_report_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/StockAvailability/product_report.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/TotalDailyTxn/bloc/total_daily_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/TransactionRef/transaction_ref.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/UserReport/StakeholdersReport/bloc/stakeholders_report_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Backup/bloc/backup_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/Ui/BranchLimits/bloc/branch_limit_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/bloc/brc_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/bloc/company_settings_menu_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/General/Ui/UserProfileSettings/bloc/user_profile_settings_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/bloc/services_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/ProductCategory/bloc/pro_cat_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/bloc/stock_settings_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/TxnTypes/bloc/txn_types_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualByID/bloc/stakeholder_by_id_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/bloc/ind_detail_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/bloc/stk_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Adjustment/bloc/adjustment_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Estimate/bloc/estimate_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/GoodsShift/bloc/goods_shift_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/GetOrderById/bloc/order_by_id_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewPurchase/bloc/purchase_invoice_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/bloc/sale_invoice_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Orders/bloc/orders_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/bloc/stock_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/bloc/menu_bloc.dart';
import 'Features/PrintSettings/bloc/PageOrientation/page_orientation_cubit.dart';
import 'Localizations/Bloc/localizations_bloc.dart';
import 'Localizations/l10n/l10n.dart';
import 'Localizations/l10n/translations/app_localizations.dart';
import 'Services/localization_services.dart';
import 'Themes/Bloc/themes_bloc.dart';
import 'Themes/Ui/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Views/Menu/Ui/HR/Ui/UserDetail/Ui/Permissions/bloc/permissions_bloc.dart';
import 'Views/Menu/Ui/Projects/Ui/AllProjects/bloc/projects_bloc.dart';
import 'Views/Menu/Ui/Reminder/bloc/reminder_bloc.dart';
import 'Views/Menu/Ui/Report/Ui/Finance/AllBalances/bloc/all_balances_bloc.dart';
import 'Views/Menu/Ui/Report/Ui/HR/AttendanceReport/bloc/attendance_report_bloc.dart';
import 'Views/Menu/Ui/Report/Ui/TransactionRef/bloc/txn_ref_report_bloc.dart';
import 'Views/Menu/Ui/Report/Ui/TxnReport/bloc/txn_report_bloc.dart';
import 'Views/Menu/Ui/Settings/Ui/Company/Branches/bloc/branch_bloc.dart';
import 'Views/Menu/Ui/Settings/Ui/General/Ui/DefaultPermissions/bloc/permission_settings_bloc.dart';
import 'Views/Menu/Ui/Settings/Ui/General/Ui/UserRole/bloc/user_role_bloc.dart';
import 'Views/Menu/Ui/Settings/Ui/General/bloc/general_tab_bloc.dart';
import 'Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import 'Views/Menu/Ui/Settings/bloc/settings_tab_bloc.dart';
import 'Views/Menu/Ui/Settings/features/Visibility/bloc/settings_visible_bloc.dart';
import 'Views/PasswordSettings/bloc/password_bloc.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrintServices.initializeFonts();
  // if (Platform.isWindows || Platform.isMacOS) {
  //   await windowManager.ensureInitialized();
  //   windowManager.setMinimumSize(const Size(900, 700));
  // }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        /// Tabs & Others ......................................................
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => LocalizationBloc()),
        BlocProvider(create: (context) => MenuBloc()),
        BlocProvider(create: (context) => JournalTabBloc()),
        BlocProvider(create: (context) => GeneralTabBloc()),
        BlocProvider(create: (context) => StockTabBloc()),
        BlocProvider(create: (context) => HrTabBloc()),
        BlocProvider(create: (context) => FinanceTabBloc()),
        BlocProvider(create: (context) => CurrencyTabBloc()),
        BlocProvider(create: (context) => StakeholderTabBloc()),
        BlocProvider(create: (context) => SettingsTabBloc()),
        BlocProvider(create: (context) => SettingsVisibleBloc()..add(LoadSettingsEvent())),
        BlocProvider(create: (context) => IndividualDetailTabBloc()),
        BlocProvider(create: (context) => CompanySettingsMenuBloc()),
        BlocProvider(create: (context) => UserDetailsTabBloc()),
        BlocProvider(create: (context) => BranchTabBloc()),
        BlocProvider(create: (context) => StockSettingsTabBloc()),
        BlocProvider(create: (context) => ProjectTabsBloc()),

        ///Print Services ............................................................
        BlocProvider(create: (context) => PrintLanguageCubit()),
        BlocProvider(create: (context) => PageOrientationCubit()),
        BlocProvider(create: (context) => PaperSizeCubit()),
        BlocProvider(create: (context) => PrinterCubit()),

        /// Data Management ....................................................
        BlocProvider(create: (context) => IndividualsBloc(Repositories(ApiServices()))..add(LoadIndividualsEvent())),
        BlocProvider(create: (context) => EoyBloc(Repositories(ApiServices()))..add(LoadPLEvent())),
        BlocProvider(create: (context) => AccountsBloc(Repositories(ApiServices()))..add(LoadAccountsEvent())),
        BlocProvider(create: (context) => UsersBloc(Repositories(ApiServices()))..add(LoadUsersEvent())),
        BlocProvider(create: (context) => CurrenciesBloc(Repositories(ApiServices()))..add(LoadCurrenciesEvent())),
        BlocProvider(create: (context) => GlAccountsBloc(Repositories(ApiServices()))..add(LoadGlAccountEvent())),
        BlocProvider(create: (context) => StakeholderByIdBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => PermissionsBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => AuthBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => ForgotPasswordBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => PasswordBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => ExchangeRateBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => TransactionsBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => CompanyProfileBloc(Repositories(ApiServices()))..add(LoadCompanyProfileEvent())),
        BlocProvider(create: (context) => BranchBloc(Repositories(ApiServices()))..add(LoadBranchesEvent())),
        BlocProvider(create: (context) => BranchLimitBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => TxnReferenceBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => EmployeeBloc(Repositories(ApiServices()))..add(LoadEmployeeEvent())),
        BlocProvider(create: (context) => FetchAtatBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => TransferBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => FxBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => GlatBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => StorageBloc(Repositories(ApiServices()))..add(LoadStorageEvent())),
        BlocProvider(create: (context) => TxnTypesBloc(Repositories(ApiServices()))..add(LoadTxnTypesEvent())),
        BlocProvider(create: (context) => ProductsBloc(Repositories(ApiServices()))..add(LoadProductsEvent())),
        BlocProvider(create: (context) => ProCatBloc(Repositories(ApiServices()))..add(LoadProCatEvent())),
        BlocProvider(create: (context) => UserLogBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => OrdersBloc(Repositories(ApiServices()))..add(LoadOrdersEvent())),
        BlocProvider(create: (context) => EstimateBloc(Repositories(ApiServices()))..add(LoadEstimatesEvent())),
        BlocProvider(create: (context) => PurchaseInvoiceBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => OrderByIdBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => SaleInvoiceBloc(Repositories(ApiServices()))..add(InitializeSaleInvoiceEvent())),
        BlocProvider(create: (context) => OrderTxnBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => GlCategoryBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => GoodsShiftBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => AdjustmentBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => ReminderBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => AttendanceBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => PayrollBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => ProjectsBloc(Repositories(ApiServices()))..add(LoadProjectsEvent())),
        BlocProvider(create: (context) => ServicesBloc(Repositories(ApiServices()))..add(LoadServicesEvent())),
        BlocProvider(create: (context) => ProjectServicesBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => ProjectIncExpBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => UserRoleBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => PermissionSettingsBloc(Repositories(ApiServices()))..add(LoadPermissionsSettingsEvent())),
        BlocProvider(create: (context) => SubscriptionBloc(Repositories(ApiServices()))..add(LoadSubscriptionEvent())),
        BlocProvider(create: (context) => UserProfileSettingsBloc(Repositories(ApiServices()))),

        ///Report Bloc
        BlocProvider(create: (context) => AccStatementBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => TxnRefReportBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => GlStatementBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => ArApBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => TrialBalanceBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => BalanceSheetBloc(Repositories(ApiServices()))..add(LoadBalanceSheet())),
        BlocProvider(create: (context) => FxRateReportBloc(Repositories(ApiServices()))..add(LoadFxRateReportEvent())),
        BlocProvider(create: (context) => CashBalancesBloc(Repositories(ApiServices()))..add(LoadCashBalanceBranchWiseEvent())),
        BlocProvider(create: (context) => TxnReportBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => AllBalancesBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => ProductReportBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => OrderReportBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => StockRecordBloc(Repositories(ApiServices()))..add(ResetStockRecordEvent())),
        BlocProvider(create: (context) => BackupBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => AttendanceReportBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => AccountsReportBloc(Repositories(ApiServices()))..add(ResetAccountsReportEvent())),
        BlocProvider(create: (context) => ProjectsByIdBloc(Repositories(ApiServices()))..add(ResetProjectByIdEvent())),
        BlocProvider(create: (context) => ProjectTxnBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => StakeholdersReportBloc(Repositories(ApiServices()))),

        ///Dashboard
        BlocProvider(create: (context) => DashboardStatsBloc(Repositories(ApiServices()))..add(FetchDashboardStatsEvent())),
        BlocProvider(create: (context) => DailyGrossBloc(Repositories(ApiServices()))),
        BlocProvider(create: (context) => TotalDailyBloc(Repositories(ApiServices()))),
      ],
      child: BlocBuilder<LocalizationBloc, Locale>(
        builder: (context, locale) {
          return BlocBuilder<ThemeBloc, ThemeMode>(
            builder: (context, themeMode) {
              final theme = AppThemes(TextTheme.of(context));
              final authState = context.watch<AuthBloc>().state;
              return GlobalShortcuts(
                shortcuts: {
                  if(authState is AuthenticatedState && (authState.loginData.hasPermission(96) ?? false))
                  const SingleActivator(
                    LogicalKeyboardKey.keyR,
                    shift: true,
                    control: true,
                  ): () => ZNavigator.goto(TransactionByReferenceView()),
                  if(authState is AuthenticatedState && (authState.loginData.hasPermission(79) ?? false))
                  const SingleActivator(
                    LogicalKeyboardKey.keyS,
                    shift: true,
                    control: true,
                  ): () => ZNavigator.goto(AccountStatementView()),
                  if(authState is AuthenticatedState && (authState.loginData.hasPermission(81) ?? false))
                  const SingleActivator(
                    LogicalKeyboardKey.keyG,
                    shift: true,
                    control: true,
                  ): () => ZNavigator.goto(GlStatementView()),
                  if(authState is AuthenticatedState && (authState.loginData.hasPermission(93) ?? false))
                    const SingleActivator(
                      LogicalKeyboardKey.f10,
                    ): () => ZNavigator.goto(CashBalancesBranchWiseView()),
                  if(authState is AuthenticatedState && (authState.loginData.hasPermission(113) ?? false))
                  const SingleActivator(
                    LogicalKeyboardKey.f12,
                  ): () => ZNavigator.goto(BalanceSheetView()),
                  if(authState is AuthenticatedState && (authState.loginData.hasPermission(95) ?? false))
                  const SingleActivator(
                    LogicalKeyboardKey.f11,
                  ): () => ZNavigator.goto(TrialBalanceView()),

                  if(authState is AuthenticatedState)
                    const SingleActivator(
                        LogicalKeyboardKey.keyX,
                      shift: true,
                      control: true
                    ): () => ZNavigator.goto(StockRecordReportView()),
                  if(authState is AuthenticatedState)
                    const SingleActivator(
                        LogicalKeyboardKey.keyZ,
                        shift: true,
                        control: true
                    ): () => ZNavigator.goto(ProductReportView()),

                },
                child: MaterialApp(
                    navigatorKey: ZNavigator.navigatorKey,
                    debugShowCheckedModeBanner: false,
                    title: 'Zaitoon System',
                    localizationsDelegates: [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    locale: locale,
                    supportedLocales: L10n.all,
                    themeMode: themeMode,
                    darkTheme: theme.dark(),
                    theme: theme.light(),
                    builder: (context, child) {
                      localizationService.update(AppLocalizations.of(context)!);
                      return child!;
                    },
                    home: LoginView()
                ),
              );
            },
          );
        },
      ),
    );
  }

}