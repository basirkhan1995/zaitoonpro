import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Features/Widgets/txn_status_widget.dart';
import 'package:zaitoon_petroleum/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/ProjectsById/bloc/projects_by_id_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/ProjectsById/model/project_by_id_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/bloc/project_tabs_bloc.dart';
import '../../../../../Features/Generic/tab_bar.dart';
import '../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../Features/PrintSettings/report_model.dart';
import '../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'Print/print.dart';

class ProjectsByIdView extends StatelessWidget {
  final int projectId;

  const ProjectsByIdView({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(projectId: projectId),
      desktop: _Desktop(projectId: projectId),
      tablet: _Tablet(projectId: projectId),
    );
  }
}

class _Mobile extends StatelessWidget {
  final int projectId;

  const _Mobile({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return _ProjectByIdContent(projectId: projectId);
  }
}

class _Tablet extends StatelessWidget {
  final int projectId;

  const _Tablet({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return _ProjectByIdContent(projectId: projectId);
  }
}

class _Desktop extends StatelessWidget {
  final int projectId;

  const _Desktop({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return _ProjectByIdContent(projectId: projectId);
  }
}

class _ProjectByIdContent extends StatefulWidget {
  final int projectId;

  const _ProjectByIdContent({required this.projectId});

  @override
  State<_ProjectByIdContent> createState() => _ProjectByIdContentState();
}

class _ProjectByIdContentState extends State<_ProjectByIdContent> {
  String? myLocale;

  @override
  void initState() {
    super.initState();
    myLocale = context.read<LocalizationBloc>().state.languageCode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProjectsByIdBloc>().add(
        LoadProjectByIdEvent(widget.projectId),
      );
    });
  }
  void _showPrintDialog(BuildContext context, ProjectByIdModel project) {
    final company = ReportModel();

    showDialog(
      context: context,
      builder: (_) => BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
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
                company.comLogo = base64Decode(base64Logo);
              } catch (e) {
                company.comLogo = Uint8List(0);
              }
            }
          }

