import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Generic/rounded_searchable_textfield.dart';
import 'package:zaitoonpro/Features/Generic/underline_searchable_textfield.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/thousand_separator.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/button.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_stock_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../Features/Generic/stock_product_field.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/Widgets/txn_status_widget.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../Settings/features/Visibility/bloc/settings_visible_bloc.dart';
import 'bloc/order_by_id_bloc.dart';
import 'model/ord_by_id_model.dart';
import 'order_by_print.dart';

class OrderByIdView extends StatefulWidget {
  final int orderId;
  final String? ordName;

  const OrderByIdView({super.key, this.ordName, required this.orderId});

  @override
  State<OrderByIdView> createState() => _OrderByIdViewState();
}

class _OrderByIdViewState extends State<OrderByIdView> {
  final List<List<FocusNode>> _rowFocusNodes = [];
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, int> _qtyCursorPositions = {};
  final Map<int, int> _priceCursorPositions = {};
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  late final TextEditingController cashController;
  late final TextEditingController creditController;

  String? _userName;
  String? ccy;

  int? _cashCursorPos;
  int? _creditCursorPos;

  @override
  void initState() {
    super.initState();
    cashController = TextEditingController();
    creditController = TextEditingController();

    cashController.addListener(() {
      _cashCursorPos = cashController.selection.baseOffset;
    });

    creditController.addListener(() {
      _creditCursorPos = creditController.selection.baseOffset;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderByIdBloc>().add(LoadOrderByIdEvent(widget.orderId));
      context.read<StorageBloc>().add(LoadStorageEvent());
      context.read<ProductsBloc>().add(LoadProductsEvent());
    });

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      ccy = companyState.company.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    for (final row in _rowFocusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _personController.dispose();
    _accountController.dispose();
    cashController.dispose();
    creditController.dispose();
    super.dispose();
  }

  OrderByIdModel? xOrder;

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _userName = authState.loginData.usrName;
    }

    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);

    return BlocListener<OrderByIdBloc, OrderByIdState>(
      listener: (context, state) {
        if (state is OrderByIdLoaded) {
          _updateControllerValue(
            cashController,
            state.cashPayment.toAmount(),
            _cashCursorPos,
          );
          _updateControllerValue(
            creditController,
            state.creditAmount.toAmount(),
            _creditCursorPos,
          );
          _updateItemControllers(state.order);
        }
        if (state is OrderByIdError) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: true,
          );
        }
        if (state is OrderByIdSaved) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: !state.success,
          );
          if (state.success) {
            Navigator.of(context).pop();
          }
        }
        if (state is OrderByIdDeleted) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: !state.success,
          );
          if (state.success) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          titleSpacing: 0,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 15),
          title: isMobile
              ? Text('#${widget.orderId}')
              : Text('${widget.ordName ?? ""} #${widget.orderId}'),
          actions: _buildAppBarActions(),
        ),
        body: BlocBuilder<OrderByIdBloc, OrderByIdState>(
          builder: (context, state) {
            if (state is OrderByIdLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OrderByIdError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ZButton(
                      width: 120,
                      label: Text(AppLocalizations.of(context)!.retry),
                      onPressed: () => context.read<OrderByIdBloc>().add(
                        LoadOrderByIdEvent(widget.orderId),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is OrderByIdSaving) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.savingChanges),
                  ],
                ),
              );
            }

            if (state is OrderByIdDeleting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Deleting order...'),
                  ],
                ),
              );
            }

            if (state is OrderByIdLoaded) {
              final order = state.order;
              _initializeControllers(order);
              return isMobile
                  ? _buildMobileLayout(state)
                  : isTablet
                  ? _buildTabletLayout(state)
                  : _buildDesktopLayout(state);
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    final isMobile = _isMobile(context);
    final tr = AppLocalizations.of(context)!;

    return [
      CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
        child: IconButton(
          icon: const Icon(Icons.refresh),
          hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
          tooltip: tr.refresh,
          onPressed: () {
            context.read<OrderByIdBloc>().add(
              LoadOrderByIdEvent(widget.orderId),
            );
          },
        ),
      ),
      const SizedBox(width: 4),
      CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
        child: IconButton(
          icon: const Icon(Icons.print),
          onPressed: () => _printInvoice(),
          hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
          tooltip: tr.print,
        ),
      ),
      const SizedBox(width: 4),
      BlocBuilder<OrderByIdBloc, OrderByIdState>(
        builder: (context, state) {
          if (state is OrderByIdLoaded) {
            xOrder = state.order;
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
                  child: IconButton(
                    icon: Icon(state.isEditing ? Icons.visibility : Icons.edit),
                    onPressed: () => _toggleEditMode(),
                    hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                    tooltip: state.isEditing ? tr.cancel : tr.edit,
                  ),
                ),
                if (state.isEditing) ...[
                  const SizedBox(width: 4),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
                    child: IconButton(
                      hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                      onPressed: !state.isPaymentValid || state.selectedSupplier == null
                          ? null
                          : () => _saveChanges(),
                      tooltip: tr.saveChanges,
                      icon: const Icon(Icons.check),
                    ),
                  ),
                ],
                if (state.order.trnStateText?.toLowerCase() == 'pending') ...[
                  const SizedBox(width: 4),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _showDeleteDialog(state.order),
                      isSelected: true,
                      hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                      tooltip: tr.delete,
                    ),
                  ),
                ],
              ],
            );
          }
          return const SizedBox();
        },
      ),
      if (isMobile) const SizedBox(width: 8),
    ];
  }

  // Mobile Layout
  Widget _buildMobileLayout(OrderByIdLoaded state) {
    final order = state.order;
    final isEditing = state.isEditing;
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Center(
            child: TransactionStatusBadge(status: order.trnStateText ?? ""),
          ),
          const SizedBox(height: 12),

          // Order Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.invoiceDetails,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildMobileInfoRow(tr.invoiceType,
                      order.ordName == "Sale" ? tr.saleTitle :
                      order.ordName == "Purchase" ? tr.purchaseTitle : ""),
                  _buildMobileInfoRow(tr.referenceNumber, order.ordTrnRef ?? ""),
                  _buildMobileInfoRow(tr.totalInvoice, "${state.grandTotal.toAmount()} $ccy"),
                  _buildMobileInfoRow(tr.orderDate, order.ordEntryDate?.toDateTime ?? ""),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Party & Payment Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.ordName == "Sale" ? tr.customerAndPaymentDetails : tr.supplierAndPaymentDetails,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),

                  // Party Selection
                  if (isEditing)
                    _buildMobilePartySelection(state)
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.ordName == "Sale" ? tr.customer : tr.supplier,
                          style: TextStyle(color: color.outline, fontSize: 12),
                        ),
                        Text(
                          order.personal ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Payment Details
                  if (isEditing)
                    _buildMobileEditablePayment(state)
                  else
                    _buildMobileReadOnlyPayment(state),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Items Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.items,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),

                  // Items List
                  ..._buildMobileItemsList(order, state, isEditing),

                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ZOutlineButton(
                        icon: Icons.add,
                        label: Text(tr.addItem),
                        onPressed: () => context.read<OrderByIdBloc>().add(AddOrderItemEvent()),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildMobileOrderSummary(state),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout(OrderByIdLoaded state) {
    final order = state.order;
    final isEditing = state.isEditing;
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.ordName ?? ""} #${widget.orderId}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TransactionStatusBadge(status: order.trnStateText ?? ""),
            ],
          ),
          const SizedBox(height: 16),

          // Two Column Layout for Tablet
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // Order Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.outline.withAlpha(8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.invoiceDetails,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(),
                          _buildTabletInfoRow(tr.invoiceType,
                              order.ordName == "Sale" ? tr.saleTitle :
                              order.ordName == "Purchase" ? tr.purchaseTitle : ""),
                          _buildTabletInfoRow(tr.referenceNumber, order.ordTrnRef ?? ""),
                          _buildTabletInfoRow(tr.totalInvoice, "${state.grandTotal.toAmount()} $ccy"),
                          _buildTabletInfoRow(tr.orderDate, order.ordEntryDate?.toDateTime ?? ""),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Party & Payment Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.outline.withAlpha(8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.ordName == "Sale" ? tr.customerAndPaymentDetails : tr.supplierAndPaymentDetails,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(),

                          // Party Selection
                          if (isEditing)
                            _buildTabletPartySelection(state)
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.ordName == "Sale" ? tr.customer : tr.supplier,
                                  style: TextStyle(color: color.outline),
                                ),
                                Text(
                                  order.personal ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),

                          // Payment Details
                          if (isEditing)
                            _buildTabletEditablePayment(state)

                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.outline.withAlpha(8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildTabletOrderSummary(state),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.outline.withAlpha(8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.items,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),

                // Items Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: color.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text('#', style: TextStyle(color: color.surface))),
                      Expanded(child: Text(tr.products, style: TextStyle(color: color.surface))),
                      SizedBox(width: 80, child: Text(tr.qty, style: TextStyle(color: color.surface))),
                      SizedBox(width: 100, child: Text(tr.unitPrice, style: TextStyle(color: color.surface))),
                      SizedBox(width: 80, child: Text(tr.totalTitle, style: TextStyle(color: color.surface))),
                      if (isEditing) SizedBox(width: 40, child: Text('', style: TextStyle(color: color.surface))),
                    ],
                  ),
                ),

                // Items List
                ..._buildTabletItemsList(order, state, isEditing),

                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ZOutlineButton(
                      icon: Icons.add,
                      label: Text(tr.addItem),
                      onPressed: () => context.read<OrderByIdBloc>().add(AddOrderItemEvent()),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Desktop Layout (Original)
  Widget _buildDesktopLayout(OrderByIdLoaded state) {
    final order = state.order;
    final isEditing = state.isEditing;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Expanded(child: _buildOrderHeader(state)),
            ],
          ),
          const SizedBox(height: 15),

          // Items Header
          _buildItemsHeader(isEditing),
          const SizedBox(height: 1),

          // Items List
          _buildItemsList(order, state, isEditing),

          const SizedBox(height: 10),

          // Order Summary
          Row(
              spacing: 7,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildOrderSummary(state)),
                Expanded(child: _buildOrderHeaderDetails(state))]),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Mobile Helper Widgets
  Widget _buildMobileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMobilePartySelection(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final isPurchase = state.order.ordName?.toLowerCase().contains('purchase') ?? true;

    return GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
      controller: TextEditingController(
        text: state.selectedSupplier != null
            ? "${state.selectedSupplier?.perName ?? ""} ${state.selectedSupplier?.perLastName ?? ""}"
            : state.order.personal ?? '',
      ),
      title: isPurchase ? tr.supplier : tr.customer,
      hintText: isPurchase ? tr.supplier : tr.customer,
      bloc: context.read<IndividualsBloc>(),
      fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
      searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
      itemBuilder: (context, ind) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("${ind.perName ?? ''} ${ind.perLastName ?? ''}"),
      ),
      itemToString: (individual) => "${individual.perName} ${individual.perLastName}",
      stateToLoading: (state) => state is IndividualLoadingState,
      stateToItems: (state) {
        if (state is IndividualLoadedState) return state.individuals;
        return [];
      },
      onSelected: (value) {
        context.read<OrderByIdBloc>().add(SelectOrderSupplierEvent(value));
        context.read<AccountsBloc>().add(
          LoadAccountsFilterEvent(input: value.perId.toString(), include: '8', exclude: ''),
        );
      },
      showClearButton: true,
    );
  }

  Widget _buildMobileEditablePayment(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Mode Chips
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              selectedColor: color.primary.withAlpha(26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              label: Text(tr.cash),
              selected: state.isCashOnly,
              onSelected: (selected) {
                if (selected) {
                  context.read<OrderByIdBloc>().add(
                    UpdateOrderPaymentEvent(cashPayment: state.grandTotal, creditAmount: 0.0),
                  );
                }
              },
            ),
            ChoiceChip(
              selectedColor: color.primary.withAlpha(26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              label: Text(tr.creditTitle),
              selected: state.isCreditOnly,
              onSelected: (selected) {
                if (selected) {
                  context.read<OrderByIdBloc>().add(
                    UpdateOrderPaymentEvent(cashPayment: 0.0, creditAmount: state.grandTotal),
                  );
                }
              },
            ),
            ChoiceChip(
              selectedColor: color.primary.withAlpha(26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              label: Text(tr.combinedPayment),
              selected: state.isMixed,
              onSelected: (selected) {
                if (selected && state.grandTotal > 0) {
                  final credit = state.grandTotal / 2;
                  final cash = state.grandTotal - credit;
                  context.read<OrderByIdBloc>().add(
                    UpdateOrderPaymentEvent(cashPayment: cash, creditAmount: credit),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Account Selection
        if (state.creditAmount > 0)
          BlocBuilder<AccountsBloc, AccountsState>(
            builder: (context, accState) {
              AccountsModel? selectedAccount;
              if (accState is AccountLoadedState && state.selectedAccount != null) {
                selectedAccount = accState.accounts.firstWhere(
                      (a) => a.accNumber == state.selectedAccount!.accNumber,
                  orElse: () => state.selectedAccount!,
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                  controller: TextEditingController(
                    text: selectedAccount != null
                        ? '${selectedAccount.accNumber ?? ""} | ${selectedAccount.accName ?? ""}'
                        : '',
                  ),
                  title: tr.accounts,
                  hintText: tr.selectAccount,
                  isRequired: true,
                  bloc: context.read<AccountsBloc>(),
                  fetchAllFunction: (bloc) => bloc.add(
                    LoadAccountsFilterEvent(include: '8', exclude: ''),
                  ),
                  searchFunction: (bloc, query) => bloc.add(
                    LoadAccountsFilterEvent(input: query, include: '8', exclude: ''),
                  ),
                  itemBuilder: (context, account) => ListTile(
                    title: Text(account.accName ?? ''),
                    subtitle: Text('${account.accNumber}'),
                  ),
                  itemToString: (account) => '${account.accName ?? ""} (${account.accNumber ?? ""})',
                  stateToLoading: (state) => state is AccountLoadingState,
                  stateToItems: (state) => state is AccountLoadedState ? state.accounts : [],
                  onSelected: (value) {
                    context.read<OrderByIdBloc>().add(SelectOrderAccountEvent(value));
                  },
                  showClearButton: true,
                ),
              );
            },
          ),

        // Cash Payment
        if (state.paymentMode != PaymentMode.credit)
          ZTextFieldEntitled(
            title: tr.cashPayment,
            controller: cashController,
            inputFormat: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (value) {
              final cursorPos = cashController.selection.baseOffset;
              final cash = double.tryParse(value) ?? 0.0;
              final credit = state.grandTotal - cash;
              context.read<OrderByIdBloc>().add(
                UpdateOrderPaymentEvent(cashPayment: cash, creditAmount: credit),
              );
              if (cursorPos != -1 && cursorPos <= cashController.text.length) {
                Future.delayed(Duration.zero, () {
                  cashController.selection = TextSelection.collapsed(offset: cursorPos);
                });
              }
            },
            end: Text(ccy ?? ""),
          ),

        const SizedBox(height: 8),

        // Credit Payment
        if (state.paymentMode != PaymentMode.cash)
          ZTextFieldEntitled(
            title: tr.accountPayment,
            controller: creditController,
            inputFormat: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (value) {
              final cursorPos = creditController.selection.baseOffset;
              final credit = double.tryParse(value) ?? 0.0;
              final cash = state.grandTotal - credit;
              context.read<OrderByIdBloc>().add(
                UpdateOrderPaymentEvent(cashPayment: cash, creditAmount: credit),
              );
              if (cursorPos != -1 && cursorPos <= creditController.text.length) {
                Future.delayed(Duration.zero, () {
                  creditController.selection = TextSelection.collapsed(offset: cursorPos);
                });
              }
            },
            end: Text(ccy ?? ""),
          ),

        // Payment Validation
        if (!state.isPaymentValid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${tr.paymentMismatchTotalInvoice} (${state.totalPayment.toAmount()} ≠ ${state.grandTotal.toAmount()})',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileReadOnlyPayment(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    double creditAmount = double.tryParse(state.order.amount ?? "0.0") ?? 0.0;
    bool hasAccount = state.order.acc != null && state.order.acc! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAccount) ...[
          Row(
            children: [
              Icon(Icons.add_card_rounded, size: 16, color: color.outline),
              const SizedBox(width: 4),
              Text(tr.accountPayment, style: TextStyle(color: color.outline)),
            ],
          ),
          Text("${state.order.acc.toString()} | ${state.order.personal}"),
          Text(
            "${creditAmount.toAmount()} $ccy",
            style: TextStyle(color: color.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(Icons.money, size: 16, color: color.outline),
            const SizedBox(width: 4),
            Text(tr.cashAmount, style: TextStyle(color: color.outline)),
          ],
        ),
        Text("10101010 | ${tr.cash}"),
        Text(
          "${state.cashPayment.toAmount()} $ccy",
          style: TextStyle(color: color.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<Widget> _buildMobileItemsList(OrderByIdModel order, OrderByIdLoaded state, bool isEditing) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    if (order.records == null || order.records!.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No items found')),
        ),
      ];
    }

    return order.records!.asMap().entries.map((entry) {
      final index = entry.key;
      final record = entry.value;
      final productName = state.productNames[record.stkProduct] ?? 'Unknown';
      final isPurchase = state.order.ordName?.toLowerCase().contains('purchase') ?? true;
      final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
      final price = isPurchase ? double.tryParse(record.stkPurPrice ?? "0") ?? 0
          : double.tryParse(record.stkSalePrice ?? "0") ?? 0;
      final total = qty * price;
      final tr = AppLocalizations.of(context)!;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(26))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  "${total.toAmount()} $ccy",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Fixed this row - using string concatenation instead of Text widgets inside Row
            Text(
              '${tr.qty}: $qty  |  ${tr.unitPrice}: ${price.toAmount()} $ccy',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline
              ),
            ),

            if (!isPurchase && record.stkPurPrice != null)...[
              if(visibility.benefit)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Profit: ${(total - (double.tryParse(record.stkPurPrice!)! * qty)).toAmount()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: (total - (double.tryParse(record.stkPurPrice!)! * qty)) >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
            ],

            if (isEditing)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _removeItemDialog(index),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMobileOrderSummary(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final isSale = state.order.ordName?.toLowerCase().contains('sale') ?? false;
    final visibility = context.read<SettingsVisibleBloc>().state;
    double totalCost = 0.0;
    double totalProfit = 0.0;

    if (isSale && state.order.records != null) {
      for (final record in state.order.records!) {
        final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
        final purPrice = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        final salePrice = double.tryParse(record.stkSalePrice ?? "0") ?? 0;
        totalCost += qty * purPrice;
        totalProfit += qty * (salePrice - purPrice);
      }
    }

    return Column(
      children: [
        if(visibility.benefit)...[
          if (isSale) ...[
            _buildMobileSummaryRow(tr.profit, totalProfit, color: totalProfit >= 0 ? Colors.green : Colors.red, isBold: true),
            if (totalCost > 0)
              _buildMobileSummaryRow('${tr.profit} %',
                  double.parse((totalProfit / totalCost * 100).toStringAsFixed(2)),
                  color: totalProfit >= 0 ? Colors.green : Colors.red),
            const Divider(),
          ],
        ],
        _buildMobileSummaryRow(tr.grandTotal, state.grandTotal, isBold: true),
        if (state.cashPayment > 0)
          _buildMobileSummaryRow(tr.cashPayment, state.cashPayment, color: Colors.green),
        if (state.creditAmount > 0)
          _buildMobileSummaryRow(tr.accountPayment, state.creditAmount, color: Colors.orange),
        if (state.selectedAccount != null && state.creditAmount > 0) ...[
          const Divider(),
          _buildMobileSummaryRow(tr.currentBalance,
              double.tryParse(state.selectedAccount!.accAvailBalance ?? "0.0") ?? 0.0,
              color: Colors.deepOrangeAccent),
          _buildMobileSummaryRow(tr.newBalance,
              (double.tryParse(state.selectedAccount!.accAvailBalance ?? "0.0") ?? 0.0) + state.creditAmount,
              isBold: true, color: color.primary),
        ],
      ],
    );
  }

  Widget _buildMobileSummaryRow(String label, double value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            "${value.toAmount()} $ccy",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Tablet Helper Widgets
  Widget _buildTabletInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildTabletPartySelection(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final isPurchase = state.order.ordName?.toLowerCase().contains('purchase') ?? true;

    return GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
      controller: TextEditingController(
        text: state.selectedSupplier != null
            ? "${state.selectedSupplier?.perName ?? ""} ${state.selectedSupplier?.perLastName ?? ""}"
            : state.order.personal ?? '',
      ),
      title: isPurchase ? tr.supplier : tr.customer,
      hintText: isPurchase ? tr.supplier : tr.customer,
      bloc: context.read<IndividualsBloc>(),
      fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
      searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
      itemBuilder: (context, ind) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("${ind.perName ?? ''} ${ind.perLastName ?? ''}"),
      ),
      itemToString: (individual) => "${individual.perName} ${individual.perLastName}",
      stateToLoading: (state) => state is IndividualLoadingState,
      stateToItems: (state) {
        if (state is IndividualLoadedState) return state.individuals;
        return [];
      },
      onSelected: (value) {
        context.read<OrderByIdBloc>().add(SelectOrderSupplierEvent(value));
        context.read<AccountsBloc>().add(
          LoadAccountsFilterEvent(input: value.perId.toString(), include: '8', exclude: ''),
        );
      },
      showClearButton: true,
    );
  }

  Widget _buildTabletEditablePayment(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              selectedColor: color.primary.withAlpha(26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              label: Text(tr.cash),
              selected: state.isCashOnly,
              onSelected: (selected) {
                if (selected) {
                  context.read<OrderByIdBloc>().add(
                    UpdateOrderPaymentEvent(cashPayment: state.grandTotal, creditAmount: 0.0),
                  );
                }
              },
            ),
            ChoiceChip(
              selectedColor: color.primary.withAlpha(26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              label: Text(tr.creditTitle),
              selected: state.isCreditOnly,
              onSelected: (selected) {
                if (selected) {
                  context.read<OrderByIdBloc>().add(
                    UpdateOrderPaymentEvent(cashPayment: 0.0, creditAmount: state.grandTotal),
                  );
                }
              },
            ),
            ChoiceChip(
              selectedColor: color.primary.withAlpha(26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              label: Text(tr.combinedPayment),
              selected: state.isMixed,
              onSelected: (selected) {
                if (selected && state.grandTotal > 0) {
                  final credit = state.grandTotal / 2;
                  final cash = state.grandTotal - credit;
                  context.read<OrderByIdBloc>().add(
                    UpdateOrderPaymentEvent(cashPayment: cash, creditAmount: credit),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (state.creditAmount > 0)
          BlocBuilder<AccountsBloc, AccountsState>(
            builder: (context, accState) {
              AccountsModel? selectedAccount;
              if (accState is AccountLoadedState && state.selectedAccount != null) {
                selectedAccount = accState.accounts.firstWhere(
                      (a) => a.accNumber == state.selectedAccount!.accNumber,
                  orElse: () => state.selectedAccount!,
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                  controller: TextEditingController(
                    text: selectedAccount != null
                        ? '${selectedAccount.accNumber ?? ""} | ${selectedAccount.accName ?? ""}'
                        : '',
                  ),
                  title: tr.accounts,
                  hintText: tr.selectAccount,
                  isRequired: true,
                  bloc: context.read<AccountsBloc>(),
                  fetchAllFunction: (bloc) => bloc.add(
                    LoadAccountsFilterEvent(include: '8', exclude: ''),
                  ),
                  searchFunction: (bloc, query) => bloc.add(
                    LoadAccountsFilterEvent(input: query, include: '8', exclude: ''),
                  ),
                  itemBuilder: (context, account) => ListTile(
                    title: Text(account.accName ?? ''),
                    subtitle: Text('${account.accNumber}'),
                  ),
                  itemToString: (account) => '${account.accName ?? ""} (${account.accNumber ?? ""})',
                  stateToLoading: (state) => state is AccountLoadingState,
                  stateToItems: (state) => state is AccountLoadedState ? state.accounts : [],
                  onSelected: (value) {
                    context.read<OrderByIdBloc>().add(SelectOrderAccountEvent(value));
                  },
                  showClearButton: true,
                ),
              );
            },
          ),

        Row(
          children: [
            Expanded(
              child: ZTextFieldEntitled(
                title: tr.cashPayment,
                controller: cashController,
                inputFormat: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                onChanged: (value) {
                  final cursorPos = cashController.selection.baseOffset;
                  final cash = double.tryParse(value) ?? 0.0;
                  final credit = state.grandTotal - cash;
                  context.read<OrderByIdBloc>().add(
                    UpdateOrderPaymentEvent(cashPayment: cash, creditAmount: credit),
                  );
                  if (cursorPos != -1 && cursorPos <= cashController.text.length) {
                    Future.delayed(Duration.zero, () {
                      cashController.selection = TextSelection.collapsed(offset: cursorPos);
                    });
                  }
                },
                end: Text(ccy ?? ""),
              ),
            ),
            if (state.paymentMode != PaymentMode.cash) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ZTextFieldEntitled(
                  title: tr.accountPayment,
                  controller: creditController,
                  inputFormat: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (value) {
                    final cursorPos = creditController.selection.baseOffset;
                    final credit = double.tryParse(value) ?? 0.0;
                    final cash = state.grandTotal - credit;
                    context.read<OrderByIdBloc>().add(
                      UpdateOrderPaymentEvent(cashPayment: cash, creditAmount: credit),
                    );
                    if (cursorPos != -1 && cursorPos <= creditController.text.length) {
                      Future.delayed(Duration.zero, () {
                        creditController.selection = TextSelection.collapsed(offset: cursorPos);
                      });
                    }
                  },
                  end: Text(ccy ?? ""),
                ),
              ),
            ],
          ],
        ),

        if (!state.isPaymentValid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${tr.paymentMismatchTotalInvoice} (${state.totalPayment.toAmount()} ≠ ${state.grandTotal.toAmount()})',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }


  List<Widget> _buildTabletItemsList(OrderByIdModel order, OrderByIdLoaded state, bool isEditing) {
    if (order.records == null || order.records!.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No items found')),
        ),
      ];
    }

    return order.records!.asMap().entries.map((entry) {
      final index = entry.key;
      final record = entry.value;
      final productName = state.productNames[record.stkProduct] ?? 'Unknown';
      final isPurchase = state.order.ordName?.toLowerCase().contains('purchase') ?? true;
      final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
      final price = isPurchase
          ? double.tryParse(record.stkPurPrice ?? "0") ?? 0
          : double.tryParse(record.stkSalePrice ?? "0") ?? 0;
      final total = qty * price;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(26))),
        ),
        child: Row(
          children: [
            SizedBox(width: 40, child: Text((index + 1).toString())),
            Expanded(child: Text(productName, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 80, child: Text(qty.toString())),
            SizedBox(width: 100, child: Text(price.toAmount())),
            SizedBox(
              width: 80,
              child: Text(
                total.toAmount(),
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            if (isEditing)
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _removeItemDialog(index),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTabletOrderSummary(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final isSale = state.order.ordName?.toLowerCase().contains('sale') ?? false;
    final visibility = context.read<SettingsVisibleBloc>().state;
    double totalCost = 0.0;
    double totalProfit = 0.0;

    if (isSale && state.order.records != null) {
      for (final record in state.order.records!) {
        final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
        final purPrice = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        final salePrice = double.tryParse(record.stkSalePrice ?? "0") ?? 0;
        totalCost += qty * purPrice;
        totalProfit += qty * (salePrice - purPrice);
      }
    }

    return Column(
      children: [
        if(visibility.benefit)...[
          if (isSale) ...[
            _buildTabletSummaryRow(tr.totalCost, totalCost),
            _buildTabletSummaryRow(tr.profit, totalProfit,
                color: totalProfit >= 0 ? Colors.green : Colors.red, isBold: true),
            if (totalCost > 0)
              _buildTabletSummaryRow('${tr.profit} %',
                  double.parse((totalProfit / totalCost * 100).toStringAsFixed(2)),
                  color: totalProfit >= 0 ? Colors.green : Colors.red),
            const Divider(),
          ],
        ],
        _buildTabletSummaryRow(tr.grandTotal, state.grandTotal, isBold: true),
        if (state.cashPayment > 0)
          _buildTabletSummaryRow(tr.cashPayment, state.cashPayment, color: Colors.green),
        if (state.creditAmount > 0)
          _buildTabletSummaryRow(tr.accountPayment, state.creditAmount, color: Colors.orange),
        if (state.selectedAccount != null && state.creditAmount > 0) ...[
          const Divider(),
          _buildTabletSummaryRow(tr.currentBalance,
              double.tryParse(state.selectedAccount!.accAvailBalance ?? "0.0") ?? 0.0,
              color: Colors.deepOrangeAccent),
          _buildTabletSummaryRow(tr.newBalance,
              (double.tryParse(state.selectedAccount!.accAvailBalance ?? "0.0") ?? 0.0) + state.creditAmount,
              isBold: true, color: color.primary),
        ],
      ],
    );
  }

  Widget _buildTabletSummaryRow(String label, double value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            "${value.toAmount()} $ccy",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to update controller value
  void _updateControllerValue(
      TextEditingController controller,
      String newValue,
      int? savedCursorPos,
      ) {
    if (controller.text == newValue) return;

    final currentCursorPos = savedCursorPos ?? controller.selection.baseOffset;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.value = controller.value.copyWith(
        text: newValue,
        selection: TextSelection.collapsed(
          offset: currentCursorPos != -1 && currentCursorPos <= newValue.length
              ? currentCursorPos
              : newValue.length,
        ),
        composing: TextRange.empty,
      );
    });
  }

  void _updateItemControllers(OrderByIdModel order) {
    if (order.records == null) return;

    for (var i = 0; i < order.records!.length; i++) {
      final record = order.records![i];

      if (_qtyControllers.containsKey(i)) {
        final savedCursorPos = _qtyCursorPositions[i];
        _updateControllerValue(
          _qtyControllers[i]!,
          record.stkQuantity ?? "",
          savedCursorPos,
        );
      }

      if (_priceControllers.containsKey(i)) {
        final savedCursorPos = _priceCursorPositions[i];
        final isPurchase = order.ordName?.toLowerCase().contains('purchase') ?? true;
        final priceText = isPurchase
            ? record.stkPurPrice?.toAmount()
            : record.stkSalePrice?.toAmount();

        _updateControllerValue(
          _priceControllers[i]!,
          priceText ?? "",
          savedCursorPos,
        );
      }
    }
  }

  void _initializeControllers(OrderByIdModel order) {
    if (order.records == null) return;

    while (_rowFocusNodes.length < order.records!.length) {
      _rowFocusNodes.add([FocusNode(), FocusNode()]);
    }
    while (_rowFocusNodes.length > order.records!.length) {
      final removed = _rowFocusNodes.removeLast();
      for (final node in removed) {
        node.dispose();
      }
    }

    for (var i = 0; i < order.records!.length; i++) {
      final record = order.records![i];

      if (!_qtyControllers.containsKey(i)) {
        _qtyControllers[i] = TextEditingController(text: record.stkQuantity);
      }

      final isPurchase = order.ordName?.toLowerCase().contains('purchase') ?? true;
      final priceText = isPurchase
          ? record.stkPurPrice?.toAmount()
          : record.stkSalePrice?.toAmount();

      if (!_priceControllers.containsKey(i)) {
        _priceControllers[i] = TextEditingController(text: priceText);
      }
    }
  }

  // Desktop original methods (kept as is)
  Widget _buildOrderHeader(OrderByIdLoaded state) {
    final order = state.order;
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final String paymentTitle = order.ordName == "Sale"
        ? tr.customerAndPaymentDetails
        : tr.supplierAndPaymentDetails;
    return ZCover(
      radius: 8,
      color: color.outline.withAlpha(8),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  paymentTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TransactionStatusBadge(status: order.trnStateText ?? ""),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(),
            const SizedBox(height: 5),

            Row(
              children: [
                Expanded(
                  child: state.isEditing
                      ? GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                    controller: TextEditingController(
                      text: state.selectedSupplier != null
                          ? "${state.selectedSupplier?.perName ?? ""} ${state.selectedSupplier?.perLastName ?? ""}"
                          : order.personal ?? '',
                    ),
                    title: order.ordName?.toLowerCase().contains('purchase') ?? true
                        ? tr.supplier
                        : tr.customer,
                    hintText: order.ordName?.toLowerCase().contains('purchase') ?? true
                        ? tr.supplier
                        : tr.customer,
                    bloc: context.read<IndividualsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                    searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
                    itemBuilder: (context, ind) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("${ind.perName ?? ''} ${ind.perLastName ?? ''}"),
                    ),
                    itemToString: (individual) => "${individual.perName} ${individual.perLastName}",
                    stateToLoading: (state) => state is IndividualLoadingState,
                    stateToItems: (state) {
                      if (state is IndividualLoadedState) return state.individuals;
                      return [];
                    },
                    onSelected: (value) {
                      context.read<OrderByIdBloc>().add(SelectOrderSupplierEvent(value));
                      context.read<AccountsBloc>().add(
                        LoadAccountsFilterEvent(
                          input: value.perId.toString(),
                          include: '8',
                          exclude: '',
                        ),
                      );
                    },
                    showClearButton: true,
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.ordName?.toLowerCase().contains('purchase') ?? true
                            ? tr.supplier
                            : tr.customer,
                        style: TextStyle(color: color.outline),
                      ),
                      Text(
                        order.personal ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (state.isEditing)
              _buildEditablePaymentSection(state)

          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeaderDetails(OrderByIdLoaded state) {
    final order = state.order;
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final String invoiceType = order.ordName == "Sale"
        ? tr.saleTitle
        : order.ordName == "Purchase"
        ? tr.purchaseTitle
        : "";
    return ZCover(
      radius: 5,
      color: color.outline.withAlpha(8),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr.invoiceDetails,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text("${tr.orderId} #${order.ordId}"),
            ],
          ),
          const Divider(),
          rowHeader(title: tr.invoiceType, value: invoiceType),
          const SizedBox(height: 5),
          rowHeader(title: tr.referenceNumber, value: order.ordTrnRef),
          const SizedBox(height: 5),
          rowHeader(title: tr.orderDate, value: order.ordEntryDate?.toDateTime),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildEditablePaymentSection(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.paymentDetails,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Divider(),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selectedColor: color.primary.withAlpha(26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    label: Text(tr.cash),
                    selected: state.isCashOnly,
                    onSelected: (selected) {
                      if (selected) {
                        context.read<OrderByIdBloc>().add(
                          UpdateOrderPaymentEvent(
                            cashPayment: state.grandTotal,
                            creditAmount: 0.0,
                          ),
                        );
                      }
                    },
                  ),
                  ChoiceChip(
                    selectedColor: color.primary.withAlpha(26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    label: Text(tr.creditTitle),
                    selected: state.isCreditOnly,
                    onSelected: (selected) {
                      if (selected) {
                        context.read<OrderByIdBloc>().add(
                          UpdateOrderPaymentEvent(
                            cashPayment: 0.0,
                            creditAmount: state.grandTotal,
                          ),
                        );
                      }
                    },
                  ),
                  ChoiceChip(
                    selectedColor: color.primary.withAlpha(26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    label: Text(tr.combinedPayment),
                    selected: state.isMixed,
                    onSelected: (selected) {
                      if (selected && state.grandTotal > 0) {
                        final credit = state.grandTotal / 2;
                        final cash = state.grandTotal - credit;
                        context.read<OrderByIdBloc>().add(
                          UpdateOrderPaymentEvent(
                            cashPayment: cash,
                            creditAmount: credit,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        if (state.isEditing && state.creditAmount > 0) ...[
          BlocBuilder<AccountsBloc, AccountsState>(
            builder: (context, accState) {
              AccountsModel? selectedAccount;

              if (accState is AccountLoadedState && state.selectedAccount != null) {
                selectedAccount = accState.accounts.firstWhere(
                      (a) => a.accNumber == state.selectedAccount!.accNumber,
                  orElse: () => state.selectedAccount!,
                );
              }

              return GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                controller: TextEditingController(
                  text: selectedAccount != null ? '${selectedAccount.accNumber ?? ""} | ${selectedAccount.accName ?? ""}'
                      : '',
                ),
                title: tr.accounts,
                hintText: tr.selectAccount,
                isRequired: state.creditAmount > 0,
                bloc: context.read<AccountsBloc>(),
                fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: state.order.perId)),
                searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: state.order.perId)),
                itemBuilder: (context, account) => ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  dense: true,visualDensity: VisualDensity(vertical: -4),
                  title: Text(account.accName ?? ''),
                  subtitle: Text('${account.accNumber}'),
                ),
                itemToString: (account) =>
                '${account.accName ?? ""} (${account.accNumber ?? ""})',
                stateToLoading: (state) => state is AccountLoadingState,
                stateToItems: (state) =>
                state is AccountLoadedState ? state.accounts : [],
                onSelected: (value) {
                  context.read<OrderByIdBloc>().add(
                    SelectOrderAccountEvent(value),
                  );
                },
                showClearButton: true,
              );
            },
          ),

          const SizedBox(height: 8),
        ],

        if (state.paymentMode != PaymentMode.credit)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ZTextFieldEntitled(
                  title: tr.cashPayment,
                  controller: cashController,
                  inputFormat: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (value) {
                    final cursorPos = cashController.selection.baseOffset;
                    final cash = double.tryParse(value) ?? 0.0;
                    final credit = state.grandTotal - cash;

                    context.read<OrderByIdBloc>().add(
                      UpdateOrderPaymentEvent(
                        cashPayment: cash,
                        creditAmount: credit,
                      ),
                    );

                    if (cursorPos != -1 && cursorPos <= cashController.text.length) {
                      Future.delayed(Duration.zero, () {
                        cashController.selection = TextSelection.collapsed(
                          offset: cursorPos,
                        );
                      });
                    }
                  },
                  end: Text(ccy ?? ""),
                ),
              ),
              if (state.paymentMode != PaymentMode.cash) ...[
                const SizedBox(width: 5),
                Expanded(
                  child: ZTextFieldEntitled(
                    title: tr.accountPayment,
                    controller: creditController,
                    inputFormat: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (value) {
                      final cursorPos = creditController.selection.baseOffset;
                      final credit = double.tryParse(value) ?? 0.0;
                      final cash = state.grandTotal - credit;

                      context.read<OrderByIdBloc>().add(
                        UpdateOrderPaymentEvent(
                          cashPayment: cash,
                          creditAmount: credit,
                        ),
                      );

                      if (cursorPos != -1 && cursorPos <= creditController.text.length) {
                        Future.delayed(Duration.zero, () {
                          creditController.selection = TextSelection.collapsed(
                            offset: cursorPos,
                          );
                        });
                      }
                    },
                    end: Text(ccy ?? ""),
                  ),
                ),
              ],
            ],
          ),

        if (!state.isPaymentValid)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${tr.paymentMismatchTotalInvoice} (${state.totalPayment.toAmount()} ≠ ${state.grandTotal.toAmount()})',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        if (state.selectedAccount != null && state.creditAmount > 0 && state.selectedAccount?.accAvailBalance !=null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Divider(color: color.outline.withAlpha(77)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.currentBalance,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    (double.tryParse(state.selectedAccount!.accAvailBalance ?? "0.0") ?? 0.0)
                        .toAmount(),
                    style: const TextStyle(color: Colors.deepOrangeAccent),
                  ),
                ],
              ),
              Divider(color: color.outline.withAlpha(77)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.newBalance,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ((double.tryParse(state.selectedAccount!.accAvailBalance ?? "0.0") ?? 0.0) +
                        state.creditAmount)
                        .toAmount(),
                    style: TextStyle(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildItemsHeader(bool isEditing) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? title = Theme.of(context).textTheme.titleSmall?.copyWith(color: color.surface);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: title)),
          Expanded(child: Text(locale.products, style: title)),
          SizedBox(width: 100, child: Text(locale.qty, style: title)),
          SizedBox(width: 150, child: Text(locale.unitPrice, style: title)),
          SizedBox(width: 100, child: Text(locale.totalTitle, style: title)),
          SizedBox(width: 180, child: Text(locale.storage, style: title)),
          if (isEditing)
            SizedBox(width: 60, child: Text(locale.actions, style: title)),
        ],
      ),
    );
  }

  Widget _buildItemsList(
      OrderByIdModel order,
      OrderByIdLoaded state,
      bool isEditing,
      ) {
    if (order.records == null || order.records!.isEmpty) {
      return ZCover(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Items Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: order.records!.length,
          itemBuilder: (context, index) {
            final record = order.records![index];
            final nodes = _rowFocusNodes.length > index
                ? _rowFocusNodes[index]
                : [FocusNode(), FocusNode()];
            return _buildItemRow(
              record: record,
              index: index,
              state: state,
              nodes: nodes,
              isEditing: isEditing,
            );
          },
        ),
        if (isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                ZOutlineButton(
                  icon: Icons.add,
                  label: Text(AppLocalizations.of(context)!.addItem),
                  onPressed: () =>
                      context.read<OrderByIdBloc>().add(AddOrderItemEvent()),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemRow({
    required OrderRecords record,
    required int index,
    required OrderByIdLoaded state,
    required List<FocusNode> nodes,
    required bool isEditing,
  }) {
    final locale = AppLocalizations.of(context)!;
    final productName = state.productNames[record.stkProduct] ?? 'Unknown';
    final storageName = state.storageNames[record.stkStorage] ?? 'Unknown';
    final isPurchase = state.order.ordName?.toLowerCase().contains('purchase') ?? true;
    final visibility = context.read<SettingsVisibleBloc>().state;
    final productController = TextEditingController(text: productName);
    final qtyController = _qtyControllers[index] ?? TextEditingController(text: record.stkQuantity);
    final storageController = TextEditingController(text: storageName);

    if (!_qtyControllers.containsKey(index)) {
      _qtyControllers[index] = qtyController;
    }

    final priceText = isPurchase
        ? record.stkPurPrice?.toAmount()
        : record.stkSalePrice?.toAmount();

    final priceController = _priceControllers[index] ?? TextEditingController(text: priceText);
    if (!_priceControllers.containsKey(index)) {
      _priceControllers[index] = priceController;
    }

    final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
    double price;

    if (isPurchase) {
      price = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
    } else {
      price = double.tryParse(record.stkSalePrice ?? "0") ?? 0;
    }

    final total = qty * price;

    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    TextStyle? title = textTheme.titleSmall?.copyWith(color: color.primary);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isEditing ? 0 : 8,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: index.isEven
            ? Theme.of(context).colorScheme.outline.withAlpha(13)
            : Colors.transparent,
        border: Border(bottom: BorderSide(color: color.outline.withAlpha(26))),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text((index + 1).toString())),

          // Product Selection Column - Using ProductSearchField for desktop
          Expanded(
            child: isEditing
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use ProductSearchField for desktop
                ProductSearchField<dynamic, ProductsBloc, ProductsState>(
                  controller: productController,
                  bloc: context.read<ProductsBloc>(),
                  searchFunction: (bloc, query) => isPurchase
                      ? bloc.add(LoadProductsEvent())
                      : bloc.add(LoadProductsStockEvent(input: query)),
                  fetchAllFunction: (bloc) => isPurchase
                      ? bloc.add(LoadProductsEvent())
                      : bloc.add(LoadProductsStockEvent()),
                  stateToItems: (state) {
                    if (isPurchase) {
                      if (state is ProductsLoadedState) return state.products;
                    } else {
                      if (state is ProductsStockLoadedState) {
                        return state.products;
                      }
                    }
                    return [];
                  },
                  stateToLoading: (state) => state is ProductsLoadingState,
                  itemToString: (product) {
                    if (isPurchase) {
                      return (product as ProductsModel).proName ?? '';
                    } else {
                      return (product as ProductsStockModel).proName ?? '';
                    }
                  },
                  onProductSelected: (product) {
                    if (product == null) return;

                    int productId;
                    String productName;

                    if (isPurchase) {
                      final purchaseProduct = product as ProductsModel;
                      productId = purchaseProduct.proId!;
                      productName = purchaseProduct.proName ?? '';

                      context.read<OrderByIdBloc>().add(
                        UpdateOrderItemEvent(
                          index: index,
                          productId: productId,
                          productName: productName,
                          price: 0.0,
                        ),
                      );

                      priceController.text = "0.00";
                    } else {
                      final stockProduct = product as ProductsStockModel;
                      productId = stockProduct.proId!;
                      productName = stockProduct.proName ?? '';

                      final purchasePrice = double.tryParse(
                          stockProduct.averagePrice?.replaceAll(',', '') ?? "0.0"
                      ) ?? 0.0;

                      final salePrice = double.tryParse(
                          stockProduct.sellPrice?.replaceAll(',', '') ?? "0.0"
                      ) ?? 0.0;

                      final storageId = stockProduct.stkStorage;
                      if (storageId != null && storageId > 0) {
                        context.read<OrderByIdBloc>().add(
                          UpdateOrderItemEvent(
                            index: index,
                            productId: productId,
                            productName: productName,
                            storageId: storageId,
                            price: salePrice,
                          ),
                        );

                        context.read<OrderByIdBloc>().add(
                          UpdateOrderItemEvent(
                            index: index,
                            productId: productId,
                            productName: productName,
                            price: purchasePrice,
                            isPurchasePrice: true,
                          ),
                        );
                        storageController.text = stockProduct.stgName ?? '';
                      } else {
                        context.read<OrderByIdBloc>().add(
                          UpdateOrderItemEvent(
                            index: index,
                            productId: productId,
                            productName: productName,
                            price: salePrice,
                          ),
                        );

                        context.read<OrderByIdBloc>().add(
                          UpdateOrderItemEvent(
                            index: index,
                            productId: productId,
                            productName: productName,
                            price: purchasePrice,
                            isPurchasePrice: true,
                          ),
                        );
                      }
                      priceController.text = salePrice.toAmount();
                    }
                  },

                  // Required product-specific fields
                  getProductId: (product) {
                    if (isPurchase) {
                      return (product as ProductsModel).proId?.toString();
                    } else {
                      return (product as ProductsStockModel).proId?.toString();
                    }
                  },
                  getProductName: (product) {
                    if (isPurchase) {
                      return (product as ProductsModel).proName;
                    } else {
                      return (product as ProductsStockModel).proName;
                    }
                  },
                  getProductCode: (product) {
                    if (isPurchase) {
                      return (product as ProductsModel).proCode;
                    } else {
                      return (product as ProductsStockModel).proCode;
                    }
                  },
                  getStorageId: (product) {
                    if (!isPurchase && product is ProductsStockModel) {
                      return product.stkStorage;
                    }
                    return null;
                  },
                  getStorageName: (product) {
                    if (!isPurchase && product is ProductsStockModel) {
                      return product.stgName;
                    }
                    return null;
                  },
                  getAvailable: (product) {
                    if (!isPurchase && product is ProductsStockModel) {
                      return product.available;
                    }
                    return '0';
                  },
                  getAveragePrice: (product) {
                    if (!isPurchase && product is ProductsStockModel) {
                      return product.averagePrice;
                    }
                    return '0';
                  },
                  getRecentPrice: (product) {
                    if (isPurchase && product is ProductsModel) {
                      return '0';
                    } else if (!isPurchase && product is ProductsStockModel) {
                      return product.recentPurPrice;
                    }
                    return '0';
                  },
                  getSellPrice: (product) {
                    if (!isPurchase && product is ProductsStockModel) {
                      return product.sellPrice;
                    }
                    return '0';
                  },

                  // Customize appearance
                  customListItemBuilder: (context, product) {
                    if (isPurchase) {
                      final prod = product as ProductsModel;
                      return ListTile(
                        title: Text(prod.proName ?? ''),
                        subtitle: Text(prod.proCode ?? ''),
                        trailing: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text("T")],
                        ),
                      );
                    } else {
                      final prod = product as ProductsStockModel;
                      return ListTile(
                        title: Text(prod.proName ?? ''),
                        subtitle: Row(
                          spacing: 5,
                          children: [
                            Wrap(
                              children: [
                                ZCover(
                                  child: Text(tr.purchasePrice, style: title),
                                ),
                                ZCover(child: Text(prod.averagePrice.toAmount())),
                              ],
                            ),
                            Wrap(
                              children: [
                                ZCover(
                                  radius: 0,
                                  child: Text(
                                    tr.salePriceBrief,
                                    style: title,
                                  ),
                                ),
                                ZCover(
                                  radius: 0,
                                  child: Text(prod.sellPrice.toAmount()),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              prod.available ?? '0',
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              prod.stgName ?? "",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },

                  // Open overlay on focus for better UX
                  openOverlayOnFocus: true,
                  showAllOnFocus: true,
                  hintText: locale.products,
                  noResultsText: 'No products found',
                  getBatch: (product)=> product.stkQtyInBatch,
                  getLandedPrice: (product)=> product.recentLandedPurPrice,
                ),

                // Show product details if not editing
                if (!isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      productName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            )
                : TextField(
              controller: productController,
              readOnly: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          // Quantity field
          SizedBox(
            width: 100,
            child: TextField(
              controller: qtyController,
              focusNode: isEditing ? nodes[0] : null,
              readOnly: !isEditing,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: isEditing
                  ? (value) {
                final cursorPos = qtyController.selection.baseOffset;
                _qtyCursorPositions[index] = cursorPos;

                final qty = double.tryParse(value) ?? 0.0;
                context.read<OrderByIdBloc>().add(
                  UpdateOrderItemEvent(index: index, quantity: qty),
                );

                if (cursorPos != -1 && cursorPos <= qtyController.text.length) {
                  Future.delayed(Duration.zero, () {
                    qtyController.selection = TextSelection.collapsed(
                      offset: cursorPos,
                    );
                  });
                }
              } : null,
            ),
          ),

          // Price field
          SizedBox(
            width: 150,
            child: TextField(
              controller: priceController,
              focusNode: isEditing ? nodes[1] : null,
              readOnly: !isEditing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                SmartThousandsDecimalFormatter(),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: isEditing
                  ? (value) {
                final cursorPos = priceController.selection.baseOffset;
                _priceCursorPositions[index] = cursorPos;

                final price = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                context.read<OrderByIdBloc>().add(
                  UpdateOrderItemEvent(index: index, price: price),
                );

                if (cursorPos != -1 && cursorPos <= priceController.text.length) {
                  Future.delayed(Duration.zero, () {
                    priceController.selection = TextSelection.collapsed(
                      offset: cursorPos,
                    );
                  });
                }
              } : null,
            ),
          ),

          // Total column
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total.toAmount(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (!isPurchase && record.stkPurPrice != null && double.tryParse(record.stkPurPrice!)! > 0)...[
                  if(visibility.benefit)
                    Text(
                      'Profit: ${(total - (double.tryParse(record.stkPurPrice!)! * qty)).toAmount()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: (total - (double.tryParse(record.stkPurPrice!)! * qty)) >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                ],

              ],
            ),
          ),

          // Storage field
          SizedBox(
            width: 180,
            child: isEditing ? GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
              controller: storageController,
              hintText: locale.storage,
              bloc: context.read<StorageBloc>(),
              fetchAllFunction: (bloc) => bloc.add(LoadStorageEvent()),
              searchFunction: (bloc, query) => bloc.add(LoadStorageEvent()),
              itemBuilder: (context, stg) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(stg.stgName ?? ''),
              ),
              itemToString: (stg) => stg.stgName ?? '',
              stateToLoading: (state) => state is StorageLoadingState,
              stateToItems: (state) {
                if (state is StorageLoadedState) return state.storage;
                return [];
              },
              onSelected: (storage) {
                context.read<OrderByIdBloc>().add(
                  UpdateOrderItemEvent(
                    index: index,
                    storageId: storage.stgId,
                  ),
                );
              },
              title: '',
            ) : TextField(
              controller: storageController,
              readOnly: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          // Delete button
          if (isEditing)
            SizedBox(
              width: 60,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _removeItemDialog(index),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(OrderByIdLoaded state) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final visibility = context.read<SettingsVisibleBloc>().state;
    final isSale = state.order.ordName?.toLowerCase().contains('sale') ?? false;
    double totalCost = 0.0;
    double totalProfit = 0.0;
    if (isSale && state.order.records != null) {
      for (final record in state.order.records!) {
        final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
        final purPrice = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        final salePrice = double.tryParse(record.stkSalePrice ?? "0") ?? 0;
        totalCost += qty * purPrice;
        totalProfit += qty * (salePrice - purPrice);
      }
    }

    return ZCover(
      radius: 5,
      padding: const EdgeInsets.all(14),
      color: color.outline.withAlpha(8),
      child: Column(
        children: [

          if(visibility.benefit)...[
            if (isSale) ...[
              _buildSummaryRow(
                label: tr.profit,
                value: totalProfit,
                color: totalProfit >= 0 ? Colors.green : Colors.red,
                isBold: true,
              ),
              if (totalCost > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${tr.profit} %', style: const TextStyle(fontSize: 14)),
                    Text(
                      '${(totalProfit / totalCost * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: totalProfit >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              Divider(color: color.outline.withAlpha(77)),
            ],
          ],

          _buildSummaryRow(
            label: tr.grandTotal,
            value: state.grandTotal,
            isBold: true,
          ),

          if (state.cashPayment > 0)
            _buildSummaryRow(
              label: tr.cashPayment,
              value: state.cashPayment,
              color: Colors.green,
            ),

          if (state.creditAmount > 0)
            _buildSummaryRow(
              label: "${tr.creditTitle} | ${state.order.acc}",
              value: state.creditAmount,
              color: Colors.orange,
            ),

          if (state.selectedAccount != null && state.creditAmount > 0)
            Column(
              children: [
                Divider(color: color.outline.withAlpha(77)),
                if(state.selectedAccount?.accAvailBalance != null && state.selectedAccount!.accAvailBalance!.isNotEmpty)
                _buildSummaryRow(
                  label: tr.currentBalance,
                  value: double.tryParse(state.selectedAccount!.accAvailBalance ?? "0.0") ?? 0.0,
                  color: Colors.deepOrangeAccent,
                ),
                _buildSummaryRow(
                  label: tr.newBalance,
                  value: (double.tryParse(state.selectedAccount!.accAvailBalance ?? "0.0") ?? 0.0) +
                      state.creditAmount,
                  isBold: true,
                  color: color.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required String label, required double value, bool isBold = false, Color? color,}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            "${value.toAmount()} $ccy",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget rowHeader({required String title, dynamic value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Text(value.toString()),
      ],
    );
  }

  void _toggleEditMode() {
    final state = context.read<OrderByIdBloc>().state;
    if (state is OrderByIdLoaded) {
      context.read<OrderByIdBloc>().add(ToggleEditModeEvent());
    }
  }

  void _removeItemDialog(int index) {
    final tr = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.removeItem),
        content: Text(tr.removeItemMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<OrderByIdBloc>().add(RemoveOrderItemEvent(index));
              Navigator.pop(context);
            },
            child: Text(tr.remove),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    if (_userName == null) {
      Utils.showOverlayMessage(
        context,
        message: 'User not authenticated',
        isError: true,
      );
      return;
    }

    final state = context.read<OrderByIdBloc>().state;

    if (state is! OrderByIdLoaded) {
      Utils.showOverlayMessage(
        context,
        message: 'Order not loaded',
        isError: true,
      );
      return;
    }

    final currentState = state;

    if (currentState.selectedSupplier == null) {
      final tr = AppLocalizations.of(context)!;
      final orderType = currentState.order.ordName?.toLowerCase().contains('purchase') ?? true
          ? tr.supplier
          : tr.customer;
      Utils.showOverlayMessage(
        context,
        message: 'Please select a $orderType',
        isError: true,
      );
      return;
    }

    final records = currentState.order.records ?? [];
    if (records.isEmpty) {
      Utils.showOverlayMessage(
        context,
        message: 'Please add at least one item',
        isError: true,
      );
      return;
    }

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.stkProduct == 0 || record.stkProduct == null) {
        Utils.showOverlayMessage(
          context,
          message: 'Please select a product for item ${i + 1}',
          isError: true,
        );
        return;
      }

      if (record.stkStorage == 0 || record.stkStorage == null) {
        Utils.showOverlayMessage(
          context,
          message: 'Please select a storage for item ${i + 1}',
          isError: true,
        );
        return;
      }

      final qty = double.tryParse(record.stkQuantity ?? "0") ?? 0;
      if (qty <= 0) {
        Utils.showOverlayMessage(
          context,
          message: 'Please enter a valid quantity for item ${i + 1}',
          isError: true,
        );
        return;
      }

      final isPurchase = currentState.order.ordName?.toLowerCase().contains('purchase') ?? true;
      final isSale = currentState.order.ordName?.toLowerCase().contains('sale') ?? false;

      if (isPurchase) {
        final price = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        if (price <= 0) {
          Utils.showOverlayMessage(
            context,
            message: 'Please enter a valid price for item ${i + 1}',
            isError: true,
          );
          return;
        }
      } else if (isSale) {
        final salePrice = double.tryParse(record.stkSalePrice ?? "0") ?? 0;
        if (salePrice <= 0) {
          Utils.showOverlayMessage(
            context,
            message: 'Please enter a valid sale price for item ${i + 1}',
            isError: true,
          );
          return;
        }

        final purPrice = double.tryParse(record.stkPurPrice ?? "0") ?? 0;
        if (purPrice <= 0) {
          Utils.showOverlayMessage(
            context,
            message: 'Purchase price not found for item ${i + 1}. Please reselect the product.',
            isError: true,
          );
          return;
        }
      }
    }

    if (!currentState.isPaymentValid) {
      Utils.showOverlayMessage(
        context,
        message: 'Total payment must equal grand total. Please adjust payment.',
        isError: true,
      );
      return;
    }

    if (currentState.creditAmount > 0 && currentState.selectedAccount == null) {
      Utils.showOverlayMessage(
        context,
        message: 'Please select an account for credit payment',
        isError: true,
      );
      return;
    }

    final completer = Completer<bool>();
    context.read<OrderByIdBloc>().add(
      SaveOrderChangesEvent(usrName: _userName!, completer: completer),
    );
  }

  void _showDeleteDialog(OrderByIdModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this order?'),
            const SizedBox(height: 8),
            Text(
              'Order: ${order.ordName ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Reference: ${order.ordTrnRef ?? 'N/A'}'),
            const SizedBox(height: 12),
            const Text(
              'Note: Only pending orders can be deleted. Verified transactions cannot be deleted.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder(order);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteOrder(OrderByIdModel order) {
    if (_userName == null) {
      Utils.showOverlayMessage(
        context,
        message: 'User not authenticated',
        isError: true,
      );
      return;
    }

    context.read<OrderByIdBloc>().add(
      DeleteOrderEvent(
        orderId: order.ordId!,
        ref: order.ordTrnRef ?? '',
        orderName: order.ordName ?? '',
        usrName: _userName!,
      ),
    );
  }

  void _printInvoice() {
    final state = context.read<OrderByIdBloc>().state;

    if (state is! OrderByIdLoaded) {
      Utils.showOverlayMessage(
        context,
        message: 'Cannot print: No order loaded',
        isError: true,
      );
      return;
    }

    final current = state;
    final order = current.order;

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is! CompanyProfileLoadedState) {
      Utils.showOverlayMessage(
        context,
        message: 'Company information not available',
        isError: true,
      );
      return;
    }

    final company = ReportModel(
      comName: companyState.company.comName ?? "",
      comAddress: companyState.company.addName ?? "",
      compPhone: companyState.company.comPhone ?? "",
      comEmail: companyState.company.comEmail ?? "",
      startDate: order.ordEntryDate?.toFormattedDate() ?? DateTime.now().toFormattedDate(),
      endDate: DateTime.now().toFormattedDate(),
      statementDate: DateTime.now().toFullDateTime,
    );

    final base64Logo = companyState.company.comLogo;
    if (base64Logo != null && base64Logo.isNotEmpty) {
      try {
        company.comLogo = base64Decode(base64Logo);
      } catch (e) {
        // Handle error
      }
    }

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<OrderByIdModel>(
        data: order,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return OrderPrintService().printPreview(
            order: order,
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            storages: current.storages,
            productNames: current.productNames,
            storageNames: current.storageNames,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            selectedAccount: current.selectedAccount,
            selectedSupplier: current.selectedSupplier,
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
          return OrderPrintService().printDocument(
            order: order,
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
            copies: copies,
            storages: current.storages,
            productNames: current.productNames,
            storageNames: current.storageNames,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            selectedAccount: current.selectedAccount,
            selectedSupplier: current.selectedSupplier,
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return OrderPrintService().createDocument(
            order: order,
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            storages: current.storages,
            productNames: current.productNames,
            storageNames: current.storageNames,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            selectedAccount: current.selectedAccount,
            selectedSupplier: current.selectedSupplier,
          );
        },
      ),
    );
  }
}