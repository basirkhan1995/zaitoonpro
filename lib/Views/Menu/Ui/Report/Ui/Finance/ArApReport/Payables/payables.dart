import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ArApReport/bloc/ar_ap_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ArApReport/model/ar_ap_model.dart';
import '../../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import '../Pdf/pdf.dart';

class PayablesView extends StatelessWidget {
  const PayablesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Mobile(),
      desktop: _Desktop(),
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
  List<ArApModel> payables = [];

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
            title: Text(tr.creditors),
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
              // Total payables row - Horizontal scrolling cards
              BlocBuilder<ArApBloc, ArApState>(
                builder: (context, state) {
                  if (state is ArApLoadedState) {
                    final filteredList = state.apAccounts;
                    final totalsByCurrency = calculateTotalPayableByCurrency(filteredList);
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
                      final filteredList = state.apAccounts.where((item) {
                        final name = item.accName?.toLowerCase() ?? '';
                        final accNumber = item.accNumber?.toString() ?? '';
                        return name.contains(query) || accNumber.contains(query);
                      }).toList();
                      payables = filteredList;

                      if (filteredList.isEmpty) {
                        return const NoDataWidget(message: 'No payables found');
                      }

                      return ListView.builder(
                        itemCount: filteredList.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final ap = filteredList[index];
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
                                          ap.accName ?? "",
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
                                          ap.accNumber.toString(),
                                          style: subtitle1?.copyWith(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Status and Limit Row
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
                                              ap.fullName ?? "",
                                              style: Theme.of(context).textTheme.bodyMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      StatusBadge(
                                        status: ap.accStatus!,
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
                                            ap.accLimit == "Unlimited"
                                                ? tr.unlimited
                                                : "${ap.accLimit.toAmount()} ${ap.accCurrency ?? ''}",
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
                                          "${ap.accBalance.toAmount()} ${ap.accCurrency}",
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

  void onPDF() {
    final locale = AppLocalizations.of(context)!;
    final state = context.read<ArApBloc>().state;

    List<ArApModel> payablesList = [];
    ReportModel company = ReportModel();

    if (state is ArApLoadedState) {
      payablesList = state.apAccounts;
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
          return ArApPdfServices().generateApReport(
            apAccounts: data,
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
            isAR: false,
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
            isAR: false,
          );
        },
      ),
    );
  }

  Map<String, double> calculateTotalPayableByCurrency(List<ArApModel> list) {
    final Map<String, double> totals = {};
    for (var acc in list.where((e) => e.isAP)) {
      final currency = acc.accCurrency ?? 'N/A';
      totals[currency] = (totals[currency] ?? 0.0) + acc.balance;
    }
    return totals;
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  final searchController = TextEditingController();
  final company = ReportModel();
  List<ArApModel> payables = [];

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
            title: Text(tr.creditors),
            titleSpacing: 0,
            actions: [
              // Search bar and PDF button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 8,
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
                    ZOutlineButton(
                      width: 110,
                      icon: FontAwesomeIcons.solidFilePdf,
                      label: Text("PDF"),
                      onPressed: onPDF,
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Total payables row
              BlocBuilder<ArApBloc, ArApState>(
                builder: (context, state) {
                  if (state is ArApLoadedState) {
                    final filteredList = state.apAccounts;
                    final totalsByCurrency = calculateTotalPayableByCurrency(filteredList);

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
                    Expanded(child: Text("${tr.signatory} | ${tr.accountLimit}", style: title)),
                    Text(tr.balance, style: title),
                  ],
                ),
              ),
              Divider(indent: 15, endIndent: 15),

              // Accounts list
              Expanded(
                child: BlocBuilder<ArApBloc, ArApState>(
                  builder: (context, state) {
                    if (state is ArApErrorState) {
                      return NoDataWidget(message: state.error);
                    }
                    if (state is ArApLoadingState) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (state is ArApLoadedState) {
                      if(state.apAccounts.isEmpty){
                        return NoDataWidget(
                          title: tr.noData,
                          message: tr.noDataFound,
                          enableAction: false,
                        );
                      }
                      final query = searchController.text.toLowerCase().trim();
                      final filteredList = state.apAccounts.where((item) {
                        final name = item.accName?.toLowerCase() ?? '';
                        final accNumber = item.accNumber?.toString() ?? '';
                        return name.contains(query) || accNumber.contains(query);
                      }).toList();
                      payables = filteredList;

                      return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final ap = filteredList[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                            decoration: BoxDecoration(
                              color: index.isOdd
                                  ? Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: .05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 280,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ap.accName ?? "", style: title),
                                      SizedBox(height: 2),
                                      Row(
                                        children: [
                                          StatusBadge(
                                            status: ap.accStatus!,
                                            trueValue: tr.active,
                                            falseValue: tr.blocked,
                                          ),
                                          SizedBox(width: 5),
                                          ZCover(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: .03),
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            child: Text(ap.accNumber.toString(), style: subtitle1),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ap.fullName ?? "", style: Theme.of(context).textTheme.titleMedium),
                                        Row(
                                          spacing: 3,
                                          children: [
                                            Text(ap.accLimit == "Unlimited"? tr.unlimited : ap.accLimit.toAmount(), style: subTitle),
                                            Text(ap.accCurrency ?? "", style: subTitle),
                                          ],
                                        ),
                                      ],
                                    )),
                                Text("${ap.accBalance.toAmount()} ${ap.accCurrency}",
                                    style: Theme.of(context).textTheme.titleMedium),
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
    ReportModel company = ReportModel(); // Initialize with your company data

    // Extract data from state
    if (state is ArApLoadedState) {
      payablesList = state.apAccounts;
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
          return ArApPdfServices().generateApReport(
            apAccounts: data,
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
            isAR: false, // false for AP
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
            isAR: false, // false for AP
          );
        },
      ),
    );
  }

  /// Calculate total payables grouped by currency
  Map<String, double> calculateTotalPayableByCurrency(List<ArApModel> list) {
    final Map<String, double> totals = {};
    for (var acc in list.where((e) => e.isAP)) {
      final currency = acc.accCurrency ?? 'N/A';
      totals[currency] = (totals[currency] ?? 0.0) + acc.balance;
    }
    return totals;
  }
}


// 🔹 EXTENSION FOR CLEANER TOTAL CALCULATION
extension ArApExtensions on List<ArApModel> {
  double calculateTotalPayable() {
    return where((e) => e.isAP).fold(0.0, (sum, e) => sum + e.balance);
  }

  double calculateTotalReceivable() {
    return where((e) => e.isAR).fold(0.0, (sum, e) => sum + e.balance);
  }
}
