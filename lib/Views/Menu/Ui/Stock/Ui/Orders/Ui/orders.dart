import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewPurchase/bloc/purchase_invoice_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/bloc/sale_invoice_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Orders/bloc/orders_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../OrderScreen/GetOrderById/order_by_id.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileOrdersView(),
      tablet: _TabletOrdersView(),
      desktop: _DesktopOrdersView(),
    );
  }
}

// Mobile View
class _MobileOrdersView extends StatefulWidget {
  const _MobileOrdersView();

  @override
  State<_MobileOrdersView> createState() => _MobileOrdersViewState();
}

class _MobileOrdersViewState extends State<_MobileOrdersView> {
  String? baseCurrency;
  final Map<String, bool> _copiedStates = {};
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersBloc>().add(const LoadOrdersEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<OrdersBloc>().add(LoadOrdersEvent());
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);
    setState(() {
      _copiedStates[reference] = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStates.remove(reference);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: MultiBlocListener(
        listeners: [
          BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
            listener: (context, state) {
              if (state is PurchaseInvoiceSaved && state.success) {
                context.read<OrdersBloc>().add(LoadOrdersEvent());
              }
            },
          ),
          BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
            listener: (context, state) {
              if (state is SaleInvoiceSaved && state.success) {
                context.read<OrdersBloc>().add(LoadOrdersEvent());
              }
            },
          ),
        ],
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ZSearchField(
                icon: FontAwesomeIcons.magnifyingGlass,
                controller: searchController,
                hint: tr.orderSearchHint,
                onChanged: (e) {
                  setState(() {});
                },
                title: "",
              ),
            ),

