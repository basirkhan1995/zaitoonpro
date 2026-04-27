import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Date/z_generic_date.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/shortcut.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/bloc/gl_accounts_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/model/gl_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/features/branch_dropdown.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/GLStatement/bloc/gl_statement_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/GLStatement/model/gl_statement_model.dart';
import '../../../../../../../Features/Date/z_range_picker.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Other/cover.dart';
import '../../../../../../../Features/Other/utils.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../Journal/Ui/TxnByReference/bloc/txn_reference_bloc.dart';
import '../../../../Journal/Ui/TxnByReference/txn_reference.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../TransactionRef/transaction_ref.dart';
import 'PDF/pdf.dart';
import 'package:flutter/services.dart';

class GlStatementView extends StatelessWidget {
  final bool isSingleDate;
  const GlStatementView({super.key, this.isSingleDate = false});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(isSingleDate: isSingleDate),
      tablet: _Mobile(isSingleDate: isSingleDate),
      desktop: _Desktop(isSingleDate: isSingleDate),
    );
  }
}

class _Mobile extends StatefulWidget {
  final bool isSingleDate;
  const _Mobile({this.isSingleDate = false});

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final accountController = TextEditingController();
  int? accNumber;
  String? myLocale;
  String? currency;
  int branchCode = 1000;
  String? baseCurrency;
  final formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  String fromDate = DateTime.now().toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;

  List<GlRecord> records = [];
  GlStatementModel? glStatementModel;

