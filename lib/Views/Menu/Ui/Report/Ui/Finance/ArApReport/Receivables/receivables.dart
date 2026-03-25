import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ArApReport/bloc/ar_ap_bloc.dart';
import '../../../../../../../../Features/Other/utils.dart';
import '../../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import '../Pdf/pdf.dart';
import '../model/ar_ap_model.dart';

class ReceivablesView extends StatelessWidget {
  const ReceivablesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _Mobile(),
      tablet: const _Tablet(),
      desktop: const _Desktop(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final searchController = TextEditingController();
  final company = ReportModel();
  List<ArApModel> receivables = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArApBloc>().add(LoadArApEvent());
    });
  }


  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    final subTitle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.outline);
    final subtitle1 = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurface);
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(tr.debtors),
            titleSpacing: 0,
            actions: [
              // PDF button only
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(FontAwesomeIcons.solidFilePdf),
                  onPressed: onPDF,
                  tooltip: "PDF",
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: ZSearchField(
                  icon: FontAwesomeIcons.magnifyingGlass,
                  controller: searchController,
                  title: '',
                  hint: tr.accountName,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Total receivables row - Horizontal scrolling cards
              BlocBuilder<ArApBloc, ArApState>(
                builder: (context, state) {
                  if (state is ArApLoadedState) {
                    final filteredList = state.arAccounts;
                    final totalsByCurrency = calculateTotalReceivableByCurrency(filteredList);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 12,
                          children: totalsByCurrency.entries.map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${tr.totalUpperCase} ${entry.key}",
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.outline,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        entry.value.toAmount(),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        entry.key,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Utils.currencyColors(entry.key),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),

              // Accounts list
              Expanded(
                child: BlocBuilder<ArApBloc, ArApState>(
                  builder: (context, state) {
                    if (state is ArApErrorState) {
                      return NoDataWidget(message: state.error);
                    }
                    if (state is ArApLoadingState) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ArApLoadedState) {
                      final query = searchController.text.toLowerCase().trim();
                      final filteredList = state.arAccounts.where((item) {
                        final name = item.accName?.toLowerCase() ?? '';
                        final accNumber = item.accNumber?.toString() ?? '';
                        return name.contains(query) || accNumber.contains(query);
                      }).toList();
                      receivables = filteredList;

                      if (filteredList.isEmpty) {
                        return const NoDataWidget(message: 'No receivables found');
                      }

                      return ListView.builder(
                        itemCount: filteredList.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final ar = filteredList[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Account Name and Number Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ar.accName ?? "",
                                          style: title?.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Text(
                                          ar.accNumber.toString(),
                                          style: subtitle1?.copyWith(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Status and Signatory Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tr.signatory,
                                              style: subTitle,
                                            ),
                                            Text(
                                              ar.fullName ?? "",
                                              style: Theme.of(context).textTheme.bodyMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(
                                        status: ar.accStatus ?? 0,
                                        trueValue: tr.active,
                                        falseValue: tr.blocked,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Limit and Balance Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Account Limit
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${tr.accountLimit}: ",
                                            style: subTitle,
                                          ),
                                          Text(
                                            ar.accLimit == "Unlimited"
                                                ? tr.unlimited
                                                : "${ar.accLimit?.toAmount() ?? '0'} ${ar.accCurrency ?? ''}",
                                            style: Theme.of(context).textTheme.bodyMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),

                                      // Balance
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          "${ar.balance.toAmount()} ${ar.accCurrency}",
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void onPDF(){
    final locale = AppLocalizations.of(context)!;
    final state = context.read<ArApBloc>().state;

    List<ArApModel> receivablesList = [];
    ReportModel company = ReportModel();

    if (state is ArApLoadedState) {
      receivablesList = state.arAccounts;
    }

    if (receivablesList.isEmpty) {
      Utils.showOverlayMessage(
        context,
        message: locale.noData,
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<List<ArApModel>>(
        data: receivablesList,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return ArApPdfServices().generateArReport(
            arAccounts: data,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            report: company,
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
          return ArApPdfServices().printDocument(
            company: company,
            accounts: data,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
            copies: copies,
            pages: pages,
            isAR: true,
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return ArApPdfServices().createDocument(
            company: company,
            accounts: data,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            isAR: true,
          );
        },
      ),
    );
  }

  Map<String, double> calculateTotalReceivableByCurrency(List<ArApModel> list) {
    final Map<String, double> totals = {};
    for (var acc in list.where((e) => e.isAR)) {
      final currency = acc.accCurrency ?? 'N/A';
      totals[currency] = (totals[currency] ?? 0.0) + acc.absBalance;
    }
    return totals;
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    return const _Mobile();
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final searchController = TextEditingController();
  List<ArApModel> receivables = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArApBloc>().add(LoadArApEvent());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleMedium;
    final subTitle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline);
    final subtitle1 = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface);
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<ArApBloc, ArApState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(tr.debtors),
            titleSpacing: 0,
            actions: [
              // Search bar and PDF button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 350,
                      child: ZSearchField(
                        icon: FontAwesomeIcons.magnifyingGlass,
                        controller: searchController,
                        title: '',
                        hint: tr.accountName,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ZOutlineButton(
                      width: 110,
                      icon: FontAwesomeIcons.solidFilePdf,
                      label: const Text("PDF"),
                      onPressed: onPDF,
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Total receivables row
              BlocBuilder<ArApBloc, ArApState>(
                builder: (context, state) {
                  if (state is ArApLoadedState) {
                    final filteredList = state.arAccounts;
                    final totalsByCurrency = calculateTotalReceivableByCurrency(filteredList);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 10,
                          children: totalsByCurrency.entries.map((entry) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${tr.totalUpperCase} ${entry.key}",style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                                ZCover(
                                  radius: 3,
                                  child: Row(
                                    children: [
                                      Text(
                                        entry.value.toAmount(),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        entry.key,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Utils.currencyColors(entry.key)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),



              // Column headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  children: [
                    SizedBox(width: 280, child: Text(tr.accounts, style: title)),
                    SizedBox(width: 200, child: Text(tr.accountLimit, style: title)),
                    Expanded(child: Text(tr.signatory, style: title)),
                    Text(tr.balance, style: title),
                  ],
                ),
              ),
              const Divider(indent: 15, endIndent: 15),

              // Receivables list
              Expanded(
                child: BlocBuilder<ArApBloc, ArApState>(
                  builder: (context, state) {
                    if (state is ArApErrorState) {
                      return NoDataWidget(
                          message: state.error);
                    }
                    if (state is ArApLoadingState) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ArApLoadedState) {
                      final query = searchController.text.toLowerCase().trim();
                      final filteredList = state.arAccounts.where((item) {
                        final name = item.accName?.toLowerCase() ?? '';
                        final accNumber = item.accNumber?.toString() ?? '';
                        return name.contains(query) || accNumber.contains(query);
                      }).toList();
                      receivables = filteredList;

                      if (filteredList.isEmpty) {
                        return NoDataWidget(
                            title: tr.noData,
                            message: tr.noDataFound,
                           enableAction: false,
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final ar = filteredList[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                            decoration: BoxDecoration(
                              color: index.isOdd
                                  ? Theme.of(context).colorScheme.outline.withValues(alpha: .05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 280,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ar.accName ?? "", style: title),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          StatusBadge(
                                            status: ar.accStatus ?? 0,
                                            trueValue: tr.active,
                                            falseValue: tr.blocked,
                                          ),
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: .03),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(ar.accNumber.toString(), style: subtitle1),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ar.accLimit == "Unlimited"? tr.unlimited : ar.accLimit?.toAmount() ?? '0', style: title),
                                      Text(ar.accCurrency ?? "", style: subTitle),
                                    ],
                                  ),
                                ),
                                Expanded(child: Text(ar.fullName ?? "", style: title)),
                                Text("${ar.balance.toAmount()} ${ar.accCurrency}", style: title),
                              ],
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void onPDF() {
    final locale = AppLocalizations.of(context)!;
    final state = context.read<ArApBloc>().state;

    List<ArApModel> payablesList = [];
    ReportModel company = ReportModel();

    // Extract data from state
    if (state is ArApLoadedState) {
      payablesList = state.arAccounts;
    }
    // Add company info (you need to get this from your auth/company state)
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      // Set company info here

    }

    if (payablesList.isEmpty) {
      Utils.showOverlayMessage(
        context,
        message: locale.noData,
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<List<ArApModel>>(
        data: payablesList,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return ArApPdfServices().generateArReport(
            arAccounts: data,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            report: company,
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
          return ArApPdfServices().printDocument(
            company: company,
            accounts: data,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
            copies: copies,
            pages: pages,
            isAR: true,
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return ArApPdfServices().createDocument(
            company: company,
            accounts: data,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            isAR: true,
          );
        },
      ),
    );
  }
  /// Calculate total receivables grouped by currency
  Map<String, double> calculateTotalReceivableByCurrency(List<ArApModel> list) {
    final Map<String, double> totals = {};
    for (var acc in list.where((e) => e.isAR)) {
      final currency = acc.accCurrency ?? 'N/A';
      totals[currency] = (totals[currency] ?? 0.0) + acc.absBalance;
    }
    return totals;
  }
}