            // Orders List
            Expanded(
              child: BlocBuilder<OrdersBloc, OrdersState>(
                builder: (context, state) {
                  if (state is OrdersErrorState) {
                    return NoDataWidget(
                      message: state.message,
                      onRefresh: onRefresh,
                    );
                  }
                  if (state is OrdersLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is OrdersLoadedState) {
                    final query = searchController.text.toLowerCase().trim();
                    final filteredList = state.order.where((item) {
                      final ref = item.ordTrnRef?.toLowerCase() ?? '';
                      final ordId = item.ordId?.toString() ?? '';
                      final ordName = item.ordName?.toLowerCase() ?? '';
                      final personal = item.personal?.toLowerCase() ?? '';
                      return ref.contains(query) ||
                          ordId.contains(query) ||
                          ordName.contains(query) ||
                          personal.contains(query);
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
                        final ord = filteredList[index];
                        final isCopied = _copiedStates[ord.ordTrnRef ?? ""] ?? false;
                        final reference = ord.ordTrnRef ?? "";

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
                                OrderByIdView(
                                  orderId: ord.ordId!,
                                  ordName: ord.ordName,
                                ),
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
                                          "#${ord.ordId}",
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
                                          ord.ordEntryDate?.toFormattedDate() ?? "",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      // Copy Button
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _copyToClipboard(reference, context),
                                          borderRadius: BorderRadius.circular(4),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 100),
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: isCopied
                                                  ? color.primary.withAlpha(25)
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isCopied
                                                    ? color.primary
                                                    : color.outline.withValues(alpha: .3),
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 300),
                                              child: Icon(
                                                isCopied ? Icons.check : Icons.content_copy,
                                                key: ValueKey<bool>(isCopied),
                                                size: 15,
                                                color: isCopied
                                                    ? color.primary
                                                    : color.outline.withValues(alpha: .6),
                                              ),
                                            ),
                                          ),
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
                                          reference,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Party Name
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: color.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ord.personal ?? "",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Bottom Row with Type and Amount
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.primary.withValues(alpha: .05),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          Utils.getInvoiceType(
                                            txn: ord.ordName ?? "",
                                            context: context,
                                          ),
                                          style: TextStyle(
                                            color: color.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${ord.totalBill?.toAmount()} $baseCurrency",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tablet View
class _TabletOrdersView extends StatefulWidget {
  const _TabletOrdersView();

  @override
  State<_TabletOrdersView> createState() => _TabletOrdersViewState();
}

class _TabletOrdersViewState extends State<_TabletOrdersView> {
  String? baseCurrency;
  final Map<String, bool> _copiedStates = {};
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersBloc>().add(const LoadOrdersEvent());
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
    context.read<OrdersBloc>().add(LoadOrdersEvent());
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);
    setState(() {
      _copiedStates[reference] = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStates.remove(reference);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);

    return Scaffold(
      backgroundColor: color.surface,
      body: MultiBlocListener(
        listeners: [
          BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
            listener: (context, state) {
              if (state is PurchaseInvoiceSaved && state.success) {
                context.read<OrdersBloc>().add(LoadOrdersEvent());
              }
            },
          ),
          BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
            listener: (context, state) {
              if (state is SaleInvoiceSaved && state.success) {
                context.read<OrdersBloc>().add(LoadOrdersEvent());
              }
            },
          ),
        ],
        child: Padding(
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
                          tr.orderTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tr.ordersSubtitle,
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
                      hint: tr.orderSearchHint,
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
                    SizedBox(width: 80, child: Text(tr.date, style: titleStyle)),
                    Expanded(
                      flex: 2,
                      child: Text(tr.referenceNumber, style: titleStyle),
                    ),
                    Expanded(child: Text(tr.party, style: titleStyle)),
                    SizedBox(
                      width: 90,
                      child: Text(tr.totalInvoice, style: titleStyle),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // Orders List
              Expanded(
                child: BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (context, state) {
                    if (state is OrdersErrorState) {
                      return NoDataWidget(
                        message: state.message,
                        onRefresh: onRefresh,
                      );
                    }
                    if (state is OrdersLoadingState) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is OrdersLoadedState) {
                      final query = searchController.text.toLowerCase().trim();
                      final filteredList = state.order.where((item) {
                        final ref = item.ordTrnRef?.toLowerCase() ?? '';
                        final ordId = item.ordId?.toString() ?? '';
                        final ordName = item.ordName?.toLowerCase() ?? '';
                        final personal = item.personal?.toLowerCase() ?? '';
                        return ref.contains(query) ||
                            ordId.contains(query) ||
                            ordName.contains(query) ||
                            personal.contains(query);
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
                          final ord = filteredList[index];
                          final isCopied = _copiedStates[ord.ordTrnRef ?? ""] ?? false;
                          final reference = ord.ordTrnRef ?? "";

                          return InkWell(
                            onTap: () {
                              Utils.goto(
                                context,
                                OrderByIdView(
                                  orderId: ord.ordId!,
                                  ordName: ord.ordName,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? color.primary.withValues(alpha: .05)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      ord.ordEntryDate?.toFormattedDate() ?? "",
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _copyToClipboard(reference, context),
                                            borderRadius: BorderRadius.circular(4),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 100),
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isCopied
                                                    ? color.primary.withAlpha(25)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: isCopied
                                                      ? color.primary
                                                      : color.outline.withValues(alpha: .3),
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: Icon(
                                                  isCopied ? Icons.check : Icons.content_copy,
                                                  key: ValueKey<bool>(isCopied),
                                                  size: 15,
                                                  color: isCopied
                                                      ? color.primary
                                                      : color.outline.withValues(alpha: .6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            reference,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      ord.personal ?? "",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      "${ord.totalBill?.toAmount()} $baseCurrency",
                                      textAlign: TextAlign.right,
                                    ),
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
        ),
      ),
    );
  }
}

// Desktop View - Keep exactly as original
class _DesktopOrdersView extends StatefulWidget {
  const _DesktopOrdersView();

  @override
  State<_DesktopOrdersView> createState() => _DesktopOrdersViewState();
}

class _DesktopOrdersViewState extends State<_DesktopOrdersView> {
  String? baseCurrency;
  final Map<String, bool> _copiedStates = {};
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersBloc>().add(const LoadOrdersEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<OrdersBloc>().add(LoadOrdersEvent());
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);
    setState(() {
      _copiedStates[reference] = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStates.remove(reference);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
            listener: (context, state) {
              if (state is PurchaseInvoiceSaved && state.success) {
                context.read<OrdersBloc>().add(LoadOrdersEvent());
              }
            },
          ),
          BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
            listener: (context, state) {
              if (state is SaleInvoiceSaved && state.success) {
                context.read<OrdersBloc>().add(LoadOrdersEvent());
              }
            },
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    flex: 5,
                    child: ListTile(
                      tileColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tr.orderTitle,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontSize: 20),
                      ),
                      subtitle: Text(
                        tr.ordersSubtitle,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: ZSearchField(
                      icon: FontAwesomeIcons.magnifyingGlass,
                      controller: searchController,
                      hint: AppLocalizations.of(context)!.orderSearchHint,
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

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .9),
              ),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text("#", style: titleStyle)),
                  SizedBox(width: 100, child: Text(tr.date, style: titleStyle)),
                  SizedBox(
                    width: 215,
                    child: Text(tr.referenceNumber, style: titleStyle),
                  ),
                  Expanded(child: Text(tr.party, style: titleStyle)),
                  SizedBox(
                    width: 100,
                    child: Text(tr.invoiceType, style: titleStyle),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(tr.totalInvoice, style: titleStyle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            Expanded(
              child: BlocBuilder<OrdersBloc, OrdersState>(
                builder: (context, state) {
                  if (state is OrdersErrorState) {
                    return NoDataWidget(message: state.message, onRefresh: onRefresh);
                  }
                  if (state is OrdersLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is OrdersLoadedState) {
                    final query = searchController.text.toLowerCase().trim();
                    final filteredList = state.order.where((item) {
                      final ref = item.ordTrnRef?.toLowerCase() ?? '';
                      final ordId = item.ordId?.toString() ?? '';
                      final ordName = item.ordName?.toLowerCase() ?? '';
                      return ref.contains(query) ||
                          ordId.contains(query) ||
                          ordName.contains(query);
                    }).toList();

                    if (filteredList.isEmpty) {
                      return NoDataWidget(message: tr.noDataFound);
                    }
                    if (state.order.isEmpty) {
                      return const NoDataWidget(enableAction: false);
                    }
                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final ord = filteredList[index];
                        final isCopied = _copiedStates[ord.ordTrnRef ?? ""] ?? false;
                        final reference = ord.ordTrnRef ?? "";
                        return InkWell(
                          onTap: () {
                            Utils.goto(
                              context,
                              OrderByIdView(
                                orderId: ord.ordId!,
                                ordName: ord.ordName,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? color.primary.withValues(alpha: .05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(ord.ordId.toString()),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    ord.ordEntryDate?.toFormattedDate() ?? "",
                                  ),
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _copyToClipboard(
                                            reference,
                                            context,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                          hoverColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: .05),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 100,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCopied
                                                  ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(25)
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isCopied
                                                    ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    : Theme.of(context)
                                                    .colorScheme
                                                    .outline
                                                    .withValues(alpha: .3),
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                child: Icon(
                                                  isCopied
                                                      ? Icons.check
                                                      : Icons.content_copy,
                                                  key: ValueKey<bool>(isCopied),
                                                  size: 15,
                                                  color: isCopied
                                                      ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      : Theme.of(context)
                                                      .colorScheme
                                                      .outline
                                                      .withValues(alpha: .6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 180,
                                      child: Text(ord.ordTrnRef ?? ""),
                                    ),
                                  ],
                                ),
                                Expanded(child: Text(ord.personal ?? "")),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    Utils.getInvoiceType(
                                      txn: ord.ordName ?? "",
                                      context: context,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 130,
                                  child: Text(
                                    "${ord.totalBill?.toAmount()} $baseCurrency",
                                  ),
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
      ),
    );
  }
}