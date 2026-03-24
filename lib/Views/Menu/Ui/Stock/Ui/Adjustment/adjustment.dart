import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/search_field.dart';
import 'package:zaitoonpro/Features/Widgets/txn_status_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Features/Other/extensions.dart';
import '../../../../../../Features/Other/utils.dart';
import '../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'adjustment_details.dart';
import 'bloc/adjustment_bloc.dart';

class AdjustmentView extends StatelessWidget {
  const AdjustmentView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileAdjustmentView(),
      tablet: _TabletAdjustmentView(),
      desktop: _DesktopAdjustmentView(),
    );
  }
}

// Mobile View
class _MobileAdjustmentView extends StatefulWidget {
  const _MobileAdjustmentView();

  @override
  State<_MobileAdjustmentView> createState() => _MobileAdjustmentViewState();
}

class _MobileAdjustmentViewState extends State<_MobileAdjustmentView> {
  String? baseCurrency;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
    });

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ZSearchField(
              icon: FontAwesomeIcons.magnifyingGlass,
              controller: searchController,
              hint: tr.search,
              onChanged: (e) {
                setState(() {});
              },
              title: "",
            ),
          ),

          // Adjustments List
          Expanded(
            child: BlocConsumer<AdjustmentBloc, AdjustmentState>(
              listener: (context, state) {
                if (state is AdjustmentDeletedState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.message,
                    isError: false,
                  );
                  context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
                }
                if (state is AdjustmentSavedState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.message,
                    isError: false,
                  );
                  context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
                }
                if (state is AdjustmentErrorState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.error,
                    isError: true,
                  );
                }
              },
              builder: (context, state) {
                if (state is AdjustmentLoadingState ||
                    state is AdjustmentSavingState ||
                    state is AdjustmentDeletingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdjustmentErrorState) {
                  return NoDataWidget(
                    imageName: 'error.png',
                    message: state.error,
                    onRefresh: onRefresh,
                  );
                }

                if (state is AdjustmentLoadedState) {
                  final query = searchController.text.toLowerCase().trim();
                  final filteredList = state.adjustments.where((item) {
                    final ref = item.ordxRef?.toLowerCase() ?? '';
                    final ordId = item.ordId?.toString() ?? '';
                    final account = item.account?.toString() ?? '';
                    final amount = item.amount?.toLowerCase() ?? '';
                    final status = item.trnStateText?.toLowerCase() ?? '';
                    return ref.contains(query) ||
                        ordId.contains(query) ||
                        account.contains(query) ||
                        amount.contains(query) ||
                        status.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      onRefresh: onRefresh,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final adjustment = filteredList[index];

                      return ZCover(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        radius: 4,
                        child: InkWell(
                          onTap: () {
                            Utils.goto(
                              context,
                              AdjustmentDetailView(orderId: adjustment.ordId!),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row with ID and Date
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.primary.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "#${adjustment.ordId}",
                                        style: TextStyle(
                                          color: color.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        adjustment.ordEntryDate != null
                                            ? adjustment.ordEntryDate!.toFormattedDate()
                                            : "",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Reference Number
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt,
                                      size: 16,
                                      color: color.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        adjustment.ordxRef ?? "-",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Account Number
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance,
                                      size: 16,
                                      color: color.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        adjustment.account?.toString() ?? "-",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Amount and Status Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${adjustment.amount?.toAmount()} $baseCurrency",
                                        style: TextStyle(
                                          color: color.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    TransactionStatusBadge(
                                      status: adjustment.trnStateText ?? "",
                                    ),
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

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Tablet View
class _TabletAdjustmentView extends StatefulWidget {
  const _TabletAdjustmentView();

  @override
  State<_TabletAdjustmentView> createState() => _TabletAdjustmentViewState();
}

class _TabletAdjustmentViewState extends State<_TabletAdjustmentView> {
  String? baseCurrency;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
    });

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Header with Title and Search
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.adjustment,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Adjust inventory shortage to expense account',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ZSearchField(
                    icon: FontAwesomeIcons.magnifyingGlass,
                    controller: searchController,
                    hint: tr.search,
                    onChanged: (e) {
                      setState(() {});
                    },
                    title: "",
                  ),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  toolTip: "F5",
                  width: 100,
                  icon: Icons.refresh,
                  onPressed: onRefresh,
                  label: Text(tr.refresh),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .9),
              ),
              child: Row(
                children: [
                  SizedBox(width: 35, child: Text('#', style: titleStyle)),
                  SizedBox(width: 90, child: Text(tr.date, style: titleStyle)),
                  Expanded(child: Text(tr.referenceNumber, style: titleStyle)),
                  SizedBox(
                    width: 80,
                    child: Text(tr.accountNumber, style: titleStyle),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(tr.amount, style: titleStyle),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(tr.status, style: titleStyle),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Adjustments List
            Expanded(
              child: BlocConsumer<AdjustmentBloc, AdjustmentState>(
                listener: (context, state) {
                  if (state is AdjustmentDeletedState) {
                    Utils.showOverlayMessage(
                      context,
                      message: state.message,
                      isError: false,
                    );
                    context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
                  }
                  if (state is AdjustmentSavedState) {
                    Utils.showOverlayMessage(
                      context,
                      message: state.message,
                      isError: false,
                    );
                    context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
                  }
                  if (state is AdjustmentErrorState) {
                    Utils.showOverlayMessage(
                      context,
                      message: state.error,
                      isError: true,
                    );
                  }
                },
                builder: (context, state) {
                  if (state is AdjustmentLoadingState ||
                      state is AdjustmentSavingState ||
                      state is AdjustmentDeletingState) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AdjustmentErrorState) {
                    return NoDataWidget(
                      imageName: 'error.png',
                      message: state.error,
                      onRefresh: onRefresh,
                    );
                  }

                  if (state is AdjustmentLoadedState) {
                    final query = searchController.text.toLowerCase().trim();
                    final filteredList = state.adjustments.where((item) {
                      final ref = item.ordxRef?.toLowerCase() ?? '';
                      final ordId = item.ordId?.toString() ?? '';
                      final account = item.account?.toString() ?? '';
                      final amount = item.amount?.toLowerCase() ?? '';
                      final status = item.trnStateText?.toLowerCase() ?? '';
                      return ref.contains(query) ||
                          ordId.contains(query) ||
                          account.contains(query) ||
                          amount.contains(query) ||
                          status.contains(query);
                    }).toList();

                    if (filteredList.isEmpty) {
                      return NoDataWidget(
                        message: tr.noDataFound,
                        onRefresh: onRefresh,
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final adjustment = filteredList[index];

                        return InkWell(
                          onTap: () {
                            Utils.goto(
                              context,
                              AdjustmentDetailView(orderId: adjustment.ordId!),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? color.primary.withValues(alpha: .05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 35,
                                  child: Text(adjustment.ordId.toString()),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    adjustment.ordEntryDate != null
                                        ? adjustment.ordEntryDate!.toFormattedDate()
                                        : "",
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    adjustment.ordxRef ?? "-",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    adjustment.account?.toString() ?? "-",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    adjustment.amount != null
                                        ? "${adjustment.amount?.toAmount()} $baseCurrency"
                                        : "-",
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: TransactionStatusBadge(
                                    status: adjustment.trnStateText ?? "",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Desktop View - Keep exactly as original
class _DesktopAdjustmentView extends StatefulWidget {
  const _DesktopAdjustmentView();

  @override
  State<_DesktopAdjustmentView> createState() => _DesktopAdjustmentViewState();
}

class _DesktopAdjustmentViewState extends State<_DesktopAdjustmentView> {
  String? baseCurrency;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
    });

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  flex: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    tileColor: Colors.transparent,
                    title: Text(
                      tr.adjustment,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20),
                    ),
                    subtitle: const Text(
                      'Adjust inventory shortage to expense account',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ZSearchField(
                    icon: FontAwesomeIcons.magnifyingGlass,
                    controller: searchController,
                    hint: tr.search,
                    onChanged: (e) {
                      setState(() {});
                    },
                    title: "",
                  ),
                ),
                ZOutlineButton(
                  toolTip: "F5",
                  width: 120,
                  icon: Icons.refresh,
                  onPressed: onRefresh,
                  label: Text(tr.refresh),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .9),
            ),
            child: Row(
              children: [
                SizedBox(width: 35, child: Text('#', style: titleStyle)),
                SizedBox(width: 90, child: Text(tr.date, style: titleStyle)),
                Expanded(child: Text(tr.referenceNumber, style: titleStyle)),
                SizedBox(
                  width: 100,
                  child: Text(tr.accountNumber, style: titleStyle),
                ),
                SizedBox(width: 150, child: Text(tr.amount, style: titleStyle)),
                SizedBox(width: 115, child: Text(tr.status, style: titleStyle)),
              ],
            ),
          ),

          // Adjustments List
          Expanded(
            child: BlocConsumer<AdjustmentBloc, AdjustmentState>(
              listener: (context, state) {
                if (state is AdjustmentDeletedState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.message,
                    isError: false,
                  );
                  context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
                }
                if (state is AdjustmentSavedState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.message,
                    isError: false,
                  );
                  context.read<AdjustmentBloc>().add(LoadAdjustmentsEvent());
                }
                if (state is AdjustmentErrorState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.error,
                    isError: true,
                  );
                }
              },
              builder: (context, state) {
                if (state is AdjustmentLoadingState ||
                    state is AdjustmentSavingState ||
                    state is AdjustmentDeletingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdjustmentErrorState) {
                  return NoDataWidget(
                    imageName: 'error.png',
                    message: state.error,
                    onRefresh: onRefresh,
                  );
                }

                if (state is AdjustmentLoadedState) {
                  final query = searchController.text.toLowerCase().trim();
                  final filteredList = state.adjustments.where((item) {
                    final ref = item.ordxRef?.toLowerCase() ?? '';
                    final ordId = item.ordId?.toString() ?? '';
                    final account = item.account?.toString() ?? '';
                    final amount = item.amount?.toLowerCase() ?? '';
                    final status = item.trnStateText?.toLowerCase() ?? '';
                    return ref.contains(query) ||
                        ordId.contains(query) ||
                        account.contains(query) ||
                        amount.contains(query) ||
                        status.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      onRefresh: onRefresh,
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final adjustment = filteredList[index];

                      return InkWell(
                        onTap: () {
                          Utils.goto(
                            context,
                            AdjustmentDetailView(orderId: adjustment.ordId!),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? color.primary.withValues(alpha: .05)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 35,
                                child: Text(adjustment.ordId.toString()),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  adjustment.ordEntryDate != null
                                      ? adjustment.ordEntryDate!.toFormattedDate()
                                      : "",
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  adjustment.ordxRef ?? "-",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  adjustment.account?.toString() ?? "-",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  adjustment.amount != null
                                      ? "${adjustment.amount?.toAmount()} $baseCurrency"
                                      : "-",
                                ),
                              ),
                              SizedBox(
                                width: 115,
                                child: TransactionStatusBadge(
                                  status: adjustment.trnStateText ?? "",
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}