          return PrintPreviewDialog<ProjectByIdModel>(
            data: project,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return ProjectByIdPrintSettings().printPreview(
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
              return ProjectByIdPrintSettings().printDocument(
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
              return ProjectByIdPrintSettings().createDocument(
                data: data,
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
              );
            },
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: BlocBuilder<ProjectsByIdBloc, ProjectsByIdState>(
          builder: (context, state) {
            if (state is ProjectByIdLoadedState) {
              return Text(state.project.prjName ?? tr.details);
            }
            return Text(tr.details);
          },
        ),
        actions: [
          BlocBuilder<ProjectsByIdBloc, ProjectsByIdState>(
            builder: (context, state) {
              if (state is ProjectByIdLoadedState) {
                return IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () => _showPrintDialog(context, state.project),
                  tooltip: tr.print,
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocBuilder<ProjectsByIdBloc, ProjectsByIdState>(
        builder: (context, state) {
          if (state is ProjectByIdLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectByIdErrorState) {
            return NoDataWidget(
              title: tr.errorTitle,
              message: state.message,
              onRefresh: () {
                context.read<ProjectsByIdBloc>().add(
                  LoadProjectByIdEvent(widget.projectId),
                );
              },
            );
          }

          if (state is ProjectByIdLoadedState) {
            final project = state.project;
            final isDesktop = ResponsiveLayout.isDesktop(context);

            return BlocBuilder<ProjectTabsBloc, ProjectTabsState>(
              builder: (context, tabState) {
                final tabs = <ZTabItem<ProjectTabsName>>[
                  ZTabItem(
                    value: ProjectTabsName.overview,
                    label: tr.overview,
                    screen: _buildOverviewTab(context, project, isDesktop),
                  ),
                  ZTabItem(
                    value: ProjectTabsName.services,
                    label: tr.services,
                    screen: _buildServicesTab(context, project, isDesktop),
                  ),
                  ZTabItem(
                    value: ProjectTabsName.incomeExpense,
                    label: tr.incomeAndExpenses,
                    screen: _buildIncomeExpenseTab(context, project, isDesktop),
                  ),
                ];

                final available = tabs.map((t) => t.value).toList();
                final selected = available.contains(tabState.tabs)
                    ? tabState.tabs
                    : tabs.first.value;

                return ZTabContainer<ProjectTabsName>(
                  tabs: tabs,
                  selectedValue: selected,
                  onChanged: (val) => context.read<ProjectTabsBloc>().add(ProjectTabOnChangedEvent(val)),
                  style: ZTabStyle.rounded,
                  tabBarPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  borderRadius: 0,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  unselectedTextColor: Theme.of(context).colorScheme.onSurface,
                  selectedTextColor: Theme.of(context).colorScheme.surface,
                  tabContainerColor: Theme.of(context).colorScheme.surface,
                  margin: const EdgeInsets.all(0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );

  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab(BuildContext context, ProjectByIdModel project, bool isDesktop) {
    if (isDesktop) {
      return _buildOverviewTabDesktop(context, project);
    }
    return _buildOverviewTabMobile(context, project);
  }

  Widget _buildOverviewTabMobile(BuildContext context, ProjectByIdModel project) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMobileSummaryCard(
                  context,
                  title: tr.services,
                  value: project.projectServices?.length.toString() ?? '0',
                  icon: Icons.build,
                  color: color.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileSummaryCard(
                  context,
                  title: tr.transactions,
                  value: project.projectPayments?.length.toString() ?? '0',
                  icon: Icons.payment,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMobileInfoSection(
            context,
            title: tr.projectInformation,
            children: [
              _buildMobileInfoRow(tr.projectName, project.prjName ?? '-'),
              _buildMobileInfoRow(tr.details, project.prjDetails ?? '-', isMultiline: true),
              _buildMobileInfoRow(tr.location, project.prjLocation ?? '-'),
              _buildMobileInfoRow(tr.deadline, project.prjDateLine?.toFormattedDate() ?? '-'),
              _buildMobileInfoRow(tr.entryDate, project.prjEntryDate?.toFormattedDate() ?? '-'),
              _buildMobileStatusRow(tr.status, project.prjStatus == 0 ? tr.inProgress : tr.completed, isActive: project.prjStatus == 0),
            ],
          ),
          const SizedBox(height: 12),
          _buildMobileInfoSection(
            context,
            title: tr.ownerInformation,
            children: [
              _buildMobileInfoRow(tr.clientTitle, project.prjOwnerfullName ?? '-'),
              _buildMobileInfoRow(tr.accountNumber, project.prjOwnerAccount?.toString() ?? '-'),
              _buildMobileInfoRow(tr.currencyTitle, project.actCurrency ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTabDesktop(BuildContext context, ProjectByIdModel project) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards in a Row
          Row(
            children: [
              Expanded(
                child: _buildDesktopSummaryCard(
                  context,
                  title: tr.totalServices,
                  value: project.projectServices?.length.toString() ?? '0',
                  subtitle: tr.activeServices,
                  icon: Icons.build,
                  color: color.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDesktopSummaryCard(
                  context,
                  title: tr.totalTransactions,
                  value: project.projectPayments?.length.toString() ?? '0',
                  subtitle: tr.incomeAndExpenses,
                  icon: Icons.payment,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDesktopSummaryCard(
                  context,
                  title: tr.projectStatus,
                  value: project.prjStatus == 0 ? tr.inProgress : tr.completed,
                  subtitle: tr.currentPhase,
                  icon: Icons.assessment,
                  color: project.prjStatus == 0 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Two Column Layout for Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Project Information
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.outline.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.info_outline, color: color.primary),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tr.projectInformation,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      _buildDesktopInfoRow(tr.projectName, project.prjName ?? '-'),
                      _buildDesktopInfoRow(tr.details, project.prjDetails ?? '-', isMultiline: true),
                      _buildDesktopInfoRow(tr.location, project.prjLocation ?? '-'),
                      _buildDesktopInfoRow(tr.deadline, project.prjDateLine?.toFormattedDate() ?? '-'),
                      _buildDesktopInfoRow(tr.entryDate, project.prjEntryDate?.toFormattedDate() ?? '-'),
                      _buildDesktopInfoRow(
                        tr.status,
                        project.prjStatus == 0 ? tr.inProgress : tr.completed,
                        isStatus: true,
                        statusColor: project.prjStatus == 0 ? Colors.orange : Colors.green,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Right Column - Owner Information
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.outline.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.person_outline, color: color.primary),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tr.ownerInformation,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      _buildDesktopInfoRow(tr.clientTitle, project.prjOwnerfullName ?? '-'),
                      _buildDesktopInfoRow(tr.accountNumber, project.prjOwnerAccount?.toString() ?? '-'),
                      _buildDesktopInfoRow(tr.currencyTitle, project.actCurrency ?? '-'),

                      const SizedBox(height: 30),

                      // Additional Stats
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDesktopStatRow(
                              tr.totalServicesValue,
                              _calculateTotalServices(project).toAmount(),
                              project.actCurrency ?? '',
                              color.primary,
                            ),
                            const Divider(height: 16),
                            _buildDesktopStatRow(
                              tr.totalPayment,
                              _calculateTotalPayments(project).toAmount(),
                              project.actCurrency ?? '',
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SERVICES TAB ====================
  Widget _buildServicesTab(BuildContext context, ProjectByIdModel project, bool isDesktop) {
    if (isDesktop) {
      return _buildServicesTabDesktop(context, project);
    }
    return _buildServicesTabMobile(context, project);
  }

  Widget _buildServicesTabMobile(BuildContext context, ProjectByIdModel project) {
    final services = project.projectServices ?? [];

    if (services.isEmpty) {
      return NoDataWidget(
        title: AppLocalizations.of(context)!.noServicesTitle,
        message: AppLocalizations.of(context)!.noServicesMessage,
        enableAction: false,
      );
    }

    double totalSum = 0;
    for (var service in services) {
      totalSum += double.tryParse(service.total ?? '0') ?? 0;
    }

    return Column(
      children: [
        _buildMobileTotalCard(
          context,
          count: services.length,
          totalAmount: totalSum,
          currency: project.actCurrency ?? '',
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildMobileServiceCard(context, service, index, project.actCurrency ?? '');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTabDesktop(BuildContext context, ProjectByIdModel project) {
    final services = project.projectServices ?? [];
    final currency = project.actCurrency ?? '';
    final tr = AppLocalizations.of(context)!;
    if (services.isEmpty) {
      return Center(
        child: NoDataWidget(
          title: tr.noServicesTitle,
          message: tr.noServicesMessage,
          enableAction: false,
        ),
      );
    }

    double totalSum = 0;
    for (var service in services) {
      totalSum += double.tryParse(service.total ?? '0') ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: .8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.totalServices,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      services.length.toString(),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.totalAmount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${totalSum.toAmount()} $currency',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Services Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40), // Index
                Expanded(flex: 3, child: _buildHeaderText(context, tr.serviceName)),
                Expanded(flex: 2, child: _buildHeaderText(context, tr.qty)),
                Expanded(flex: 2, child: _buildHeaderText(context, tr.unitPrice)),
                Expanded(flex: 2, child: _buildHeaderText(context, tr.totalTitle)),
                Expanded(flex: 2, child: _buildHeaderText(context, tr.referenceNumber)),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: ListView.builder(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  final quantity = double.tryParse(service.pjdQuantity ?? '0') ?? 0;
                  final price = double.tryParse(service.pjdPricePerQty ?? '0') ?? 0;
                  final total = double.tryParse(service.total ?? '0') ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                        ),
                      ),
                      color: index.isOdd
                          ? Theme.of(context).colorScheme.surface.withValues(alpha: .02)
                          : Colors.transparent,
                    ),
                    child: InkWell(
                      onTap: () {
                        // Handle service tap
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${index + 1}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.srvName ?? 'Service',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (service.pjdRemark?.isNotEmpty ?? false)
                                    Text(
                                      service.pjdRemark!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(flex: 2, child: Text(quantity.toString())),
                            Expanded(flex: 2, child: Text('${price.toAmount()} $currency')),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${total.toAmount()} $currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                service.prpTrnRef ?? '-',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INCOME/EXPENSE TAB ====================
  Widget _buildIncomeExpenseTab(BuildContext context, ProjectByIdModel project, bool isDesktop) {
    if (isDesktop) {
      return _buildIncomeExpenseTabDesktop(context, project);
    }
    return _buildIncomeExpenseTabMobile(context, project);
  }

  Widget _buildIncomeExpenseTabMobile(BuildContext context, ProjectByIdModel project) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final payments = project.projectPayments ?? [];
    final services = project.projectServices ?? [];

    if (payments.isEmpty) {
      return NoDataWidget(
        title: "No Transactions",
        message: "No income or expense records found",
        enableAction: false,
      );
    }

    double totalIncome = 0;
    double totalExpense = 0;
    double totalServicesAmount = 0;

    for (var service in services) {
      totalServicesAmount += double.tryParse(service.total ?? '0') ?? 0;
    }

    for (var payment in payments) {
      if (payment.prpType == 'Payment') {
        totalIncome += double.tryParse(payment.payments ?? '0') ?? 0;
      } else if (payment.prpType == 'Expense') {
        totalExpense += double.tryParse(payment.expenses ?? '0') ?? 0;
      }
    }

    final balance = totalIncome - totalExpense;
    final currency = project.actCurrency ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              _buildMobileFinancialCard(
                context,
                title: tr.services,
                amount: totalServicesAmount,
                currency: currency,
                color: color.primary,
                icon: Icons.build,
              ),
              _buildMobileFinancialCard(
                context,
                title: tr.payment,
                amount: totalIncome,
                currency: currency,
                color: Colors.green,
                icon: Icons.arrow_downward,
              ),
              _buildMobileFinancialCard(
                context,
                title: tr.expense,
                amount: totalExpense,
                currency: currency,
                color: color.error,
                icon: Icons.arrow_upward,
              ),
              _buildMobileFinancialCard(
                context,
                title: tr.balance,
                amount: balance,
                currency: currency,
                color: balance >= 0 ? Colors.blue : Colors.orange,
                icon: Icons.account_balance_wallet,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildMobileTransactionCard(context, payment, index, currency);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseTabDesktop(BuildContext context, ProjectByIdModel project) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final payments = project.projectPayments ?? [];
    final services = project.projectServices ?? [];

    if (payments.isEmpty) {
      return Center(
        child: NoDataWidget(
          title: "No Transactions",
          message: "No income or expense records found",
          enableAction: false,
        ),
      );
    }

    double totalIncome = 0;
    double totalExpense = 0;
    double totalServicesAmount = 0;

    for (var service in services) {
      totalServicesAmount += double.tryParse(service.total ?? '0') ?? 0;
    }

    for (var payment in payments) {
      if (payment.prpType == 'Payment') {
        totalIncome += double.tryParse(payment.payments ?? '0') ?? 0;
      } else if (payment.prpType == 'Expense') {
        totalExpense += double.tryParse(payment.expenses ?? '0') ?? 0;
      }
    }

    final balance = totalIncome - totalExpense;
    final currency = project.actCurrency ?? '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildDesktopFinancialCard(
                  context,
                  title: tr.totalServicesValue,
                  amount: totalServicesAmount,
                  currency: currency,
                  color: color.primary,
                  icon: Icons.build,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesktopFinancialCard(
                  context,
                  title: tr.payment,
                  amount: totalIncome,
                  currency: currency,
                  color: Colors.green,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesktopFinancialCard(
                  context,
                  title: tr.expense,
                  amount: totalExpense,
                  currency: currency,
                  color: color.error,
                  icon: Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesktopFinancialCard(
                  context,
                  title: tr.balance,
                  amount: balance,
                  currency: currency,
                  color: balance >= 0 ? Colors.blue : Colors.orange,
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Transactions Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: color.outline.withValues(alpha: .2)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40), // For index
                Expanded(flex: 2, child: _buildHeaderText(context, tr.date)),
                Expanded(flex: 3, child: _buildHeaderText(context, tr.referenceNumber)),
                Expanded(flex: 2, child: _buildHeaderText(context, tr.txnType)),
                Expanded(flex: 2, child: _buildHeaderText(context, tr.amount)),
                Expanded(flex: 2, child: _buildHeaderText(context, tr.currencyTitle)),
                Expanded(flex: 2, child: _buildHeaderText(context, tr.status)),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: color.outline.withValues(alpha: .2)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: ListView.builder(
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  final isPayment = payment.prpType == 'Payment';
                  final isExpense = payment.prpType == 'Expense';
                  final amount = double.tryParse(
                      isPayment ? payment.payments ?? '0' : payment.expenses ?? '0'
                  ) ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: color.outline.withValues(alpha: .1),
                        ),
                      ),
                      color: index.isOdd
                          ? color.surface.withValues(alpha: .02)
                          : Colors.transparent,
                    ),
                    child: InkWell(
                      onTap: () {
                        // Handle transaction tap
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${index + 1}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.outline,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                payment.trnEntryDate?.toFormattedDate() ?? '-',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                payment.prpTrnRef ?? '-',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPayment
                                      ? Colors.green.withValues(alpha: .1)
                                      : isExpense
                                      ? color.error.withValues(alpha: .1)
                                      : Colors.grey.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPayment
                                      ? tr.payment
                                      : isExpense
                                      ? tr.expense
                                      : payment.prpType ?? '-',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isPayment
                                        ? Colors.green
                                        : isExpense
                                        ? color.error
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                amount.toAmount(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isPayment
                                      ? Colors.green
                                      : isExpense
                                      ? color.error
                                      : color.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                currency,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TransactionStatusBadge(
                                status: payment.trnStateText ?? "",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP COMPONENTS ====================

  Widget _buildDesktopSummaryCard(BuildContext context,
      {required String title, required String value, required String subtitle,
        required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: .7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFinancialCard(BuildContext context,
      {required String title, required double amount, required String currency,
        required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${amount.toAmount()} $currency',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoRow(String label, String value,
      {bool isMultiline = false, bool isStatus = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (statusColor ?? Colors.green).withValues(alpha: .1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: statusColor ?? Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                : Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: isMultiline ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStatRow(String label, String amount, String currency, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '$amount $currency',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // ==================== MOBILE COMPONENTS (Keep existing) ====================

  Widget _buildMobileSummaryCard(BuildContext context,
      {required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: isMultiline ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatusRow(String label, String value, {required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.orange.withValues(alpha: .1)
                  : Colors.green.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTotalCard(BuildContext context,
      {required int count, required double totalAmount, required String currency}) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.primaryContainer,
            color.primary.withValues(alpha: .1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.primary.withValues(alpha: .1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Services",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.onPrimaryContainer.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.list_alt, size: 16, color: color.primary),
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Total Amount",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.onPrimaryContainer.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: color.primary),
                  Text(
                    "${totalAmount.toAmount()} $currency",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileServiceCard(BuildContext context,
      dynamic service, int index, String currency) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outline.withValues(alpha: .1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  service.srvName ?? 'Service',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ref: ${service.prpTrnRef ?? ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.primary,
                  ),
                ),
              ),
            ],
          ),
          if (service.pjdRemark?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              service.pjdRemark!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.onSurface.withValues(alpha: .6),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  label: AppLocalizations.of(context)!.qty,
                  value: service.pjdQuantity?.toString() ?? '0',
                  icon: Icons.format_list_numbered,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  context,
                  label: AppLocalizations.of(context)!.unitPrice,
                  value: (double.tryParse(service.pjdPricePerQty ?? '0') ?? 0).toAmount(),
                  icon: Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  context,
                  label: AppLocalizations.of(context)!.totalTitle,
                  value: (double.tryParse(service.total ?? '0') ?? 0).toAmount(),
                  icon: Icons.calculate,
                  isHighlighted: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFinancialCard(BuildContext context,
      {required String title, required double amount, required String currency,
        required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toAmount()} $currency',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransactionCard(BuildContext context,
      dynamic payment, int index, String currency) {
    final color = Theme.of(context).colorScheme;
    final isPayment = payment.prpType == 'Payment';
    final isExpense = payment.prpType == 'Expense';
    final amount = double.tryParse(isPayment ? payment.payments ?? '0' : payment.expenses ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outline.withValues(alpha: .1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.trnEntryDate != null
                      ? '${payment.trnEntryDate!.day}/${payment.trnEntryDate!.month}'
                      : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.prpTrnRef ?? 'No Reference',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TransactionStatusBadge(
                status: payment.trnStateText ?? "",
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isPayment
                          ? Colors.green.withValues(alpha: .1)
                          : isExpense
                          ? color.error.withValues(alpha: .1)
                          : Colors.grey.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPayment
                          ? Icons.arrow_downward
                          : isExpense
                          ? Icons.arrow_upward
                          : Icons.swap_horiz,
                      size: 12,
                      color: isPayment
                          ? Colors.green
                          : isExpense
                          ? color.error
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPayment ? "Payment" : isExpense ? "Expense" : payment.prpType ?? "",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPayment
                          ? Colors.green
                          : isExpense
                          ? color.error
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              Text(
                '${amount.toAmount()} $currency',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPayment ? Colors.green : color.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context,
      {required String label, required String value, required IconData icon, bool isHighlighted = false}) {
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: isHighlighted ? color.primary : color.outline),
              const SizedBox(width: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: isHighlighted ? color.primary : color.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? color.primary : color.onSurface,
              fontSize: isHighlighted ? 14 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  double _calculateTotalServices(ProjectByIdModel project) {
    double total = 0;
    for (var service in project.projectServices ?? []) {
      total += double.tryParse(service.total ?? '0') ?? 0;
    }
    return total;
  }

  double _calculateTotalPayments(ProjectByIdModel project) {
    double total = 0;
    for (var payment in project.projectPayments ?? []) {
      if (payment.prpType == 'Payment') {
        total += double.tryParse(payment.payments ?? '0') ?? 0;
      }
    }
    return total;
  }
}