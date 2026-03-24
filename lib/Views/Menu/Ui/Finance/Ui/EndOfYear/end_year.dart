import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/EndOfYear/bloc/eoy_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/EndOfYear/model/eoy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../../Localizations/Bloc/localizations_bloc.dart';

class EndOfYearView extends StatelessWidget {
  const EndOfYearView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Desktop(),
      desktop: _Desktop(),
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
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final company = ReportModel();
  String? myLocale;
  final formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  String? usrName;
  int? branchCode;
  final TextEditingController remark = TextEditingController();

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EoyBloc>().add(LoadPLEvent());
    });
    super.initState();
  }

  @override
  void dispose() {
    remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.surface,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.profitAndLoss, style: titleStyle?.copyWith(fontSize: 25,color: Theme.of(context).colorScheme.onSurface)),
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          // ZOutlineButton(
          //   width: 110,
          //   label: Text(tr.print),
          //   icon: Icons.print,
          //   onPressed: () {},
          // ),
          // const SizedBox(width: 8),
          ZOutlineButton(
            width: 110,
            label: Text(tr.refresh),
            icon: Icons.refresh,
            onPressed: () {
              context.read<EoyBloc>().add(LoadPLEvent());
            },
          ),
          const SizedBox(width: 8),
          ZOutlineButton(
            isActive: true,
            width: 150,
            label: Text(tr.eoyClosing),
            icon: Icons.access_time_outlined,
            onPressed: eoyClosing,
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthenticatedState) {
            usrName = state.loginData.usrName;
            branchCode = state.loginData.usrBranch;
          }
          return BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
            builder: (context, state) {
              if (state is CompanyProfileLoadedState) {
                company.comName = state.company.comName ?? "";
                company.comAddress = state.company.addName ?? "";
                company.compPhone = state.company.comPhone ?? "";
                company.comEmail = state.company.comEmail ?? "";
                company.statementDate = DateTime.now().toFullDateTime;
                final base64Logo = state.company.comLogo;
                if (base64Logo != null && base64Logo.isNotEmpty) {
                  try {
                    _companyLogo = base64Decode(base64Logo);
                    company.comLogo = _companyLogo;
                  } catch (e) {
                    _companyLogo = Uint8List(0);
                  }
                }
              }
              return Column(
                children: [
                  _HeaderRow(titleStyle: titleStyle, tr: tr, myLocale: myLocale??"en"),
                  Expanded(
                    child: BlocConsumer<EoyBloc, EoyState>(
                      listener: (context, state) {
                        if (state is EoySuccessState) {
                          Navigator.of(context).pop();
                        }
                        if (state is EoyErrorState) {
                          Utils.showOverlayMessage(
                            context,
                            message: state.error,
                            isError: true,
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is EoyErrorState) {
                          return NoDataWidget(
                            onRefresh: () {
                              context.read<EoyBloc>().add(LoadPLEvent());
                            },
                            message: state.error,
                          );
                        }
                        if (state is EoyLoadingState) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is EoyLoadedState) {
                          if(state.eoy.isEmpty){
                            return NoDataWidget(
                              title: tr.noData,
                              message: tr.noPandLMessage,
                              enableAction: false,
                            );
                          }
                          final summary = state.eoy.summary;
                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: state.eoy.length,
                                  itemBuilder: (context, index) {
                                    final eoy = state.eoy[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: index.isEven
                                            ? theme.colorScheme.primary
                                                  .withValues(alpha: .05)
                                            : Colors.transparent,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              eoy.accountNumber.toString(),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(eoy.accountName ?? ""),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              eoy.trdBranch.toString(),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: Text(eoy.category ?? ""),
                                          ),
                                          _AmountCell(
                                            amount: eoy.debitAmount,
                                            currency: eoy.currency,
                                          ),
                                          _AmountCell(
                                            amount: eoy.creditAmount,
                                            currency: eoy.currency,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              _BottomSummary(
                                tr: tr,
                                incomeByCurrency: summary.incomeByCurrency,
                                expenseByCurrency: summary.expenseByCurrency,
                                retainedByCurrency: summary.retainedByCurrency,
                              ),
                            ],
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void eoyClosing() {
    final eoyState = context.read<EoyBloc>().state;
    final color = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    PAndLSummary? summary;
    if (eoyState is EoyLoadedState) summary = eoyState.eoy.summary;
    final tr = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<EoyBloc, EoyState>(
          builder: (context, state) {
            final isLoading = state is EoyLoadingState;
            return ZFormDialog(
              padding: EdgeInsets.all(12),
              title: tr.eoyClosing,
              icon: Icons.line_axis,
              actionLabel: isLoading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(tr.proceed),
              onAction: isLoading
                  ? null
                  : () {
                if (usrName != null && branchCode != null) {
                  context.read<EoyBloc>().add(
                    ProcessPLEvent(usrName!, remark.text, branchCode!),
                  );
                }
              },
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: color.outline.withValues(alpha: .3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            spacing: 5,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: color.error,
                              ),
                              Text(
                                tr.attentionTitle,
                                style: txt.titleSmall?.copyWith(
                                  color: color.error,
                                ),
                              ),
                            ],
                          ),
                          Divider(color: color.error),
                          SizedBox(height: 5),
                          Text(
                            tr.plMessage,
                            style: txt.bodyMedium?.copyWith(color: color.error),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (summary != null) ...[
                      // Main Row containing all three sections
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Income Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.income,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Divider(),
                                ...summary.incomeByCurrency.entries.map(
                                      (e) => _InfoRow(label: e.key, amount: e.value),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),

                          SizedBox(width: 16), // Spacer between columns

                          // Expense Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.expense,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Divider(),
                                ...summary.expenseByCurrency.entries.map(
                                      (e) => _InfoRow(label: e.key, amount: e.value),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),

                          SizedBox(width: 16), // Spacer between columns

                          // Retained Earnings Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.retainedEarnings,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Divider(),
                                ...summary.retainedByCurrency.entries.map(
                                      (e) => _InfoRow(
                                    label: e.key,
                                    amount: e.value,
                                    isPositive: e.value >= 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    ZTextFieldEntitled(
                      controller: remark,
                      keyboardInputType: TextInputType.multiline,
                      title: tr.remark,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool? isPositive;

  const _InfoRow({required this.label, required this.amount, this.isPositive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 5,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Utils.currencyColors(label),
            ),
          ),
          Text(
            amount.toAmount(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPositive != null
                  ? (isPositive! ? Colors.green : Colors.red)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header Row
class _HeaderRow extends StatelessWidget {
  final TextStyle? titleStyle;
  final String myLocale;
  final AppLocalizations tr;

  const _HeaderRow({required this.titleStyle, required this.myLocale, required this.tr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: .5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),

        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(tr.accountNumber, style: titleStyle),
            ),
            Expanded(child: Text(tr.accountName, style: titleStyle)),
            SizedBox(width: 100, child: Text(tr.branch, style: titleStyle)),
            SizedBox(
              width: 100,
              child: Text(tr.categoryTitle, style: titleStyle),
            ),
            SizedBox(
              width: 150,
              child: Text(
                tr.debitTitle,
                textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                style: titleStyle,
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                tr.creditTitle,
                textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                style: titleStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amount Cell
class _AmountCell extends StatelessWidget {
  final double amount;
  final String? currency;

  const _AmountCell({required this.amount, required this.currency});

  @override
  Widget build(BuildContext context) {
    final bool showDash = amount == 0 || amount.isNaN || amount.isInfinite;
    final hasCurrency = currency != null && currency!.isNotEmpty;

    return SizedBox(
      width: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            showDash ? "-" : amount.toAmount(),
            style: TextStyle(
              color: showDash
                  ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                  : null,
            ),
          ),

          if (!showDash && hasCurrency) ...[
            const SizedBox(width: 5),
            Text(
              currency!,
              style: TextStyle(
                color: Utils.currencyColors(currency!),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom Summary (multi-currency) - Full row with expanded Total
class _BottomSummary extends StatelessWidget {
  final AppLocalizations tr;
  final Map<String, double> incomeByCurrency;
  final Map<String, double> expenseByCurrency;
  final Map<String, double> retainedByCurrency;

  const _BottomSummary({
    required this.tr,
    required this.incomeByCurrency,
    required this.expenseByCurrency,
    required this.retainedByCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget currencyColumn(
      String title,
      Map<String, double> data, {
      required Color amountColor,
      bool highlightNegative = false,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 4),

          /// Values
          ...data.entries.map(
            (e) => Text(
              "${e.key}: ${e.value.toAmount()}",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: highlightNegative && e.value < 0
                    ? Colors.red
                    : amountColor,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: .8),
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ================= LEFT: TOTAL (EXPANDED) =================
          Expanded(
            child: Row(
              children: [
                Icon(Icons.ssid_chart,size: 20),
                SizedBox(width: 8),
                Text(
                  "${tr.totalTitle} ${tr.profitAndLoss}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// ================= RIGHT: SUMMARY COLUMNS =================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                currencyColumn(
                  tr.income,
                  incomeByCurrency,
                  amountColor: Colors.green,
                ),
                const SizedBox(width: 40),
                currencyColumn(
                  tr.expense,
                  expenseByCurrency,
                  amountColor: Colors.red,
                ),
                const SizedBox(width: 40),
                currencyColumn(
                  tr.retainedEarnings,
                  retainedByCurrency,
                  amountColor: Colors.green,
                  highlightNegative: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
