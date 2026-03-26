import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Reminder/add_edit_reminders.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/bloc/sale_invoice_bloc.dart';
import '../../../../../../../Features/Generic/product_info_field.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../Features/Other/utils.dart';
import '../../../../../../../Features/Other/zForm_dialog.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/Widgets/button.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import '../../../../Settings/Ui/Stock/Ui/Products/model/product_stock_model.dart';
import '../../../../Settings/features/Visibility/bloc/settings_visible_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../Print/print.dart';
import 'model/sale_invoice_items.dart';

class NewSaleView extends StatelessWidget {
  const NewSaleView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _MobileNewSaleView(),
      desktop: const _DesktopNewSaleView(),
      tablet: const _TabletNewSaleView(),
    );
  }
}
class _DesktopNewSaleView extends StatefulWidget {
  const _DesktopNewSaleView();

  @override
  State<_DesktopNewSaleView> createState() => _DesktopNewSaleViewState();
}
class _DesktopNewSaleViewState extends State<_DesktopNewSaleView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();

  final List<List<FocusNode>> _rowFocusNodes = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  String? _userName;
  String? baseCurrency;
  int? signatory;

  // Track controllers for each row
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};
  int? _selectedAccountNumber;

  @override
  void initState() {
    super.initState();

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      final auth = companyState.loginData;
      baseCurrency = auth.company?.comLocalCcy ?? "";
      company.comName = auth.company?.comName??"";
      company.comAddress = auth.company?.comAddress??"";
      company.compPhone = auth.company?.comPhone??"";
      company.comEmail = auth.company?.comEmail??"";
      company.statementDate = DateTime.now().toFullDateTime;
      final base64Logo = auth.company?.comLogo;
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          _companyLogo = base64Decode(base64Logo);
          company.comLogo = _companyLogo;
        } catch (e) {
          _companyLogo = Uint8List(0);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final row in _rowFocusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    _accountController.dispose();
    _personController.dispose();
    _xRefController.dispose();

    // Dispose all price and qty controllers
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = state.loginData;
    _userName = login.usrName??"";

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          _userName = state.loginData.usrName ?? '';
        }
      },
      child: BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
        listener: (context, state) {
          if (state is SaleInvoiceError) {
            ToastManager.show(context: context,title: tr.errorTitle, message: state.message, type: ToastType.error);
          }
          if (state is SaleInvoiceSaved) {
            Navigator.of(context).pop();
            if (state.success) {
              // Store the invoice number first
              String? savedInvoiceNumber = state.invoiceNumber;
              ToastManager.show(context: context, title:  tr.successTitle, message: tr.successPurchaseInvoiceMsg, type: ToastType.success);
              _accountController.clear();
              _personController.clear();
              _xRefController.clear();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onSalePrint(invoiceNumber: savedInvoiceNumber);
                }
              });
            } else {
              Utils.showOverlayMessage(context, message: "Failed to create invoice", isError: true);
            }
          }

          // Handle focus after new row is added
          if (state is SaleInvoiceLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusNewRowIfNeeded(state);
            });
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Utils.zBackButton(context),
                      Text(tr.saleEntry, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold,fontSize: 20))
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Customer and Account Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                          key: const ValueKey('person_field'),
                          controller: _personController,
                          title: tr.customer,
                          hintText: tr.customer,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr.required(tr.customer);
                            }
                            return null;
                          },
                          bloc: context.read<IndividualsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(const LoadIndividualsEvent()),
                          searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent(search: query)),
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
                            _personController.text = "${value.perName} ${value.perLastName}";
                            context.read<SaleInvoiceBloc>().add(SelectCustomerEvent(value));
                            context.read<AccountsBloc>().add(LoadAccountsEvent(ownerId: value.perId));
                            setState(() {
                              signatory = value.perId;
                            });
                          },
                          showClearButton: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                          builder: (context, state) {
                            if (state is SaleInvoiceLoaded) {
                              final current = state;
                              return GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                                key: const ValueKey('account_field'),
                                controller: _accountController,
                                title: tr.accounts,
                                hintText: tr.selectAccount,
                                isRequired: current.paymentMode != PaymentMode.cash,
                                validator: (value) {
                                  if (current.paymentMode != PaymentMode.cash && (value == null || value.isEmpty)) {
                                    return tr.selectCreditAccountMsg;
                                  }
                                  return null;
                                },
                                bloc: context.read<AccountsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                                searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                                itemBuilder: (context, account) => ListTile(
                                  visualDensity: VisualDensity(vertical: -4,horizontal: -4),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 5),
                                  title: Text(account.accName ?? ''),
                                  subtitle: Text('${account.accNumber}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(tr.balance,style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                                      Text("${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}",style: Theme.of(context).textTheme.titleSmall,),
                                    ],
                                  ),
                                ),
                                itemToString: (account) => '${account.accName} (${account.accNumber})',
                                stateToLoading: (state) => state is AccountLoadingState,
                                stateToItems: (state) {
                                  if (state is AccountLoadedState) return state.accounts;
                                  return [];
                                },
                                onSelected: (value) {
                                  setState(() {
                                    _accountController.text = '${value.accName} (${value.accNumber})';
                                    _selectedAccountNumber = value.accNumber;
                                  });
                                  context.read<SaleInvoiceBloc>().add(SelectCustomerAccountEvent(value));
                                },
                                showClearButton: true,
                              );
                            }
                            return GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                              key: const ValueKey('account_field'),
                              controller: _accountController,
                              title: tr.accounts,
                              hintText: tr.selectAccount,
                              isRequired: false,
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(LoadAccountsFilterEvent(include: '8', exclude: '')),
                              searchFunction: (bloc, query) => bloc.add(LoadAccountsFilterEvent(
                                  input: query,
                                  include: '8',
                                  exclude: ''
                              )),
                              itemBuilder: (context, account) => ListTile(
                                title: Text(account.accName ?? ''),
                                subtitle: Text('${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}'),
                                trailing: Text(account.actCurrency ?? ""),
                              ),
                              itemToString: (account) => '${account.accName} (${account.accNumber})',
                              stateToLoading: (state) => state is AccountLoadingState,
                              stateToItems: (state) {
                                if (state is AccountLoadedState) return state.accounts;
                                return [];
                              },
                              onSelected: (value) {
                                setState(() {
                                  _accountController.text = value.accNumber.toString();
                                });
                                context.read<SaleInvoiceBloc>().add(SelectCustomerAccountEvent(value));
                              },
                              showClearButton: true,
                            );
                          },
                        ),
                      ),
                      if(_accountController.text.isNotEmpty)...[
                        const SizedBox(width: 8),
                        ZOutlineButton(
                          width: 140,
                          icon: Icons.alarm_rounded,
                          onPressed: (){
                            showDialog(context: context, builder: (context){
                              return AddEditReminderView(
                                  accNumber: _selectedAccountNumber,
                                  dueParameter: "Receivable",
                                  isEnable: true);
                            });
                          },
                          label: Text(tr.setReminder),
                        ),
                      ],
                      const SizedBox(width: 8),
                      ZOutlineButton(
                        height: 48,
                        icon: Icons.refresh,
                        onPressed: (){
                          context.read<SaleInvoiceBloc>().add(InitializeSaleInvoiceEvent());
                        },
                        label: Text(tr.newSale),
                      ),
                      const SizedBox(width: 8),
                      ZOutlineButton(
                        width: 100,
                        icon: Icons.print,
                        onPressed: () => _onSalePrint(invoiceNumber: null),
                        label: Text(tr.print),
                      ),
                      const SizedBox(width: 8),
                      BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                          builder: (context, state) {
                            if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                              final current = state is SaleInvoiceSaving ?
                              state : (state as SaleInvoiceLoaded);
                              final isSaving = state is SaleInvoiceSaving;

                              return ZButton(
                                width: 100,
                                onPressed: (isSaving || !current.isFormValid) ? null : () => _saveInvoice(context, current),
                                label: isSaving
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.surface,
                                  ),
                                )
                                    : Text(tr.create),
                              );
                            }
                            return const SizedBox();
                          }
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Items Header
                  _buildItemsHeader(context),
                  const SizedBox(height: 8),

                  // Items List
                  Expanded(
                    child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                      builder: (context, state) {
                        if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                          final current = state is SaleInvoiceSaving ?
                          state : (state as SaleInvoiceLoaded);
                          _synchronizeFocusNodes(current.items.length);
                          return ListView.builder(
                            itemCount: current.items.length,
                            itemBuilder: (context, index) {
                              final item = current.items[index];
                              final isLastRow = index == current.items.length - 1;
                              final nodes = _rowFocusNodes[index];

                              return _buildItemRow(
                                item: item,
                                nodes: nodes,
                                isLastRow: isLastRow,
                                context: context,
                              );
                            },
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),

                  // Summary Section
                  _buildSummarySection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsHeader(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? title = Theme.of(context).textTheme.titleSmall?.copyWith(color: color.surface);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          SizedBox(width: 25, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Text('#', style: title),
          )),
          Expanded(child: Text(locale.products, style: title)),
          SizedBox(width: 80, child: Text(locale.qty, style: title)),
          SizedBox(width: 120, child: Text(locale.unitPrice, style: title)),
          SizedBox(width: 120, child: Text(locale.totalTitle, style: title)),
          SizedBox(width: 150, child: Text(locale.storage, style: title)),
          SizedBox(width: 60, child: Text(locale.actions, style: title)),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required BuildContext context,
    required SaleInvoiceItem item,
    required List<FocusNode> nodes,
    required bool isLastRow,
  }) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final productController = TextEditingController(text: item.productName);
    final qtyController = _qtyControllers.putIfAbsent(
      item.rowId, () => TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
    );

    final salePriceController = _priceControllers.putIfAbsent(
      "sale_${item.rowId}", () => TextEditingController(text: item.salePrice != null && item.salePrice! > 0 ? item.salePrice!.toAmount() : ''),
    );

    final storageController = TextEditingController(text: item.storageName);

    // Handle product selection
    void onProductSelected(ProductsStockModel? product) {
      if (product != null) {
        final salePrice = double.tryParse(
            product.sellPrice?.toAmount() ?? "0.0"
        ) ?? 0.0;

        context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
          rowId: item.rowId,
          productId: product.proId.toString(),
          productName: product.proName ?? '',
          storageId: product.stkStorage,
          storageName: product.stgName ?? '',
          purPrice: double.tryParse(product.averagePrice?.toAmount() ?? "0.0") ?? 0.0,
          salePrice: salePrice,
        ));

        salePriceController.text = salePrice.toAmount();
        storageController.text = product.stgName ?? '';

        // Move focus to quantity field after product selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          nodes[1].requestFocus(); // Quantity field
        });
      } else {
        // Handle clear
        context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
          rowId: item.rowId,
          productId: null,
          productName: '',
          storageId: null,
          storageName: '',
          purPrice: 0,
          salePrice: 0,
        ));

        salePriceController.clear();
        storageController.clear();
      }
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  (_rowFocusNodes.indexOf(nodes) + 1).toString(),
                  textAlign: TextAlign.center,
                ),
              ),
              // Product Selection
              Expanded(
                child: ProductSearchField<ProductsStockModel, ProductsBloc, ProductsState>(
                  controller: productController,
                  hintText: tr.products,
                  bloc: context.read<ProductsBloc>(),
                  searchFunction: (bloc, query) => bloc.add(LoadProductsStockEvent(input: query)),
                  fetchAllFunction: (bloc) => bloc.add(LoadProductsStockEvent()),
                  stateToItems: (state) {
                    if (state is ProductsStockLoadedState) return state.products;
                    return [];
                  },
                  stateToLoading: (state) => state is ProductsLoadingState,
                  itemToString: (product) => product.proName ?? '',

                  // Product field getters
                  getProductId: (product) => product.proId?.toString(),
                  getProductName: (product) => product.proName,
                  getProductCode: (product) => product.proCode,
                  getStorageId: (product) => product.stkStorage,
                  getStorageName: (product) => product.stgName,
                  getAvailable: (product) => product.available,
                  getAveragePrice: (product) => product.averagePrice,
                  getRecentPrice: (product) => product.recentPrice,
                  getSellPrice: (product) => product.sellPrice,

                  // Handle product selection
                  onProductSelected: onProductSelected,

                  // Open overlay automatically when this field gets focus (for new rows)
                  openOverlayOnFocus: item.productId.isEmpty,

                  // Make sure showAllOnFocus is true to fetch all products
                  showAllOnFocus: true,
                ),
              ),

              // Quantity
              SizedBox(
                width: 80,
                child: TextField(
                  controller: qtyController,
                  focusNode: nodes[1],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: tr.qty,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                        rowId: item.rowId,
                        qty: 0,
                      ));
                      return;
                    }
                    final qty = int.tryParse(value) ?? 0;
                    if (qty > 0) {
                      context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                        rowId: item.rowId,
                        qty: qty,
                      ));
                    }
                  },
                  onSubmitted: (_) {
                    // On Enter, move to sale price field
                    nodes[2].requestFocus();
                  },
                  textInputAction: TextInputAction.next,
                ),
              ),

              // Sale Price (Editable)
              SizedBox(
                width: 120,
                child: TextField(
                  controller: salePriceController,
                  focusNode: nodes[2],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  decoration: InputDecoration(
                    hintText: tr.salePrice,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                        rowId: item.rowId,
                        salePrice: 0,
                      ));
                      return;
                    }
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      context.read<SaleInvoiceBloc>().add(
                        UpdateSaleItemEvent(
                          rowId: item.rowId,
                          salePrice: parsed,
                        ),
                      );
                    }
                  },
                  onSubmitted: (_) {
                    // On Enter, create new row
                    context.read<SaleInvoiceBloc>().add(AddNewSaleItemEvent());

                    // Focus will be handled by _focusNewRowIfNeeded after state update
                    // No need to request focus here
                  },
                  textInputAction: TextInputAction.done,
                ),
              ),

              // Total Sale
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.totalSale.toAmount(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if(visibility.benefit)...[
                      if (item.purPrice != null && item.purPrice! > 0 && item.salePrice != null && item.salePrice! > 0)
                        Text(
                          '${tr.profit}: ${(item.totalSale - item.totalPurchase).toAmount()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: (item.totalSale - item.totalPurchase) >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                    ]

                  ],
                ),
              ),

              // Storage Display (Read-only)
              SizedBox(
                width: 150,
                child: TextField(
                  controller: storageController,
                  focusNode: nodes[3],
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: tr.storage,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              // Actions
              SizedBox(
                width: 65,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      isSelected: true,
                      hoverColor: color.primary.withValues(alpha: .05),
                      onPressed: () {
                        // Clean up controllers before removing
                        _priceControllers.remove("purchase_${item.rowId}");
                        _priceControllers.remove("sale_${item.rowId}");
                        _qtyControllers.remove(item.rowId);
                        context.read<SaleInvoiceBloc>().add(RemoveSaleItemEvent(item.rowId));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isLastRow)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                ZOutlineButton(
                  width: 120,
                  height: 35,
                  backgroundColor: color.primary.withValues(alpha: .08),
                  icon: Icons.add,
                  label: Text(tr.addItem),
                  onPressed: () {
                    context.read<SaleInvoiceBloc>().add(AddNewSaleItemEvent());
                  },
                )
              ],
            ),
          )
      ],
    );
  }

  void _synchronizeFocusNodes(int itemCount) {
    // Add new focus nodes if needed
    while (_rowFocusNodes.length < itemCount) {
      _rowFocusNodes.add([
        FocusNode(), // Product (index 0)
        FocusNode(), // Quantity (index 1)
        FocusNode(), // Sale Price (index 2)
        FocusNode(), // Storage (index 3)
      ]);
    }

    // Remove excess focus nodes
    while (_rowFocusNodes.length > itemCount) {
      final removed = _rowFocusNodes.removeLast();
      for (final node in removed) {
        node.dispose();
      }
    }
  }

  void _focusNewRowIfNeeded(SaleInvoiceLoaded state) {
    if (!mounted) return;

    // Add a small delay to ensure the new row is fully rendered
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      // Find the first row without a product and focus its product field
      for (int i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        if (item.productId.isEmpty) {
          if (i < _rowFocusNodes.length) {
            // Focus the product field
            _rowFocusNodes[i][0].requestFocus();

            // Ensure products are loaded
            context.read<ProductsBloc>().add(LoadProductsStockEvent());
            break;
          }
        }
      }
    });
  }

  Widget _buildSummarySection(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final visibility = context.read<SettingsVisibleBloc>().state;
    return BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
      builder: (context, state) {
        if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
          final current = state is SaleInvoiceSaving ?
          state : (state as SaleInvoiceLoaded);

          final bool hasCreditAccount = current.customerAccount != null && current.creditAmount > 0;

          return ZCover(
            padding: const EdgeInsets.all(12),
            radius: 8,
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT SECTION - Always visible
                Expanded(
                  flex: hasCreditAccount ? 5 : 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Minimize height
                    children: [
                      // Payment Method Row - Compact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.paymentMethod,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          InkWell(
                            onTap: () => _showPaymentModeDialog(current),
                            child: Row(
                              children: [
                                Text(_getPaymentModeLabel(current.paymentMode),
                                    style: TextStyle(color: color.primary, fontSize: 15)),
                                const SizedBox(width: 8),
                                Icon(Icons.more_vert_outlined, size: 20, color: color.primary),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Divider(height: 1, color: color.outline.withValues(alpha: .5)),
                      const SizedBox(height: 6),

                      // Grand Total - Compact
                      _buildCompactSummaryRow(
                        label: tr.grandTotal,
                        value: current.grandTotal,
                        isBold: true,
                      ),

                      // Profit in same row with percentage - Compact
                     if(visibility.benefit)...[
                       if (current.totalPurchaseCost > 0) ...[
                         const SizedBox(height: 4),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               tr.profit,
                               style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                             ),
                             Container(
                               padding: const EdgeInsets.symmetric(
                                 horizontal: 6,
                                 vertical: 2,
                               ),
                               decoration: BoxDecoration(
                                 color: current.totalProfit >= 0
                                     ? Colors.green.withValues(alpha: .1)
                                     : Colors.red.withValues(alpha: .1),
                                 borderRadius: BorderRadius.circular(2),
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Text(
                                     current.totalProfit >= 0 ? '+' : '',
                                     style: TextStyle(
                                       fontSize: 15,
                                       fontWeight: FontWeight.bold,
                                       color: current.totalProfit >= 0
                                           ? Colors.green
                                           : Colors.red,
                                     ),
                                   ),
                                   Text(
                                     current.totalProfit.toAmount(),
                                     style: TextStyle(
                                       fontSize: 15,
                                       fontWeight: FontWeight.bold,
                                       color: current.totalProfit >= 0
                                           ? Colors.green
                                           : Colors.red,
                                     ),
                                   ),
                                   Text(
                                     ' (${current.profitPercentage.toStringAsFixed(1)}%)',
                                     style: TextStyle(
                                       fontSize: 14,
                                       color: current.totalProfit >= 0
                                           ? Colors.green.withValues(alpha: .9)
                                           : Colors.red.withValues(alpha: .7),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ],
                     ],

                      const SizedBox(height: 6),
                      Divider(height: 1, color: color.outline.withValues(alpha: .5)),
                      const SizedBox(height: 6),

                      // Payment Breakdown - Compact
                      if (current.paymentMode == PaymentMode.cash) ...[
                        _buildCompactSummaryRow(
                          label: AppLocalizations.of(context)!.cashPayment,
                          value: current.cashPayment,
                          color: Colors.green,
                        ),
                      ] else if (current.paymentMode == PaymentMode.credit) ...[
                        _buildCompactSummaryRow(
                          label: AppLocalizations.of(context)!.accountPayment,
                          value: current.creditAmount,
                          color: Colors.orange,
                        ),
                      ] else if (current.paymentMode == PaymentMode.mixed) ...[
                        _buildCompactSummaryRow(
                          label: AppLocalizations.of(context)!.accountPayment,
                          value: current.creditAmount,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 2),
                        _buildCompactSummaryRow(
                          label: AppLocalizations.of(context)!.cashPayment,
                          value: current.cashPayment,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),

                // RIGHT SECTION - Only visible when credit account is selected
                if (hasCreditAccount) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 120,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1.5,
                      color: color.outline.withValues(alpha: .15),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Minimize height
                      children: [
                        // Account name and number in a single row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: .05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  current.customerAccount!.accName ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${current.customerAccount!.accNumber}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Balance Information in a row
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniBalanceRow(
                                label: tr.currentBalance,
                                value: current.currentBalance,
                                color: _getBalanceColor(current.currentBalance),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildMiniBalanceRow(
                                label: tr.invoiceAmount,
                                value: current.creditAmount,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // New Balance and Status in a row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: .05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // New Balance
                              Row(
                                children: [
                                  Text(
                                    '${tr.newBalance} :',
                                    style: TextStyle(fontSize: 15, color: color.outline),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (current.currentBalance - current.creditAmount).toAmount(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _getBalanceColor(current.currentBalance - current.creditAmount),
                                    ),
                                  ),
                                ],
                              ),

                              // Status
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getBalanceColor(current.currentBalance - current.creditAmount)
                                      .withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getBalanceStatus(current.currentBalance - current.creditAmount),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getBalanceColor(current.currentBalance - current.creditAmount),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

// Helper method for compact summary rows
  Widget _buildCompactSummaryRow({
    required String label,
    required double value,
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value.toAmount(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

// Helper method for mini balance rows in the right section
  Widget _buildMiniBalanceRow({
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color.withValues(alpha: .7)),
          ),
          Text(
            value.toAmount(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentModeDialog(SaleInvoiceLoaded current) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,

              decoration: BoxDecoration(
                color: color.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment,
                          color: color.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr.selectPaymentMethod.toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: color.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment Options
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cash Payment Option
                        _buildPaymentOptionTile(
                          context: context,
                          icon: Icons.money,
                          title: tr.cashPayment,
                          subtitle: tr.cashPaymentSubtitle,
                          isSelected: current.paymentMode == PaymentMode.cash,
                          selectedColor: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            _accountController.clear();
                            context.read<SaleInvoiceBloc>().add(ClearCustomerAccountEvent());
                          },
                        ),
                        const SizedBox(height: 12),

                        // Account Credit Option
                        _buildPaymentOptionTile(
                          context: context,
                          icon: Icons.credit_card,
                          title: tr.accountCredit,
                          subtitle: tr.accountCreditSubtitle,
                          isSelected: current.paymentMode == PaymentMode.credit,
                          selectedColor: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            context.read<SaleInvoiceBloc>().add(UpdateSaleReceivePaymentEvent(0));
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 12),

                        // Combined Payment Option
                        _buildPaymentOptionTile(
                          context: context,
                          icon: Icons.payments,
                          title: tr.combinedPayment,
                          subtitle: tr.combinedPaymentSubtitle,
                          isSelected: current.paymentMode == PaymentMode.mixed,
                          selectedColor: Colors.orange,
                          onTap: () {
                            Navigator.pop(context);
                            _showMixedPaymentDialog(context, current);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    final themeColor = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? selectedColor : themeColor.outline.withValues(alpha: .2),
          width: isSelected ? 1 : 0.5,
        ),
        gradient: isSelected
            ? LinearGradient(
          colors: [
            selectedColor.withValues(alpha: .08),
            selectedColor.withValues(alpha: .02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: selectedColor.withValues(alpha: .2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? selectedColor.withValues(alpha: .15)
                        : themeColor.primary.withValues(alpha: .05),
                    border: Border.all(
                      color: isSelected ? selectedColor : themeColor.outline.withValues(alpha: .3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? selectedColor : themeColor.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? selectedColor : themeColor.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColor.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected Checkmark
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedColor,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMixedPaymentDialog(BuildContext context, SaleInvoiceLoaded current) {
    final controller = TextEditingController();
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => ZFormDialog(
        title: tr.combinedPayment,
        actionLabel: Text(tr.submit),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZTextFieldEntitled(
                title: "Account (Credit) Payment Amount",
                controller: controller,
                hint: "Enter amount to add to account as credit",
                inputFormat: [SmartThousandsDecimalFormatter()],
                onSubmit: (e){
                  final cleaned = controller.text.replaceAll(',', '');
                  final creditPayment = double.tryParse(cleaned) ?? 0;

                  if (creditPayment <= 0) {
                    ToastManager.show(context: context,title: "Invalid Amount", message: "Account payment must be greater than zero", type: ToastType.warning);
                    return;
                  }

                  if (creditPayment >= current.grandTotal) {
                    ToastManager.show(context: context, title: "Invalid Payment", message: "Account payment must be less than total amount for mixed payment", type: ToastType.warning);
                    return;
                  }

                  // Pass credit amount to bloc with isCreditAmount flag
                  context.read<SaleInvoiceBloc>().add(UpdateSaleReceivePaymentEvent(
                    creditPayment,
                    isCreditAmount: true,
                  ));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Text(
                "${tr.grandTotal}: ${current.grandTotal.toAmount()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (controller.text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Account (Credit) Payment: ${double.tryParse(controller.text.replaceAll(',', ''))?.toAmount() ?? '0.0'}",
                      style: const TextStyle(color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${tr.cashPayment}: ${(current.grandTotal - (double.tryParse(controller.text.replaceAll(',', '')) ?? 0)).toAmount()}",
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
            ],
          ),
        ),

        onAction: () {
          final cleaned = controller.text.replaceAll(',', '');
          final creditPayment = double.tryParse(cleaned) ?? 0;

          if (creditPayment <= 0) {
            ToastManager.show(context: context,title: "Invalid Amount", message: "Account payment must be greater than zero", type: ToastType.warning);
            return;
          }

          if (creditPayment >= current.grandTotal) {
            ToastManager.show(context: context, title: "Invalid Payment", message: "Account payment must be less than total amount for mixed payment", type: ToastType.warning);
            return;
          }

          // Pass credit amount to bloc with isCreditAmount flag
          context.read<SaleInvoiceBloc>().add(UpdateSaleReceivePaymentEvent(
            creditPayment,
            isCreditAmount: true,
          ));
          Navigator.pop(context);
        },
      ),
    );
  }

  String _getPaymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash: return AppLocalizations.of(context)!.cash;
      case PaymentMode.credit: return AppLocalizations.of(context)!.creditTitle;
      case PaymentMode.mixed: return AppLocalizations.of(context)!.combinedPayment;
    }
  }

  void _saveInvoice(BuildContext context, SaleInvoiceLoaded state) {
    if (!state.isFormValid) {
      Utils.showOverlayMessage(context, message: 'Please fill all required fields correctly', isError: true);
      return;
    }
    final completer = Completer<String>();
    context.read<SaleInvoiceBloc>().add(SaveSaleInvoiceEvent(
      usrName: _userName ?? '',
      orderName: "Sale",
      ordPersonal: state.customer!.perId!,
      xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
      items: state.items,
      completer: completer,
    ));
  }

  void _onSalePrint({String? invoiceNumber}) {
    final state = context.read<SaleInvoiceBloc>().state;

    // Handle both loaded and saved states
    SaleInvoiceLoaded? current;

    if (state is SaleInvoiceLoaded) {
      current = state;
    } else if (state is SaleInvoiceSaved && state.invoiceData != null) {
      // Use the saved invoice data
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(context,
          message: 'Cannot print: No invoice data available',
          isError: true);
      return;
    }

    // Prepare invoice items for print
    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return SaleInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        unitPrice: item.salePrice ?? 0.0,
        total: item.totalSale,
        storageName: item.storageName,
        purchasePrice: item.purPrice ?? 0.0,
        profit: (item.salePrice ?? 0.0) - (item.purPrice ?? 0.0),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<dynamic>(
        data: null,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().printInvoicePreview(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: true
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
          return InvoicePrintService().printInvoiceDocument(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              selectedPrinter: selectedPrinter,
              pageFormat: pageFormat,
              copies: copies,
              currency: baseCurrency,
              isSale: true
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().createInvoiceDocument(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: true
          );
        },
      ),
    );
  }

  // Add these helper methods
  Color _getBalanceColor(double balance) {
    if (balance < 0) {
      return Colors.red;
    } else if (balance > 0) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _getBalanceStatus(double balance) {
    if (balance < 0) {
      return AppLocalizations.of(context)!.debtor;
    } else if (balance > 0) {
      return AppLocalizations.of(context)!.creditor;
    } else {
      return AppLocalizations.of(context)!.noAccountsFound;
    }
  }
}

// Mobile Version
class _MobileNewSaleView extends StatefulWidget {
  const _MobileNewSaleView();

  @override
  State<_MobileNewSaleView> createState() => _MobileNewSaleViewState();
}

class _MobileNewSaleViewState extends State<_MobileNewSaleView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  String? _userName;
  String? baseCurrency;
  int? signatory;
  int? _selectedAccountNumber;

  // Track controllers for each row
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleInvoiceBloc>().add(InitializeSaleInvoiceEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      final auth = companyState.loginData;
      baseCurrency = auth.company?.comLocalCcy ?? "";
      company.comName = auth.company?.comName??"";
      company.comAddress = auth.company?.comAddress??"";
      company.compPhone = auth.company?.comPhone??"";
      company.comEmail = auth.company?.comEmail??"";
      company.statementDate = DateTime.now().toFullDateTime;
      final base64Logo = auth.company?.comLogo;
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          _companyLogo = base64Decode(base64Logo);
          company.comLogo = _companyLogo;
        } catch (e) {
          _companyLogo = Uint8List(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _personController.dispose();
    _xRefController.dispose();
    _scrollController.dispose();

    // Dispose all controllers
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;


    if (state is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = state.loginData;
    _userName = login.usrName??"";

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          _userName = state.loginData.usrName ?? '';
        }
      },
      child: BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
        listener: (context, state) {
          if (state is SaleInvoiceError) {
            Utils.showOverlayMessage(context, message: state.message, isError: true);
          }
          if (state is SaleInvoiceSaved) {
            Navigator.of(context).pop();
            if (state.success) {
              String? savedInvoiceNumber = state.invoiceNumber;

              Utils.showOverlayMessage(
                context,
                title: tr.successTitle,
                message: tr.successPurchaseInvoiceMsg,
                isError: false,
              );
              _accountController.clear();
              _personController.clear();
              _xRefController.clear();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onSalePrint(invoiceNumber: savedInvoiceNumber);
                }
              });
            } else {
              Utils.showOverlayMessage(context, message: "Failed to create invoice", isError: true);
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(tr.saleEntry),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => _onSalePrint(invoiceNumber: null),
              ),
              BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                builder: (context, state) {
                  if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                    final current = state is SaleInvoiceSaving ?
                    state : (state as SaleInvoiceLoaded);
                    final isSaving = state is SaleInvoiceSaving;

                    return IconButton(
                      icon: isSaving
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                          : const Icon(Icons.save),
                      onPressed: (isSaving || !current.isFormValid)
                          ? null
                          : () => _saveInvoice(context, current),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                // Customer and Account Selection
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                        key: const ValueKey('person_field'),
                        controller: _personController,
                        title: tr.customer,
                        hintText: tr.customer,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.customer);
                          }
                          return null;
                        },
                        bloc: context.read<IndividualsBloc>(),
                        fetchAllFunction: (bloc) => bloc.add(const LoadIndividualsEvent()),
                        searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent(search: query)),
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
                          _personController.text = "${value.perName} ${value.perLastName}";
                          context.read<SaleInvoiceBloc>().add(SelectCustomerEvent(value));
                          context.read<AccountsBloc>().add(LoadAccountsEvent(ownerId: value.perId));
                          setState(() {
                            signatory = value.perId;
                          });
                        },
                        showClearButton: true,
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                        builder: (context, state) {
                          if (state is SaleInvoiceLoaded) {
                            final current = state;
                            return GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                              key: const ValueKey('account_field'),
                              controller: _accountController,
                              title: tr.accounts,
                              hintText: tr.selectAccount,
                              isRequired: current.paymentMode != PaymentMode.cash,
                              validator: (value) {
                                if (current.paymentMode != PaymentMode.cash && (value == null || value.isEmpty)) {
                                  return tr.selectCreditAccountMsg;
                                }
                                return null;
                              },
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                              searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                              itemBuilder: (context, account) => ListTile(
                                visualDensity: VisualDensity(vertical: -4,horizontal: -4),
                                contentPadding: EdgeInsets.symmetric(horizontal: 5),
                                title: Text(account.accName ?? ''),
                                subtitle: Text('${account.accNumber}'),
                                trailing: Text("${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}"),
                              ),
                              itemToString: (account) => '${account.accName} (${account.accNumber})',
                              stateToLoading: (state) => state is AccountLoadingState,
                              stateToItems: (state) {
                                if (state is AccountLoadedState) return state.accounts;
                                return [];
                              },
                              onSelected: (value) {
                                setState(() {
                                  _accountController.text = '${value.accName} (${value.accNumber})';
                                  _selectedAccountNumber = value.accNumber;
                                });
                                context.read<SaleInvoiceBloc>().add(SelectCustomerAccountEvent(value));
                              },
                              showClearButton: true,
                            );
                          }
                          return GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                            key: const ValueKey('account_field'),
                            controller: _accountController,
                            title: tr.accounts,
                            hintText: tr.selectAccount,
                            isRequired: false,
                            bloc: context.read<AccountsBloc>(),
                            fetchAllFunction: (bloc) => bloc.add(LoadAccountsFilterEvent(include: '8', exclude: '')),
                            searchFunction: (bloc, query) => bloc.add(LoadAccountsFilterEvent(
                                input: query,
                                include: '8',
                                exclude: ''
                            )),
                            itemBuilder: (context, account) => ListTile(
                              title: Text(account.accName ?? ''),
                              subtitle: Text('${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}'),
                              trailing: Text(account.actCurrency ?? ""),
                            ),
                            itemToString: (account) => '${account.accName} (${account.accNumber})',
                            stateToLoading: (state) => state is AccountLoadingState,
                            stateToItems: (state) {
                              if (state is AccountLoadedState) return state.accounts;
                              return [];
                            },
                            onSelected: (value) {
                              setState(() {
                                _accountController.text = value.accNumber.toString();
                              });
                              context.read<SaleInvoiceBloc>().add(SelectCustomerAccountEvent(value));
                            },
                            showClearButton: true,
                          );
                        },
                      ),
                      if(_accountController.text.isNotEmpty)...[
                        const SizedBox(height: 8),
                        ZOutlineButton(
                          width: double.infinity,
                          icon: Icons.alarm_rounded,
                          onPressed: (){
                            showDialog(context: context, builder: (context){
                              return AddEditReminderView(
                                  accNumber: _selectedAccountNumber,
                                  dueParameter: "Receivable",
                                  isEnable: true);
                            });
                          },
                          label: Text(tr.setReminder),
                        ),
                      ],
                    ],
                  ),
                ),

                // Items List
                Expanded(
                  child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                    builder: (context, state) {
                      if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                        final current = state is SaleInvoiceSaving ?
                        state : (state as SaleInvoiceLoaded);

                        if (current.items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tr.noItems,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<SaleInvoiceBloc>().add(AddNewSaleItemEvent());
                                  },
                                  icon: const Icon(Icons.add),
                                  label: Text(tr.addItem),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: current.items.length,
                          itemBuilder: (context, index) {
                            final item = current.items[index];
                            return _buildMobileItemCard(item, context);
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),

                // Summary Section
                _buildMobileSummarySection(context),

                // Add Item Button
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ZOutlineButton(
                    width: double.infinity,
                    height: 45,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                    icon: Icons.add,
                    label: Text(AppLocalizations.of(context)!.addItem),
                    onPressed: () {
                      context.read<SaleInvoiceBloc>().add(AddNewSaleItemEvent());
                      // Scroll to bottom
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileItemCard(SaleInvoiceItem item, BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final visibility = context.read<SettingsVisibleBloc>().state;
    final productController = TextEditingController(text: item.productName);
    final qtyController = _qtyControllers.putIfAbsent(
      item.rowId, () => TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
    );

    final salePriceController = _priceControllers.putIfAbsent(
      "sale_${item.rowId}", () => TextEditingController(text: item.salePrice != null && item.salePrice! > 0 ? item.salePrice!.toAmount() : ''),
    );

    return ZCover(
      margin: const EdgeInsets.only(bottom: 5),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr.items} #${item.rowId.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    _priceControllers.remove("sale_${item.rowId}");
                    _qtyControllers.remove(item.rowId);
                    context.read<SaleInvoiceBloc>().add(RemoveSaleItemEvent(item.rowId));
                  },
                ),
              ],
            ),

            // Product Selection using GenericUnderlineTextfield
            GenericTextfield<ProductsStockModel, ProductsBloc, ProductsState>(
              title: tr.products,
              controller: productController,
              hintText: tr.products,
              isRequired: true,
              bloc: context.read<ProductsBloc>(),
              fetchAllFunction: (bloc) => bloc.add(LoadProductsStockEvent(noStock: 1)),
              searchFunction: (bloc, query) => bloc.add(LoadProductsStockEvent(input: query)),
              itemBuilder: (context, product) => ListTile(
                tileColor: Colors.transparent,
                title: Text(product.proName ?? ''),
                subtitle: Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${tr.purchasePrice}: ${product.averagePrice?.toAmount() ?? ""}'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${tr.salePriceBrief}: ${product.sellPrice?.toAmount() ?? ""}'),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.available?.toAmount() ?? "",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      product.stgName ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              itemToString: (product) => product.proName ?? '',
              stateToLoading: (state) => state is ProductsLoadingState,
              stateToItems: (state) {
                if (state is ProductsStockLoadedState) return state.products;
                return [];
              },
              onSelected: (product) {
                final purchasePrice = double.tryParse(product.averagePrice?.toAmount() ?? "0.0") ?? 0.0;
                final salePrice = double.tryParse(product.sellPrice?.toAmount() ?? "0.0") ?? 0.0;

                context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                  rowId: item.rowId,
                  productId: product.proId.toString(),
                  productName: product.proName ?? '',
                  storageId: product.stkStorage,
                  storageName: product.stgName ?? '',
                  purPrice: purchasePrice,
                  salePrice: salePrice,
                ));

                salePriceController.text = salePrice.toAmount();
              },
            ),

            const SizedBox(height: 12),

            // Quantity and Price Row
            Row(
              children: [
                // Quantity
                Expanded(
                  child: TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: tr.qty,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                          rowId: item.rowId,
                          qty: 0,
                        ));
                        return;
                      }
                      final qty = int.tryParse(value) ?? 0;
                      context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                        rowId: item.rowId,
                        qty: qty,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Sale Price
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: salePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    decoration: InputDecoration(
                      labelText: tr.unitPrice,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                          rowId: item.rowId,
                          salePrice: 0,
                        ));
                        return;
                      }
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        context.read<SaleInvoiceBloc>().add(
                          UpdateSaleItemEvent(
                            rowId: item.rowId,
                            salePrice: parsed,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Totals Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.totalTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.outline,
                      ),
                    ),
                    Text(
                      item.totalSale.toAmount(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ],
                ),

                // Profit if available
                if (item.purPrice != null && item.purPrice! > 0 && item.salePrice != null && item.salePrice! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if(visibility.benefit)...[
                        Text(
                          tr.profit,
                          style: TextStyle(
                            fontSize: 12,
                            color: color.outline,
                          ),
                        ),
                        Text(
                          (item.totalSale - item.totalPurchase).toAmount(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (item.totalSale - item.totalPurchase) >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],

                    ],
                  ),

                // Storage
                if (item.storageName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.storageName,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSummarySection(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final visibility = context.read<SettingsVisibleBloc>().state;
    return BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
      builder: (context, state) {
        if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
          final current = state is SaleInvoiceSaving ?
          state : (state as SaleInvoiceLoaded);

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Payment Method
                InkWell(
                  onTap: () => _showPaymentModeDialog(current),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr.paymentMethod,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              _getPaymentModeLabel(current.paymentMode),
                              style: TextStyle(color: color.primary),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 16, color: color.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.grandTotal),
                    Text(
                      "${current.grandTotal.toAmount()} $baseCurrency",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Profit
                if(visibility.benefit)...[
                  if(current.totalPurchaseCost > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.profit),
                      Text(
                        "${current.totalProfit.toAmount()} $baseCurrency (${current.profitPercentage.toStringAsFixed(2)}%)",
                        style: TextStyle(
                          color: current.totalProfit >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],



               // Payment breakdown
                if (current.paymentMode == PaymentMode.cash) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.cashPayment),
                      Text(
                        current.cashPayment.toAmount(),
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ] else if (current.paymentMode == PaymentMode.credit) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.accountPayment),
                      Text(
                        current.creditAmount.toAmount(),
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ] else if (current.paymentMode == PaymentMode.mixed) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.accountPayment),
                      Text(
                        current.creditAmount.toAmount(),
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.cashPayment),
                      Text(
                        current.cashPayment.toAmount(),
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ],

                // Account info if available
                if (current.customerAccount != null && current.creditAmount > 0) ...[
                  const Divider(height: 12),
                  Text(
                    '${current.customerAccount!.accNumber} | ${current.customerAccount!.accName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.currentBalance),
                      Text(
                        current.currentBalance.toAmount(),
                        style: TextStyle(
                          color: _getBalanceColor(current.currentBalance),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.newBalance),
                      Text(
                        (current.currentBalance - current.creditAmount).toAmount(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getBalanceColor(current.currentBalance - current.creditAmount),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showPaymentModeDialog(SaleInvoiceLoaded current) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr.selectPaymentMethod,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: color.primary.withValues(alpha: .05),
                  child: Icon(Icons.money,
                      color: current.paymentMode == PaymentMode.cash ? color.primary : color.outline)),
              title: Text(tr.cashPayment),
              subtitle: Text(tr.cashPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.cash ? Icon(Icons.check, color: color.primary) : null,
              onTap: () {
                Navigator.pop(context);
                _accountController.clear();
                context.read<SaleInvoiceBloc>().add(ClearCustomerAccountEvent());
              },
            ),
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: color.primary.withValues(alpha: .05),
                  child: Icon(Icons.credit_card,
                      color: current.paymentMode == PaymentMode.credit ? color.primary : color.outline)),
              title: Text(tr.accountCredit),
              subtitle: Text(tr.accountCreditSubtitle),
              trailing: current.paymentMode == PaymentMode.credit ? Icon(Icons.check, color: color.primary) : null,
              onTap: () {
                Navigator.pop(context);
                context.read<SaleInvoiceBloc>().add(UpdateSaleReceivePaymentEvent(0));
                setState(() {});
              },
            ),
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: color.primary.withValues(alpha: .05),
                  child: Icon(Icons.payments,
                      color: current.paymentMode == PaymentMode.mixed ? color.primary : color.outline)),
              title: Text(tr.combinedPayment),
              subtitle: Text(tr.combinedPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.mixed ? Icon(Icons.check, color: color.primary) : null,
              onTap: () {
                Navigator.pop(context);
                _showMixedPaymentDialog(context, current);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMixedPaymentDialog(BuildContext context, SaleInvoiceLoaded current) {
    final controller = TextEditingController();
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.combinedPayment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Account (Credit) Payment Amount",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [SmartThousandsDecimalFormatter()],
            ),
            const SizedBox(height: 16),
            Text(
              "${tr.grandTotal}: ${current.grandTotal.toAmount()}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final cleaned = controller.text.replaceAll(',', '');
              final creditPayment = double.tryParse(cleaned) ?? 0;

              if (creditPayment <= 0) {
                Utils.showOverlayMessage(context, message: 'Account payment must be greater than 0', isError: true);
                return;
              }

              if (creditPayment >= current.grandTotal) {
                Utils.showOverlayMessage(context, message: 'Account payment must be less than total amount for mixed payment', isError: true);
                return;
              }

              context.read<SaleInvoiceBloc>().add(UpdateSaleReceivePaymentEvent(
                creditPayment,
                isCreditAmount: true,
              ));
              Navigator.pop(context);
            },
            child: Text(tr.submit),
          ),
        ],
      ),
    );
  }

  String _getPaymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash: return AppLocalizations.of(context)!.cash;
      case PaymentMode.credit: return AppLocalizations.of(context)!.creditTitle;
      case PaymentMode.mixed: return AppLocalizations.of(context)!.combinedPayment;
    }
  }

  Color _getBalanceColor(double balance) {
    if (balance < 0) {
      return Colors.red;
    } else if (balance > 0) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  void _saveInvoice(BuildContext context, SaleInvoiceLoaded state) {
    if (!state.isFormValid) {
      Utils.showOverlayMessage(context, message: 'Please fill all required fields correctly', isError: true);
      return;
    }
    final completer = Completer<String>();
    context.read<SaleInvoiceBloc>().add(SaveSaleInvoiceEvent(
      usrName: _userName ?? '',
      orderName: "Sale",
      ordPersonal: state.customer!.perId!,
      xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
      items: state.items,
      completer: completer,
    ));
  }

  void _onSalePrint({String? invoiceNumber}) {
    final state = context.read<SaleInvoiceBloc>().state;

    SaleInvoiceLoaded? current;

    if (state is SaleInvoiceLoaded) {
      current = state;
    } else if (state is SaleInvoiceSaved && state.invoiceData != null) {
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(context,
          message: 'Cannot print: No invoice data available',
          isError: true);
      return;
    }

    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return SaleInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        unitPrice: item.salePrice ?? 0.0,
        total: item.totalSale,
        storageName: item.storageName,
        purchasePrice: item.purPrice ?? 0.0,
        profit: (item.salePrice ?? 0.0) - (item.purPrice ?? 0.0),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<dynamic>(
        data: null,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().printInvoicePreview(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: true
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
          return InvoicePrintService().printInvoiceDocument(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              selectedPrinter: selectedPrinter,
              pageFormat: pageFormat,
              copies: copies,
              currency: baseCurrency,
              isSale: true
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().createInvoiceDocument(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: true
          );
        },
      ),
    );
  }
}

// Tablet Version (Enhanced Mobile Version)
class _TabletNewSaleView extends StatefulWidget {
  const _TabletNewSaleView();

  @override
  State<_TabletNewSaleView> createState() => _TabletNewSaleViewState();
}
class _TabletNewSaleViewState extends State<_TabletNewSaleView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  String? _userName;
  String? baseCurrency;
  int? signatory;
  int? _selectedAccountNumber;

  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleInvoiceBloc>().add(InitializeSaleInvoiceEvent());
    });

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
      company.comName = companyState.company.comName??"";
      company.comAddress = companyState.company.addName??"";
      company.compPhone = companyState.company.comPhone??"";
      company.comEmail = companyState.company.comEmail??"";
      company.statementDate = DateTime.now().toFullDateTime;
      final base64Logo = companyState.company.comLogo;
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          _companyLogo = base64Decode(base64Logo);
          company.comLogo = _companyLogo;
        } catch (e) {
          _companyLogo = Uint8List(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _personController.dispose();
    _xRefController.dispose();
    _scrollController.dispose();

    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = state.loginData;
    _userName = login.usrName??"";

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          _userName = state.loginData.usrName ?? '';
        }
      },
      child: BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
        listener: (context, state) {
          if (state is SaleInvoiceError) {
            Utils.showOverlayMessage(context, message: state.message, isError: true);
          }
          if (state is SaleInvoiceSaved) {
            Navigator.of(context).pop();
            if (state.success) {
              String? savedInvoiceNumber = state.invoiceNumber;

              Utils.showOverlayMessage(
                context,
                title: tr.successTitle,
                message: tr.successPurchaseInvoiceMsg,
                isError: false,
              );
              _accountController.clear();
              _personController.clear();
              _xRefController.clear();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onSalePrint(invoiceNumber: savedInvoiceNumber);
                }
              });
            } else {
              Utils.showOverlayMessage(context, message: "Failed to create invoice", isError: true);
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(tr.saleEntry),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => _onSalePrint(invoiceNumber: null),
              ),
              BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                builder: (context, state) {
                  if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                    final current = state is SaleInvoiceSaving ?
                    state : (state as SaleInvoiceLoaded);
                    final isSaving = state is SaleInvoiceSaving;

                    return IconButton(
                      icon: isSaving
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                          : const Icon(Icons.save),
                      onPressed: (isSaving || !current.isFormValid)
                          ? null
                          : () => _saveInvoice(context, current),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Customer and Account Selection - Row layout for tablet
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                          key: const ValueKey('person_field'),
                          controller: _personController,
                          title: tr.customer,
                          hintText: tr.customer,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr.required(tr.customer);
                            }
                            return null;
                          },
                          bloc: context.read<IndividualsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(const LoadIndividualsEvent()),
                          searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent(search: query)),
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
                            _personController.text = "${value.perName} ${value.perLastName}";
                            context.read<SaleInvoiceBloc>().add(SelectCustomerEvent(value));
                            context.read<AccountsBloc>().add(LoadAccountsEvent(ownerId: value.perId));
                            setState(() {
                              signatory = value.perId;
                            });
                          },
                          showClearButton: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                          builder: (context, state) {
                            if (state is SaleInvoiceLoaded) {
                              final current = state;
                              return GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                                key: const ValueKey('account_field'),
                                controller: _accountController,
                                title: tr.accounts,
                                hintText: tr.selectAccount,
                                isRequired: current.paymentMode != PaymentMode.cash,
                                validator: (value) {
                                  if (current.paymentMode != PaymentMode.cash && (value == null || value.isEmpty)) {
                                    return tr.selectCreditAccountMsg;
                                  }
                                  return null;
                                },
                                bloc: context.read<AccountsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                                searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                                itemBuilder: (context, account) => ListTile(
                                  visualDensity: VisualDensity(vertical: -4,horizontal: -4),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 5),
                                  title: Text(account.accName ?? ''),
                                  subtitle: Text('${account.accNumber}'),
                                  trailing: Text("${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}"),
                                ),
                                itemToString: (account) => '${account.accName} (${account.accNumber})',
                                stateToLoading: (state) => state is AccountLoadingState,
                                stateToItems: (state) {
                                  if (state is AccountLoadedState) return state.accounts;
                                  return [];
                                },
                                onSelected: (value) {
                                  setState(() {
                                    _accountController.text = '${value.accName} (${value.accNumber})';
                                    _selectedAccountNumber = value.accNumber;
                                  });
                                  context.read<SaleInvoiceBloc>().add(SelectCustomerAccountEvent(value));
                                },
                                showClearButton: true,
                              );
                            }
                            return GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                              key: const ValueKey('account_field'),
                              controller: _accountController,
                              title: tr.accounts,
                              hintText: tr.selectAccount,
                              isRequired: false,
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(LoadAccountsFilterEvent(include: '8', exclude: '')),
                              searchFunction: (bloc, query) => bloc.add(LoadAccountsFilterEvent(
                                  input: query,
                                  include: '8',
                                  exclude: ''
                              )),
                              itemBuilder: (context, account) => ListTile(
                                title: Text(account.accName ?? ''),
                                subtitle: Text('${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}'),
                                trailing: Text(account.actCurrency ?? ""),
                              ),
                              itemToString: (account) => '${account.accName} (${account.accNumber})',
                              stateToLoading: (state) => state is AccountLoadingState,
                              stateToItems: (state) {
                                if (state is AccountLoadedState) return state.accounts;
                                return [];
                              },
                              onSelected: (value) {
                                setState(() {
                                  _accountController.text = value.accNumber.toString();
                                });
                                context.read<SaleInvoiceBloc>().add(SelectCustomerAccountEvent(value));
                              },
                              showClearButton: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if(_accountController.text.isNotEmpty)...[
                    const SizedBox(height: 12),
                    ZOutlineButton(
                      width: 200,
                      icon: Icons.alarm_rounded,
                      onPressed: (){
                        showDialog(context: context, builder: (context){
                          return AddEditReminderView(
                              accNumber: _selectedAccountNumber,
                              dueParameter: "Receivable",
                              isEnable: true);
                        });
                      },
                      label: Text(tr.setReminder),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Items Header
                  _buildItemsHeader(context),
                  const SizedBox(height: 8),

                  // Items List - Using card layout but more compact than mobile
                  Expanded(
                    child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                      builder: (context, state) {
                        if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                          final current = state is SaleInvoiceSaving ?
                          state : (state as SaleInvoiceLoaded);

                          if (current.items.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tr.noItems,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<SaleInvoiceBloc>().add(AddNewSaleItemEvent());
                                    },
                                    icon: const Icon(Icons.add),
                                    label: Text(tr.addItem),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: current.items.length,
                            itemBuilder: (context, index) {
                              final item = current.items[index];
                              return _buildTabletItemCard(item, context);
                            },
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),

                  // Summary Section - Row layout for tablet
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTabletSummarySection(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildTabletProfitSummarySection(context),
                        ),
                      ],
                    ),
                  ),

                  // Add Item Button
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ZOutlineButton(
                      width: 200,
                      height: 45,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                      icon: Icons.add,
                      label: Text(AppLocalizations.of(context)!.addItem),
                      onPressed: () {
                        context.read<SaleInvoiceBloc>().add(AddNewSaleItemEvent());
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsHeader(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? title = Theme.of(context).textTheme.titleSmall?.copyWith(color: color.surface);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: title)),
          Expanded(flex: 3, child: Text(locale.products, style: title)),
          SizedBox(width: 80, child: Text(locale.qty, style: title)),
          SizedBox(width: 100, child: Text(locale.unitPrice, style: title)),
          SizedBox(width: 100, child: Text(locale.totalTitle, style: title)),
          SizedBox(width: 100, child: Text(locale.storage, style: title)),
          SizedBox(width: 60, child: Text(locale.actions, style: title)),
        ],
      ),
    );
  }
  Widget _buildTabletItemCard(SaleInvoiceItem item, BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final productController = TextEditingController(text: item.productName);
    final qtyController = _qtyControllers.putIfAbsent(
      item.rowId, () => TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
    );

    final salePriceController = _priceControllers.putIfAbsent(
      "sale_${item.rowId}", () => TextEditingController(text: item.salePrice != null && item.salePrice! > 0 ? item.salePrice!.toAmount() : ''),
    );

    final storageController = TextEditingController(text: item.storageName);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Desktop-like row layout but adapted for tablet
            Row(
              children: [
                // Row Number
                SizedBox(
                  width: 30,
                  child: Text(
                    item.rowId.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Product Selection
                Expanded(
                  flex: 3,
                  child: GenericTextfield<ProductsStockModel, ProductsBloc, ProductsState>(
                    title: "",
                    controller: productController,
                    hintText: tr.products,
                    bloc: context.read<ProductsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadProductsStockEvent(noStock: 1)),
                    searchFunction: (bloc, query) => bloc.add(LoadProductsStockEvent(input: query)),
                    itemBuilder: (context, product) => ListTile(
                      tileColor: Colors.transparent,
                      title: Text(product.proName ?? ''),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${tr.purchasePrice}: ${product.averagePrice?.toAmount() ?? ""}'),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${tr.salePriceBrief}: ${product.sellPrice?.toAmount() ?? ""}'),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            product.available?.toAmount() ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            product.stgName ?? "",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemToString: (product) => product.proName ?? '',
                    stateToLoading: (state) => state is ProductsLoadingState,
                    stateToItems: (state) {
                      if (state is ProductsStockLoadedState) return state.products;
                      return [];
                    },
                    onSelected: (product) {
                      final purchasePrice = double.tryParse(product.averagePrice?.toAmount() ?? "0.0") ?? 0.0;
                      final salePrice = double.tryParse(product.sellPrice?.toAmount() ?? "0.0") ?? 0.0;

                      context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                        rowId: item.rowId,
                        productId: product.proId.toString(),
                        productName: product.proName ?? '',
                        storageId: product.stkStorage,
                        storageName: product.stgName ?? '',
                        purPrice: purchasePrice,
                        salePrice: salePrice,
                      ));

                      salePriceController.text = salePrice.toAmount();
                      storageController.text = product.stgName ?? '';
                    },
                  ),
                ),

                // Quantity
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                          rowId: item.rowId,
                          qty: 0,
                        ));
                        return;
                      }
                      final qty = int.tryParse(value) ?? 0;
                      context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                        rowId: item.rowId,
                        qty: qty,
                      ));
                    },
                  ),
                ),

                // Sale Price
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: salePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(
                          rowId: item.rowId,
                          salePrice: 0,
                        ));
                        return;
                      }
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        context.read<SaleInvoiceBloc>().add(
                          UpdateSaleItemEvent(
                            rowId: item.rowId,
                            salePrice: parsed,
                          ),
                        );
                      }
                    },
                  ),
                ),

                // Total
                SizedBox(
                  width: 100,
                  child: Text(
                    item.totalSale.toAmount(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ),

                // Storage
                SizedBox(
                  width: 100,
                  child: Text(
                    item.storageName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

                // Actions
                SizedBox(
                  width: 60,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () {
                      _priceControllers.remove("sale_${item.rowId}");
                      _qtyControllers.remove(item.rowId);
                      context.read<SaleInvoiceBloc>().add(RemoveSaleItemEvent(item.rowId));
                    },
                  ),
                ),
              ],
            ),

            // Profit info if available (shown below the row for tablet)
            if (item.purPrice != null && item.purPrice! > 0 && item.salePrice != null && item.salePrice! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 30),
                child: Row(
                  children: [
                    Text(
                      '${tr.profit}: ${(item.totalSale - item.totalPurchase).toAmount()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: (item.totalSale - item.totalPurchase) >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildTabletSummarySection(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
      builder: (context, state) {
        if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
          final current = state is SaleInvoiceSaving ?
          state : (state as SaleInvoiceLoaded);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.surface,
              border: Border.all(color: color.outline.withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => _showPaymentModeDialog(current),
                      child: Row(
                        children: [
                          Text(_getPaymentModeLabel(current.paymentMode),
                              style: TextStyle(color: color.primary)),
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 16, color: color.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(color: color.outline.withValues(alpha: .2)),

                // Grand Total
                _buildSummaryRow(
                  label: tr.grandTotal,
                  value: current.grandTotal,
                  isBold: true,
                ),
                Divider(color: color.outline.withValues(alpha: .2)),

                // Payment Breakdown
                if (current.paymentMode == PaymentMode.cash) ...[
                  _buildSummaryRow(
                    label: tr.cashPayment,
                    value: current.cashPayment,
                    color: Colors.green,
                  ),
                ] else if (current.paymentMode == PaymentMode.credit) ...[
                  _buildSummaryRow(
                    label: tr.accountPayment,
                    value: current.creditAmount,
                    color: Colors.orange,
                  ),
                ] else if (current.paymentMode == PaymentMode.mixed) ...[
                  _buildSummaryRow(
                    label: tr.accountPayment,
                    value: current.creditAmount,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    label: tr.cashPayment,
                    value: current.cashPayment,
                    color: Colors.green,
                  ),
                ],

                // Account Information
                if (current.customerAccount != null && current.creditAmount > 0) ...[
                  Divider(color: color.outline.withValues(alpha: .2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${current.customerAccount!.accNumber} | ${current.customerAccount!.accName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildSummaryRow(
                    label: tr.currentBalance,
                    value: current.currentBalance,
                    color: _getBalanceColor(current.currentBalance),
                  ),
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    label: tr.invoiceAmount,
                    value: current.creditAmount,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    label: tr.newBalance,
                    value: current.currentBalance - current.creditAmount,
                    isBold: true,
                    color: _getBalanceColor(current.currentBalance - current.creditAmount),
                  ),
                ],
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
  Widget _buildTabletProfitSummarySection(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
      builder: (context, state) {
        if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
          final current = state is SaleInvoiceSaving ?
          state : (state as SaleInvoiceLoaded);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.surface,
              border: Border.all(color: color.outline.withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.profitSummary, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Icon(Icons.ssid_chart, size: 22, color: color.primary),
                  ],
                ),
                Divider(color: color.outline.withValues(alpha: .2)),
                _buildSummaryRow(
                  label: tr.totalCost,
                  value: current.totalPurchaseCost,
                  color: color.primary.withValues(alpha: .9),
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  label: tr.profit,
                  value: current.totalProfit,
                  color: current.totalProfit >= 0 ? Colors.green : Colors.red,
                  isBold: true,
                ),
                if (current.totalPurchaseCost > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${tr.profit} %'),
                      Text(
                        '${current.profitPercentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: current.totalProfit >= 0 ? Colors.green : Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
  Widget _buildSummaryRow({required String label, required double value, bool isBold = false, Color? color}) {
    return Row(
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
          "${value.toAmount()} $baseCurrency",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
  void _showPaymentModeDialog(SaleInvoiceLoaded current) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.selectPaymentMethod),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: color.primary.withValues(alpha: .05),
                  child: Icon(Icons.money,
                      color: current.paymentMode == PaymentMode.cash ? color.primary : color.outline)),
              title: Text(tr.cashPayment),
              subtitle: Text(tr.cashPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.cash ? Icon(Icons.check, color: color.primary) : null,
              onTap: () {
                Navigator.pop(context);
                _accountController.clear();
                context.read<SaleInvoiceBloc>().add(ClearCustomerAccountEvent());
              },
            ),
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: color.primary.withValues(alpha: .05),
                  child: Icon(Icons.credit_card,
                      color: current.paymentMode == PaymentMode.credit ? color.primary : color.outline)),
              title: Text(tr.accountCredit),
              subtitle: Text(tr.accountCreditSubtitle),
              trailing: current.paymentMode == PaymentMode.credit ? Icon(Icons.check, color: color.primary) : null,
              onTap: () {
                Navigator.pop(context);
                context.read<SaleInvoiceBloc>().add(UpdateSaleReceivePaymentEvent(0));
                setState(() {});
              },
            ),
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: color.primary.withValues(alpha: .05),
                  child: Icon(Icons.payments,
                      color: current.paymentMode == PaymentMode.mixed ? color.primary : color.outline)),
              title: Text(tr.combinedPayment),
              subtitle: Text(tr.combinedPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.mixed ? Icon(Icons.check, color: color.primary) : null,
              onTap: () {
                Navigator.pop(context);
                _showMixedPaymentDialog(context, current);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
        ],
      ),
    );
  }
  void _showMixedPaymentDialog(BuildContext context, SaleInvoiceLoaded current) {
    final controller = TextEditingController();
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.combinedPayment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Account (Credit) Payment Amount",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [SmartThousandsDecimalFormatter()],
            ),
            const SizedBox(height: 16),
            Text(
              "${tr.grandTotal}: ${current.grandTotal.toAmount()}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final cleaned = controller.text.replaceAll(',', '');
              final creditPayment = double.tryParse(cleaned) ?? 0;

              if (creditPayment <= 0) {
                Utils.showOverlayMessage(context, message: 'Account payment must be greater than 0', isError: true);
                return;
              }

              if (creditPayment >= current.grandTotal) {
                Utils.showOverlayMessage(context, message: 'Account payment must be less than total amount for mixed payment', isError: true);
                return;
              }

              context.read<SaleInvoiceBloc>().add(UpdateSaleReceivePaymentEvent(
                creditPayment,
                isCreditAmount: true,
              ));
              Navigator.pop(context);
            },
            child: Text(tr.submit),
          ),
        ],
      ),
    );
  }
  String _getPaymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash: return AppLocalizations.of(context)!.cash;
      case PaymentMode.credit: return AppLocalizations.of(context)!.creditTitle;
      case PaymentMode.mixed: return AppLocalizations.of(context)!.combinedPayment;
    }
  }
  Color _getBalanceColor(double balance) {
    if (balance < 0) {
      return Colors.red;
    } else if (balance > 0) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }
  void _saveInvoice(BuildContext context, SaleInvoiceLoaded state) {
    if (!state.isFormValid) {
      Utils.showOverlayMessage(context, message: 'Please fill all required fields correctly', isError: true);
      return;
    }
    final completer = Completer<String>();
    context.read<SaleInvoiceBloc>().add(SaveSaleInvoiceEvent(
      usrName: _userName ?? '',
      orderName: "Sale",
      ordPersonal: state.customer!.perId!,
      xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
      items: state.items,
      completer: completer,
    ));
  }
  void _onSalePrint({String? invoiceNumber}) {
    final state = context.read<SaleInvoiceBloc>().state;

    SaleInvoiceLoaded? current;

    if (state is SaleInvoiceLoaded) {
      current = state;
    } else if (state is SaleInvoiceSaved && state.invoiceData != null) {
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(context,
          message: 'Cannot print: No invoice data available',
          isError: true);
      return;
    }

    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return SaleInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        unitPrice: item.salePrice ?? 0.0,
        total: item.totalSale,
        storageName: item.storageName,
        purchasePrice: item.purPrice ?? 0.0,
        profit: (item.salePrice ?? 0.0) - (item.purPrice ?? 0.0),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<dynamic>(
        data: null,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().printInvoicePreview(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: true
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
          return InvoicePrintService().printInvoiceDocument(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              selectedPrinter: selectedPrinter,
              pageFormat: pageFormat,
              copies: copies,
              currency: baseCurrency,
              isSale: true
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().createInvoiceDocument(
              invoiceType: "Sale",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.customer?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.customerAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: true
          );
        },
      ),
    );
  }
}