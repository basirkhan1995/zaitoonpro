import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FxTransaction/Ui/fx_transaction.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/View/all_transactions.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/View/authorized.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/View/pending.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/bloc/transactions_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/model/transaction_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/bloc/transaction_tab_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../../../../Features/Date/z_generic_date.dart';
import '../../../../Features/Generic/complex_textfield.dart';
import '../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../Features/Generic/tab_bar.dart';
import '../../../../Features/Other/cover.dart';
import '../../../../Features/Other/responsive.dart';
import '../../../../Features/Other/shortcut.dart';
import '../../../../Features/Other/thousand_separator.dart';
import '../../../../Features/PrintSettings/print_preview.dart';
import '../../../../Features/PrintSettings/report_model.dart';
import '../../../../Features/Widgets/outline_button.dart';
import '../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../Reminder/bloc/reminder_bloc.dart';
import '../Reminder/model/reminder_model.dart';
import '../Report/Ui/Finance/AccountStatement/acc_statement.dart';
import '../Report/Ui/Finance/GLStatement/gl_statement.dart';
import '../Report/Ui/TransactionRef/transaction_ref.dart';
import '../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../Stakeholders/Ui/Accounts/model/stk_acc_model.dart';
import 'PDF/cash_flow_print.dart';
import 'Ui/FundTransfer/BulkTransfer/Ui/bulk_transfer.dart';

class JournalView extends StatelessWidget {
  const JournalView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _MobileView(),
      desktop: const _DesktopView(),
      tablet: const _DesktopView(),
    );
  }
}

// Mobile Specific View
class _MobileView extends StatefulWidget {
  const _MobileView();

