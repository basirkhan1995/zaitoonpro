import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../../Auth/models/login_model.dart';
import '../../../../HR/Ui/Users/features/branch_dropdown.dart';
import 'PDF/pdf.dart';
import 'bloc/balance_sheet_bloc.dart';
import 'model/bs_model.dart';

class BalanceSheetView extends StatelessWidget {
  const BalanceSheetView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _MobileBalanceSheet(),
      tablet: const _TabletBalanceSheet(),
      desktop: const _DesktopBalanceSheet(),
    );
  }
}

// Desktop Version
class _DesktopBalanceSheet extends StatefulWidget {
  const _DesktopBalanceSheet();

  @override
  State<_DesktopBalanceSheet> createState() => _DesktopBalanceSheetState();
}

class _DesktopBalanceSheetState extends State<_DesktopBalanceSheet> {
  String? ccy;
  int? branchCode;
  LoginData? loginData;
  @override
  void initState() {
    final authState = context.read<AuthBloc>().state;
    if(authState is AuthenticatedState){
      loginData = authState.loginData;
      ccy = loginData?.company?.comLocalCcy;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalanceSheetBloc>().add(LoadBalanceSheet(branchCode: loginData?.usrBranch));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? baseCurrency;
    ReportModel company = ReportModel();

    return Scaffold(
      appBar: AppBar(

        title: Text(AppLocalizations.of(context)!.balanceSheet),
        titleSpacing: 0,
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: BranchDropdown(
                showAllOption: true,
                selectedId: loginData?.usrBranch,
                onBranchSelected: (e){
                  context.read<BalanceSheetBloc>().add(LoadBalanceSheet(branchCode: e?.brcId)
                  );
                }),
          ),
          SizedBox(width: 8),
          ZOutlineButton(
            width: 100,
            icon: Icons.refresh,
            onPressed: () {
              context.read<BalanceSheetBloc>().add(LoadBalanceSheet());
            },
            label: Text(AppLocalizations.of(context)!.refresh),
          ),
          const SizedBox(width: 8),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, comState) {
              if (comState is AuthenticatedState) {
                baseCurrency = comState.loginData.company?.comLocalCcy;
                company.comName = comState.loginData.company?.comName ?? "";
                company.comAddress = comState.loginData.usrFullName ?? "";
                company.compPhone = comState.loginData.company?.comPhone ?? "";
                company.comEmail = comState.loginData.company?.comEmail ?? "";
                company.statementDate = DateTime.now().toFullDateTime;
                company.baseCurrency = comState.loginData.company?.comLocalCcy;

                final base64Logo = comState.loginData.company?.comLogo;
                if (base64Logo != null && base64Logo.isNotEmpty) {
                  try {
                    company.comLogo = base64Decode(base64Logo);
                  } catch (e) {
                    company.comLogo = Uint8List(0);
                  }
                }
              }

              return BlocBuilder<BalanceSheetBloc, BalanceSheetState>(
                builder: (context, state) {
                  if (state is BalanceSheetLoaded) {
                    return ZOutlineButton(
                      width: 110,
                      icon: FontAwesomeIcons.solidFilePdf,
                      label: Text("PDF"),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => PrintPreviewDialog<BalanceSheetModel>(
                            data: state.data,
                            company: company,
                            buildPreview: ({
                              required data,
                              required language,
                              required orientation,
                              required pageFormat,
                            }) {
                              return BalanceSheetPrintSettings().printPreview(
                                company: company,
                                language: language,
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
                              return BalanceSheetPrintSettings().printDocument(
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
                              return BalanceSheetPrintSettings().createDocument(
                                company: company,
                                language: language,
                                orientation: orientation,
                                pageFormat: pageFormat,
                                data: data,
                              );
                            },
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: ZCover(
            radius: 8,
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(8),
            child: BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
              builder: (context, comState) {
                if (comState is CompanyProfileLoadedState) {
                  baseCurrency = comState.company.comLocalCcy;
                }

                return BlocBuilder<BalanceSheetBloc, BalanceSheetState>(
                  builder: (context, state) {
                    if (state is BalanceSheetLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is BalanceSheetError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      );
                    } else if (state is BalanceSheetLoaded) {
                      final data = state.data;
                      final t = AppLocalizations.of(context)!;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Assets
                            _buildMainTitle(context, t.assets),
                            _buildYearHeader(context, t),
                            ..._buildAssetSection(context, data.assets, baseCurrency, t),
                            const SizedBox(height: 16),

                            // Liabilities & Equity
                            _buildMainTitle(context, t.liabilitiesEquity),
                            ..._buildLiabilitySection(context, data.liability, baseCurrency, t),
                          ],
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Main section title (Assets / Liabilities & Equity)
  Widget _buildMainTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  // Year header with actual year numbers
  Widget _buildYearHeader(BuildContext context, AppLocalizations t) {
    final currentYear = DateTime.now().year;
    final lastYear = currentYear - 1;

    return Row(
      children: [
        Expanded(flex: 4, child: Container()),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.currentYear,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .8),
                ),
              ),
              Text(
                currentYear.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.lastYear,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .8),
                ),
              ),
              Text(
                lastYear.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Subsection title (grey)
  Widget _buildSubSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Format amounts with currency
  String formatNumber(double value, String? currency) {
    final formatter = NumberFormat("#,##0.00");
    return "${formatter.format(value)} ${currency ?? ''}";
  }

  // Build asset sections with totals
  List<Widget> _buildAssetSection(BuildContext context, Assets? assets, String? currency, AppLocalizations t) {
    if (assets == null) return [];

    final sections = <Widget>[];

    double totalCurrentAsset = 0;
    double totalFixedAsset = 0;
    double totalIntangibleAsset = 0;

    void addSection(String title, List<AssetItem>? items, void Function(double) addTotal) {
      if (items == null || items.isEmpty) return;

      sections.add(_buildSubSectionTitle(context, title));

      double sectionCurrentTotal = 0;
      double sectionLastTotal = 0;

      for (var item in items) {
        final lastYear = double.tryParse(item.lastYear ?? "0") ?? 0;
        final currentYear = double.tryParse(item.currentYear ?? "0") ?? 0;

        sectionCurrentTotal += currentYear;
        sectionLastTotal += lastYear;

        sections.add(_buildTableRow(context, item.accName ?? "", currentYear, lastYear, currency));
      }

      sections.add(_buildTotalRow(context, "${t.totalTitle} $title", sectionCurrentTotal, sectionLastTotal, currency));

      addTotal(sectionCurrentTotal);
    }

    addSection(t.currentAssets, assets.currentAsset, (val) => totalCurrentAsset = val);
    addSection(t.fixedAssets, assets.fixedAsset, (val) => totalFixedAsset = val);
    addSection(t.intangibleAssets, assets.intangibleAsset, (val) => totalIntangibleAsset = val);

    final totalAssetsCurrent = totalCurrentAsset + totalFixedAsset + totalIntangibleAsset;
    final totalAssetsLast = (assets.currentAsset?.fold<double>(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0)) ?? 0) +
        (assets.fixedAsset?.fold<double>(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0)) ?? 0) +
        (assets.intangibleAsset?.fold<double>(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0)) ?? 0);

    sections.add(_buildTotalRow(context, t.totalAssets, totalAssetsCurrent, totalAssetsLast, currency,
        foregroundColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.primary));

    return sections;
  }

  // Build liability & equity sections with totals
  List<Widget> _buildLiabilitySection(
      BuildContext context, Liability? liability, String? currency, AppLocalizations t) {
    if (liability == null) return [];

    final sections = <Widget>[];

    double totalCurrentLiability = 0;
    double totalOwnerEquity = 0;
    double totalStakeholders = 0;
    double totalNetProfit = 0;

    void addSection(String title, List<AssetItem>? items, void Function(double) addTotal) {
      if (items == null || items.isEmpty) return;

      sections.add(_buildSubSectionTitle(context, title));

      double sectionCurrentTotal = 0;
      double sectionLastTotal = 0;

      for (var item in items) {
        final lastYear = double.tryParse(item.lastYear ?? "0") ?? 0;
        final currentYear = double.tryParse(item.currentYear ?? "0") ?? 0;

        sectionCurrentTotal += currentYear;
        sectionLastTotal += lastYear;

        sections.add(_buildTableRow(context, item.accName ?? "", currentYear, lastYear, currency));
      }

      sections.add(_buildTotalRow(context, "${t.totalTitle} $title", sectionCurrentTotal, sectionLastTotal, currency));
      addTotal(sectionCurrentTotal);
    }

    addSection(t.currentLiabilities, liability.currentLiability, (val) => totalCurrentLiability = val);
    addSection(t.ownerEquity, liability.ownersEquity, (val) => totalOwnerEquity = val);
    addSection(t.stakeholders, liability.stakeholders, (val) => totalStakeholders = val);
    addSection(t.netProfit, liability.netProfit, (val) => totalNetProfit = val);

    final totalLiabilitiesEquityCurrent = totalCurrentLiability +
        totalOwnerEquity +
        totalStakeholders +
        totalNetProfit;

    final totalLiabilitiesEquityLast = (liability.currentLiability?.fold<double>(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0)) ?? 0) +
        (liability.ownersEquity?.fold<double>(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0)) ?? 0) +
        (liability.stakeholders?.fold<double>(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0)) ?? 0) +
        (liability.netProfit?.fold<double>(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0)) ?? 0);

    sections.add(_buildTotalRow(context, t.totalLiabilitiesEquity,
        foregroundColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.primary,
        totalLiabilitiesEquityCurrent, totalLiabilitiesEquityLast, currency));

    return sections;
  }

  // Individual row
  Widget _buildTableRow(BuildContext context, String name, double currentYear, double lastYear, String? currency) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(name)),
          Expanded(
            flex: 3,
            child: Text(
              formatNumber(currentYear, currency),
              textAlign: TextAlign.end,
              style: TextStyle(color: currentYear < 0 ? theme.colorScheme.error : theme.colorScheme.outline),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              formatNumber(lastYear, currency),
              textAlign: TextAlign.end,
              style: TextStyle(color: lastYear < 0 ? theme.colorScheme.error : theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  // Total row
  Widget _buildTotalRow(BuildContext context, String title, double currentTotal, double lastTotal, String? currency,
      {Color? backgroundColor, Color? foregroundColor}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest.withAlpha(128),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(title,
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: foregroundColor ?? Theme.of(context).colorScheme.onSurface))),
          Expanded(
            flex: 3,
            child: Text(
              formatNumber(currentTotal, currency),
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: currentTotal < 0 ? theme.colorScheme.error : foregroundColor ?? theme.colorScheme.primary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              formatNumber(lastTotal, currency),
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: lastTotal < 0 ? theme.colorScheme.error : foregroundColor ?? theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// Mobile Version
class _MobileBalanceSheet extends StatefulWidget {
  const _MobileBalanceSheet();

  @override
  State<_MobileBalanceSheet> createState() => _MobileBalanceSheetState();
}

class _MobileBalanceSheetState extends State<_MobileBalanceSheet> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalanceSheetBloc>().add(LoadBalanceSheet());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? baseCurrency;
    ReportModel company = ReportModel();
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.balanceSheet),
        actionsPadding: EdgeInsets.symmetric(horizontal: 8),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BalanceSheetBloc>().add(LoadBalanceSheet());
            },
          ),
          BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
            builder: (context, comState) {
              if (comState is CompanyProfileLoadedState) {
                baseCurrency = comState.company.comLocalCcy;
                company.comName = comState.company.comName ?? "";
                company.comAddress = comState.company.addName ?? "";
                company.compPhone = comState.company.comPhone ?? "";
                company.comEmail = comState.company.comEmail ?? "";
                company.statementDate = DateTime.now().toFullDateTime;
                company.baseCurrency = comState.company.comLocalCcy;

                final base64Logo = comState.company.comLogo;
                if (base64Logo != null && base64Logo.isNotEmpty) {
                  try {
                    company.comLogo = base64Decode(base64Logo);
                  } catch (e) {
                    company.comLogo = Uint8List(0);
                  }
                }
              }

              return BlocBuilder<BalanceSheetBloc, BalanceSheetState>(
                builder: (context, state) {
                  if (state is BalanceSheetLoaded) {
                    return IconButton(
                      icon: const Icon(FontAwesomeIcons.filePdf),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => PrintPreviewDialog<BalanceSheetModel>(
                            data: state.data,
                            company: company,
                            buildPreview: ({
                              required data,
                              required language,
                              required orientation,
                              required pageFormat,
                            }) {
                              return BalanceSheetPrintSettings().printPreview(
                                company: company,
                                language: language,
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
                              return BalanceSheetPrintSettings().printDocument(
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
                              return BalanceSheetPrintSettings().createDocument(
                                company: company,
                                language: language,
                                orientation: orientation,
                                pageFormat: pageFormat,
                                data: data,
                              );
                            },
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
        builder: (context, comState) {
          if (comState is CompanyProfileLoadedState) {
            baseCurrency = comState.company.comLocalCcy;
          }

          return BlocBuilder<BalanceSheetBloc, BalanceSheetState>(
            builder: (context, state) {
              if (state is BalanceSheetLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is BalanceSheetError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: color.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(color: color.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is BalanceSheetLoaded) {
                final data = state.data;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Assets Section
                      _buildMobileSectionTitle(context, tr.assets, color.primary),
                      const SizedBox(height: 8),
                      ..._buildMobileAssetSection(context, data.assets, baseCurrency, tr),

                      const SizedBox(height: 20),

                      // Liabilities & Equity Section
                      _buildMobileSectionTitle(context, tr.liabilitiesEquity, color.secondary),
                      const SizedBox(height: 8),
                      ..._buildMobileLiabilitySection(context, data.liability, baseCurrency, tr),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 64,
                        color: color.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr.noData,
                        style: TextStyle(color: color.outline),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMobileSectionTitle(BuildContext context, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_open,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSubSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  String formatNumber(double value, String? currency) {
    final formatter = NumberFormat("#,##0.00");
    return "${formatter.format(value)} ${currency ?? ''}";
  }

  List<Widget> _buildMobileAssetSection(BuildContext context, Assets? assets, String? currency, AppLocalizations t) {
    if (assets == null) return [];

    final sections = <Widget>[];
    double totalCurrentAsset = 0;
    double totalFixedAsset = 0;
    double totalIntangibleAsset = 0;

    void addSection(String title, List<AssetItem>? items, void Function(double) addTotal) {
      if (items == null || items.isEmpty) return;

      sections.add(_buildMobileSubSectionTitle(context, title));

      double sectionCurrentTotal = 0;

      for (var item in items) {
        final currentYear = double.tryParse(item.currentYear ?? "0") ?? 0;
        sectionCurrentTotal += currentYear;

        sections.add(_buildMobileItemCard(context, item.accName ?? "", currentYear, currency));
      }

      sections.add(_buildMobileTotalRow(context, "${t.totalTitle} $title", sectionCurrentTotal, currency));
      addTotal(sectionCurrentTotal);
    }

    addSection(t.currentAssets, assets.currentAsset, (val) => totalCurrentAsset = val);
    addSection(t.fixedAssets, assets.fixedAsset, (val) => totalFixedAsset = val);
    addSection(t.intangibleAssets, assets.intangibleAsset, (val) => totalIntangibleAsset = val);

    final totalAssetsCurrent = totalCurrentAsset + totalFixedAsset + totalIntangibleAsset;

    sections.add(_buildMobileGrandTotalRow(context, t.totalAssets, totalAssetsCurrent, currency));

    return sections;
  }

  List<Widget> _buildMobileLiabilitySection(BuildContext context, Liability? liability, String? currency, AppLocalizations t) {
    if (liability == null) return [];

    final sections = <Widget>[];
    double totalCurrentLiability = 0;
    double totalOwnerEquity = 0;
    double totalStakeholders = 0;
    double totalNetProfit = 0;

    void addSection(String title, List<AssetItem>? items, void Function(double) addTotal) {
      if (items == null || items.isEmpty) return;

      sections.add(_buildMobileSubSectionTitle(context, title));

      double sectionCurrentTotal = 0;

      for (var item in items) {
        final currentYear = double.tryParse(item.currentYear ?? "0") ?? 0;
        sectionCurrentTotal += currentYear;

        sections.add(_buildMobileItemCard(context, item.accName ?? "", currentYear, currency));
      }

      sections.add(_buildMobileTotalRow(context, "${t.totalTitle} $title", sectionCurrentTotal, currency));
      addTotal(sectionCurrentTotal);
    }

    addSection(t.currentLiabilities, liability.currentLiability, (val) => totalCurrentLiability = val);
    addSection(t.ownerEquity, liability.ownersEquity, (val) => totalOwnerEquity = val);
    addSection(t.stakeholders, liability.stakeholders, (val) => totalStakeholders = val);
    addSection(t.netProfit, liability.netProfit, (val) => totalNetProfit = val);

    final totalLiabilitiesEquityCurrent = totalCurrentLiability + totalOwnerEquity + totalStakeholders + totalNetProfit;

    sections.add(_buildMobileGrandTotalRow(context, t.totalLiabilitiesEquity, totalLiabilitiesEquityCurrent, currency));

    return sections;
  }

  Widget _buildMobileItemCard(BuildContext context, String name, double amount, String? currency) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.outline.withValues(alpha: .1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: amount >= 0 ? Colors.green.withValues(alpha: .1) : color.error.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              formatNumber(amount, currency),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: amount >= 0 ? Colors.green : color.error,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTotalRow(BuildContext context, String title, double amount, String? currency) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color.outline,
            ),
          ),
          Text(
            formatNumber(amount, currency),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileGrandTotalRow(BuildContext context, String title, double amount, String? currency) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.primary.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.primary,
              fontSize: 16,
            ),
          ),
          Text(
            formatNumber(amount, currency),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.primary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// Tablet Version
class _TabletBalanceSheet extends StatefulWidget {
  const _TabletBalanceSheet();

  @override
  State<_TabletBalanceSheet> createState() => _TabletBalanceSheetState();
}

class _TabletBalanceSheetState extends State<_TabletBalanceSheet> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BalanceSheetBloc>().add(LoadBalanceSheet());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? baseCurrency;
    ReportModel company = ReportModel();
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.balanceSheet),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BalanceSheetBloc>().add(LoadBalanceSheet());
            },
          ),
          BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
            builder: (context, comState) {
              if (comState is CompanyProfileLoadedState) {
                baseCurrency = comState.company.comLocalCcy;
                company.comName = comState.company.comName ?? "";
                company.comAddress = comState.company.addName ?? "";
                company.compPhone = comState.company.comPhone ?? "";
                company.comEmail = comState.company.comEmail ?? "";
                company.statementDate = DateTime.now().toFullDateTime;
                company.baseCurrency = comState.company.comLocalCcy;

                final base64Logo = comState.company.comLogo;
                if (base64Logo != null && base64Logo.isNotEmpty) {
                  try {
                    company.comLogo = base64Decode(base64Logo);
                  } catch (e) {
                    company.comLogo = Uint8List(0);
                  }
                }
              }

              return BlocBuilder<BalanceSheetBloc, BalanceSheetState>(
                builder: (context, state) {
                  if (state is BalanceSheetLoaded) {
                    return IconButton(
                      icon: const Icon(FontAwesomeIcons.filePdf),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => PrintPreviewDialog<BalanceSheetModel>(
                            data: state.data,
                            company: company,
                            buildPreview: ({
                              required data,
                              required language,
                              required orientation,
                              required pageFormat,
                            }) {
                              return BalanceSheetPrintSettings().printPreview(
                                company: company,
                                language: language,
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
                              return BalanceSheetPrintSettings().printDocument(
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
                              return BalanceSheetPrintSettings().createDocument(
                                company: company,
                                language: language,
                                orientation: orientation,
                                pageFormat: pageFormat,
                                data: data,
                              );
                            },
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
        builder: (context, comState) {
          if (comState is CompanyProfileLoadedState) {
            baseCurrency = comState.company.comLocalCcy;
          }

          return BlocBuilder<BalanceSheetBloc, BalanceSheetState>(
            builder: (context, state) {
              if (state is BalanceSheetLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is BalanceSheetError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: color.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(color: color.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is BalanceSheetLoaded) {
                final data = state.data;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assets Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTabletSectionHeader(context, tr.assets, color.primary),
                            const SizedBox(height: 12),
                            ..._buildTabletAssetSection(context, data.assets, baseCurrency, tr),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Liabilities Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTabletSectionHeader(context, tr.liabilitiesEquity, color.secondary),
                            const SizedBox(height: 12),
                            ..._buildTabletLiabilitySection(context, data.liability, baseCurrency, tr),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 80,
                        color: color.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr.noData,
                        style: TextStyle(color: color.outline),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildTabletSectionHeader(BuildContext context, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_open,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String formatNumber(double value, String? currency) {
    final formatter = NumberFormat("#,##0.00");
    return "${formatter.format(value)} ${currency ?? ''}";
  }

  List<Widget> _buildTabletAssetSection(BuildContext context, Assets? assets, String? currency, AppLocalizations t) {
    if (assets == null) return [];

    final sections = <Widget>[];
    double totalCurrentAsset = 0;
    double totalFixedAsset = 0;
    double totalIntangibleAsset = 0;

    void addSection(String title, List<AssetItem>? items, void Function(double) addTotal) {
      if (items == null || items.isEmpty) return;

      sections.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );

      double sectionCurrentTotal = 0;

      for (var item in items) {
        final currentYear = double.tryParse(item.currentYear ?? "0") ?? 0;
        sectionCurrentTotal += currentYear;

        sections.add(_buildTabletItemRow(context, item.accName ?? "", currentYear, currency));
      }

      sections.add(_buildTabletTotalRow(context, "${t.totalTitle} $title", sectionCurrentTotal, currency));
      addTotal(sectionCurrentTotal);
    }

    addSection(t.currentAssets, assets.currentAsset, (val) => totalCurrentAsset = val);
    addSection(t.fixedAssets, assets.fixedAsset, (val) => totalFixedAsset = val);
    addSection(t.intangibleAssets, assets.intangibleAsset, (val) => totalIntangibleAsset = val);

    final totalAssetsCurrent = totalCurrentAsset + totalFixedAsset + totalIntangibleAsset;

    sections.add(_buildTabletGrandTotalRow(context, t.totalAssets, totalAssetsCurrent, currency));

    return sections;
  }

  List<Widget> _buildTabletLiabilitySection(BuildContext context, Liability? liability, String? currency, AppLocalizations t) {
    if (liability == null) return [];

    final sections = <Widget>[];
    double totalCurrentLiability = 0;
    double totalOwnerEquity = 0;
    double totalStakeholders = 0;
    double totalNetProfit = 0;

    void addSection(String title, List<AssetItem>? items, void Function(double) addTotal) {
      if (items == null || items.isEmpty) return;

      sections.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );

      double sectionCurrentTotal = 0;

      for (var item in items) {
        final currentYear = double.tryParse(item.currentYear ?? "0") ?? 0;
        sectionCurrentTotal += currentYear;

        sections.add(_buildTabletItemRow(context, item.accName ?? "", currentYear, currency));
      }

      sections.add(_buildTabletTotalRow(context, "${t.totalTitle} $title", sectionCurrentTotal, currency));
      addTotal(sectionCurrentTotal);
    }

    addSection(t.currentLiabilities, liability.currentLiability, (val) => totalCurrentLiability = val);
    addSection(t.ownerEquity, liability.ownersEquity, (val) => totalOwnerEquity = val);
    addSection(t.stakeholders, liability.stakeholders, (val) => totalStakeholders = val);
    addSection(t.netProfit, liability.netProfit, (val) => totalNetProfit = val);

    final totalLiabilitiesEquityCurrent = totalCurrentLiability + totalOwnerEquity + totalStakeholders + totalNetProfit;

    sections.add(_buildTabletGrandTotalRow(context, t.totalLiabilitiesEquity, totalLiabilitiesEquityCurrent, currency));

    return sections;
  }

  Widget _buildTabletItemRow(BuildContext context, String name, double amount, String? currency) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: amount >= 0 ? Colors.green.withValues(alpha: .05) : color.error.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              formatNumber(amount, currency),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: amount >= 0 ? Colors.green : color.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletTotalRow(BuildContext context, String title, double amount, String? currency) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color.outline.withValues(alpha: .2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color.outline,
              fontSize: 13,
            ),
          ),
          Text(
            formatNumber(amount, currency),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletGrandTotalRow(BuildContext context, String title, double amount, String? currency) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.primary,
              fontSize: 14,
            ),
          ),
          Text(
            formatNumber(amount, currency),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.primary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}