  void showTxnDetails() {
    showDialog(
      context: context,
      builder: (context) => const TransactionByReferenceView(),
    );
  }

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<GlStatementBloc>().add(ResetGlStmtEvent());
    super.initState();
  }

  void _generateAndShowPDF(BuildContext context) {
    if (formKey.currentState!.validate() && accNumber != null) {
      setState(() {
        records = [];
        glStatementModel = null;
      });

      context.read<GlStatementBloc>().add(
        LoadGlStatementEvent(
          currency: currency ?? baseCurrency ?? "",
          branchCode: branchCode,
          accountNumber: accNumber!,
          fromDate: fromDate,
          toDate: widget.isSingleDate ? fromDate : toDate,
        ),
      );
    } else {
      Utils.showOverlayMessage(
        context,
        message: AppLocalizations.of(context)!.accountStatementMessage,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.keyR, control: true, shift: true):
          () => showTxnDetails(),
    };

    return GlobalShortcuts(
      shortcuts: shortcuts,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(tr.glStatement),
          titleSpacing: 0,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if(state is AuthenticatedState){
              final auth = state.loginData;
              company.comName = auth.company?.comName??"";
              company.comAddress = auth.company?.comAddress??"";
              company.compPhone = auth.company?.comPhone??"";
              company.comEmail = auth.company?.comEmail??"";
              company.startDate = fromDate;
              company.endDate = toDate;
              company.statementDate = DateTime.now().toFullDateTime;
              final base64Logo = auth.company?.comLogo;
              if (base64Logo != null && base64Logo.isNotEmpty) {
                try {
                  _companyLogo = base64Decode(base64Logo);
                  company.comLogo = _companyLogo;
                } catch (e) {
                  _companyLogo = Uint8List(0);
                }
              }
            }

            return BlocConsumer<TxnReferenceBloc, TxnReferenceState>(
              listener: (context, state) {
                if (state is TxnReferenceLoadedState) {
                  showDialog(
                    context: context,
                    builder: (context) => const TxnReferenceView(),
                  );
                }
              },
              builder: (context, txnState) {
                return BlocConsumer<GlStatementBloc, GlStatementState>(
                  listener: (context, state) {
                    if (state is GlStatementLoadedState) {
                      final statementDetails = state.stmt;

                      setState(() {
                        glStatementModel = statementDetails;
                        records = statementDetails.records ?? [];
                      });

                      if (records.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (_) => PrintPreviewDialog<GlStatementModel>(
                            data: glStatementModel!,
                            company: company,
                            buildPreview: ({
                              required data,
                              required language,
                              required orientation,
                              required pageFormat,
                            }) {
                              return GlStatementPrintSettings().printPreview(
                                company: company,
                                language: language,
                                orientation: orientation,
                                pageFormat: pageFormat,
                                info: glStatementModel!,
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
                              return GlStatementPrintSettings().printDocument(
                                statement: [glStatementModel!],
                                company: company,
                                language: language,
                                orientation: orientation,
                                pageFormat: pageFormat,
                                selectedPrinter: selectedPrinter,
                                info: glStatementModel!,
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
                              return GlStatementPrintSettings().createDocument(
                                statement: [glStatementModel!],
                                company: company,
                                language: language,
                                orientation: orientation,
                                pageFormat: pageFormat,
                                info: glStatementModel!,
                              );
                            },
                          ),
                        );
                      } else {
                        Utils.showOverlayMessage(
                          context,
                          message: "No transactions found",
                          isError: true,
                        );
                      }
                    } else if (state is GlStatementErrorState) {
                      Utils.showOverlayMessage(
                        context,
                        message: state.message,
                        isError: true,
                      );
                    }
                  },
                  builder: (context, state) {
                    return Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            // Account Selection
                            GenericTextField<GlAccountsModel, GlAccountsBloc, GlAccountsState>(
                              showAllOnFocus: true,
                              controller: accountController,
                              title: tr.accounts,
                              hintText: tr.accNameOrNumber,
                              isRequired: true,
                              bloc: context.read<GlAccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(
                                const LoadGlAccountEvent(),
                              ),
                              searchFunction: (bloc, query) => bloc.add(
                                LoadGlAccountEvent(query: query),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${account.accNumber} | ${account.accName}",
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                              stateToLoading: (state) => state is GlAccountsLoadingState,
                              loadingBuilder: (context) => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 3),
                              ),
                              stateToItems: (state) {
                                if (state is GlAccountLoadedState) {
                                  return state.gl;
                                }
                                return [];
                              },
                              onSelected: (value) {
                                setState(() {
                                  accNumber = value.accNumber;
                                });
                              },
                              noResultsText: tr.noDataFound,
                              showClearButton: true,
                            ),

                            const SizedBox(height: 12),

                            // Branch & Currency Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: BranchDropdown(
                                    height: 40,
                                    onBranchSelected: (e) {
                                      setState(() {
                                        branchCode = e?.brcId ?? 1000;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: CurrencyDropdown(
                                    initiallySelectedSingle: CurrenciesModel(ccyCode: baseCurrency),
                                    title: AppLocalizations.of(context)!.currencyTitle,
                                    isMulti: false,
                                    onMultiChanged: (e) {},
                                    onSingleChanged: (e) {
                                      setState(() {
                                        currency = e?.ccyCode ?? "";
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Date Range
                            Column(
                              children: [
                                ZDatePicker(
                                  label: widget.isSingleDate ? tr.date : tr.fromDate,
                                  value: fromDate,
                                  onDateChanged: (v) {
                                    setState(() {
                                      fromDate = v;
                                      shamsiFromDate = v.toAfghanShamsi;
                                    });
                                  },
                                ),
                                if (!widget.isSingleDate) ...[
                                  const SizedBox(height: 12),
                                  ZDatePicker(
                                    label: tr.toDate,
                                    value: toDate,
                                    onDateChanged: (v) {
                                      setState(() {
                                        toDate = v;
                                        shamsiToDate = v.toAfghanShamsi;
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Generate PDF Button
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ZOutlineButton(
                                isActive: (state is GlStatementLoadingState || accNumber == null) ? false : true,
                                onPressed: (state is GlStatementLoadingState || accNumber == null)
                                    ? null
                                    : () => _generateAndShowPDF(context),
                                icon: FontAwesomeIcons.solidFilePdf,
                                label: state is GlStatementLoadingState
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text("PDF"),
                              ),
                            ),

                            if (glStatementModel != null && records.isNotEmpty) ...[
                              const SizedBox(height: 16),

                              // Quick Summary Card
                              ZCover(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                        title: Text(
                                          "Account Summary",
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(glStatementModel?.accName ?? ""),
                                            Text("${glStatementModel?.brcName} | ${glStatementModel?.glCategory}"),
                                          ],
                                        ),
                                      ),
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(tr.currentBalance),
                                            Text(
                                              "${glStatementModel?.curBalance.toAmount()} ${glStatementModel?.ccySymbol ?? baseCurrency}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(tr.availableBalance),
                                            Text(
                                              "${glStatementModel?.avilBalance.toAmount()} ${glStatementModel?.ccySymbol ?? baseCurrency}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Share button (GL might not need WhatsApp share, but keeping for consistency)
                              SizedBox(
                                width: double.infinity,
                                child: ZOutlineButton(
                                  onPressed: () {
                                    _generateAndShowPDF(context);
                                  },
                                  icon: Icons.refresh,
                                  label: const Text("Regenerate"),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Transaction count and info
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(10),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total Transactions",
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    Text(
                                      "${records.length}",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Add some bottom padding for better scrolling experience
                              const SizedBox(height: 20),
                            ],

                            // Hint text - only show when no data
                            if (glStatementModel == null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.solidFilePdf,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.outline.withAlpha(100),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Select an account, branch, currency and date range,\nthen tap the PDF button to generate statement",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}


class _Desktop extends StatefulWidget {
  final bool isSingleDate;
  const _Desktop({this.isSingleDate = false});

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  final Map<String, bool> _copiedStates = {};
  final accountController = TextEditingController();
  int? accNumber;
  String? myLocale;
  String? currency;
  int branchCode = 1000;
  String? baseCurrency;
  final formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  late String fromDate;
  late String toDate;


  List<GlStatementModel> records = [];
  GlStatementModel? accountStatementModel;
  void showTxnDetails(){
    showDialog(context: context, builder: (context){
      return TransactionByReferenceView();
    });
  }
  @override
  void initState() {
    final now = DateTime.now();
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    fromDate = lastMonthStart.toFormattedDate();
    toDate = lastMonthEnd.toFormattedDate();
    WidgetsBinding.instance.addPostFrameCallback((_){
      myLocale = context.read<LocalizationBloc>().state.languageCode;
      context.read<GlStatementBloc>().add(ResetGlStmtEvent());
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    double dateWith = 100;
    double refWidth = 240;
    double amountWidth = 130;
    double balanceWidth =  160;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if(state is AuthenticatedState){
            final auth = state.loginData;
            baseCurrency = auth.company?.comLocalCcy ??"";
            company.comName = auth.company?.comName??"";
            company.comAddress = auth.company?.comAddress??"";
            company.compPhone = auth.company?.comPhone??"";
            company.comEmail = auth.company?.comEmail??"";
            company.startDate = fromDate;
            company.endDate = toDate;
            company.statementDate = DateTime.now().toFullDateTime;
            final base64Logo = auth.company?.comLogo;
            if (base64Logo != null && base64Logo.isNotEmpty) {
              try {
                _companyLogo = base64Decode(base64Logo);
                company.comLogo = _companyLogo;
              } catch (e) {
                _companyLogo = Uint8List(0);
              }
            }
          }
          return BlocConsumer<TxnReferenceBloc, TxnReferenceState>(
            listener: (context, state) {
              if (state is TxnReferenceLoadedState) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return TxnReferenceView();
                  },
                );
              }
            },
            builder: (context, state) {
              return Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Utils.zBackButton(context),
                                Text(
                                  tr.glStatement,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ZOutlineButton(
                                  width: 100,
                                  icon: Icons.print,
                                  label: Text(tr.print),
                                  onPressed: (){
                                    if(formKey.currentState!.validate()){
                                        pdf();
                                    }else{
                                      Utils.showOverlayMessage(context, message: tr.accountStatementMessage, isError: true);
                                    }
                                  },
                                ),
                                SizedBox(width: 8),
                                ZOutlineButton(
                                  isActive: true,
                                  icon: Icons.call_to_action_outlined,
                                  width: 100,
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      onSubmit();
                                    }
                                  },
                                  label: Text(tr.apply),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child:
                              GenericTextField<GlAccountsModel, GlAccountsBloc, GlAccountsState>(
                                showAllOnFocus: true,
                                controller: accountController,
                                title: tr.accounts,
                                hintText: tr.accNameOrNumber,
                                isRequired: true,
                                bloc: context.read<GlAccountsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(
                                  const LoadGlAccountEvent(),
                                ),
                                searchFunction: (bloc, query) => bloc.add(
                                  LoadGlAccountEvent(query: query),
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
                                state is GlAccountsLoadingState,
                                loadingBuilder: (context) => const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                                stateToItems: (state) {
                                  if (state is GlAccountLoadedState) {
                                    return state.gl;
                                  }
                                  return [];
                                },
                                onSelected: (value) {
                                  setState(() {
                                    accNumber = value.accNumber;
                                  });
                                },
                                noResultsText: tr.noDataFound,
                                showClearButton: true,
                              ),

                            ),
                            SizedBox(
                              width: 200,
                              child: BranchDropdown(
                                  title: tr.branch,
                                  height: 40,
                                  onBranchSelected: (e){
                                    setState(() {
                                      branchCode = e?.brcId ?? 1000;
                                    });
                                  }),
                            ),
                            SizedBox(
                              width: 160,
                              child: CurrencyDropdown(
                                initiallySelectedSingle: CurrenciesModel(ccyCode: baseCurrency),
                                   title: AppLocalizations.of(context)!.currencyTitle,
                                  isMulti: false,
                                  onMultiChanged: (e){},
                                 onSingleChanged: (e){
                                   setState(() {
                                     currency = e?.ccyCode ??"";
                                   });
                                   onSubmit();
                                 },
                              ),
                            ),
                            if(widget.isSingleDate !=true)
                            SizedBox(
                              width: 220,
                              child: ZRangeDatePicker(
                                label: tr.selectDate,
                                initialStartDate: DateTime.tryParse(fromDate),
                                initialEndDate: DateTime.tryParse(toDate),
                                startValue: fromDate,
                                endValue: toDate,
                                onStartDateChanged: (startDate) {
                                  setState(() {
                                    fromDate = startDate;
                                  });
                                },
                                onEndDateChanged: (endDate) {
                                  setState(() {
                                    toDate = endDate;
                                  });
                                  onSubmit();
                                },
                                disablePastDate: false,
                                minYear: 2000,
                                maxYear: 2100,
                              ),
                            ),
                            if(widget.isSingleDate)...[
                              SizedBox(
                                width: 150,
                                child: ZDatePicker(
                                  label: tr.date,
                                  value: fromDate,
                                  onDateChanged: (v) {
                                    setState(() {
                                      fromDate = v;
                                    });
                                    onSubmit();
                                  },
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: dateWith,
                              child: Text(
                                tr.txnDate,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            SizedBox(
                              width: refWidth,
                              child: Text(
                                tr.referenceNumber,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tr.narration,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            SizedBox(
                              width: amountWidth,
                              child: Text(
                                textAlign: myLocale == "en"
                                    ? TextAlign.right
                                    : TextAlign.left,
                                tr.debitTitle,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            SizedBox(
                              width: amountWidth,
                              child: Text(
                                textAlign: myLocale == "en"
                                    ? TextAlign.right
                                    : TextAlign.left,
                                tr.creditTitle,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            SizedBox(
                              width: balanceWidth,
                              child: Text(
                                textAlign: myLocale == "en"
                                    ? TextAlign.right
                                    : TextAlign.left,
                                tr.balance,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            SizedBox(width: 15),
                          ],
                        ),
                      ),
                      Divider(
                        endIndent: 10,
                        indent: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Expanded(
                        child: BlocBuilder<GlStatementBloc, GlStatementState>(
                          builder: (context, state) {
                            if (state is GlStatementLoadingState) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (state is GlStatementErrorState) {
                              return Center(child: Text(state.message));
                            }
                            if (state is GlStatementLoadedState) {
                              final records = state.stmt.records;
                              accountStatementModel = state.stmt;
                              if (records == null || records.isEmpty) {
                                return Center(child: Text("No transactions found"));
                              }

                              return ListView.builder(
                                itemCount: records.length,
                                itemBuilder: (context, index) {

                                  final stmt = records[index];
                                  final isCopied = _copiedStates[stmt.trnReference ?? ""] ?? false;
                                  final reference = stmt.trnReference ?? "";
                                  Color bg =
                                  stmt.trdNarration == "Opening Balance" ||
                                      stmt.trdNarration == "Closing Balance"
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary;
                                  bool isOp =
                                      stmt.trdNarration == "Opening Balance" ||
                                          stmt.trdNarration == "Closing Balance";
                                  return InkWell(
                                    hoverColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.05),
                                    highlightColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.05),
                                    onTap: isOp
                                        ? null
                                        : () {
                                      context.read<TxnReferenceBloc>().add(
                                        FetchTxnByReferenceEvent(
                                          stmt.trnReference ?? "",
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: index.isOdd
                                            ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.05)
                                            : Colors.transparent,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: dateWith,
                                            child: Text(
                                              stmt.trnEntryDate?.toFormattedDate() ??
                                                  "",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleSmall,
                                            ),
                                          ),
                                          SizedBox(
                                            width: refWidth,
                                            child: Row(
                                              children: [
                                                if(stmt.trnReference !=null && stmt.trnReference!.isNotEmpty)...[
                                                  SizedBox(
                                                    width: 28,
                                                    height: 28,
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () => _copyToClipboard(reference, context),
                                                        borderRadius: BorderRadius.circular(4),
                                                        hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                                                        child: AnimatedContainer(
                                                          duration: const Duration(milliseconds: 100),
                                                          decoration: BoxDecoration(
                                                            color: isCopied
                                                                ? Theme.of(context).colorScheme.primary.withAlpha(25)
                                                                : Colors.transparent,
                                                            border: Border.all(
                                                              color: isCopied
                                                                  ? Theme.of(context).colorScheme.primary
                                                                  : Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                                                              width: 1,
                                                            ),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Center(
                                                            child: AnimatedSwitcher(
                                                              duration: const Duration(milliseconds: 300),
                                                              child: Icon(
                                                                isCopied ? Icons.check : Icons.content_copy,
                                                                key: ValueKey<bool>(isCopied), // Important for AnimatedSwitcher
                                                                size: 15,
                                                                color: isCopied
                                                                    ? Theme.of(context).colorScheme.primary
                                                                    : Theme.of(context).colorScheme.outline.withValues(alpha: .6),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Expanded(
                                                    child:
                                                    Text(stmt.trnReference.toString())),
                                              ],
                                            ),
                                          ),

                                          Expanded(
                                            child: Text(stmt.trdNarration ?? ""),
                                          ),

                                          SizedBox(
                                            width: amountWidth,
                                            child: Text(
                                              textAlign: myLocale == "en"
                                                  ? TextAlign.right
                                                  : TextAlign.left,
                                              "${stmt.debit?.toAmount()}",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ),

                                          SizedBox(
                                            width: amountWidth,
                                            child: Text(
                                              textAlign: myLocale == "en"
                                                  ? TextAlign.right
                                                  : TextAlign.left,
                                              "${stmt.credit?.toAmount()}",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ),
                                          SizedBox(
                                            width: balanceWidth,
                                            child: Text(
                                              textAlign: myLocale == "en"
                                                  ? TextAlign.right
                                                  : TextAlign.left,
                                              "${stmt.total?.toAmount()} ${currency ?? baseCurrency}",
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: bg),
                                            ),
                                          ),
                                          SizedBox(
                                              width: 15,
                                              child: Text(stmt.status??"",
                                                textAlign: myLocale == "en"? TextAlign.right : TextAlign.left,
                                                style: TextStyle(color: Theme.of(context).colorScheme.error),)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            return Center(
                              child: NoDataWidget(
                                title: tr.glStatement,
                                message:
                                tr.accountStatementMessage,
                                enableAction: false,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void onSubmit(){
    if(accNumber !=null){
      context.read<GlStatementBloc>().add(
        LoadGlStatementEvent(
          currency: currency ?? baseCurrency ?? "",
          branchCode: branchCode,
          accountNumber: accNumber!,
          fromDate: widget.isSingleDate? fromDate : fromDate,
          toDate: widget.isSingleDate? fromDate : toDate,
        ),
      );
    }else{
      ToastManager.show(context: context,
          title: "No Account Selected",
          message: "Please select an account to continue", type: ToastType.info);
    }
  }

  void pdf(){
    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<GlStatementModel>(
        data: accountStatementModel!,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return GlStatementPrintSettings().printPreview(
              company: company,
              language: language,
              orientation: orientation,
              pageFormat: pageFormat,
              info: accountStatementModel!
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
          return GlStatementPrintSettings().printDocument(
            statement: records,
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
            info: accountStatementModel!,
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
          return GlStatementPrintSettings().createDocument(
            statement: records,
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            info: accountStatementModel!,
          );
        },
      ),
    );
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);

    // Set copied state to true
    setState(() {
      _copiedStates[reference] = true;
    });

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStates.remove(reference);
        });
      }
    });
  }
}
