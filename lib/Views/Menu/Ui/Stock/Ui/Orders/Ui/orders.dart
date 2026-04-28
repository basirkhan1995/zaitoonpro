import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewPurchase/bloc/purchase_invoice_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewPurchase/new_purchase.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/bloc/sale_invoice_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/new_sale.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/Orders/bloc/orders_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Generic/shimmer.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../Features/Widgets/txn_status_widget.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../Settings/features/Visibility/bloc/settings_visible_bloc.dart';
import '../../OrderScreen/GetOrderById/order_by_id.dart';
import '../model/orders_model.dart';

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
                                 ord.ordName == "Sale"? NewSaleView(orderId: ord.ordId) : NewPurchaseOrderView()
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

// Desktop View
class _DesktopOrdersView extends StatefulWidget {
  const _DesktopOrdersView();

  @override
  State<_DesktopOrdersView> createState() => _DesktopOrdersViewState();
}

class _DesktopOrdersViewState extends State<_DesktopOrdersView> {
  String? baseCurrency;
  final Map<String, bool> _copiedStates = {};
  final TextEditingController searchController = TextEditingController();

  // Multi-select related variables
  final Set<int> _selectedOrderIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrdersBloc>().add(const LoadOrdersEvent());
      }
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
    if (!mounted) return;
    _exitSelectionMode();
    context.read<OrdersBloc>().add(const LoadOrdersEvent());
  }

  void _exitSelectionMode() {
    if (!mounted) return;
    setState(() {
      _selectedOrderIds.clear();
      _isSelectionMode = false;
    });
  }

  void _enterSelectionMode() {
    if (!mounted) return;
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _toggleSelection(int orderId) {
    if (!mounted) return;
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
        if (_selectedOrderIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedOrderIds.add(orderId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<OrdersModel> orders) {
    if (!mounted) return;
    setState(() {
      _selectedOrderIds.clear();
      for (var order in orders) {
        if (order.ordId != null) {
          _selectedOrderIds.add(order.ordId!);
        }
      }
      _isSelectionMode = _selectedOrderIds.isNotEmpty;
    });
  }

  void _deselectAll() {
    if (!mounted) return;
    setState(() {
      _selectedOrderIds.clear();
      // Exit selection mode completely when deselect all
      _isSelectionMode = false;
    });
  }

  Future<void> _updateSelectedOrdersStatus() async {
    if (!mounted) return;

    if (_selectedOrderIds.isEmpty) {
      _showSnackBar('No orders selected', isError: true);
      return;
    }

    // Store selected IDs before async gap
    final selectedCount = _selectedOrderIds.length;
    final ordersData = _selectedOrderIds.map((orderId) {
      return {
        'ordID': orderId,
        'ordStatus': 'Authorized',
      };
    }).toList();

    // Show confirmation dialog with safe context
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)
        ),
        title:   Text(AppLocalizations.of(context)!.areYouSure),
        content: Text(
          'Do you want to update $selectedCount order(s) status to "Authorized"?',
        ),
        actions: [
          ZOutlineButton(
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext, false);
              }
            },
            label: Text(AppLocalizations.of(context)!.cancel),
          ),
          ZOutlineButton(
            isActive: true,
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext, true);
              }
            },
            label: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    // Check mounted after dialog
    if (!mounted) return;

    if (confirmed == true) {
      // Call BLoC to update status
      context.read<OrdersBloc>().add(UpdateOrdersStatusEvent(ordersData));
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ToastManager.show(context: context,
        title: isError? AppLocalizations.of(context)!.errorTitle : AppLocalizations.of(context)!.successTitle,
        message: message, type: isError? ToastType.error : ToastType.success);
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);
    if (!mounted) return;
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
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.onSurface);
    final tr = AppLocalizations.of(context)!;
    final visibility = context.read<SettingsVisibleBloc>().state;
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
            listener: (context, state) {
              if (state is PurchaseInvoiceSaved && state.success) {
                if (mounted) {
                  context.read<OrdersBloc>().add(const LoadOrdersEvent());
                }
              }
            },
          ),
          BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
            listener: (context, state) {
              if (state is SaleInvoiceSaved && state.success) {
                if (mounted) {
                  context.read<OrdersBloc>().add(const LoadOrdersEvent());
                }
              }
            },
          ),
          BlocListener<OrdersBloc, OrdersState>(
            listener: (context, state) {
              if(state is OrdersDeletedState){
                Navigator.of(context).pop();
                ToastManager.show(context: context, message: tr.successMessage,title: tr.successTitle, type: ToastType.success);
              }
              if (!mounted) return;
              if (state is OrdersStatusUpdatedState) {
                _showSnackBar(state.message);
                _exitSelectionMode();
              } else if (state is OrdersErrorState) {
                _showSnackBar(state.message, isError: true);
              }
            },
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search and Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20),
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
                        if (!mounted) return;
                        setState(() {
                          if (_isSelectionMode) {
                            _exitSelectionMode();
                          }
                        });
                      },
                      title: "",
                    ),
                  ),

                  // Selection Mode Actions
                  if (_isSelectionMode) ...[
                    ZOutlineButton(
                      icon: Icons.check_circle,
                      onPressed: _updateSelectedOrdersStatus,
                      label:   Text(tr.authorize),
                      width: 120,
                    ),
                    ZOutlineButton(
                      width: 120,
                      icon: Icons.close,
                      onPressed: _exitSelectionMode,
                      label: Text(tr.cancel),
                    ),
                  ],

                  // Normal Actions
                  if (!_isSelectionMode) ...[
                    ZOutlineButton(
                      toolTip: "F5",
                      width: 120,
                      icon: Icons.refresh,
                      onPressed: onRefresh,
                      label: Text(tr.refresh),
                    ),
                  ],
                ],
              ),
            ),

            // Column Headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              decoration: BoxDecoration(
                color: color.outline.withValues(alpha: .06),
              ),
              child: Row(
                children: [
                  // Dynamic width based on selection mode
                  SizedBox(
                    width: _isSelectionMode ? 74 : 50, // 50 + 24 for checkbox
                    child: Row(
                      children: [
                        if (_isSelectionMode)
                          const SizedBox(width: 24), // Placeholder for checkbox
                        const SizedBox(width: 4),
                        Text("#", style: titleStyle),
                      ],
                    ),
                  ),
                    SizedBox(width: 100, child: Text(tr.date,style: titleStyle)),
                    SizedBox(width: 215, child: Text(tr.referenceNumber,style: titleStyle)),
                    Expanded(child: Text(tr.party,style: titleStyle)),
                    SizedBox(width: 100, child: Text(tr.category,style: titleStyle)),
                    SizedBox(
                    width: 160,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Directionality(
                        textDirection: context.read<LocalizationBloc>().state.languageCode == "en"? TextDirection.rtl : TextDirection.ltr,
                        child: Text(tr.totalInvoice,style: titleStyle),
                      ),
                    ),
                  ),
                    SizedBox(width: 115, child: Text(tr.status,style: titleStyle)),
                ]
              ),
            ),


            // Orders List
            Expanded(
              child: BlocBuilder<OrdersBloc, OrdersState>(
                builder: (context, state) {
                  if (state is OrdersErrorState) {
                    return NoDataWidget(message: state.message, onRefresh: onRefresh);
                  }

                  if (state is OrdersLoadingState) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 7,
                    );
                  }

                  if (state is OrdersStatusUpdatingState) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Updating order status...'),
                        ],
                      ),
                    );
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
                      return NoDataWidget(
                        message: query.isEmpty ? tr.noDataFound : "No result found",
                        onRefresh: onRefresh,
                      );
                    }

                    return Column(
                      children: [
                        // Selection Controls (only show in selection mode and when there are items)
                        if (_isSelectionMode && filteredList.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .05),
                              borderRadius: BorderRadius.circular(1),
                            ),
                            margin: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedOrderIds.length} of ${filteredList.length} selected',
                                  style: TextStyle(
                                    color: color.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _selectAll(filteredList),
                                      icon: const Icon(Icons.select_all, size: 18),
                                      label: Text('${tr.selectAll} (${filteredList.length})'),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: _deselectAll,
                                      icon: const Icon(Icons.deselect, size: 18),
                                      label: Text(tr.deselectAll),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final ord = filteredList[index];
                              final isCopied = _copiedStates[ord.ordTrnRef ?? ""] ?? false;
                              final reference = ord.ordTrnRef ?? "";
                              final isSelected = _selectedOrderIds.contains(ord.ordId);

                              return InkWell(
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(ord.ordId!);
                                  } else {
                                    Utils.goto(
                                        context,
                                        ord.ordName == "Sale"? NewSaleView(orderId: ord.ordId, ref: ord.ordTrnRef) : NewPurchaseOrderView(orderId: ord.ordId)
                                    );
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _enterSelectionMode();
                                    _toggleSelection(ord.ordId!);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.primary.withValues(alpha: .15)
                                        : index.isOdd
                                        ? color.surfaceContainer.withValues(alpha: .6)
                                        : Colors.transparent,
                                    border: isSelected
                                        ? Border.all(
                                      color: color.primary,
                                      width: 1,
                                    )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Order ID with dynamic spacing for checkbox
                                      SizedBox(
                                        width: _isSelectionMode ? 74 : 50,
                                        child: Row(
                                          children: [
                                            if (_isSelectionMode)
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Checkbox(
                                                  value: isSelected,
                                                  onChanged: (_) => _toggleSelection(ord.ordId!),
                                                  visualDensity: VisualDensity.compact,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  activeColor: color.primary,
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                ord.ordId.toString(),
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Date
                                      if(visibility.dateType == DateType.gregorian)...[
                                        SizedBox(width: 100, child: Text(ord.ordEntryDate.toFormattedDate())),
                                      ]else ...[
                                        SizedBox(width: 100, child: Text(ord.ordEntryDate?.shamsiDateString??"",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 17),)),
                                      ],
                                      // Reference Number with Copy
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _copyToClipboard(reference, context),
                                                borderRadius: BorderRadius.circular(4),
                                                hoverColor: color.primary.withValues(alpha: .05),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 100),
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
                                                  child: Center(
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
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              reference,
                                              style: TextStyle(
                                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Party
                                      Expanded(
                                        child: Text(
                                          ord.personal ?? "",
                                          style: TextStyle(
                                            color: isSelected ? color.primary : null,
                                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                        ),
                                      ),

                                      // Invoice Type
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          Utils.getInvoiceType(
                                            txn: ord.ordName ?? "",
                                            context: context,
                                          ),
                                        ),
                                      ),

                                      // Total Amount
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        width: 160,
                                        child: Directionality(
                                          textDirection: context.read<LocalizationBloc>().state.languageCode == "en"? TextDirection.rtl : TextDirection.ltr,
                                          child: Text(
                                            "${ord.totalBill?.toAmount()} $baseCurrency",
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                              color: isSelected ? color.primary : null,
                                              fontSize: 14
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ),

                                      // Status Badge
                                      SizedBox(
                                        width: 115,
                                        child: TransactionStatusBadge(status: ord.ordStatus ?? ""),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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