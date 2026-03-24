import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import '../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../UserReport/status_drop.dart';
import 'bloc/accounts_report_bloc.dart';

class AccountsReportView extends StatelessWidget {
  const AccountsReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _Mobile(),
      desktop: const _Desktop(),
      tablet: const _Tablet(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  String? ccy;
  int? status;
  double? limit;
  final accountLimit = TextEditingController();
  final searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsReportBloc>().add(ResetAccountsReportEvent());
    });
    super.initState();
  }

  void _showFilterSheet() {
    final tr = AppLocalizations.of(context)!;

    // Create local controllers to avoid affecting main controllers until apply
    final tempSearchController = TextEditingController(text: searchController.text);
    final tempAccountLimitController = TextEditingController(text: accountLimit.text);
    String? tempCcy = ccy;
    int? tempStatus = status;
    double? tempLimit = limit;

    ZDraggableSheet.show(
      context: context,
      title: tr.filterTitle,
      showCloseButton: false,
      showDragHandle: true,

      bodyBuilder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          children: [
            const SizedBox(height: 5),
            // Search Field
            ZTextFieldEntitled(
              onChanged: (e) {},
              controller: tempSearchController,
              title: "Search by Account Name",
            ),
            const SizedBox(height: 16),

            // Currency Dropdown
            CurrencyDropdown(
              flag: true,
              isMulti: false,
              title: tr.currencyTitle,
              onMultiChanged: (e) {},
              onSingleChanged: (e) {
                tempCcy = e?.ccyCode ?? "";
              },
            ),
            const SizedBox(height: 16),

            // Status Dropdown
            StatusDropdown(
              onChanged: (e) {
                tempStatus = e;
              },
            ),
            const SizedBox(height: 16),
            // Account Limit Field
            ZTextFieldEntitled(
              inputFormat: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (e) {
                tempLimit = double.tryParse(e);
              },
              controller: tempAccountLimitController,
              title: tr.accountLimit,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    height: 47,
                    icon: Icons.filter_alt_off_outlined,
                    onPressed: () {
                      tempSearchController.clear();
                      tempAccountLimitController.clear();
                      tempCcy = null;
                      tempStatus = null;
                      tempLimit = null;
                      setState(() {});
                    },
                    label: Text(tr.clearFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZOutlineButton(
                    height: 47,
                    isActive: true,
                    icon: Icons.filter_alt_outlined,
                    onPressed: () {
                      // Apply filters
                      setState(() {
                        ccy = tempCcy;
                        status = tempStatus;
                        limit = tempLimit;
                        searchController.text = tempSearchController.text;
                        accountLimit.text = tempAccountLimitController.text;
                      });

                      context.read<AccountsReportBloc>().add(
                        LoadAccountsReportEvent(
                          status: tempStatus,
                          currency: tempCcy,
                          limit: tempLimit ?? 0.0,
                          search: tempSearchController.text,
                        ),
                      );

                      Navigator.pop(context);
                    },
                    label: Text(tr.applyFilter),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("Accounts Report"),
        actions: [
          // Filter button in app bar
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          // Clear filters button (only shown if filters are applied)
          if (ccy != null || status != null || limit != null || searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                setState(() {
                  ccy = null;
                  status = null;
                  limit = null;
                  searchController.clear();
                  accountLimit.clear();
                });
                context.read<AccountsReportBloc>().add(
                  LoadAccountsReportEvent(),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Active filters indicator
          if (ccy != null || status != null || limit != null || searchController.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: color.primaryContainer,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(Icons.filter_alt, size: 16, color: color.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      tr.activeFilters,
                      style: TextStyle(color: color.onPrimaryContainer),
                    ),
                    const SizedBox(width: 8),
                    if (searchController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "${tr.search}: ${searchController.text}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (limit != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "${tr.accountLimit}: ${limit!.toAmount()}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (ccy != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "${tr.currencyTitle}: $ccy",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "${tr.status}: ${status == 1 ? tr.active : tr.blocked}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),


          // List with MobileInfoCard
          Expanded(
            child: BlocBuilder<AccountsReportBloc, AccountsReportState>(
              builder: (context, state) {
                if(state is AccountsReportInitial){
                  return NoDataWidget(
                    title: "Accounts Report",
                    message: "Apply filters to see accounts",
                    enableAction: false,
                  );
                }
                if (state is AccountsReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AccountsReportErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is AccountsReportLoadedState) {
                  if (state.accounts.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      onRefresh: () {
                        context.read<AccountsReportBloc>().add(
                          LoadAccountsReportEvent(),
                        );
                      },
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.accounts.length,
                    itemBuilder: (context, index) {
                      final acc = state.accounts[index];

                      // Create info items for the card
                      final infoItems = [
                        MobileInfoItem(
                          icon: Icons.account_balance_wallet,
                          text: acc.creditLimit.toAmount(),
                        ),
                        MobileInfoItem(
                          icon: Icons.business,
                          text: acc.accNumber.toString(),
                        ),
                        MobileInfoItem(
                          icon: Icons.currency_exchange,
                          text: acc.ccyName ?? '',
                        ),
                      ];

                      // Create status for the card
                      final accountStatus = MobileStatus(
                        label: acc.status == "Active" ? tr.active : tr.blocked,
                        color: acc.status == "Active"
                            ? Colors.green
                            : Colors.red,
                        backgroundColor: acc.status == "Active"
                            ? Colors.green.withValues(alpha: .12)
                            : Colors.red.withValues(alpha: .12),
                      );

                      return MobileInfoCard(
                        title: acc.accName ?? "",
                        subtitle: acc.ownerName,
                        infoItems: infoItems,
                        status: accountStatus,
                        showActions: false, // Disable the View Details button
                        // No onTap, so it won't be clickable
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
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  String? ccy;
  int? status;
  double? limit;
  final accountLimit = TextEditingController();
  final searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsReportBloc>().add(ResetAccountsReportEvent());
    });
    super.initState();
  }

  void _showFilterSheet() {
    final tr = AppLocalizations.of(context)!;

    final tempSearchController = TextEditingController(text: searchController.text);
    final tempAccountLimitController = TextEditingController(text: accountLimit.text);
    String? tempCcy = ccy;
    int? tempStatus = status;
    double? tempLimit = limit;

    ZDraggableSheet.show(
      context: context,
      title: "Filter",
      showCloseButton: true,
      showDragHandle: true,
      estimatedContentHeight: 450,
      initialChildSize: 0.5,
      bodyBuilder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          children: [
            // For tablet, we can use a more spacious layout
            Row(
              children: [
                Expanded(
                  child: ZTextFieldEntitled(
                    onChanged: (e) {},
                    controller: tempSearchController,
                    title: tr.search,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZTextFieldEntitled(
                    inputFormat: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (e) {
                      tempLimit = double.tryParse(e);
                    },
                    controller: tempAccountLimitController,
                    title: tr.accountLimit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CurrencyDropdown(
                    flag: true,
                    isMulti: false,
                    title: tr.currencyTitle,
                    onMultiChanged: (e) {},
                    onSingleChanged: (e) {
                      tempCcy = e?.ccyCode ?? "";
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatusDropdown(
                    onChanged: (e) {
                      tempStatus = e;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    height: 47,
                    isActive: true,
                    icon: Icons.clear_all,
                    onPressed: () {
                      tempSearchController.clear();
                      tempAccountLimitController.clear();
                      tempCcy = null;
                      tempStatus = null;
                      tempLimit = null;
                      setState(() {});
                    },
                    label: Text(tr.clearFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZOutlineButton(
                    height: 47,
                    isActive: true,
                    icon: Icons.filter_alt_outlined,
                    onPressed: () {
                      setState(() {
                        ccy = tempCcy;
                        status = tempStatus;
                        limit = tempLimit;
                        searchController.text = tempSearchController.text;
                        accountLimit.text = tempAccountLimitController.text;
                      });

                      context.read<AccountsReportBloc>().add(
                        LoadAccountsReportEvent(
                          status: tempStatus,
                          currency: tempCcy,
                          limit: tempLimit ?? 0.0,
                          search: tempSearchController.text,
                        ),
                      );

                      Navigator.pop(context);
                    },
                    label: Text(tr.applyFilter),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.accountsReport),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          if (ccy != null || status != null || limit != null || searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                setState(() {
                  ccy = null;
                  status = null;
                  limit = null;
                  searchController.clear();
                  accountLimit.clear();
                });
                context.read<AccountsReportBloc>().add(
                  LoadAccountsReportEvent(),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick filter bar for tablet
          if (ccy != null || status != null || limit != null || searchController.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: color.primaryContainer,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(tr.activeFilters),
                    backgroundColor: color.primary,
                    labelStyle: TextStyle(color: color.onPrimary),
                  ),
                  if (searchController.text.isNotEmpty)
                    Chip(
                      label: Text("${tr.search}: ${searchController.text}"),
                      onDeleted: () {
                        setState(() {
                          searchController.clear();
                        });
                        context.read<AccountsReportBloc>().add(
                          LoadAccountsReportEvent(
                            status: status,
                            currency: ccy,
                            limit: limit ?? 0.0,
                          ),
                        );
                      },
                    ),
                  if (limit != null)
                    Chip(
                      label: Text("${tr.accountLimit}: ${limit!.toAmount()}"),
                      onDeleted: () {
                        setState(() {
                          limit = null;
                          accountLimit.clear();
                        });
                        context.read<AccountsReportBloc>().add(
                          LoadAccountsReportEvent(
                            status: status,
                            currency: ccy,
                            search: searchController.text,
                          ),
                        );
                      },
                    ),
                  if (ccy != null)
                    Chip(
                      label: Text("${tr.currencyTitle}: $ccy"),
                      onDeleted: () {
                        setState(() {
                          ccy = null;
                        });
                        context.read<AccountsReportBloc>().add(
                          LoadAccountsReportEvent(
                            status: status,
                            limit: limit ?? 0.0,
                            search: searchController.text,
                          ),
                        );
                      },
                    ),
                  if (status != null)
                    Chip(
                      label: Text("${tr.status}: ${status == 1 ? tr.active : tr.blocked}"),
                      onDeleted: () {
                        setState(() {
                          status = null;
                        });
                        context.read<AccountsReportBloc>().add(
                          LoadAccountsReportEvent(
                            currency: ccy,
                            limit: limit ?? 0.0,
                            search: searchController.text,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

          // List with MobileInfoCard for tablet (can use grid layout for better tablet experience)
          Expanded(
            child: BlocBuilder<AccountsReportBloc, AccountsReportState>(
              builder: (context, state) {
                if(state is AccountsReportInitial){
                  return NoDataWidget(
                    title: "Accounts Report",
                    message: "Apply filters to see accounts",
                    enableAction: false,
                  );
                }
                if (state is AccountsReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AccountsReportErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is AccountsReportLoadedState) {
                  if (state.accounts.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      onRefresh: () {
                        context.read<AccountsReportBloc>().add(
                          LoadAccountsReportEvent(),
                        );
                      },
                    );
                  }

                  // Use GridView for tablet for better space utilization
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: state.accounts.length,
                    itemBuilder: (context, index) {
                      final acc = state.accounts[index];

                      // Create info items for the card
                      final infoItems = [
                        MobileInfoItem(
                          icon: Icons.account_balance_wallet,
                          text: acc.creditLimit.toAmount(),
                        ),
                        MobileInfoItem(
                          icon: Icons.business,
                          text: acc.accNumber.toString(),
                        ),
                        MobileInfoItem(
                          icon: Icons.currency_exchange,
                          text: acc.ccyName ?? '',
                        ),
                      ];

                      // Create status for the card
                      final accountStatus = MobileStatus(
                        label: acc.status == "Active" ? tr.active : tr.blocked,
                        color: acc.status == "Active"
                            ? Colors.green
                            : Colors.red,
                        backgroundColor: acc.status == "Active"
                            ? Colors.green.withValues(alpha: .12)
                            : Colors.red.withValues(alpha: .12),
                      );

                      return MobileInfoCard(
                        title: acc.accName ?? "",
                        subtitle: acc.ownerName,
                        infoItems: infoItems,
                        status: accountStatus,
                        showActions: false, // Disable the View Details button
                        // No onTap, so it won't be clickable
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
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsReportBloc>().add(ResetAccountsReportEvent());
    });
    super.initState();
  }

  String? ccy;
  int? status;
  double? limit;
  final accountLimit = TextEditingController();
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: color.surface);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("Accounts Report"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                Expanded(
                  flex: 2,
                  child: ZTextFieldEntitled(
                    onChanged: (e) {
                      context.read<AccountsReportBloc>().add(
                        LoadAccountsReportEvent(
                          search: e,
                        ),
                      );
                    },
                    controller: searchController,
                    title: tr.search,
                  ),
                ),
                Expanded(
                  child: ZTextFieldEntitled(
                    inputFormat: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onChanged: (e) {
                      setState(() {
                        limit = double.tryParse(e);
                      });
                    },
                    controller: accountLimit,
                    title: tr.accountLimit,
                  ),
                ),
                Expanded(
                  child: CurrencyDropdown(
                    flag: true,
                    isMulti: false,
                    title: tr.currencyTitle,
                    onMultiChanged: (e) {},
                    onSingleChanged: (e) {
                      setState(() {
                        ccy = e?.ccyCode ?? "";
                      });
                    },
                  ),
                ),
                Expanded(
                  child: StatusDropdown(
                    onChanged: (e) {
                      setState(() {
                        status = e;
                      });
                    },
                  ),
                ),
                // Show clear filter button only when filters are applied
                if (ccy != null || status != null || limit != null || searchController.text.isNotEmpty)
                  ZOutlineButton(
                    height: 47,
                    isActive: true,
                    icon: Icons.filter_alt_off_outlined,
                    onPressed: () {
                      setState(() {
                        ccy = null;
                        limit = null;
                        status = null;
                        searchController.clear();
                        accountLimit.clear();
                      });
                      context.read<AccountsReportBloc>().add(
                        LoadAccountsReportEvent(),
                      );
                    },
                    label: Text(tr.clearFilters),
                  ),
                ZOutlineButton(
                  height: 47,
                  isActive: true,
                  icon: Icons.filter_alt_outlined,
                  onPressed: () {
                    context.read<AccountsReportBloc>().add(
                      LoadAccountsReportEvent(
                        status: status,
                        currency: ccy,
                        limit: limit ?? 0.0,
                        search: searchController.text,
                      ),
                    );
                  },
                  label: Text(tr.applyFilter),
                ),
              ],
            ),
          ),

          // Active filters indicator for desktop
          if (ccy != null || status != null || limit != null || searchController.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(tr.activeFilters, style: TextStyle(fontWeight: FontWeight.bold)),
                  if (searchController.text.isNotEmpty)
                    Chip(
                      label: Text("${tr.search}: ${searchController.text}"),
                      backgroundColor: color.primaryContainer,
                    ),
                  if (limit != null)
                    Chip(
                      label: Text("${tr.accountLimit}: ${limit!.toAmount()}"),
                      backgroundColor: color.primaryContainer,
                    ),
                  if (ccy != null)
                    Chip(
                      label: Text("${tr.currencyTitle}: $ccy"),
                      backgroundColor: color.primaryContainer,
                    ),
                  if (status != null)
                    Chip(
                      label: Text("${tr.status}: ${status == 1 ? tr.active : tr.blocked}"),
                      backgroundColor: color.primaryContainer,
                    ),
                ],
              ),
            ),

          // Desktop header (keep table view for desktop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: color.primary,
            ),
            child: Row(
              children: [
                Expanded(child: Text(tr.accounts, style: titleStyle)),
                SizedBox(
                  width: 250,
                  child: Text(tr.ownerInformation, style: titleStyle),
                ),
                SizedBox(
                  width: 150,
                  child: Text(tr.accountLimit, style: titleStyle),
                ),
                SizedBox(
                  width: 100,
                  child: Text(tr.status, style: titleStyle),
                ),
              ],
            ),
          ),

          // Desktop list (keep table view for desktop)
          Expanded(
            child: BlocBuilder<AccountsReportBloc, AccountsReportState>(
              builder: (context, state) {
                if (state is AccountsReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AccountsReportErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is AccountsReportLoadedState) {
                  if (state.accounts.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      onRefresh: () {
                        context.read<AccountsReportBloc>().add(
                          LoadAccountsReportEvent(),
                        );
                      },
                    );
                  }
                  return ListView.builder(
                    itemCount: state.accounts.length,
                    itemBuilder: (context, index) {
                      final acc = state.accounts[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: index.isOdd
                              ? color.primary.withValues(alpha: .05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.accName ?? "",
                                    style: TextStyle(color: color.onSurface),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: 5,
                                    children: [
                                      ZCover(
                                        child: Text(
                                          acc.accNumber.toString(),
                                          style: TextStyle(color: color.outline),
                                        ),
                                      ),
                                      ZCover(
                                        child: Text(
                                          acc.ccyName.toString(),
                                          style: TextStyle(color: color.outline),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: Text(acc.ownerName ?? ""),
                            ),
                            SizedBox(
                              width: 150,
                              child: Text(acc.creditLimit.toAmount()),
                            ),
                            SizedBox(
                              width: 100,
                              child: StatusBadge(
                                trueValue: tr.active,
                                falseValue: tr.blocked,
                                status: acc.status == "Active" ? 1 : 0,
                              ),
                            ),
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
  }
}