  @override
  State<_MobileView> createState() => _MobileViewState();
}
class _MobileViewState extends State<_MobileView> {
  String? currentLocale;
  String? trnCurrency;
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  bool isPrint = true;

  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          currentLocale = context.read<LocalizationBloc>().state.languageCode;
        });
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  String? _getBaseCurrency() {
    try {
      final companyState = context.read<CompanyProfileBloc>().state;
      if (companyState is CompanyProfileLoadedState) {
        return companyState.company.comLocalCcy;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  void onCashDepositWithdraw({String? trnType}) {
    // Copy the exact same implementation from _DesktopState
    final locale = AppLocalizations.of(context)!;
    final accountController = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();
    bool isReminder = false;
    String? reminderDate;

    String? currentBalance;
    String? availableBalance;
    String? accName;
    int? accNumber;
    String? accCurrency;
    String? ccySymbol;
    String? accountLimit;
    int? status;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, trState) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ZFormDialog(
                  width: 600,
                  icon: trnType == "CHDP"
                      ? Icons.arrow_circle_down_rounded
                      : Icons.arrow_circle_up_rounded,
                  title: trnType == "CHDP" ? locale.deposit : locale.withdraw,
                  onAction: () {
                    if(isReminder){
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: accCurrency ?? "",
                            trnType: trnType,
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                      onReminder(
                          accNumber: accNumber!,
                          amount: amount.text.cleanAmount,
                          date: reminderDate??DateTime.now().toFormattedDate(),
                          dueType: trnType == "CHDP" ? "payable" : "receivable",
                          narration: narration.text,
                          usrName: login.usrName??""
                      );
                    }else{
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: accCurrency ?? "",
                            trnType: trnType,
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                    }
                  },
                  actionLabel: trState is TxnLoadingState
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.surface,
                      strokeWidth: 4,
                    ),
                  )
                      : Text(locale.create),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          GenericTextField<StakeholdersAccountsModel, AccountsBloc, AccountsState>(
                            showAllOnFocus: true,
                            controller: accountController,
                            title: locale.accounts,
                            hintText: locale.accNameOrNumber,
                            isRequired: true,
                            bloc: context.read<AccountsBloc>(),
                            fetchAllFunction: (bloc) => bloc.add(LoadStkAccountsEvent()),
                            searchFunction: (bloc, query) => bloc.add(LoadStkAccountsEvent(search: query)),
                            validator: (value) {
                              if (value.isEmpty) {
                                return locale.required(locale.accounts);
                              }
                              return null;
                            },
                            itemBuilder: (context, account) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 5,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${account.accnumber} | ${account.accName}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            itemToString: (acc) =>
                            "${acc.accnumber} | ${acc.accName}",
                            stateToLoading: (state) =>
                            state is AccountLoadingState,
                            loadingBuilder: (context) => const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                            stateToItems: (state) {
                              if (state is StkAccountLoadedState) {
                                return state.accounts;
                              }
                              return [];
                            },
                            onSelected: (value) {
                              setState(() {
                                accNumber = value.accnumber;
                                ccySymbol = value.ccySymbol;
                                accCurrency = value.actCurrency;
                                accName = value.accName ?? "";
                                availableBalance = value.avilBalance;
                                currentBalance = value.curBalance;
                                accountLimit = value.actCreditLimit;
                                status = value.actStatus ?? 0;
                              });
                            },
                            noResultsText: locale.noDataFound,
                            showClearButton: true,
                          ),
                          if (accName != null && accName!.isNotEmpty)...[
                            ZCover(
                              color: Theme.of(context).colorScheme.surface,
                              padding: EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  if (accName != null && accName!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            locale.accountDetails,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (accName != null && accName!.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      width: double.infinity,
                                      child: Row(
                                        spacing: 5,
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.start,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            spacing: 5,
                                            children: [
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountNumber}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountName}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.currencyTitle}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountLimit}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountStatus}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountPosition}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.currentBalance}:",
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.availableBalance}:",
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.start,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            spacing: 5,
                                            children: [
                                              Text(
                                                accNumber.toString(),
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(accName ?? ""),
                                              Text(accCurrency ?? ""),
                                              Text(
                                                "$ccySymbol${accountLimit?.toAmount()}",
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                status == 1
                                                    ? locale.active
                                                    : locale.blocked,
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                getAccountPosition(availableBalance),
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                "$ccySymbol${currentBalance?.toAmount()}",
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                "$ccySymbol${availableBalance?.toAmount()}",
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                          ],

                          ZTextFieldEntitled(
                            isRequired: true,
                            keyboardInputType:
                            TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormat: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]*'),
                              ),
                              SmartThousandsDecimalFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return locale.required(locale.exchangeRate);
                              }

                              // Remove formatting (e.g. commas)
                              final clean = value.replaceAll(
                                RegExp(r'[^\d.]'),
                                '',
                              );
                              final amount = double.tryParse(clean);

                              if (amount == null || amount <= 0.0) {
                                return locale.amountGreaterZero;
                              }

                              return null;
                            },
                            controller: amount,
                            title: locale.amount,
                          ),
                          ZTextFieldEntitled(
                            keyboardInputType: TextInputType.multiline,
                            controller: narration,
                            title: locale.narration,
                          ),
                          Row(
                            spacing: 5,
                            children: [
                              Checkbox(
                                visualDensity: VisualDensity(horizontal: -4,vertical: -4),
                                value: isPrint,
                                onChanged: (e) {
                                  setState(() {
                                    isPrint = e ?? true;
                                  });
                                },
                              ),
                              Text(locale.print),
                            ],
                          ),
                          Row(
                            spacing: 5,
                            children: [
                              Checkbox(
                                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                value: isReminder,
                                onChanged: (value) {
                                  setState(() {
                                    isReminder = value ?? false;
                                  });
                                },
                              ),
                              Text(locale.setReminder),
                            ],
                          ),

                          if(isReminder)
                            ZDatePicker(
                              disablePastDate: true,
                              label: locale.dueDate,
                              value: reminderDate,
                              onDateChanged: (v) {
                                setState(() {
                                  reminderDate = v;
                                });
                              },
                            ),

                          if (trState is TransactionErrorState)...[
                            Row(
                              children: [
                                Text(
                                  trState.message,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void onCashIncome({String? trnType}) {
    // Copy the exact same implementation from _DesktopState
    final locale = AppLocalizations.of(context)!;
    final accountController = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();
    int? accNumber;
    String? availableBalance;
    int? accCategory;
    int? accStatus;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;
    final baseCurrency = _getBaseCurrency();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context,setState) {
              return BlocBuilder<TransactionsBloc, TransactionsState>(
                builder: (context, trState) {
                  return ZFormDialog(
                    width: 600,
                    icon: Icons.arrow_circle_down_rounded,
                    title: locale.income,
                    onAction: () {
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: trnCurrency ?? baseCurrency,
                            trnType: trnType,
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                    },
                    actionLabel: trState is TxnLoadingState
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                        : Text(locale.create),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 12,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 5,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                                    showAllOnFocus: true,
                                    controller: accountController,
                                    title: locale.accounts,
                                    hintText: locale.accNameOrNumber,
                                    isRequired: true,
                                    bloc: context.read<AccountsBloc>(),
                                    fetchAllFunction: (bloc) => bloc.add(
                                      LoadAccountsFilterEvent(include: '9,10',ccy: baseCurrency,exclude: ""),
                                    ),
                                    searchFunction: (bloc, query) => bloc.add(
                                      LoadAccountsFilterEvent(
                                          include: "9,10",
                                          ccy: baseCurrency,
                                          input: query,
                                          exclude: ""
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return locale.required(locale.accounts);
                                      }
                                      return null;
                                    },
                                    itemBuilder: (context, account) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "${account.accNumber} | ${account.accName}",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                                    stateToLoading: (state) => state is AccountLoadingState,
                                    loadingBuilder: (context) => const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                    stateToItems: (state) {
                                      if (state is AccountLoadedState) {
                                        return state.accounts;
                                      }
                                      return [];
                                    },
                                    onSelected: (value) {
                                      setState(() {
                                        accNumber = value.accNumber;
                                        availableBalance = value.accAvailBalance;
                                        accountController.text = value.accName?? "";
                                        accCategory = value.accCategory;
                                        accStatus = value.accStatus;
                                      });
                                    },
                                    noResultsText: locale.noDataFound,
                                    showClearButton: true,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: CurrencyDropdown(
                                      initiallySelectedSingle: CurrenciesModel(ccyCode: baseCurrency),
                                      title: locale.currencyTitle,
                                      isMulti: false,
                                      onSingleChanged: (e){
                                        trnCurrency = e?.ccyCode ?? baseCurrency;
                                      },
                                      onMultiChanged: (e){}),
                                )
                              ],
                            ),

                            if(accNumber != null)...[
                              accountDetailsView(AccountsModel(
                                  accNumber: accNumber,
                                  accAvailBalance: availableBalance?.toAmount(),
                                  accName: accountController.text,
                                  accCategory: accCategory,
                                  accStatus: accStatus
                              )),
                            ],

                            ZTextFieldEntitled(
                              isRequired: true,
                              keyboardInputType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormat: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]*'),
                                ),
                                SmartThousandsDecimalFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return locale.required(locale.exchangeRate);
                                }

                                // Remove formatting (e.g. commas)
                                final clean = value.replaceAll(
                                  RegExp(r'[^\d.]'),
                                  '',
                                );
                                final amount = double.tryParse(clean);

                                if (amount == null || amount <= 0.0) {
                                  return locale.amountGreaterZero;
                                }

                                return null;
                              },
                              controller: amount,
                              title: locale.amount,
                            ),
                            ZTextFieldEntitled(
                              keyboardInputType: TextInputType.multiline,
                              controller: narration,
                              title: locale.narration,
                            ),

                            Row(
                              spacing: 5,
                              children: [
                                Checkbox(
                                  visualDensity: VisualDensity(horizontal: -4),
                                  value: isPrint,
                                  onChanged: (e) {
                                    setState(() {
                                      isPrint = e ?? true;
                                    });
                                  },
                                ),
                                Text(locale.print),
                              ],
                            ),
                            if (trState is TransactionErrorState)
                              SizedBox(height: 10),
                            Row(
                              children: [
                                trState is TransactionErrorState
                                    ? Text(
                                  trState.message,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                )
                                    : SizedBox(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
        );
      },
    );
  }

  void onCashExpense({String? trnType}) {
    // Copy the exact same implementation from _DesktopState
    final locale = AppLocalizations.of(context)!;
    final accountController = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();
    int? accNumber;
    String? availableBalance;
    int? accCategory;
    int? accStatus;
    String? accName;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;
    final baseCurrency = _getBaseCurrency();

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, trState) {
            return StatefulBuilder(
                builder: (context,setState) {
                  return ZFormDialog(
                    width: 600,
                    icon: Icons.arrow_circle_up_rounded,
                    title: locale.expense,
                    onAction: () {
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: trnCurrency ?? baseCurrency ?? "",
                            trnType: trnType ?? "",
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                    },
                    actionLabel: trState is TxnLoadingState
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                        : Text(locale.create),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 12,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 8,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                                    showAllOnFocus: true,
                                    controller: accountController,
                                    title: locale.accounts,
                                    hintText: locale.accNameOrNumber,
                                    isRequired: true,
                                    bloc: context.read<AccountsBloc>(),
                                    fetchAllFunction: (bloc) => bloc.add(
                                      LoadAccountsFilterEvent(include: "11,12",ccy: baseCurrency,exclude: ""),
                                    ),
                                    searchFunction: (bloc, query) => bloc.add(
                                      LoadAccountsFilterEvent(
                                          include: "11,12",
                                          ccy: baseCurrency,
                                          input: query, exclude: ""
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return locale.required(locale.accounts);
                                      }
                                      return null;
                                    },
                                    itemBuilder: (context, account) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "${account.accNumber} | ${account.accName}",
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                                    stateToLoading: (state) => state is AccountLoadingState,
                                    loadingBuilder: (context) => const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                    stateToItems: (state) {
                                      if (state is AccountLoadedState) {
                                        return state.accounts;
                                      }
                                      return [];
                                    },
                                    onSelected: (value) {
                                      setState(() {
                                        accNumber = value.accNumber;
                                        availableBalance = value.accAvailBalance;
                                        accCategory = value.accCategory;
                                        accStatus = value.accStatus;
                                        accName = value.accName;
                                      });
                                    },
                                    noResultsText: locale.noDataFound,
                                    showClearButton: true,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: CurrencyDropdown(
                                      initiallySelectedSingle: CurrenciesModel(ccyCode: baseCurrency),
                                      title: locale.currencyTitle,
                                      isMulti: false,
                                      onSingleChanged: (e){
                                        trnCurrency = e?.ccyCode ?? baseCurrency;
                                      },
                                      onMultiChanged: (e){}),
                                )
                              ],
                            ),

                            if(accNumber !=null)...[
                              accountDetailsView(AccountsModel(
                                accNumber: accNumber,
                                accCategory: accCategory,
                                accName: accName,
                                accAvailBalance: availableBalance,
                                accStatus: accStatus,
                              ))
                            ],

                            ZTextFieldEntitled(
                              isRequired: true,
                              keyboardInputType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormat: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]*'),
                                ),
                                SmartThousandsDecimalFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return locale.required(locale.exchangeRate);
                                }

                                // Remove formatting (e.g. commas)
                                final clean = value.replaceAll(
                                  RegExp(r'[^\d.]'),
                                  '',
                                );
                                final amount = double.tryParse(clean);

                                if (amount == null || amount <= 0.0) {
                                  return locale.amountGreaterZero;
                                }

                                return null;
                              },
                              controller: amount,
                              title: locale.amount,
                            ),
                            ZTextFieldEntitled(
                              keyboardInputType: TextInputType.multiline,
                              controller: narration,
                              title: locale.narration,
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                Checkbox(
                                  visualDensity: VisualDensity(horizontal: -4),
                                  value: isPrint,
                                  onChanged: (e) {
                                    setState(() {
                                      isPrint = e ?? true;
                                    });
                                  },
                                ),
                                Text(locale.print),
                              ],
                            ),
                            if (trState is TransactionErrorState)
                              SizedBox(height: 10),
                            Row(
                              children: [
                                trState is TransactionErrorState
                                    ? Text(
                                  trState.message,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                )
                                    : SizedBox(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            );
          },
        );
      },
    );
  }

  void onGL({String? trnType}) {
    // Copy the exact same implementation from _DesktopState
    final locale = AppLocalizations.of(context)!;
    final accountController = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();
    int? accNumber;
    String? availableBalance;
    int? accCategory;
    int? accStatus;
    String? accName;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;
    final baseCurrency = _getBaseCurrency();

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, trState) {
            return StatefulBuilder(
                builder: (context,setState) {
                  return ZFormDialog(
                    width: 600,
                    icon: Icons.cached_rounded,
                    title: trnType == "GLCR"
                        ? locale.glCreditTitle
                        : locale.glDebitTitle,
                    onAction: () {
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: trnCurrency ?? baseCurrency,
                            trnType: trnType,
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                    },
                    actionLabel: trState is TxnLoadingState
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                        : Text(locale.create),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 12,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 8,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                                    showAllOnFocus: true,
                                    controller: accountController,
                                    title: locale.accounts,
                                    hintText: locale.accNameOrNumber,
                                    isRequired: true,
                                    bloc: context.read<AccountsBloc>(),
                                    fetchAllFunction: (bloc) => bloc.add(
                                      LoadAccountsFilterEvent(
                                        include: '1,2,3,4,5,6,7',
                                        ccy: baseCurrency,
                                        exclude: "10101011",
                                      ),
                                    ),
                                    searchFunction: (bloc, query) => bloc.add(
                                      LoadAccountsFilterEvent(
                                        include: '1,2,3,4,5,6,7',
                                        ccy: baseCurrency,
                                        input: query,
                                        exclude: "10101011",
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return locale.required(locale.accounts);
                                      }
                                      return null;
                                    },
                                    itemBuilder: (context, account) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "${account.accNumber} | ${account.accName}",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemToString: (acc) =>
                                    "${acc.accNumber} | ${acc.accName}",
                                    stateToLoading: (state) =>
                                    state is AccountLoadingState,
                                    loadingBuilder: (context) => const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                    stateToItems: (state) {
                                      if (state is AccountLoadedState) {
                                        return state.accounts;
                                      }
                                      return [];
                                    },
                                    onSelected: (value) {
                                      setState(() {
                                        accNumber = value.accNumber;
                                        availableBalance = value.accAvailBalance;
                                        accName = value.accName?? "";
                                        accCategory = value.accCategory;
                                        accStatus = value.accStatus;
                                      });
                                    },
                                    noResultsText: locale.noDataFound,
                                    showClearButton: true,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: CurrencyDropdown(
                                      initiallySelectedSingle: CurrenciesModel(ccyCode: baseCurrency),
                                      title: locale.currencyTitle,
                                      isMulti: false,
                                      onSingleChanged: (e){
                                        trnCurrency = e?.ccyCode ?? baseCurrency;
                                      },
                                      onMultiChanged: (e){}),
                                )
                              ],
                            ),
                            if(accNumber !=null)...[
                              accountDetailsView(AccountsModel(
                                accNumber: accNumber,
                                accCategory: accCategory,
                                accName: accName,
                                accAvailBalance: availableBalance,
                                accStatus: accStatus,
                              ))
                            ],
                            ZTextFieldEntitled(
                              isRequired: true,
                              // onSubmit: (_)=> onSubmit(),
                              keyboardInputType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormat: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]*'),
                                ),
                                SmartThousandsDecimalFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return locale.required(locale.exchangeRate);
                                }

                                // Remove formatting (e.g. commas)
                                final clean = value.replaceAll(
                                  RegExp(r'[^\d.]'),
                                  '',
                                );
                                final amount = double.tryParse(clean);

                                if (amount == null || amount <= 0.0) {
                                  return locale.amountGreaterZero;
                                }

                                return null;
                              },
                              controller: amount,
                              title: locale.amount,
                            ),
                            ZTextFieldEntitled(
                              keyboardInputType: TextInputType.multiline,
                              controller: narration,
                              title: locale.narration,
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                Checkbox(
                                  visualDensity: VisualDensity(horizontal: -4),
                                  value: isPrint,
                                  onChanged: (e) {
                                    setState(() {
                                      isPrint = e ?? true;
                                    });
                                  },
                                ),
                                Text(locale.print),
                              ],
                            ),
                            if (trState is TransactionErrorState)
                              SizedBox(height: 10),
                            Row(
                              children: [
                                trState is TransactionErrorState
                                    ? Text(trState.message)
                                    : SizedBox(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            );
          },
        );
      },
    );
  }

  void accountToAccount({String? trnType}) {
    // Copy the exact same implementation from _DesktopState
    final tr = AppLocalizations.of(context)!;

    /// Credit .......................................
    final creditAccountCtrl = TextEditingController();
    String? creditAccCurrency;
    String? creditCurrentBalance;
    String? creditAvailableBalance;
    int? creditAccNumber;
    String? creditAccName;
    String? creditAccountLimit;
    String? creditCcySymbol;
    int? creditStatus;

    /// Debit .....................................
    final debitAccountCtrl = TextEditingController();
    String? debitAccCurrency;
    String? debitCurrentBalance;
    String? debitAvailableBalance;
    int? debitAccNumber;
    String? debitAccName;
    String? debitAccountLimit;
    String? debitCcySymbol;
    int? debitStatus;

    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;
    final baseCurrency = _getBaseCurrency();

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, trState) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ZFormDialog(
                  width: 800,
                  icon: Icons.swap_horiz_rounded,
                  title: tr.fundTransferTitle,
                  onAction: () {
                    context.read<TransactionsBloc>().add(
                      OnACTATTransactionEvent(
                        TransactionsModel(
                          usrName: login.usrName,
                          fromAccount: debitAccNumber,
                          fromAccCy: debitAccCurrency,
                          toAccount: creditAccNumber,
                          toAccCcy: creditAccCurrency,
                          trdAmount: amount.text.cleanAmount,
                          trdNarration: narration.text,
                        ),
                      ),
                    );
                  },
                  actionLabel: trState is TxnLoadingState
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  )
                      : Text(tr.create),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ///Debit Section
                              Expanded(
                                child: Column(
                                  children: [
                                    GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                                      showAllOnFocus: true,
                                      controller: debitAccountCtrl,
                                      title: tr.debitAccount,
                                      hintText: tr.accNameOrNumber,
                                      isRequired: true,
                                      bloc: context.read<AccountsBloc>(),
                                      fetchAllFunction: (bloc) => bloc.add(
                                        LoadAccountsFilterEvent(
                                          include: '1,2,3,4,5,6,7,8,9,10,11,12',
                                          exclude: "10101011",
                                          ccy: baseCurrency,
                                        ),
                                      ),
                                      searchFunction: (bloc, query) =>
                                          bloc.add(
                                            LoadAccountsFilterEvent(
                                              input: query,
                                              include: '1,2,3,4,5,6,7,8,9,10,11,12',
                                              exclude: "10101011",
                                              ccy: baseCurrency,
                                            ),
                                          ),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return tr.required(tr.accounts);
                                        }
                                        return null;
                                      },
                                      itemBuilder: (context, account) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  "${account.accNumber} | ${account.accName}",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      itemToString: (acc) =>
                                      "${acc.accNumber} | ${acc.accName}",
                                      stateToLoading: (state) =>
                                      state is AccountLoadingState,
                                      loadingBuilder: (context) =>
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      stateToItems: (state) {
                                        if (state is AccountLoadedState) {
                                          return state.accounts;
                                        }
                                        return [];
                                      },
                                      onSelected: (value) {
                                        setState(() {
                                          debitAccNumber = value.accNumber;
                                          debitCcySymbol = value.actCurrency;
                                          debitAccCurrency =
                                              value.actCurrency;
                                          debitAccName = value.accName ?? "";
                                          debitAvailableBalance =
                                              value.accAvailBalance;
                                          debitCurrentBalance =
                                              value.accBalance;
                                          debitAccountLimit =
                                              value.accCreditLimit;
                                          debitStatus = value.accStatus ?? 0;
                                        });
                                      },
                                      noResultsText: tr.noDataFound,
                                      showClearButton: true,
                                    ),
                                    if (debitAccName != null && debitAccName!.isNotEmpty)
                                      ZCover(
                                        color: Theme.of(context).colorScheme.surface,
                                        margin: EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          children: [
                                            if (debitAccName != null &&
                                                debitAccName!.isNotEmpty)
                                              Padding(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 5.0,
                                                  vertical: 3,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      tr.details,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                        color:
                                                        Theme.of(
                                                          context,
                                                        )
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (debitAccName != null &&
                                                debitAccName!.isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 5,
                                                ),
                                                width: double.infinity,
                                                child: Row(
                                                  spacing: 5,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      spacing: 5,
                                                      children: [
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountNumber,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountName,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.currencyTitle,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountLimit,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.status,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.currentBalance,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.availableBalance,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      spacing: 5,
                                                      children: [
                                                        Text(
                                                          debitAccNumber
                                                              .toString(),
                                                        ),
                                                        Text(
                                                          debitAccName ?? "",
                                                        ),
                                                        Text(
                                                          debitAccCurrency ??
                                                              "",
                                                        ),
                                                        Text(
                                                          debitAccountLimit
                                                              ?.toAmount() ==
                                                              "999999999999"
                                                                  .toAmount()
                                                              ? tr.unlimited
                                                              : debitAccountLimit
                                                              ?.toAmount() ??
                                                              "",
                                                        ),
                                                        Text(
                                                          debitStatus == 1
                                                              ? tr.active
                                                              : tr.blocked,
                                                        ),
                                                        Text(
                                                          "${debitCurrentBalance?.toAmount()} $debitCcySymbol",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${debitAvailableBalance?.toAmount()} $debitCcySymbol",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              ///Credit Section
                              Expanded(
                                child: Column(
                                  children: [
                                    GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                                      showAllOnFocus: true,
                                      controller: creditAccountCtrl,
                                      title: tr.creditAccount,
                                      hintText: tr.accNameOrNumber,
                                      isRequired: true,
                                      bloc: context.read<AccountsBloc>(),
                                      fetchAllFunction: (bloc) => bloc.add(
                                        LoadAccountsFilterEvent(
                                          include: '1,2,3,4,5,6,7,8,9,10,11,12',
                                          exclude: "10101010,10101011",
                                          ccy: baseCurrency,
                                        ),
                                      ),
                                      searchFunction: (bloc, query) =>
                                          bloc.add(
                                            LoadAccountsFilterEvent(
                                              input: query,
                                              include: '1,2,3,4,5,6,7,8,9,10,11,12',
                                              exclude: "10101010,10101011",
                                              ccy: baseCurrency,
                                            ),
                                          ),

                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return tr.required(tr.accounts);
                                        }
                                        return null;
                                      },
                                      itemBuilder: (context, account) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  "${account.accNumber} | ${account.accName}",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      itemToString: (acc) =>
                                      "${acc.accNumber} | ${acc.accName}",
                                      stateToLoading: (state) =>
                                      state is AccountLoadingState,
                                      loadingBuilder: (context) =>
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      stateToItems: (state) {
                                        if (state is AccountLoadedState) {
                                          return state.accounts;
                                        }
                                        return [];
                                      },
                                      onSelected: (value) {
                                        setState(() {
                                          creditAccNumber = value.accNumber;
                                          creditCcySymbol = value.actCurrency;
                                          creditAccCurrency =
                                              value.actCurrency;
                                          creditAccName = value.accName ?? "";
                                          creditAvailableBalance =
                                              value.accAvailBalance;
                                          creditCurrentBalance =
                                              value.accBalance;
                                          creditAccountLimit =
                                              value.accCreditLimit;
                                          creditStatus = value.accStatus ?? 0;
                                        });
                                      },
                                      noResultsText: tr.noDataFound,
                                      showClearButton: true,
                                    ),
                                    if (creditAccName != null &&
                                        creditAccName!.isNotEmpty)
                                      ZCover(
                                        margin: EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        child: Column(
                                          children: [
                                            if (creditAccName != null &&
                                                creditAccName!.isNotEmpty)
                                              Padding(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 5.0,
                                                  vertical: 3,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      tr.details,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                        color:
                                                        Theme.of(
                                                          context,
                                                        )
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (creditAccName != null &&
                                                creditAccName!.isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 5,
                                                ),
                                                width: double.infinity,
                                                child: Row(
                                                  spacing: 5,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .start,
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      spacing: 5,
                                                      children: [
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountNumber,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountName,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.currencyTitle,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountLimit,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.status,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.currentBalance,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.availableBalance,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .start,
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      spacing: 5,
                                                      children: [
                                                        Text(
                                                          creditAccNumber
                                                              .toString(),
                                                        ),
                                                        Text(
                                                          creditAccName ?? "",
                                                        ),
                                                        Text(
                                                          creditAccCurrency ??
                                                              "",
                                                        ),
                                                        Text(
                                                          creditAccountLimit
                                                              ?.toAmount() ==
                                                              "999999999999"
                                                                  .toAmount()
                                                              ? tr.unlimited
                                                              : creditAccountLimit
                                                              ?.toAmount() ??
                                                              "",
                                                        ),
                                                        Text(
                                                          creditStatus == 1
                                                              ? tr.active
                                                              : tr.blocked,
                                                        ),
                                                        Text(
                                                          "${creditCurrentBalance?.toAmount()} $creditCcySymbol",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${creditAvailableBalance?.toAmount()} $creditCcySymbol",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          ZTextFieldEntitled(
                            isRequired: true,
                            keyboardInputType:
                            TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormat: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]*'),
                              ),
                              SmartThousandsDecimalFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr.required(tr.amount);
                              }

                              // Remove formatting (e.g. commas)
                              final clean = value.replaceAll(
                                RegExp(r'[^\d.]'),
                                '',
                              );
                              final amount = double.tryParse(clean);

                              if (amount == null || amount <= 0.0) {
                                return tr.amountGreaterZero;
                              }

                              return null;
                            },
                            controller: amount,
                            title: tr.amount,
                          ),
                          ZTextFieldEntitled(
                            keyboardInputType: TextInputType.multiline,
                            controller: narration,
                            title: tr.narration,
                          ),
                          Row(
                            spacing: 5,
                            children: [
                              Checkbox(
                                visualDensity: VisualDensity(horizontal: -4),
                                value: isPrint,
                                onChanged: (e) {
                                  setState(() {
                                    isPrint = e ?? true;
                                  });
                                },
                              ),
                              Text(tr.print),
                            ],
                          ),
                          if (trState is TransactionErrorState)
                            SizedBox(height: 10),
                          Row(
                            children: [
                              trState is TransactionErrorState
                                  ? Text(
                                trState.message,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                                  : SizedBox(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void onReminder({
    required int accNumber,
    required String dueType,
    required String usrName,
    required String narration,
    required String amount,
    required String date,
  }) {
    final model = ReminderModel(
      usrName: usrName,
      rmdName: dueType,
      rmdAccount: accNumber,
      rmdAmount: amount.cleanAmount,
      rmdDetails: narration,
      rmdAlertDate: DateTime.tryParse(date),
      rmdStatus: 1,
    );
    context.read<ReminderBloc>().add(AddReminderEvent(model));
  }

  void onMultiATAT(){
    showDialog(
      context: context,
      builder: (context) {
        return BulkTransferScreen();
      },
    );
  }

  void onFxTxn(){
    Utils.goto(context, FxTransactionView());
  }

  void showTxnDetails(){
    showDialog(context: context, builder: (context){
      return TransactionByReferenceView();
    });
  }

  void showGlStatement(){
    showDialog(context: context, builder: (context){
      return GlStatementView();
    });
  }

  void showAccountStatement(){
    showDialog(context: context, builder: (context){
      return AccountStatementView();
    });
  }

  String getAccountPosition(String? balance) {
    if (balance == null || balance.isEmpty) return "No Balance";
    final locale = AppLocalizations.of(context)!;

    // Remove formatting if needed
    final clean = double.tryParse(balance.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;

    if (clean > 0) return locale.creditor;
    if (clean < 0) return locale.debtor;
    return locale.noBalance;
  }

  Widget accountDetailsView(AccountsModel details){
    final tr = AppLocalizations.of(context)!;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith();
    return ZCover(
      margin: EdgeInsets.symmetric(horizontal: 2),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .02),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Text(tr.accountDetails,style: titleStyle?.copyWith(fontWeight: FontWeight.bold),)
            ],
          ),
          Divider(),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(tr.accountNumber,style: titleStyle),
                    Text(tr.accountName,style: titleStyle),
                    Text(tr.accountCategory,style: titleStyle),
                    Text(tr.status,style: titleStyle),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  Text(details.accNumber.toString()),
                  Text(details.accName??""),
                  Text(details.accCategory.toString()),
                  StatusBadge(status: details.accStatus??1, trueValue: tr.active,falseValue: tr.inactive),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  void getPrinted({required TransactionsModel data, required ReportModel company}) {
    if (isPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<TransactionsModel>(
            data: data,
            company: company,
            buildPreview: ({
              required data,
              required String language,
              required orientation,
              required pageFormat,
            }) {
              return CashFlowTransactionPrint().printPreview(
                company: company,
                language: context.read<LocalizationBloc>().state.languageCode,
                orientation: orientation,
                pageFormat: pageFormat,
                data: data,
              );
            },
            onPrint: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return CashFlowTransactionPrint().printDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                data: data,
                copies: copies,
                pages: pages,
              );
            },
            onSave: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashFlowTransactionPrint().createDocument(
                data: data,
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionSheet(context, login),
        child: Icon(Icons.add),
      ),
      body: BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
        builder: (context, companyState) {
          if (companyState is CompanyProfileLoadedState) {
            company.comName = companyState.company.comName ?? "";
            company.comAddress = companyState.company.addName ?? "";
            company.compPhone = companyState.company.comPhone ?? "";
            company.comEmail = companyState.company.comEmail ?? "";
            company.statementDate = DateTime.now().toFullDateTime;
            final base64Logo = companyState.company.comLogo;
            if (base64Logo != null && base64Logo.isNotEmpty) {
              try {
                _companyLogo = base64Decode(base64Logo);
                company.comLogo = _companyLogo;
              } catch (e) {
                _companyLogo = Uint8List(0);
              }
            }
          }

          return BlocListener<TransactionsBloc, TransactionsState>(
            listener: (context, trState) {
              if (trState is TransactionLoadedState && trState.printTxn != null) {
                getPrinted(data: trState.printTxn!, company: company);
              }
            },
            child: BlocBuilder<JournalTabBloc, JournalTabState>(
              builder: (context, tabState) {
                final tabs = <ZTabItem<JournalTabName>>[
                  if (login.hasPermission(19) ?? false)
                    ZTabItem(
                      value: JournalTabName.allTransactions,
                      label: locale.allTransactions,
                      screen: const AllTransactionsView(),
                    ),
                  if (login.hasPermission(20) ?? false)
                    ZTabItem(
                      value: JournalTabName.authorized,
                      label: locale.authorizedTransactions,
                      screen: const AuthorizedTransactionsView(),
                    ),
                  if (login.hasPermission(21) ?? false)
                    ZTabItem(
                      value: JournalTabName.pending,
                      label: locale.pendingTransactions,
                      screen: const PendingTransactionsView(),
                    ),
                ];

                final availableValues = tabs.map((tab) => tab.value).toList();
                final selected = availableValues.contains(tabState.tab)
                    ? tabState.tab
                    : availableValues.first;

                return ZTabContainer<JournalTabName>(
                  tabs: tabs,
                  selectedValue: selected,
                  onChanged: (val) => context.read<JournalTabBloc>().add(JournalOnChangedEvent(val)),

                  style: ZTabStyle.rounded,
                  tabBarPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  borderRadius: 0,
                  selectedColor: color.primary,
                  unselectedTextColor: color.secondary,
                  selectedTextColor: color.surface,
                  tabContainerColor: color.surface,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showTransactionSheet(BuildContext context, LoginData login) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    double opacity = .05;

    ZDraggableSheet.show(
      context: context,
      title: locale.actions,
      showDragHandle: true,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      estimatedContentHeight: MediaQuery.of(context).size.height,

      bodyBuilder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            // Cash Flow Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.money, size: 20, color: color.primary),
                  const SizedBox(width: 8),
                  Text(
                    locale.cashFlow,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Cash Deposit
            if (login.hasPermission(22) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F1",
                  label: Text(locale.deposit),
                  icon: Icons.arrow_circle_down_rounded,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    onCashDepositWithdraw(trnType: "CHDP");
                  },
                ),
              ),

            // Cash Withdraw
            if (login.hasPermission(23) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F2",
                  label: Text(locale.withdraw),
                  icon: Icons.arrow_circle_up_rounded,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    onCashDepositWithdraw(trnType: "CHWL");
                  },
                ),
              ),

            // Income
            if (login.hasPermission(24) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F3",
                  label: Text(locale.income),
                  icon: Icons.arrow_circle_down_rounded,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    onCashIncome(trnType: "INCM");
                  },
                ),
              ),

            // Expense
            if (login.hasPermission(25) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F4",
                  label: Text(locale.expense),
                  icon: Icons.arrow_circle_up_rounded,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    onCashExpense(trnType: "XPNS");
                  },
                ),
              ),

            const Divider(height: 24),

            // Fund Transfer Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 20, color: color.primary),
                  const SizedBox(width: 8),
                  Text(
                    locale.fundTransferTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Single Account Transfer
            if (login.hasPermission(28) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F5",
                  label: Text(locale.singleAccount),
                  icon: Icons.swap_horiz_rounded,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    accountToAccount(trnType: "ATAT");
                  },
                ),
              ),

            // Multi Account Transfer
            if (login.hasPermission(29) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F6",
                  label: Text(locale.multiAccount),
                  icon: Icons.swap_horiz_rounded,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    onMultiATAT();
                  },
                ),
              ),

            // FX Transaction
            if (login.hasPermission(30) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F7",
                  label: Text(locale.fxTransaction),
                  icon: Icons.swap_horiz_rounded,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    onFxTxn();
                  },
                ),
              ),

            const Divider(height: 24),

            // System Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.computer_rounded, size: 20, color: color.primary),
                  const SizedBox(width: 8),
                  Text(
                    locale.systemAction,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // GL Credit
            if (login.hasPermission(26) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F8",
                  label: Text(locale.glCreditTitle),
                  width: double.infinity,
                  icon: Icons.menu_book_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    onGL(trnType: "GLCR");
                  },
                ),
              ),

            // GL Debit
            if (login.hasPermission(27) ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ZOutlineButton(
                  backgroundColor: color.primary.withValues(alpha: opacity),
                  toolTip: "F9",
                  label: Text(locale.glDebitTitle),
                  width: double.infinity,
                  icon: Icons.menu_book_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    onGL(trnType: "GLDR");
                  },
                ),
              ),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// Desktop View (unchanged from original)
class _DesktopView extends StatefulWidget {
  const _DesktopView();

  @override
  State<_DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<_DesktopView> {
  String? currentLocale;
  String? trnCurrency;
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  bool isPrint = true;
  bool _isExpanded = true;
  double opacity = .05;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1100;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(isMobile(context) || isTablet(context)) {
        _isExpanded = false;
      }
      if (mounted) {
        setState(() {
          currentLocale = context.read<LocalizationBloc>().state.languageCode;
        });
      }
    });
  }

  String? _getBaseCurrency() {
    try {
      final companyState = context.read<CompanyProfileBloc>().state;
      if (companyState is CompanyProfileLoadedState) {
        return companyState.company.comLocalCcy;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  // Copy all the methods from the original _DesktopState here
  void onCashDepositWithdraw({String? trnType}) {
    // Same as in original _DesktopState
    // (Copy the entire method from your original code)
    final locale = AppLocalizations.of(context)!;
    final accountController = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();
    bool isReminder = false;
    String? reminderDate;

    String? currentBalance;
    String? availableBalance;
    String? accName;
    int? accNumber;
    String? accCurrency;
    String? ccySymbol;
    String? accountLimit;
    int? status;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, trState) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ZFormDialog(
                  width: 600,
                  icon: trnType == "CHDP"
                      ? Icons.arrow_circle_down_rounded
                      : Icons.arrow_circle_up_rounded,
                  title: trnType == "CHDP" ? locale.deposit : locale.withdraw,
                  onAction: () {
                    if(isReminder){
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: accCurrency ?? "",
                            trnType: trnType,
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                      onReminder(
                          accNumber: accNumber!,
                          amount: amount.text.cleanAmount,
                          date: reminderDate??DateTime.now().toFormattedDate(),
                          dueType: trnType == "CHDP" ? "payable" : "receivable",
                          narration: narration.text,
                          usrName: login.usrName??""
                      );
                    }else{
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: accCurrency ?? "",
                            trnType: trnType,
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                    }
                  },
                  actionLabel: trState is TxnLoadingState
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.surface,
                      strokeWidth: 4,
                    ),
                  )
                      : Text(locale.create),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          GenericTextField<StakeholdersAccountsModel, AccountsBloc, AccountsState>(
                            showAllOnFocus: true,
                            controller: accountController,
                            title: locale.accounts,
                            hintText: locale.accNameOrNumber,
                            isRequired: true,
                            bloc: context.read<AccountsBloc>(),
                            fetchAllFunction: (bloc) => bloc.add(LoadStkAccountsEvent()),
                            searchFunction: (bloc, query) => bloc.add(LoadStkAccountsEvent(search: query)),
                            validator: (value) {
                              if (value.isEmpty) {
                                return locale.required(locale.accounts);
                              }
                              return null;
                            },
                            itemBuilder: (context, account) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 5,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${account.accnumber} | ${account.accName}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            itemToString: (acc) =>
                            "${acc.accnumber} | ${acc.accName}",
                            stateToLoading: (state) =>
                            state is AccountLoadingState,
                            loadingBuilder: (context) => const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                            stateToItems: (state) {
                              if (state is StkAccountLoadedState) {
                                return state.accounts;
                              }
                              return [];
                            },
                            onSelected: (value) {
                              setState(() {
                                accNumber = value.accnumber;
                                ccySymbol = value.ccySymbol;
                                accCurrency = value.actCurrency;
                                accName = value.accName ?? "";
                                availableBalance = value.avilBalance;
                                currentBalance = value.curBalance;
                                accountLimit = value.actCreditLimit;
                                status = value.actStatus ?? 0;
                              });
                            },
                            noResultsText: locale.noDataFound,
                            showClearButton: true,
                          ),
                          if (accName != null && accName!.isNotEmpty)...[
                            ZCover(
                              color: Theme.of(context).colorScheme.surface,
                              padding: EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  if (accName != null && accName!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            locale.accountDetails,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (accName != null && accName!.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      width: double.infinity,
                                      child: Row(
                                        spacing: 5,
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.start,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            spacing: 5,
                                            children: [
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountNumber}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountName}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.currencyTitle}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountLimit}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountStatus}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.accountPosition}:",
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.currentBalance}:",
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 170,
                                                child: Text(
                                                  "${locale.availableBalance}:",
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.start,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            spacing: 5,
                                            children: [
                                              Text(
                                                accNumber.toString(),
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(accName ?? ""),
                                              Text(accCurrency ?? ""),
                                              Text(
                                                "$ccySymbol${accountLimit?.toAmount()}",
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                status == 1
                                                    ? locale.active
                                                    : locale.blocked,
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                getAccountPosition(availableBalance),
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                "$ccySymbol${currentBalance?.toAmount()}",
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              Text(
                                                "$ccySymbol${availableBalance?.toAmount()}",
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                          ],

                          ZTextFieldEntitled(
                            isRequired: true,
                            keyboardInputType:
                            TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormat: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]*'),
                              ),
                              SmartThousandsDecimalFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return locale.required(locale.exchangeRate);
                              }

                              // Remove formatting (e.g. commas)
                              final clean = value.replaceAll(
                                RegExp(r'[^\d.]'),
                                '',
                              );
                              final amount = double.tryParse(clean);

                              if (amount == null || amount <= 0.0) {
                                return locale.amountGreaterZero;
                              }

                              return null;
                            },
                            controller: amount,
                            title: locale.amount,
                          ),
                          ZTextFieldEntitled(
                            keyboardInputType: TextInputType.multiline,
                            controller: narration,
                            title: locale.narration,
                          ),
                          Row(
                            spacing: 5,
                            children: [
                              Checkbox(
                                visualDensity: VisualDensity(horizontal: -4,vertical: -4),
                                value: isPrint,
                                onChanged: (e) {
                                  setState(() {
                                    isPrint = e ?? true;
                                  });
                                },
                              ),
                              Text(locale.print),
                            ],
                          ),
                          Row(
                            spacing: 5,
                            children: [
                              Checkbox(
                                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                value: isReminder,
                                onChanged: (value) {
                                  setState(() {
                                    isReminder = value ?? false;
                                  });
                                },
                              ),
                              Text(locale.setReminder),
                            ],
                          ),

                          if(isReminder)
                            ZDatePicker(
                              disablePastDate: true,
                              label: locale.dueDate,
                              value: reminderDate,
                              onDateChanged: (v) {
                                setState(() {
                                  reminderDate = v;
                                });
                              },
                            ),

                          if (trState is TransactionErrorState)...[
                            Row(
                              children: [
                                Text(
                                  trState.message,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void onCashIncome({String? trnType}) {
    // Copy the exact same implementation from the original
    final locale = AppLocalizations.of(context)!;
    final accountController = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();
    int? accNumber;
    String? availableBalance;
    int? accCategory;
    int? accStatus;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;
    final baseCurrency = _getBaseCurrency();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context,setState) {
              return BlocBuilder<TransactionsBloc, TransactionsState>(
                builder: (context, trState) {
                  return ZFormDialog(
                    width: 600,
                    icon: Icons.arrow_circle_down_rounded,
                    title: locale.income,
                    onAction: () {
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: trnCurrency ?? baseCurrency,
                            trnType: trnType,
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                    },
                    actionLabel: trState is TxnLoadingState
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                        : Text(locale.create),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 12,
                          children: [
                            GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                              showAllOnFocus: true,
                              controller: accountController,
                              title: locale.accounts,
                              hintText: locale.accNameOrNumber,
                              isRequired: true,
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(
                                LoadAccountsFilterEvent(include: '9,10',ccy: baseCurrency,exclude: ""),
                              ),
                              searchFunction: (bloc, query) => bloc.add(
                                LoadAccountsFilterEvent(
                                    include: "9,10",
                                    ccy: baseCurrency,
                                    input: query,
                                    exclude: ""
                                ),
                              ),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return locale.required(locale.accounts);
                                }
                                return null;
                              },
                              itemBuilder: (context, account) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 5,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${account.accNumber} | ${account.accName}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                              stateToLoading: (state) => state is AccountLoadingState,
                              loadingBuilder: (context) => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 3),
                              ),
                              stateToItems: (state) {
                                if (state is AccountLoadedState) {
                                  return state.accounts;
                                }
                                return [];
                              },
                              onSelected: (value) {
                                setState(() {
                                  accNumber = value.accNumber;
                                  availableBalance = value.accAvailBalance;
                                  accountController.text = value.accName?? "";
                                  accCategory = value.accCategory;
                                  accStatus = value.accStatus;
                                });
                              },
                              noResultsText: locale.noDataFound,
                              showClearButton: true,
                            ),
                            if(accNumber != null)...[
                              accountDetailsView(AccountsModel(
                                  accNumber: accNumber,
                                  accAvailBalance: availableBalance?.toAmount(),
                                  accName: accountController.text,
                                  accCategory: accCategory,
                                  accStatus: accStatus
                              )),
                            ],

                            ZGenericTextField(
                              controller: amount,
                              title: locale.amount,
                              defaultCurrencyCode: baseCurrency,
                              fieldType: ZTextFieldType.currencyWithAmount,
                              useThousandSeparator: true,
                              decimalPlaces: 2,
                              onCurrencyAmountChanged: (data) {
                                final (currency, amount) = data;
                                trnCurrency = currency?.ccyCode ?? baseCurrency;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return locale.required(locale.exchangeRate);
                                }

                                // Clean value already passed, but you can also use helper
                                final amountValue = getAmountValue(value);
                                if (amountValue == null || amountValue <= 0.0) {
                                  return locale.amountGreaterZero;
                                }

                                return null;
                              },
                              showFlag: true,
                              showClearButton: true,
                              showSymbol: false,
                              isRequired: true,
                            ),

                            ZTextFieldEntitled(
                              keyboardInputType: TextInputType.multiline,
                              controller: narration,
                              title: locale.narration,
                            ),

                            Row(
                              spacing: 5,
                              children: [
                                Checkbox(
                                  visualDensity: VisualDensity(horizontal: -4),
                                  value: isPrint,
                                  onChanged: (e) {
                                    setState(() {
                                      isPrint = e ?? true;
                                    });
                                  },
                                ),
                                Text(locale.print),
                              ],
                            ),
                            if (trState is TransactionErrorState)
                              SizedBox(height: 10),
                            Row(
                              children: [
                                trState is TransactionErrorState
                                    ? Text(
                                  trState.message,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                )
                                    : SizedBox(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
        );
      },
    );
  }

  void onCashExpense({String? trnType}) {
    // Copy the exact same implementation from the original
    final locale = AppLocalizations.of(context)!;
    final accountController = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();
    int? accNumber;
    String? availableBalance;
    int? accCategory;
    int? accStatus;
    String? accName;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;
    final baseCurrency = _getBaseCurrency();

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, trState) {
            return StatefulBuilder(
                builder: (context,setState) {
                  return ZFormDialog(
                    width: 600,
                    icon: Icons.arrow_circle_up_rounded,
                    title: locale.expense,
                    onAction: () {
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: trnCurrency ?? baseCurrency ?? "",
                            trnType: trnType ?? "",
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                    },
                    actionLabel: trState is TxnLoadingState
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                        : Text(locale.create),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 12,
                          children: [
                            GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                              showAllOnFocus: true,
                              controller: accountController,
                              title: locale.accounts,
                              hintText: locale.accNameOrNumber,
                              isRequired: true,
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(
                                LoadAccountsFilterEvent(include: "11,12",ccy: baseCurrency,exclude: ""),
                              ),
                              searchFunction: (bloc, query) => bloc.add(
                                LoadAccountsFilterEvent(
                                    include: "11,12",
                                    ccy: baseCurrency,
                                    input: query, exclude: ""
                                ),
                              ),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return locale.required(locale.accounts);
                                }
                                return null;
                              },
                              itemBuilder: (context, account) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 5,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${account.accNumber} | ${account.accName}",
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                              stateToLoading: (state) => state is AccountLoadingState,
                              loadingBuilder: (context) => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 3),
                              ),
                              stateToItems: (state) {
                                if (state is AccountLoadedState) {
                                  return state.accounts;
                                }
                                return [];
                              },
                              onSelected: (value) {
                                setState(() {
                                  accNumber = value.accNumber;
                                  availableBalance = value.accAvailBalance;
                                  accCategory = value.accCategory;
                                  accStatus = value.accStatus;
                                  accName = value.accName;
                                });
                              },
                              noResultsText: locale.noDataFound,
                              showClearButton: true,
                            ),

                            if(accNumber !=null)...[
                              accountDetailsView(AccountsModel(
                                accNumber: accNumber,
                                accCategory: accCategory,
                                accName: accName,
                                accAvailBalance: availableBalance,
                                accStatus: accStatus,
                              ))
                            ],

                            ZGenericTextField(
                              controller: amount,
                              title: locale.amount,
                              defaultCurrencyCode: baseCurrency,
                              fieldType: ZTextFieldType.currencyWithAmount,
                              useThousandSeparator: true,
                              decimalPlaces: 2,
                              onCurrencyAmountChanged: (data) {
                                final (currency, amount) = data;
                                trnCurrency = currency?.ccyCode ?? baseCurrency;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return locale.required(locale.exchangeRate);
                                }

                                // Clean value already passed, but you can also use helper
                                final amountValue = getAmountValue(value);
                                if (amountValue == null || amountValue <= 0.0) {
                                  return locale.amountGreaterZero;
                                }

                                return null;
                              },
                              showFlag: true,
                              showClearButton: true,
                              showSymbol: false,
                              isRequired: true,
                            ),

                            ZTextFieldEntitled(
                              keyboardInputType: TextInputType.multiline,
                              controller: narration,
                              title: locale.narration,
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                Checkbox(
                                  visualDensity: VisualDensity(horizontal: -4),
                                  value: isPrint,
                                  onChanged: (e) {
                                    setState(() {
                                      isPrint = e ?? true;
                                    });
                                  },
                                ),
                                Text(locale.print),
                              ],
                            ),
                            if (trState is TransactionErrorState)
                              SizedBox(height: 10),
                            Row(
                              children: [
                                trState is TransactionErrorState
                                    ? Text(
                                  trState.message,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                )
                                    : SizedBox(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            );
          },
        );
      },
    );
  }

  void onGL({String? trnType}) {
    // Copy the exact same implementation from the original
    final locale = AppLocalizations.of(context)!;
    final accountController = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();
    int? accNumber;
    String? availableBalance;
    int? accCategory;
    int? accStatus;
    String? accName;

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;
    final baseCurrency = _getBaseCurrency();

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, trState) {
            return StatefulBuilder(
                builder: (context,setState) {
                  return ZFormDialog(
                    width: 600,
                    icon: Icons.cached_rounded,
                    title: trnType == "GLCR"
                        ? locale.glCreditTitle
                        : locale.glDebitTitle,
                    onAction: () {
                      context.read<TransactionsBloc>().add(
                        OnCashTransactionEvent(
                          TransactionsModel(
                            usrName: login.usrName,
                            trdAccount: accNumber,
                            trdCcy: trnCurrency ?? baseCurrency,
                            trnType: trnType,
                            trdAmount: amount.text.cleanAmount,
                            trdNarration: narration.text,
                          ),
                        ),
                      );
                    },
                    actionLabel: trState is TxnLoadingState
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                        : Text(locale.create),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 12,
                          children: [
                            GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                              showAllOnFocus: true,
                              controller: accountController,
                              title: locale.accounts,
                              hintText: locale.accNameOrNumber,
                              isRequired: true,
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(
                                LoadAccountsFilterEvent(
                                  include: '1,2,3,4,5,6,7',
                                  ccy: baseCurrency,
                                  exclude: "10101011",
                                ),
                              ),
                              searchFunction: (bloc, query) => bloc.add(
                                LoadAccountsFilterEvent(
                                  include: '1,2,3,4,5,6,7',
                                  ccy: baseCurrency,
                                  input: query,
                                  exclude: "10101011",
                                ),
                              ),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return locale.required(locale.accounts);
                                }
                                return null;
                              },
                              itemBuilder: (context, account) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 5,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${account.accNumber} | ${account.accName}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              itemToString: (acc) =>
                              "${acc.accNumber} | ${acc.accName}",
                              stateToLoading: (state) =>
                              state is AccountLoadingState,
                              loadingBuilder: (context) => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 3),
                              ),
                              stateToItems: (state) {
                                if (state is AccountLoadedState) {
                                  return state.accounts;
                                }
                                return [];
                              },
                              onSelected: (value) {
                                setState(() {
                                  accNumber = value.accNumber;
                                  availableBalance = value.accAvailBalance;
                                  accName = value.accName?? "";
                                  accCategory = value.accCategory;
                                  accStatus = value.accStatus;
                                });
                              },
                              noResultsText: locale.noDataFound,
                              showClearButton: true,
                            ),
                            if(accNumber !=null)...[
                              accountDetailsView(AccountsModel(
                                accNumber: accNumber,
                                accCategory: accCategory,
                                accName: accName,
                                accAvailBalance: availableBalance,
                                accStatus: accStatus,
                              ))
                            ],
                            ZGenericTextField(
                              controller: amount,
                              title: locale.amount,
                              defaultCurrencyCode: baseCurrency,
                              fieldType: ZTextFieldType.currencyWithAmount,
                              useThousandSeparator: true,
                              decimalPlaces: 2,
                              onCurrencyAmountChanged: (data) {
                                final (currency, amount) = data;
                                trnCurrency = currency?.ccyCode ?? baseCurrency;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return locale.required(locale.exchangeRate);
                                }

                                // Clean value already passed, but you can also use helper
                                final amountValue = getAmountValue(value);
                                if (amountValue == null || amountValue <= 0.0) {
                                  return locale.amountGreaterZero;
                                }

                                return null;
                              },
                              showFlag: true,
                              showClearButton: true,
                              showSymbol: false,
                              isRequired: true,
                            ),
                            ZTextFieldEntitled(
                              keyboardInputType: TextInputType.multiline,
                              controller: narration,
                              title: locale.narration,
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                Checkbox(
                                  visualDensity: VisualDensity(horizontal: -4),
                                  value: isPrint,
                                  onChanged: (e) {
                                    setState(() {
                                      isPrint = e ?? true;
                                    });
                                  },
                                ),
                                Text(locale.print),
                              ],
                            ),
                            if (trState is TransactionErrorState)
                              SizedBox(height: 10),
                            Row(
                              children: [
                                trState is TransactionErrorState
                                    ? Text(trState.message)
                                    : SizedBox(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            );
          },
        );
      },
    );
  }

  void accountToAccount({String? trnType}) {
    // Copy the exact same implementation from the original
    final tr = AppLocalizations.of(context)!;

    /// Credit .......................................
    final creditAccountCtrl = TextEditingController();
    String? creditAccCurrency;
    String? creditCurrentBalance;
    String? creditAvailableBalance;
    int? creditAccNumber;
    String? creditAccName;
    String? creditAccountLimit;
    String? creditCcySymbol;
    int? creditStatus;

    /// Debit .....................................
    final debitAccountCtrl = TextEditingController();
    String? debitAccCurrency;
    String? debitCurrentBalance;
    String? debitAvailableBalance;
    int? debitAccNumber;
    String? debitAccName;
    String? debitAccountLimit;
    String? debitCcySymbol;
    int? debitStatus;

    final TextEditingController amount = TextEditingController();
    final TextEditingController narration = TextEditingController();

    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;
    final login = state.loginData;
    final baseCurrency = _getBaseCurrency();

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, trState) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ZFormDialog(
                  width: 800,
                  icon: Icons.swap_horiz_rounded,
                  title: tr.fundTransferTitle,
                  onAction: () {
                    context.read<TransactionsBloc>().add(
                      OnACTATTransactionEvent(
                        TransactionsModel(
                          usrName: login.usrName,
                          fromAccount: debitAccNumber,
                          fromAccCy: debitAccCurrency,
                          toAccount: creditAccNumber,
                          toAccCcy: creditAccCurrency,
                          trdAmount: amount.text.cleanAmount,
                          trdNarration: narration.text,
                        ),
                      ),
                    );
                  },
                  actionLabel: trState is TxnLoadingState
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  )
                      : Text(tr.create),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ///Debit Section
                              Expanded(
                                child: Column(
                                  children: [
                                    GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                                      showAllOnFocus: true,
                                      controller: debitAccountCtrl,
                                      title: tr.debitAccount,
                                      hintText: tr.accNameOrNumber,
                                      isRequired: true,
                                      bloc: context.read<AccountsBloc>(),
                                      fetchAllFunction: (bloc) => bloc.add(
                                        LoadAccountsFilterEvent(
                                          include: '1,2,3,4,5,6,7,8,9,10,11,12',
                                          exclude: "10101011",
                                          ccy: baseCurrency,
                                        ),
                                      ),
                                      searchFunction: (bloc, query) =>
                                          bloc.add(
                                            LoadAccountsFilterEvent(
                                              input: query,
                                              include: '1,2,3,4,5,6,7,8,9,10,11,12',
                                              exclude: "10101011",
                                              ccy: baseCurrency,
                                            ),
                                          ),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return tr.required(tr.accounts);
                                        }
                                        return null;
                                      },
                                      itemBuilder: (context, account) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  "${account.accNumber} | ${account.accName}",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      itemToString: (acc) =>
                                      "${acc.accNumber} | ${acc.accName}",
                                      stateToLoading: (state) =>
                                      state is AccountLoadingState,
                                      loadingBuilder: (context) =>
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      stateToItems: (state) {
                                        if (state is AccountLoadedState) {
                                          return state.accounts;
                                        }
                                        return [];
                                      },
                                      onSelected: (value) {
                                        setState(() {
                                          debitAccNumber = value.accNumber;
                                          debitCcySymbol = value.actCurrency;
                                          debitAccCurrency =
                                              value.actCurrency;
                                          debitAccName = value.accName ?? "";
                                          debitAvailableBalance =
                                              value.accAvailBalance;
                                          debitCurrentBalance =
                                              value.accBalance;
                                          debitAccountLimit =
                                              value.accCreditLimit;
                                          debitStatus = value.accStatus ?? 0;
                                        });
                                      },
                                      noResultsText: tr.noDataFound,
                                      showClearButton: true,
                                    ),
                                    if (debitAccName != null && debitAccName!.isNotEmpty)
                                      ZCover(
                                        color: Theme.of(context).colorScheme.surface,
                                        margin: EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          children: [
                                            if (debitAccName != null &&
                                                debitAccName!.isNotEmpty)
                                              Padding(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 5.0,
                                                  vertical: 3,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      tr.details,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                        color:
                                                        Theme.of(
                                                          context,
                                                        )
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (debitAccName != null &&
                                                debitAccName!.isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 5,
                                                ),
                                                width: double.infinity,
                                                child: Row(
                                                  spacing: 5,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      spacing: 5,
                                                      children: [
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountNumber,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountName,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.currencyTitle,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountLimit,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.status,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.currentBalance,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.availableBalance,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      spacing: 5,
                                                      children: [
                                                        Text(
                                                          debitAccNumber
                                                              .toString(),
                                                        ),
                                                        Text(
                                                          debitAccName ?? "",
                                                        ),
                                                        Text(
                                                          debitAccCurrency ??
                                                              "",
                                                        ),
                                                        Text(
                                                          debitAccountLimit
                                                              ?.toAmount() ==
                                                              "999999999999"
                                                                  .toAmount()
                                                              ? tr.unlimited
                                                              : debitAccountLimit
                                                              ?.toAmount() ??""
                                                          "",
                                                        ),
                                                        Text(
                                                          debitStatus == 1
                                                              ? tr.active
                                                              : tr.blocked,
                                                        ),
                                                        Text(
                                                          "${debitCurrentBalance?.toAmount()} $debitCcySymbol",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${debitAvailableBalance?.toAmount()} $debitCcySymbol",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              ///Credit Section
                              Expanded(
                                child: Column(
                                  children: [
                                    GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                                      showAllOnFocus: true,
                                      controller: creditAccountCtrl,
                                      title: tr.creditAccount,
                                      hintText: tr.accNameOrNumber,
                                      isRequired: true,
                                      bloc: context.read<AccountsBloc>(),
                                      fetchAllFunction: (bloc) => bloc.add(
                                        LoadAccountsFilterEvent(
                                          include: '1,2,3,4,5,6,7,8,9,10,11,12',
                                          exclude: "10101011",
                                          ccy: baseCurrency,
                                        ),
                                      ),
                                      searchFunction: (bloc, query) =>
                                          bloc.add(
                                            LoadAccountsFilterEvent(
                                              input: query,
                                              include: '1,2,3,4,5,6,7,8,9,10,11,12',
                                              exclude: "10101011",
                                              ccy: baseCurrency,
                                            ),
                                          ),

                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return tr.required(tr.accounts);
                                        }
                                        return null;
                                      },
                                      itemBuilder: (context, account) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Text(
                                                  "${account.accNumber} | ${account.accName}",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      itemToString: (acc) =>
                                      "${acc.accNumber} | ${acc.accName}",
                                      stateToLoading: (state) =>
                                      state is AccountLoadingState,
                                      loadingBuilder: (context) =>
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      stateToItems: (state) {
                                        if (state is AccountLoadedState) {
                                          return state.accounts;
                                        }
                                        return [];
                                      },
                                      onSelected: (value) {
                                        setState(() {
                                          creditAccNumber = value.accNumber;
                                          creditCcySymbol = value.actCurrency;
                                          creditAccCurrency =
                                              value.actCurrency;
                                          creditAccName = value.accName ?? "";
                                          creditAvailableBalance =
                                              value.accAvailBalance;
                                          creditCurrentBalance =
                                              value.accBalance;
                                          creditAccountLimit =
                                              value.accCreditLimit;
                                          creditStatus = value.accStatus ?? 0;
                                        });
                                      },
                                      noResultsText: tr.noDataFound,
                                      showClearButton: true,
                                    ),
                                    if (creditAccName != null &&
                                        creditAccName!.isNotEmpty)
                                      ZCover(
                                        margin: EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        child: Column(
                                          children: [
                                            if (creditAccName != null &&
                                                creditAccName!.isNotEmpty)
                                              Padding(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 5.0,
                                                  vertical: 3,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      tr.details,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                        color:
                                                        Theme.of(
                                                          context,
                                                        )
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (creditAccName != null &&
                                                creditAccName!.isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 5,
                                                ),
                                                width: double.infinity,
                                                child: Row(
                                                  spacing: 5,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .start,
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      spacing: 5,
                                                      children: [
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountNumber,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountName,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.currencyTitle,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.accountLimit,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.status,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.currentBalance,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            tr.availableBalance,
                                                            style: Theme.of(context).textTheme.titleSmall,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .start,
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      spacing: 5,
                                                      children: [
                                                        Text(
                                                          creditAccNumber
                                                              .toString(),
                                                        ),
                                                        Text(
                                                          creditAccName ?? "",
                                                        ),
                                                        Text(
                                                          creditAccCurrency ??
                                                              "",
                                                        ),
                                                        Text(
                                                          creditAccountLimit
                                                              ?.toAmount() ==
                                                              "999999999999"
                                                                  .toAmount()
                                                              ? tr.unlimited
                                                              : creditAccountLimit
                                                              ?.toAmount() ??""
                                                          "",
                                                        ),
                                                        Text(
                                                          creditStatus == 1
                                                              ? tr.active
                                                              : tr.blocked,
                                                        ),
                                                        Text(
                                                          "${creditCurrentBalance?.toAmount()} $creditCcySymbol",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${creditAvailableBalance?.toAmount()} $creditCcySymbol",
                                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          ZTextFieldEntitled(
                            isRequired: true,
                            keyboardInputType:
                            TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormat: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]*'),
                              ),
                              SmartThousandsDecimalFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr.required(tr.amount);
                              }

                              // Remove formatting (e.g. commas)
                              final clean = value.replaceAll(
                                RegExp(r'[^\d.]'),
                                '',
                              );
                              final amount = double.tryParse(clean);

                              if (amount == null || amount <= 0.0) {
                                return tr.amountGreaterZero;
                              }

                              return null;
                            },
                            controller: amount,
                            title: tr.amount,
                          ),
                          ZTextFieldEntitled(
                            keyboardInputType: TextInputType.multiline,
                            controller: narration,
                            title: tr.narration,
                          ),
                          Row(
                            spacing: 5,
                            children: [
                              Checkbox(
                                visualDensity: VisualDensity(horizontal: -4),
                                value: isPrint,
                                onChanged: (e) {
                                  setState(() {
                                    isPrint = e ?? true;
                                  });
                                },
                              ),
                              Text(tr.print),
                            ],
                          ),
                          if (trState is TransactionErrorState)
                            SizedBox(height: 10),
                          Row(
                            children: [
                              trState is TransactionErrorState
                                  ? Text(
                                trState.message,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                                  : SizedBox(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void onReminder({
    required int accNumber,
    required String dueType,
    required String usrName,
    required String narration,
    required String amount,
    required String date,
  }) {
    final model = ReminderModel(
      usrName: usrName,
      rmdName: dueType,
      rmdAccount: accNumber,
      rmdAmount: amount.cleanAmount,
      rmdDetails: narration,
      rmdAlertDate: DateTime.tryParse(date),
      rmdStatus: 1,
    );
    context.read<ReminderBloc>().add(AddReminderEvent(model));
  }

  void onMultiATAT(){
    showDialog(
      context: context,
      builder: (context) {
        return BulkTransferScreen();
      },
    );
  }

  void onFxTxn(){
    Utils.goto(context, FxTransactionView());
  }

  void showTxnDetails(){
    showDialog(context: context, builder: (context){
      return TransactionByReferenceView();
    });
  }

  void showGlStatement(){
    showDialog(context: context, builder: (context){
      return GlStatementView();
    });
  }

  void showAccountStatement(){
    showDialog(context: context, builder: (context){
      return AccountStatementView();
    });
  }

  String getAccountPosition(String? balance) {
    if (balance == null || balance.isEmpty) return "No Balance";
    final locale = AppLocalizations.of(context)!;

    final clean = double.tryParse(balance.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;

    if (clean > 0) return locale.creditor;
    if (clean < 0) return locale.debtor;
    return locale.noBalance;
  }

  Widget accountDetailsView(AccountsModel details){
    final tr = AppLocalizations.of(context)!;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith();
    return ZCover(
      margin: EdgeInsets.symmetric(horizontal: 2),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .02),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Text(tr.accountDetails,style: titleStyle?.copyWith(fontWeight: FontWeight.bold),)
            ],
          ),
          Divider(),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(tr.accountNumber,style: titleStyle),
                    Text(tr.accountName,style: titleStyle),
                    Text(tr.accountCategory,style: titleStyle),
                    Text(tr.status,style: titleStyle),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  Text(details.accNumber.toString()),
                  Text(details.accName??""),
                  Text(details.accCategory.toString()),
                  StatusBadge(status: details.accStatus??1, trueValue: tr.active,falseValue: tr.inactive),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  void getPrinted({required TransactionsModel data, required ReportModel company}) {
    if (isPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<TransactionsModel>(
            data: data,
            company: company,
            buildPreview:
                ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashFlowTransactionPrint().printPreview(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                data: data,
              );
            },
            onPrint:
                ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return CashFlowTransactionPrint().printDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                data: data,
                copies: copies,
                pages: pages,
              );
            },
            onSave:
                ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return CashFlowTransactionPrint().createDocument(
                data: data,
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): () => onCashDepositWithdraw(trnType: "CHDP"),
      const SingleActivator(LogicalKeyboardKey.f2): () => onCashDepositWithdraw(trnType: "CHWL"),
      const SingleActivator(LogicalKeyboardKey.f3): () => onCashIncome(trnType: "INCM"),
      const SingleActivator(LogicalKeyboardKey.f4): () => onCashExpense(trnType: "XPNS"),
      const SingleActivator(LogicalKeyboardKey.f5): () => accountToAccount(trnType: "ATAT"),
      const SingleActivator(LogicalKeyboardKey.f6): () => onMultiATAT(),
      const SingleActivator(LogicalKeyboardKey.f7): () => onFxTxn(),
      const SingleActivator(LogicalKeyboardKey.f8): () => onGL(trnType: "GLCR"),
      const SingleActivator(LogicalKeyboardKey.f9): () => onGL(trnType: "GLDR"),
      const SingleActivator(LogicalKeyboardKey.keyR,control: true, shift: true): () => showTxnDetails(),
      const SingleActivator(LogicalKeyboardKey.keyG,control: true, shift: true): () => showGlStatement(),
      const SingleActivator(LogicalKeyboardKey.keyA,control: true, shift: true): () => showAccountStatement(),
    };

    return Scaffold(
      body: BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
        builder: (context, companyState) {
          if (companyState is CompanyProfileLoadedState) {
            company.comName = companyState.company.comName ?? "";
            company.comAddress = companyState.company.addName ?? "";
            company.compPhone = companyState.company.comPhone ?? "";
            company.comEmail = companyState.company.comEmail ?? "";
            company.statementDate = DateTime.now().toFullDateTime;
            final base64Logo = companyState.company.comLogo;
            if (base64Logo != null && base64Logo.isNotEmpty) {
              try {
                _companyLogo = base64Decode(base64Logo);
                company.comLogo = _companyLogo;
              } catch (e) {
                _companyLogo = Uint8List(0);
              }
            }
          }
          return BlocListener<TransactionsBloc, TransactionsState>(
            listener: (context, trState) {
              if (trState is TransactionLoadedState && trState.printTxn != null) {
                getPrinted(data: trState.printTxn!, company: company);
              }
            },
            child: GlobalShortcuts(
              shortcuts: shortcuts,
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<JournalTabBloc, JournalTabState>(
                      builder: (context, tabState) {
                        final tabs = <ZTabItem<JournalTabName>>[
                          if (login.hasPermission(19) ?? false)
                            ZTabItem(
                              value: JournalTabName.allTransactions,
                              label: locale.allTransactions,
                              screen: const AllTransactionsView(),
                            ),
                          if (login.hasPermission(20) ?? false)
                            ZTabItem(
                              value: JournalTabName.authorized,
                              label: locale.authorizedTransactions,
                              screen: const AuthorizedTransactionsView(),
                            ),
                          if (login.hasPermission(21) ?? false)
                            ZTabItem(
                              value: JournalTabName.pending,
                              label: locale.pendingTransactions,
                              screen: const PendingTransactionsView(),
                            ),
                        ];

                        final availableValues = tabs.map((tab) => tab.value).toList();
                        final selected = availableValues.contains(tabState.tab)
                            ? tabState.tab
                            : availableValues.first;

                        return ZTabContainer<JournalTabName>(
                          tabs: tabs,
                          selectedValue: selected,
                          onChanged: (val) => context.read<JournalTabBloc>().add(JournalOnChangedEvent(val)),
                          title: locale.journal,
                          description: locale.journalHint,
                          style: ZTabStyle.rounded,
                          tabBarPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          borderRadius: 0,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          unselectedTextColor: Theme.of(context).colorScheme.secondary,
                          selectedTextColor: Theme.of(context).colorScheme.surface,
                          tabContainerColor: Theme.of(context).colorScheme.surface,
                        );
                      },
                    ),
                  ),
                  // RIGHT SIDE — SHORTCUT BUTTONS PANEL
                  AnimatedContainer(
                    clipBehavior: Clip.hardEdge,
                    duration: const Duration(milliseconds: 300),
                    width: _isExpanded ? 170 : 70,
                    margin: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 3,
                          spreadRadius: 2,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .03),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(5),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          /// Toggle arrow
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: _isExpanded
                                  ? MainAxisAlignment.spaceBetween
                                  : MainAxisAlignment.start,
                              children: [
                                if (_isExpanded)
                                  Flexible(
                                    child: Text(
                                      locale.shortcuts,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: .06),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: IconButton(
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    icon: Icon(_isExpanded
                                        ? Icons.chevron_right
                                        : Icons.chevron_left),
                                    onPressed: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_isExpanded)
                            Wrap(
                              spacing: 5,
                              children: [
                                const Icon(Icons.money, size: 20),
                                Text(
                                  locale.cashFlow,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),

                          // Cash Deposit
                          if (login.hasPermission(22) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F1",
                              label: Text(locale.deposit),
                              icon: Icons.arrow_circle_down_rounded,
                              width: double.infinity,
                              onPressed: () => onCashDepositWithdraw(trnType: "CHDP"),
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F1 - ${locale.deposit}",
                                label: null,
                                icon: Icons.arrow_circle_down_rounded,
                                width: double.infinity,
                                onPressed: () => onCashDepositWithdraw(trnType: "CHDP"),
                              ),
                            ),

                          // Cash Withdraw
                          if (login.hasPermission(23) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F2",
                              label: Text(locale.withdraw),
                              icon: Icons.arrow_circle_up_rounded,
                              width: double.infinity,
                              onPressed: () => onCashDepositWithdraw(trnType: "CHWL"),
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F2 - ${locale.withdraw}",
                                label: null,
                                icon: Icons.arrow_circle_up_rounded,
                                width: double.infinity,
                                onPressed: () => onCashDepositWithdraw(trnType: "CHWL"),
                              ),
                            ),

                          // Income
                          if (login.hasPermission(24) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F3",
                              label: Text(locale.income),
                              icon: Icons.arrow_circle_down_rounded,
                              width: double.infinity,
                              onPressed: () => onCashIncome(trnType: "INCM"),
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F3 - ${locale.income}",
                                label: null,
                                icon: Icons.arrow_circle_down_rounded,
                                width: double.infinity,
                                onPressed: () => onCashIncome(trnType: "INCM"),
                              ),
                            ),

                          // Expense
                          if (login.hasPermission(25) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F4",
                              label: Text(locale.expense),
                              icon: Icons.arrow_circle_up_rounded,
                              width: double.infinity,
                              onPressed: () => onCashExpense(trnType: "XPNS"),
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F4 - ${locale.expense}",
                                label: null,
                                icon: Icons.arrow_circle_up_rounded,
                                width: double.infinity,
                                onPressed: () => onCashExpense(trnType: "XPNS"),
                              ),
                            ),

                          const SizedBox(height: 5),

                          if (_isExpanded)
                            Wrap(
                              spacing: 5,
                              children: [
                                const Icon(Icons.swap_horiz_rounded, size: 20),
                                Text(
                                  locale.fundTransferTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),

                          // Single Account Transfer
                          if (login.hasPermission(28) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F5",
                              label: Text(locale.singleAccount),
                              icon: Icons.swap_horiz_rounded,
                              width: double.infinity,
                              onPressed: () => accountToAccount(trnType: "ATAT"),
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F5 - ${locale.singleAccount}",
                                label: null,
                                icon: Icons.swap_horiz_rounded,
                                width: double.infinity,
                                onPressed: () => accountToAccount(trnType: "ATAT"),
                              ),
                            ),

                          // Multi Account Transfer
                          if (login.hasPermission(29) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F6",
                              label: Text(locale.multiAccount),
                              icon: Icons.swap_horiz_rounded,
                              width: double.infinity,
                              onPressed: onMultiATAT,
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F6 - ${locale.multiAccount}",
                                label: null,
                                icon: Icons.swap_horiz_rounded,
                                width: double.infinity,
                                onPressed: onMultiATAT,
                              ),
                            ),

                          // FX Transaction
                          if (login.hasPermission(30) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F7",
                              label: Text(locale.fxTransaction),
                              icon: Icons.swap_horiz_rounded,
                              width: double.infinity,
                              onPressed: onFxTxn,
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F7 - ${locale.fxTransaction}",
                                label: null,
                                icon: Icons.swap_horiz_rounded,
                                width: double.infinity,
                                onPressed: onFxTxn,
                              ),
                            ),

                          const SizedBox(height: 5),

                          if (_isExpanded)
                            Wrap(
                              spacing: 5,
                              children: [
                                const Icon(Icons.computer_rounded, size: 20),
                                Text(
                                  locale.systemAction,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),

                          // GL Credit
                          if (login.hasPermission(26) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F8",
                              label: Text(locale.glCreditTitle),
                              width: double.infinity,
                              icon: Icons.menu_book_rounded,
                              onPressed: () => onGL(trnType: "GLCR"),
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F8 - ${locale.glCreditTitle}",
                                label: null,
                                width: double.infinity,
                                icon: Icons.menu_book_rounded,
                                onPressed: () => onGL(trnType: "GLCR"),
                              ),
                            ),

                          // GL Debit
                          if (login.hasPermission(27) ?? false)
                            _isExpanded
                                ? ZOutlineButton(
                              backgroundColor: color.primary.withValues(alpha: opacity),
                              toolTip: "F9",
                              label: Text(locale.glDebitTitle),
                              width: double.infinity,
                              icon: Icons.menu_book_rounded,
                              onPressed: () => onGL(trnType: "GLDR"),
                            )
                                : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: ZOutlineButton(
                                backgroundColor: color.primary.withValues(alpha: opacity),
                                toolTip: "F9 - ${locale.glDebitTitle}",
                                label: null,
                                width: double.infinity,
                                icon: Icons.menu_book_rounded,
                                onPressed: () => onGL(trnType: "GLDR"),
                              ),
                            ),
                        ],
                      ),
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
}