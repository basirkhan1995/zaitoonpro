import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Widgets/amount_display.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../Features/Generic/complex_textfield.dart';
import '../../../../../../../Features/Generic/purchase_product_field.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Generic/underline_searchable_textfield.dart';
import '../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../Features/Other/utils.dart';
import '../../../../../../../Features/Other/zForm_dialog.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/section_title.dart';
import '../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import '../../../../Settings/Ui/Stock/Ui/Products/model/product_model.dart';
import '../../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../Print/print.dart';
import 'bloc/purchase_invoice_bloc.dart';
import 'expense_section.dart';
import 'model/purchase_invoice_items.dart';

class NewPurchaseOrderView extends StatelessWidget {
  const NewPurchaseOrderView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _MobilePurchaseOrderView(),
      desktop: const _DesktopPurchaseOrderView(),
      tablet: const _TabletPurchaseOrderView(),
    );
  }
}

// Desktop Version (Original)
class _DesktopPurchaseOrderView extends StatefulWidget {
  const _DesktopPurchaseOrderView();

  @override
  State<_DesktopPurchaseOrderView> createState() =>
      _DesktopPurchaseOrderViewState();
}
class _DesktopPurchaseOrderViewState extends State<_DesktopPurchaseOrderView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final TextEditingController _remark = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final List<List<FocusNode>> _rowFocusNodes = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showExpensesDialog(BuildContext context) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded) {
      showDialog(
        context: context,
        builder: (context) => const ExpensesDialog(),
      );
    }
  }

  void _showPaymentDialog(PurchaseInvoiceLoaded state) {
    showDialog(
      context: context,
      builder: (context) => PurchasePaymentDialog(state: state),
    );
  }

  String? _userName;
  String? baseCurrency = "";
  int? signatory;

  void _updateControllersFromState(PurchaseInvoiceState state) {
    if (state is PurchaseInvoiceLoaded) {
      // Update exchange rate controller if needed
      if (state.exchangeRate != null && state.exchangeRate! > 0) {
        if (_exchangeRateController.text != state.exchangeRate!.toStringAsFixed(4)) {
          _exchangeRateController.text = state.exchangeRate!.toStringAsFixed(4);
        }
      }

      // Update local amount controllers for each item
      for (var i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        if (item.localAmount != null && item.localAmount! > 0) {
          final controller = _localeAmountControllers[item.rowId];
          if (controller != null && controller.text != item.localAmount!.toAmount()) {
            controller.text = item.localAmount!.toAmount();
          }
        }
      }
    }
  }

  final Map<String, TextEditingController> _purchasePriceControllers = {};
  final Map<String, TextEditingController> _costPriceControllers = {};
  final Map<String, TextEditingController> _sellPriceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _localeAmountControllers = {};
  final Map<String, TextEditingController> _batchControllers = {};

  Timer? _debounce;

  void _onExchangeRateChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final rate = double.tryParse(value.replaceAll(',', ''));

      if (rate != null && rate > 0) {
        final state = context.read<PurchaseInvoiceBloc>().state;

        if (state is PurchaseInvoiceLoaded && state.supplierAccount != null) {
          if (state.exchangeRate != rate) {
            context.read<PurchaseInvoiceBloc>().add(
              UpdateExchangeRateManuallyEvent(
                rate: rate,
                fromCurrency: state.fromCurrency ?? baseCurrency ?? '',
                toCurrency: state.toCurrency ?? state.supplierAccount!.actCurrency ?? '',
              ),
            );
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      baseCurrency = authState.loginData.company?.comLocalCcy;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final purchaseBloc = context.read<PurchaseInvoiceBloc>();
      final exchangeBloc = context.read<ExchangeRateBloc>();
      purchaseBloc.setExchangeRateBloc(exchangeBloc);
      purchaseBloc.add(InitializePurchaseInvoiceEvent());
      _clearAllControllers();
    });
  }

  @override
  void dispose() {
    _clearAllControllers();
    for (final row in _rowFocusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    _accountController.dispose();
    _personController.dispose();
    _xRefController.dispose();
    _remark.dispose();
    _exchangeRateController.dispose();

    for (final controller in _purchasePriceControllers.values) {
      controller.dispose();
    }
    for (final controller in _costPriceControllers.values) {
      controller.dispose();
    }
    for (final controller in _sellPriceControllers.values) {
      controller.dispose();
    }
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (final controller in _batchControllers.values) {
      controller.dispose();
    }
    for (final controller in _localeAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? accountCcy = "";

  void _clearAllControllers() {
    _accountController.clear();
    _personController.clear();
    _xRefController.clear();
    _remark.clear();
    _exchangeRateController.clear();

    _purchasePriceControllers.clear();
    _costPriceControllers.clear();
    _sellPriceControllers.clear();
    _qtyControllers.clear();
    _batchControllers.clear();
    _localeAmountControllers.clear();

    for (final row in _rowFocusNodes) {
      for (final node in row) {
        node.unfocus();
      }
    }
    _rowFocusNodes.clear();
  }

  void _resetForm() {
    _clearAllControllers();
    context.read<PurchaseInvoiceBloc>().add(ResetPurchaseInvoiceEvent());
    _rowFocusNodes.clear();
    _purchasePriceControllers.clear();
    _qtyControllers.clear();
    _batchControllers.clear();
    _sellPriceControllers.clear();
    _localeAmountControllers.clear();
    _costPriceControllers.clear();
    context.read<PurchaseInvoiceBloc>().add(InitializePurchaseInvoiceEvent());
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final purchaseState = context.watch<PurchaseInvoiceBloc>().state;
    final needsConversion = purchaseState is PurchaseInvoiceLoaded
        ? purchaseState.needsExchangeRate
        : false;

    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = authState.loginData;
    _userName = login.usrName ?? "";

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          _userName = state.loginData.usrName ?? '';
        }
      },
      child: BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
        listener: (context, state) {
          if (state is PurchaseInvoiceError) {
            ToastManager.show(
              context: context,
              title: tr.operationFailedTitle,
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is PurchaseInvoiceSaved) {
            Navigator.of(context).pop();
            if (state.success) {
              String? savedInvoiceNumber = state.invoiceNumber;
              ToastManager.show(
                context: context,
                title: tr.successTitle,
                message: tr.successPurchaseInvoiceMsg,
                type: ToastType.success,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onPrint(invoiceNumber: savedInvoiceNumber);
                }
              });
            } else {
              ToastManager.show(
                context: context,
                title: tr.operationFailedTitle,
                message: "Failed to create invoice",
                type: ToastType.error,
              );
            }
          }
          if (state is PurchaseInvoiceInitial || state is PurchaseInvoiceLoaded) {
            _updateControllersFromState(state);
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          appBar: AppBar(
            title: Text(tr.purchaseEntry),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            titleSpacing: 0,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
            actions: [
              ZOutlineButton(
                icon: Icons.lock_reset_outlined,
                onPressed: _resetForm,
                label: Text(tr.newPurchase),
              ),
              const SizedBox(width: 8),
              ZOutlineButton(
                icon: Icons.outbond_outlined,
                onPressed: () => _showExpensesDialog(context),
                label: Text(tr.manageExpenses),
              ),
              const SizedBox(width: 8),
              ZOutlineButton(
                icon: FontAwesomeIcons.print,
                onPressed: _onPrint,

                label: Text(tr.print),
              ),
              const SizedBox(width: 8),
              BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                builder: (context, state) {
                  if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
                    final current = state is PurchaseInvoiceSaving
                        ? state
                        : (state as PurchaseInvoiceLoaded);
                    final isSaving = state is PurchaseInvoiceSaving;

                    return ZOutlineButton(
                      isActive: true,
                      icon: Icons.save_rounded,
                      onPressed: (isSaving || !current.isFormValid)
                          ? null
                          : () => _saveInvoice(context, current),
                      label: isSaving
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                          : Text(tr.saveTitle),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
          body: ZCover(
            color: Theme.of(context).colorScheme.surface,
            borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
            margin: EdgeInsets.all(8),
            radius: 8,
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Supplier and Account Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2,
                          child: GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                            key: const ValueKey('person_field'),
                            controller: _personController,
                            title: tr.supplier,
                            hintText: tr.supplier,
                            isRequired: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr.required(tr.supplier);
                              }
                              return null;
                            },
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
                              if (state is IndividualLoadedState) {
                                return state.individuals;
                              }
                              return [];
                            },
                            onSelected: (value) {
                              _personController.text = "${value.perName} ${value.perLastName}";
                              context.read<PurchaseInvoiceBloc>().add(SelectSupplierEvent(value));
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
                          flex: 2,
                          child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                            builder: (context, state) {
                              if (state is PurchaseInvoiceLoaded) {
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
                                    visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                                    title: Text(account.accName ?? ''),
                                    subtitle: Text('${account.accNumber}'),
                                    trailing: Text(
                                      "${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}",
                                    ),
                                  ),
                                  itemToString: (account) => '${account.accName} (${account.accNumber})',
                                  stateToLoading: (state) => state is AccountLoadingState,
                                  stateToItems: (state) {
                                    if (state is AccountLoadedState) {
                                      return state.accounts;
                                    }
                                    return [];
                                  },
                                  onSelected: (value) {
                                    _accountController.text = '${value.accName} (${value.accNumber})';
                                    setState(() {
                                      accountCcy = value.actCurrency;
                                    });
                                    context.read<PurchaseInvoiceBloc>().add(SelectSupplierAccountEvent(value));

                                    final companyState = context.read<CompanyProfileBloc>().state;
                                    if (companyState is CompanyProfileLoadedState) {
                                      final baseCurr = companyState.company.comLocalCcy ?? '';
                                      final accountCurrency = value.actCurrency ?? '';

                                      if (baseCurr.isNotEmpty && accountCurrency.isNotEmpty && baseCurr != accountCurrency) {
                                        context.read<PurchaseInvoiceBloc>().add(
                                          UpdateExchangeRateForInvoiceEvent(
                                            fromCurrency: baseCurr,
                                            toCurrency: accountCurrency,
                                          ),
                                        );
                                      } else {
                                        context.read<PurchaseInvoiceBloc>().add(
                                          UpdateExchangeRateManuallyEvent(
                                            rate: 1.0,
                                            fromCurrency: baseCurr,
                                            toCurrency: accountCurrency,
                                          ),
                                        );
                                      }
                                    }
                                    _exchangeRateController.clear();
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
                                fetchAllFunction: (bloc) => bloc.add(
                                  LoadAccountsFilterEvent(include: '8', exclude: ''),
                                ),
                                searchFunction: (bloc, query) => bloc.add(
                                  LoadAccountsFilterEvent(input: query, include: '8', exclude: ''),
                                ),
                                itemBuilder: (context, account) => ListTile(
                                  title: Text(account.accName ?? ''),
                                  subtitle: Text(
                                    '${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}',
                                  ),
                                  trailing: Text(account.actCurrency ?? ""),
                                ),
                                itemToString: (account) => '${account.accName} (${account.accNumber})',
                                stateToLoading: (state) => state is AccountLoadingState,
                                stateToItems: (state) {
                                  if (state is AccountLoadedState) {
                                    return state.accounts;
                                  }
                                  return [];
                                },
                                onSelected: (value) {
                                  setState(() {
                                    accountCcy = value.actCurrency;
                                  });
                                  _accountController.text = '${value.accName} (${value.accNumber})';
                                  context.read<PurchaseInvoiceBloc>().add(SelectSupplierAccountEvent(value));
                                },
                                showClearButton: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: _xRefController,
                            title: tr.invoiceNumber,
                          ),
                        ),
                        if (needsConversion) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 1,
                            child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                              builder: (context, state) {
                                if (state is PurchaseInvoiceLoaded) {
                                  final isLoading = state.exchangeRate == null;
                                  return ZTextFieldEntitled(
                                    showClearButton: true,
                                    controller: _exchangeRateController,
                                    title: tr.exchangeRate,
                                    hint: isLoading ? "Loading rate..." : "Enter rate",
                                    inputFormat: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
                                    ],
                                    onSubmit: _onExchangeRateChanged,
                                    end: isLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : null,
                                    isEnabled: !isLoading,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: ZTextFieldEntitled(
                            controller: _remark,
                            title: tr.remark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildItemsHeader(context),
                    const SizedBox(height: 8),
                    Expanded(
                      child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                        builder: (context, state) {
                          if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
                            final current = state is PurchaseInvoiceSaving ? state : (state as PurchaseInvoiceLoaded);
                            _synchronizeFocusNodes(current.items.length);
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
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
                                  ),
                                ],
                              ),
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),

                    _buildSummarySection(context)
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('#'))),
          Expanded(child: Text(locale.products, style: title)),
          const SizedBox(width: 100, child: Text('Qty')),
          const SizedBox(width: 100, child: Text('Batch')),
          const SizedBox(width: 100, child: Text('Total Qty')),
          SizedBox(width: 150, child: Text("${locale.unitPrice} ($baseCurrency)")),
          SizedBox(width: 150, child: Text("${locale.amount} (${accountCcy ?? baseCurrency})")),
          const SizedBox(width: 150, child: Text('Sale %')),
          SizedBox(width: 150, child: Text("${locale.landedPrice} ($baseCurrency)")),
          const SizedBox(width: 180, child: Text('Storage')),
          const SizedBox(width: 60, child: Text('Actions')),
        ].map((child) => DefaultTextStyle(style: title!, child: child)).toList(),
      ),
    );
  }

  void _setupRowFocus(int rowIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rowIndex < _rowFocusNodes.length && _rowFocusNodes[rowIndex].isNotEmpty) {
        _rowFocusNodes[rowIndex][0].requestFocus();
      }
    });
  }

  Widget _buildItemRow({
    required BuildContext context,
    required PurchaseInvoiceItem item,
    required List<FocusNode> nodes,
    required bool isLastRow,
  }) {
    final rowIndex = _rowFocusNodes.indexOf(nodes);

    return _PurchaseItemRow(
      item: item,
      nodes: nodes,
      isLastRow: isLastRow,
      rowIndex: rowIndex,
      onFocusNewRow: (rowIndex) {
        _setupRowFocus(rowIndex);
      },
      qtyControllers: _qtyControllers,
      batchControllers: _batchControllers,
      sellPriceControllers: _sellPriceControllers,
      purchasePriceControllers: _purchasePriceControllers,
      costPriceControllers: _costPriceControllers,
      onDelete: (rowId) {
        _purchasePriceControllers.remove(rowId);
        _qtyControllers.remove(rowId);
        context.read<PurchaseInvoiceBloc>().add(RemovePurchaseItemEvent(rowId));
      },
      onQtyChanged: (rowId, qty) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, qty: qty),
        );
      },
      onBatchChanged: (rowId, batch) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, batch: batch),
        );
      },
      onPurchasePriceChanged: (rowId, price) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, purPrice: price),
        );
      },
      onSellPriceChanged: (rowId, price) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, sellPriceAmount: price),
        );
      },
      onStorageSelected: (rowId, storageId, storageName) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(
            rowId: rowId,
            storageId: storageId,
            storageName: storageName,
          ),
        );
      },
      onProductSelected: (rowId, productId, productName) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(
            rowId: rowId,
            productId: productId,
            productName: productName,
          ),
        );
        _autoSelectFirstStorage(context, rowId);
      },
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
      builder: (context, state) {
        if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
          final current = state is PurchaseInvoiceSaving ? state : (state as PurchaseInvoiceLoaded);
          final totalExpenses = current.totalExpenses;
          final needsAccountConversion = current.needsExchangeRate;
          final needsCashConversion = current.needsCashConversion;
          final bool isLoading = current.isExchangeRateLoading;
          final baseCurrency = current.fromCurrency ?? '';
          final String accountCurr = current.supplierAccount?.actCurrency ?? '';
          final bool needsConversion = current.needsExchangeRate;
          final bool hasCreditAccount = current.supplierAccount != null && current.creditAmount > 0;

          // Calculate account amounts correctly
          final double remainingAmountInAccountCurrency = hasCreditAccount
              ? current.creditAmountLocal
              : 0.0;

          // New balance calculation
          final double newBalanceInAccountCurrency = hasCreditAccount
              ? current.currentBalance + remainingAmountInAccountCurrency
              : 0.0;

          return Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.surface,
              border: Border.all(color: color.outline.withValues(alpha: .2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Icon(Icons.file_open_outlined),
                                Text(tr.invoiceSummary.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            InkWell(
                              onTap: () => _showPaymentDialog(current),
                              child: Row(
                                children: [
                                  Text(_getPaymentModeLabel(current.paymentMode).toUpperCase(), style: TextStyle(color: color.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.more_vert_rounded, size: 20, color: color.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Divider(color: color.outline.withValues(alpha: .2)),
                        const SizedBox(height: 4),

                        _buildSummaryRow(label: tr.subtotal, value: current.subtotal, currency: baseCurrency),

                        if (totalExpenses > 0) ...[
                          const SizedBox(height: 4),
                          _buildSummaryRow(label: tr.totalExpense, value: totalExpenses, color: Colors.red, currency: baseCurrency),
                          const SizedBox(height: 4),
                        ],

                        Divider(color: color.outline.withValues(alpha: .2)),
                        const SizedBox(height: 4),
                        _buildSummaryRow(
                          label: tr.grandTotal,
                          value: current.subtotal + totalExpenses,
                          isBold: true,
                          fontSize: 17,
                          color: Colors.purple,
                          currency: baseCurrency,
                        ),

                        if (needsConversion && !isLoading)...[
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            label: '${tr.grandTotal} (${current.toCurrency})',
                            value: current.grandTotalLocal,
                            fontSize: 14,
                            color: color.outline.withValues(alpha: .8),
                            currency: current.toCurrency ?? '',
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(width: 12),
                  VerticalDivider(width: 20, thickness: 1, color: color.outline.withValues(alpha: .2)),
                  SizedBox(width: 12),

                  // if (current.supplierAccount != null && current.supplierAccount!.actCurrency != null && current.supplierAccount!.actCurrency!.isNotEmpty) ...[
                  //   const SizedBox(height: 4),
                  //   Divider(color: color.outline.withValues(alpha: .2)),
                  //   const SizedBox(height: 4),
                  //   _buildSummaryRow(
                  //     label: "${tr.totalTitle} (${current.supplierAccount!.actCurrency})",
                  //     value: current.totalLocalAmount,
                  //     isBold: true,
                  //     color: Colors.purple,
                  //     currency: current.supplierAccount!.actCurrency,
                  //   ),
                  // ],


                  //Cash Payment
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            Icon(Icons.money),
                            Text(tr.payment.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Divider(color: color.outline.withValues(alpha: .2)),
                        const SizedBox(height: 4),

                        // Payment section with currency conversion
                        if (current.paymentMode == PaymentMode.cash) ...[

                          AmountDisplay(
                              title: tr.cashPayment,
                              baseAmount: current.cashPayment,
                              baseCurrency: baseCurrency,
                              convertedAmount: (needsCashConversion && current.cashCurrency != null && current.cashCurrency != baseCurrency) ?
                              current.cashPaymentInCashCurrency : null,
                              convertedCurrency: current.cashCurrency?? "",
                          ),

                          // _buildSummaryRow(label: tr.cashPayment, value: current.cashPayment, color: Colors.green, currency: baseCurrency),
                          //
                          // if (needsCashConversion && current.cashCurrency != null && current.cashCurrency != baseCurrency)
                          //   _buildSummaryRow(
                          //     label: '${tr.cashPayment} (${current.cashCurrency})',
                          //     value: current.cashPaymentInCashCurrency,
                          //     color: Colors.green,
                          //     currency: current.cashCurrency!,
                          //     fontSize: 12,
                          //   ),

                          if (current.supplierAccount != null && needsAccountConversion)
                            _buildSummaryRow(
                              label: "${tr.cashPayment} (${current.supplierAccount!.actCurrency})",
                              value: current.cashPaymentLocal,
                              color: Colors.green,
                              currency: current.supplierAccount!.actCurrency,
                              fontSize: 12,
                            ),
                        ] else if (current.paymentMode == PaymentMode.credit) ...[
                          if (current.supplierAccount != null && needsAccountConversion)
                            _buildSummaryRow(
                              label: "${tr.creditPayment} (${current.supplierAccount!.actCurrency})",
                              value: current.creditAmountLocal,
                              color: Colors.orange,
                              currency: current.supplierAccount!.actCurrency,
                              fontSize: 13,
                            ),
                        ] else if (current.paymentMode == PaymentMode.mixed) ...[
                          AmountDisplay(
                            title: tr.cashPayment,
                            baseAmount: current.cashPayment,
                            baseCurrency: baseCurrency,
                            convertedAmount: (needsCashConversion && current.cashCurrency != null && current.cashCurrency != baseCurrency) ?
                            current.cashPaymentInCashCurrency : null,
                            convertedCurrency: current.cashCurrency ?? "",
                          ),
                          _buildSummaryRow(label: tr.accountPayment, value: current.creditAmount, color: Colors.orange, currency: baseCurrency),
                          _buildSummaryRow(label: tr.cashPayment, value: current.cashPayment, color: Colors.green, currency: baseCurrency),

                          // Show cash payment in selected cash currency if different
                          if (needsCashConversion && current.cashCurrency != null && current.cashCurrency != baseCurrency)
                            _buildSummaryRow(
                              label: '${tr.cashPayment} (${current.cashCurrency})',
                              value: current.cashPaymentInCashCurrency,
                              color: Colors.green,
                              currency: current.cashCurrency!,
                              fontSize: 12,
                            ),

                          // Show converted amounts in account currency
                          if (current.supplierAccount != null && needsAccountConversion) ...[
                            const SizedBox(height: 4),
                            Divider(color: color.outline.withValues(alpha: .2)),
                            _buildSummaryRow(
                              label: "${tr.creditPayment} (${current.supplierAccount!.actCurrency})",
                              value: current.creditAmountLocal,
                              color: Colors.orange,
                              currency: current.supplierAccount!.actCurrency,
                              fontSize: 12,
                            ),
                            _buildSummaryRow(
                              label: "${tr.cashPayment} (${current.supplierAccount!.actCurrency})",
                              value: current.cashPaymentLocal,
                              color: Colors.green,
                              currency: current.supplierAccount!.actCurrency,
                              fontSize: 12,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  SizedBox(width: 12),
                  VerticalDivider(width: 20, thickness: 1, color: color.outline.withValues(alpha: .2)),
                  SizedBox(width: 12),

                  Expanded(
                      child: Column(
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Icon(FontAwesomeIcons.buildingColumns,size: 20),
                          Text(tr.accountInformation.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Divider(color: color.outline.withValues(alpha: .2)),
                      const SizedBox(height: 4),
                      // Account balance section
                      if (current.supplierAccount != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${current.supplierAccount!.accNumber} | ${current.supplierAccount!.accName}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(current.supplierAccount!.actCurrency ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        _buildSummaryRow(
                          label: tr.currentBalance,
                          value: current.currentBalance,
                          color: _getBalanceColor(current.currentBalance),
                          currency: current.supplierAccount!.actCurrency,
                        ),
                        if (current.creditAmountLocal > 0) ...[
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            label: tr.invoiceAmount,
                            value: current.creditAmountLocal,
                            color: Colors.orange,
                            currency: current.supplierAccount!.actCurrency,
                          ),
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            label: "${tr.newBalance} | ${_getBalanceStatus(current.newBalance)}",
                            value: current.newBalance,
                            isBold: true,
                            color: _getBalanceColor(current.newBalance),
                            currency: current.supplierAccount!.actCurrency,
                          ),
                        ],
                      ],
                    ],
                  ))
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Color _getBalanceColor(double balance) {
    if (balance < 0) return Colors.red;
    if (balance > 0) return Colors.green;
    return Colors.grey;
  }

  String _getBalanceStatus(double balance) {
    if (balance < 0) return AppLocalizations.of(context)!.debtor;
    if (balance > 0) return AppLocalizations.of(context)!.creditor;
    return AppLocalizations.of(context)!.noAccountsFound;
  }

  Widget _buildSummaryRow({
    required String label,
    required double value,
    bool isBold = false,
    Color? color,
    String? currency,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
        Text(
          "${value.toAmount()} ${currency ?? ''}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _synchronizeFocusNodes(int itemCount) {
    while (_rowFocusNodes.length < itemCount) {
      _rowFocusNodes.add([
        FocusNode(), // Product
        FocusNode(), // Qty
        FocusNode(), // Batch
        FocusNode(), // Unit Price
        FocusNode(), // Sell Price
        FocusNode(), // Storage
      ]);
    }
    while (_rowFocusNodes.length > itemCount) {
      final removed = _rowFocusNodes.removeLast();
      for (final node in removed) {
        node.dispose();
      }
    }
  }

  String _getPaymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return AppLocalizations.of(context)!.cash;
      case PaymentMode.credit:
        return AppLocalizations.of(context)!.creditTitle;
      case PaymentMode.mixed:
        return AppLocalizations.of(context)!.combinedPayment;
    }
  }

  void _autoSelectFirstStorage(BuildContext context, String rowId) {
    final storageState = context.read<StorageBloc>().state;
    if (storageState is StorageLoadedState && storageState.storage.isNotEmpty) {
      final firstStorage = storageState.storage.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(
            rowId: rowId,
            storageId: firstStorage.stgId!,
            storageName: firstStorage.stgName ?? '',
          ),
        );
      });
    }
  }

  void _saveInvoice(BuildContext context, PurchaseInvoiceLoaded state) {
    if (!state.isFormValid) {
      Utils.showOverlayMessage(
        context,
        message: 'Please fill all required fields correctly',
        isError: true,
      );
      return;
    }

    final completer = Completer<String>();

    context.read<PurchaseInvoiceBloc>().add(
      SavePurchaseInvoiceEvent(
        usrName: _userName ?? '',
        orderName: "Purchase",
        ordPersonal: state.supplier!.perId!,
        xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
        remark: _remark.text,
        completer: completer,
      ),
    );
  }

  void _onPrint({String? invoiceNumber}) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    PurchaseInvoiceLoaded? current;

    if (state is PurchaseInvoiceLoaded) {
      current = state;
    } else if (state is PurchaseInvoiceSaved && state.invoiceData != null) {
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(
        context,
        message: 'Cannot print: No invoice data available',
        isError: true,
      );
      return;
    }

    final needsConversion = current.supplierAccount?.actCurrency != null &&
        baseCurrency != null &&
        baseCurrency != current.supplierAccount!.actCurrency;

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
      statementDate: DateTime.now().toFullDateTime,
    );

    final base64Logo = companyState.company.comLogo;
    if (base64Logo != null && base64Logo.isNotEmpty) {
      try {
        company.comLogo = base64Decode(base64Logo);
      } catch (e) {
        "";
      }
    }

    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return PurchaseInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        unitPrice: item.purPrice ?? 0.0,
        batch: item.stkBatch,
        unit: '',
        total: item.totalPurchase,
        storageName: item.storageName,
        localAmount: item.singleLocalAmount,
        localCurrency: current?.supplierAccount?.actCurrency ?? current?.toCurrency,
        exchangeRate: current?.exchangeRate,
      );
    }).toList();

    final totalLocalAmount = current.totalLocalAmount;

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
            invoiceType: "Purchase",
            invoiceNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: current?.supplier?.perName ?? "",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion ? (current.supplierAccount?.actCurrency ?? current.toCurrency) : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
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
            invoiceType: "Purchase",
            invoiceNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: current?.supplier?.perName ?? "",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company,
            selectedPrinter: selectedPrinter,
            pageFormat: pageFormat,
            copies: copies,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion ? (current.supplierAccount?.actCurrency ?? current.toCurrency) : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().createInvoiceDocument(
            invoiceType: "Purchase",
            invoiceNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: current?.supplier?.perName ?? "",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion ? (current.supplierAccount?.actCurrency ?? current.toCurrency) : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
          );
        },
      ),
    );
  }
}

class _PurchaseItemRow extends StatefulWidget {
  final PurchaseInvoiceItem item;
  final List<FocusNode> nodes;
  final Function(int)? onFocusNewRow;
  final bool isLastRow;
  final int rowIndex;
  final Map<String, TextEditingController> qtyControllers;
  final Map<String, TextEditingController> batchControllers;
  final Map<String, TextEditingController> sellPriceControllers;
  final Map<String, TextEditingController> purchasePriceControllers;
  final Map<String, TextEditingController> costPriceControllers;
  final Function(String) onDelete;
  final Function(String, int) onQtyChanged;
  final Function(String, int) onBatchChanged;
  final Function(String, double) onPurchasePriceChanged;
  final Function(String, double) onSellPriceChanged;
  final Function(String, int, String) onStorageSelected;
  final Function(String, String, String) onProductSelected;

  const _PurchaseItemRow({
    required this.item,
    required this.nodes,
    required this.isLastRow,
    required this.rowIndex,
    required this.qtyControllers,
    required this.batchControllers,
    required this.sellPriceControllers,
    required this.purchasePriceControllers,
    required this.costPriceControllers,
    required this.onDelete,
    this.onFocusNewRow,
    required this.onQtyChanged,
    required this.onBatchChanged,
    required this.onPurchasePriceChanged,
    required this.onSellPriceChanged,
    required this.onStorageSelected,
    required this.onProductSelected,
  });

  @override
  State<_PurchaseItemRow> createState() => _PurchaseItemRowState();
}
class _PurchaseItemRowState extends State<_PurchaseItemRow> {
  late TextEditingController _landedPriceController;
  late TextEditingController _storageController;
  late TextEditingController _localAmountController;
  double? _lastExchangeRate;
  double? _lastPurPrice;
  @override
  void initState() {
    super.initState();
    _landedPriceController = TextEditingController(
      text: widget.item.landedPrice != null && widget.item.landedPrice! > 0
          ? widget.item.landedPrice!.toAmount()
          : '',
    );
    _storageController = TextEditingController(text: widget.item.storageName);
    _localAmountController = TextEditingController(
      text: _getLocalAmountText(),
    );
    _lastExchangeRate = _getCurrentExchangeRate();
    _lastPurPrice = widget.item.purPrice;
  }

  double? _getCurrentExchangeRate() {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded) {
      return state.exchangeRate;
    }
    return null;
  }

  void _updateLocalAmount() {
    final currentExchangeRate = _getCurrentExchangeRate();
    final currentPurPrice = widget.item.purPrice;

    // Check if exchange rate or purchase price changed
    if (_lastExchangeRate != currentExchangeRate || _lastPurPrice != currentPurPrice) {
      _lastExchangeRate = currentExchangeRate;
      _lastPurPrice = currentPurPrice;

      // Calculate new local amount
      double? newLocalAmount;
      if (currentPurPrice != null && currentExchangeRate != null) {
        newLocalAmount = currentPurPrice * currentExchangeRate;
      }

      // Update the local amount text
      final newText = (newLocalAmount != null && newLocalAmount > 0)
          ? newLocalAmount.toAmount()
          : '';

      if (_localAmountController.text != newText) {
        _localAmountController.text = newText;

        // Also update the item's localAmount if needed
        if (widget.item.localAmount != newLocalAmount) {
          widget.item.localAmount = newLocalAmount;
        }
      }
    }
  }

  String _getLocalAmountText() {
    // First check if item has localAmount stored
    if (widget.item.localAmount != null && widget.item.localAmount! > 0) {
      return widget.item.localAmount!.toAmount();
    }

    // Calculate from current values
    final exchangeRate = _getCurrentExchangeRate();
    if (widget.item.purPrice != null && exchangeRate != null && exchangeRate > 0) {
      final calculatedAmount = widget.item.purPrice! * exchangeRate;
      if (calculatedAmount > 0) {
        return calculatedAmount.toAmount();
      }
    }
    return '';
  }

  @override
  void didUpdateWidget(_PurchaseItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update landed price
    if (widget.item.landedPrice != oldWidget.item.landedPrice) {
      final newValue = widget.item.landedPrice != null && widget.item.landedPrice! > 0
          ? widget.item.landedPrice!.toAmount()
          : '';
      if (_landedPriceController.text != newValue) {
        _landedPriceController.text = newValue;
      }
    }

    // Update storage
    if (widget.item.storageName != oldWidget.item.storageName) {
      if (_storageController.text != widget.item.storageName) {
        _storageController.text = widget.item.storageName;
      }
    }

    // Update local amount whenever anything changes
    _updateLocalAmount();
  }

  @override
  void dispose() {
    _landedPriceController.dispose();
    _storageController.dispose();
    _localAmountController.dispose();
    super.dispose();
  }

  void focusNext(int index) {
    if (index < widget.nodes.length) {
      final nextNode = widget.nodes[index];
      Future.delayed(const Duration(milliseconds: 50), () {
        if (nextNode.canRequestFocus) {
          nextNode.requestFocus();
        }
      });
    }
  }

  FocusNode? safeNode(int index) {
    return (index >= 0 && index < widget.nodes.length) ? widget.nodes[index] : null;
  }

  void _addNewRowAndFocus() {
    // Add new row
    context.read<PurchaseInvoiceBloc>().add(AddNewPurchaseItemEvent());

    // After adding, focus the new row's product field
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        final state = context.read<PurchaseInvoiceBloc>().state;
        if (state is PurchaseInvoiceLoaded) {
          final newRowIndex = state.items.length - 1;
          widget.onFocusNewRow?.call(newRowIndex);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    final productController = TextEditingController(
      text: widget.item.productName,
    );
    final headerProductController = TextEditingController(
      text: widget.item.productName,
    );
    final qtyController = widget.qtyControllers.putIfAbsent(
      widget.item.rowId,
          () => TextEditingController(
        text: widget.item.qty > 0 ? widget.item.qty.toString() : '',
      ),
    );
    final batchController = widget.batchControllers.putIfAbsent(
      widget.item.rowId,
          () => TextEditingController(
        text: widget.item.stkBatch > 0 ? widget.item.stkBatch.toString() : '',
      ),
    );
    final sellPriceController = widget.sellPriceControllers.putIfAbsent(
      widget.item.rowId,
          () => TextEditingController(
        text: widget.item.sellPriceAmount > 0 ? widget.item.sellPriceAmount.toString() : '',
      ),
    );
    final priceController = widget.purchasePriceControllers.putIfAbsent(
      widget.item.rowId,
          () => TextEditingController(
        text: widget.item.purPrice != null && widget.item.purPrice! > 0
            ? widget.item.purPrice!.toAmount()
            : '',
      ),
    );

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              /// Row number
              SizedBox(
                width: 40,
                child: Text(
                  (widget.rowIndex + 1).toString(),
                  textAlign: TextAlign.center,
                ),
              ),

              /// Product Search Field - Index 0
              Expanded(
                child: PurchaseProductSearchField(
                  controller: productController,
                  headerSearchController: headerProductController, // Optional: for header sync
                  focusNode: safeNode(0),
                  bloc: context.read<ProductsBloc>(),
                  onProductSelected: (product) {
                    if (product != null) {
                      widget.onProductSelected(
                        widget.item.rowId,
                        product.proId.toString(),
                        product.proName ?? '',
                      );
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          focusNext(1);
                        }
                      });
                    }
                  },
                  onSubmitted: () {
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted && widget.item.productId.isNotEmpty) {
                        focusNext(1);
                      }
                    });
                  },
                  hintText: AppLocalizations.of(context)!.products,
                  showAllOnFocus: true,
                  openOverlayOnFocus: true, // Opens overlay when field gets focus
                ),
              ),

              /// Qty - Index 1
              SizedBox(
                width: 100,
                child: TextField(
                  controller: qtyController,
                  focusNode: safeNode(1),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: locale.qty,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final qty = int.tryParse(value) ?? 0;
                    widget.onQtyChanged(widget.item.rowId, qty);
                  },
                  onSubmitted: (_) => focusNext(2), // Move to Batch
                ),
              ),

              /// Batch - Index 2
              SizedBox(
                width: 100,
                child: TextField(
                  controller: batchController,
                  focusNode: safeNode(2),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: locale.batchTitle,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final batch = int.tryParse(value) ?? 0;
                    widget.onBatchChanged(widget.item.rowId, batch);
                  },
                  onSubmitted: (_) => focusNext(3), // Move to Unit Price
                ),
              ),

              /// Total (read-only) - No focus
              SizedBox(
                width: 100,
                child: Text(
                  widget.item.totalQty.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              /// Unit Price - Index 3
              SizedBox(
                width: 150,
                child: TextField(
                  controller: priceController,
                  focusNode: safeNode(3),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(

                    hintText: locale.unitPrice,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value.replaceAll(',', '')) ?? 0;
                    widget.onPurchasePriceChanged(widget.item.rowId, parsed);
                  },
                  onSubmitted: (_) {
                    if (widget.isLastRow) {
                      // Add new row and focus its product field
                      _addNewRowAndFocus();
                    } else {
                      // Move to next row's product field (index 0 of next row)
                      focusNext(0);
                    }
                  },
                ),
              ),

              /// Local Amount (read-only)
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _localAmountController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.amount,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  readOnly: true,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              /// Sell Price - Index 4
              SizedBox(
                width: 150,
                child: TextField(
                  controller: sellPriceController,
                  focusNode: safeNode(4),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: locale.salePercentage,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value.replaceAll(',', '')) ?? 0;
                    widget.onSellPriceChanged(widget.item.rowId, parsed);
                  },
                  onSubmitted: (_) => focusNext(5), // Move to Storage
                ),
              ),

              /// Landed Price (read-only)
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _landedPriceController,
                  decoration: InputDecoration(
                    hintText: locale.landedPrice,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  readOnly: true,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              /// Storage - Index 5
              SizedBox(
                width: 180,
                child: BlocBuilder<StorageBloc, StorageState>(
                  builder: (context, state) {
                    final storageFocus = safeNode(5);

                    if (state is StorageLoadedState &&
                        state.storage.isNotEmpty &&
                        widget.item.storageId == 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final first = state.storage.first;
                        widget.onStorageSelected(
                          widget.item.rowId,
                          first.stgId!,
                          first.stgName ?? '',
                        );
                        _storageController.text = first.stgName ?? '';
                      });
                    }

                    return GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
                      title: "",
                      focusNode: storageFocus,
                      controller: _storageController,
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
                        if (state is StorageLoadedState) {
                          return state.storage;
                        }
                        return [];
                      },
                      onSelected: (storage) {
                        widget.onStorageSelected(
                          widget.item.rowId,
                          storage.stgId!,
                          storage.stgName ?? '',
                        );
                        _storageController.text = storage.stgName ?? '';
                        // After selecting storage, move to next row's product or add new row
                        if (widget.isLastRow) {
                          _addNewRowAndFocus();
                        } else {
                          focusNext(0); // Move to next row's product
                        }
                      },
                    );
                  },
                ),
              ),

              /// Delete button
              SizedBox(
                width: 60,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => widget.onDelete(widget.item.rowId),
                ),
              ),
            ],
          ),
        ),

        /// Add button (only for last row)
        if (widget.isLastRow)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                ZOutlineButton(
                  width: 120,
                  icon: Icons.add,
                  label: Text(locale.addItem),
                  onPressed: () {
                    _addNewRowAndFocus();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PurchasePaymentDialog extends StatefulWidget {
  final PurchaseInvoiceLoaded state;

  const PurchasePaymentDialog({super.key, required this.state});

  @override
  State<PurchasePaymentDialog> createState() => _PurchasePaymentDialogState();
}
class _PurchasePaymentDialogState extends State<PurchasePaymentDialog> {
  late TextEditingController _cashPaymentController;
  late TextEditingController _exchangeRateController;
  late TextEditingController _cashExchangeRateController;

  String _selectedCashCurrency = '';
  double _cashExchangeRate = 1.0;
  bool _isLoadingCashRate = false;
  String _baseCurrency = '';

  @override
  void initState() {
    super.initState();

    // Get base currency from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _baseCurrency = authState.loginData.company?.comLocalCcy ?? 'USD';
    }

    // If still empty, try to get from state
    if (_baseCurrency.isEmpty) {
      _baseCurrency = widget.state.fromCurrency ?? 'USD';
    }

    // Initialize cash currency - ALWAYS start with base currency
    _selectedCashCurrency = _baseCurrency;
    _cashExchangeRate = 1.0;

    // Convert stored base amount to selected currency for display
    final cashPaymentInSelectedCurrency = widget.state.cashPayment * _cashExchangeRate;

    _cashPaymentController = TextEditingController(
      text: cashPaymentInSelectedCurrency > 0 ? cashPaymentInSelectedCurrency.toStringAsFixed(2) : '',
    );

    _exchangeRateController = TextEditingController(
      text: widget.state.exchangeRate != null && widget.state.exchangeRate! > 0
          ? widget.state.exchangeRate!.toStringAsFixed(4)
          : '',
    );

    _cashExchangeRateController = TextEditingController(
      text: _cashExchangeRate.toStringAsFixed(4),
    );
  }

  void _updateCashPayment(double amountInSelectedCurrency) {
    // Convert selected currency amount to base currency for storage
    final amountInBaseCurrency = amountInSelectedCurrency / _cashExchangeRate;
    context.read<PurchaseInvoiceBloc>().add(UpdateCashPaymentEvent(amountInBaseCurrency));
    setState(() {});
  }

  void _updateCashCurrencyAndRate(String currency, double rate) {
    setState(() {
      _selectedCashCurrency = currency;
      _cashExchangeRate = rate;
      _cashExchangeRateController.text = rate.toStringAsFixed(4);
    });

    context.read<PurchaseInvoiceBloc>().add(UpdateCashCurrencyEvent(
      currency: currency,
      exchangeRate: rate,
    ));
  }

  void _onCashCurrencyChanged(CurrenciesModel? currency) {
    if (currency == null) return;

    final newCurrency = currency.ccyCode!;

    // If currency didn't change, do nothing
    if (newCurrency == _selectedCashCurrency) return;

    setState(() {
      _selectedCashCurrency = newCurrency;
      _isLoadingCashRate = true;
    });

    // If new currency is different from base currency, fetch rate
    if (_baseCurrency.isNotEmpty && newCurrency != _baseCurrency) {
      _fetchCashExchangeRate(_baseCurrency, newCurrency);
    } else {
      // Same as base currency, rate is 1.0
      setState(() {
        _cashExchangeRate = 1.0;
        _cashExchangeRateController.text = '1.0000';
        _isLoadingCashRate = false;
      });
      _updateCashCurrencyAndRate(newCurrency, 1.0);
    }
  }

  Future<void> _fetchCashExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      final rateStr = await context.read<PurchaseInvoiceBloc>().repo.getSingleRate(
        fromCcy: fromCurrency,
        toCcy: toCurrency,
      );
      final rate = double.tryParse(rateStr ?? "1.0") ?? 1.0;

      setState(() {
        _cashExchangeRate = rate;
        _cashExchangeRateController.text = rate.toStringAsFixed(4);
        _isLoadingCashRate = false;
      });
      _updateCashCurrencyAndRate(toCurrency, rate);
    } catch (e) {
      setState(() {
        _cashExchangeRate = 1.0;
        _cashExchangeRateController.text = '1.0000';
        _isLoadingCashRate = false;
      });
      _updateCashCurrencyAndRate(toCurrency, 1.0);
    }
  }

  void _updateExchangeRate(double rate) {
    final state = widget.state;
    if (state.supplierAccount != null) {
      context.read<PurchaseInvoiceBloc>().add(
        UpdateExchangeRateManuallyEvent(
          rate: rate,
          fromCurrency: _baseCurrency,
          toCurrency: state.supplierAccount!.actCurrency ?? '',
        ),
      );
      setState(() {});
    }
  }

  void _updateCashExchangeRate(double rate) {
    setState(() {
      _cashExchangeRate = rate;
      _cashExchangeRateController.text = rate.toStringAsFixed(4);
    });
    _updateCashCurrencyAndRate(_selectedCashCurrency, rate);
  }

  double get _convertedCashAmount {
    final amountInSelectedCurrency = double.tryParse(_cashPaymentController.text.replaceAll(',', '')) ?? 0;
    return amountInSelectedCurrency / _cashExchangeRate;
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final needsAccountConversion = widget.state.needsExchangeRate;
    final grandTotal = widget.state.subtotal;

    // Check if cash currency is different from base currency
    final bool needsCashConversion = _selectedCashCurrency.isNotEmpty &&
        _baseCurrency.isNotEmpty &&
        _selectedCashCurrency != _baseCurrency;

    return ZFormDialog(
      title: tr.payment.toUpperCase(),
      icon: Icons.payment,
      width: 550,
      actionLabel: Text(tr.confirm),
      onAction: () => Navigator.pop(context),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Section
              SectionTitle(title: tr.orderSummary.toUpperCase()),
              const SizedBox(height: 8),
              ZCover(
                padding: const EdgeInsets.all(12),
                radius: 8,
                child: Column(
                  children: [
                    _infoRow(
                      label: tr.grandTotal,
                      value: grandTotal,
                      currency: _baseCurrency,
                      isBold: true,
                      fontSize: 20,
                    ),
                    if (widget.state.totalExpenses > 0)
                      _infoRow(
                        label: tr.totalExpense,
                        value: widget.state.totalExpenses,
                        currency: _baseCurrency,
                        color: Colors.red,
                      ),
                    if (widget.state.totalExpenses > 0)
                      _infoRow(
                        label: tr.totalCostPludExpenses,
                        value: grandTotal + widget.state.totalExpenses,
                        currency: _baseCurrency,
                        isBold: true,
                      ),
                    // Account conversion summary (if account is selected)
                    if (needsAccountConversion && widget.state.exchangeRate != null && widget.state.exchangeRate! > 0 && widget.state.toCurrency != null)
                      _infoRow(
                        label: "${tr.grandTotal} (${widget.state.toCurrency})",
                        value: grandTotal * widget.state.safeExchangeRate,
                        currency: widget.state.toCurrency!,
                        fontSize: 15,
                        color: color.outline.withValues(alpha: .7),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Payment Section
              SectionTitle(title: tr.payment),
              const SizedBox(height: 10),

              // Cash Payment Section - ALWAYS visible, starts with base currency
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ZGenericTextField(
                    controller: _cashPaymentController,
                    title: "${tr.cashAmount} ($_baseCurrency)",
                    hint: "0.00",
                    defaultCurrencyCode: _baseCurrency,
                    fieldType: ZTextFieldType.currency,
                    onCurrencyChanged: _onCashCurrencyChanged,
                    inputFormat: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    onChanged: (value) {
                      final amountInSelectedCurrency = double.tryParse(value.replaceAll(',', '')) ?? 0;
                      _updateCashPayment(amountInSelectedCurrency);
                    },
                    showFlag: true,
                    showClearButton: true,
                    showSymbol: false,
                    isRequired: true,
                  ),

                  // Show current selected currency info
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Selected cash currency: $_selectedCashCurrency",
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),

                  // Exchange Rate Section for Cash (if currency changed from base)
                  if (needsCashConversion) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: _cashExchangeRateController,
                            title: "${tr.exchangeRate} (1 $_baseCurrency = ? $_selectedCashCurrency)",
                            hint: "1 $_baseCurrency = ?",
                            inputFormat: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}'))
                            ],
                            onChanged: (value) {
                              final rate = double.tryParse(value.replaceAll(',', '')) ?? 1.0;
                              if (rate > 0) {
                                _updateCashExchangeRate(rate);
                              }
                            },
                            trailing: _isLoadingCashRate
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3)),
                            color: color.primary.withValues(alpha: .03),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "≈ ${_convertedCashAmount.toStringAsFixed(2)} $_baseCurrency",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              if (_convertedCashAmount > 0 && grandTotal > 0)
                                Text(
                                  "(${(_convertedCashAmount / grandTotal * 100).toStringAsFixed(1)}% of total)",
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Account Payment Exchange Rate Section (only if account is selected)
                  if (needsAccountConversion && widget.state.toCurrency != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: _exchangeRateController,
                            title: "${tr.exchangeRate} ($_baseCurrency → ${widget.state.toCurrency})",
                            hint: "1 $_baseCurrency = ?",
                            inputFormat: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}'))
                            ],
                            onChanged: (value) {
                              final rate = double.tryParse(value.replaceAll(',', '')) ?? 1.0;
                              if (rate > 0) {
                                _updateExchangeRate(rate);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3)),
                            color: color.primary.withValues(alpha: .03),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            "${widget.state.creditAmountLocal.toStringAsFixed(2)} ${widget.state.toCurrency}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Credit Account Section (only if account is selected)
              if (widget.state.supplierAccount != null)
                ZCover(
                  padding: const EdgeInsets.all(12),
                  radius: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.credit_card, size: 20, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(tr.accountPayment.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.creditAccount),
                          Text(
                            "${widget.state.supplierAccount?.accName} (${widget.state.supplierAccount?.accNumber})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.creditAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "${widget.state.creditAmount.toStringAsFixed(2)} $_baseCurrency",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      if (needsAccountConversion && widget.state.creditAmount > 0 && widget.state.toCurrency != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${tr.amount} (${widget.state.toCurrency})",
                                style: const TextStyle(fontSize: 14)),
                            Text(
                              "${widget.state.creditAmountLocal.toStringAsFixed(2)} ${widget.state.toCurrency}",
                              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                      if (widget.state.supplierAccount != null) ...[
                        const SizedBox(height: 8),
                        Divider(),
                        const SizedBox(height: 4),
                        _infoRow(
                          label: tr.currentBalance,
                          value: widget.state.currentBalance,
                          currency: widget.state.supplierAccount!.actCurrency ?? _baseCurrency,
                          fontSize: 15,
                        ),
                        _infoRow(
                          label: tr.newBalance,
                          value: widget.state.newBalance,
                          currency: widget.state.supplierAccount!.actCurrency ?? _baseCurrency,
                          isBold: true,
                          fontSize: 17,
                          color: widget.state.newBalance < 0 ? Colors.red : Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required double value,
    required String currency,
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    final themeColor = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            "${value.toStringAsFixed(2)} $currency",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color ?? themeColor.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Mobile Version
class _MobilePurchaseOrderView extends StatefulWidget {
  const _MobilePurchaseOrderView();

  @override
  State<_MobilePurchaseOrderView> createState() =>
      _MobilePurchaseOrderViewState();
}
class _MobilePurchaseOrderViewState extends State<_MobilePurchaseOrderView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _userName;
  String? baseCurrency;
  int? signatory;
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseInvoiceBloc>().add(InitializePurchaseInvoiceEvent());
    });

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
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
    _userName = login.usrName ?? "";

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          _userName = state.loginData.usrName ?? '';
        }
      },
      child: BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
        listener: (context, state) {
          if (state is PurchaseInvoiceError) {
            Utils.showOverlayMessage(
              context,
              message: state.message,
              isError: true,
            );
          }
          if (state is PurchaseInvoiceSaved) {
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
                if (savedInvoiceNumber != null &&
                    savedInvoiceNumber.isNotEmpty) {
                  _onPrint(invoiceNumber: savedInvoiceNumber);
                }
              });
            } else {
              Utils.showOverlayMessage(
                context,
                message: "Failed to create invoice",
                isError: true,
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(tr.purchaseEntry),
            actions: [
              IconButton(icon: const Icon(Icons.print), onPressed: _onPrint),
              BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                builder: (context, state) {
                  if (state is PurchaseInvoiceLoaded ||
                      state is PurchaseInvoiceSaving) {
                    final current = state is PurchaseInvoiceSaving
                        ? state
                        : (state as PurchaseInvoiceLoaded);
                    final isSaving = state is PurchaseInvoiceSaving;

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
                // Supplier and Account Selection
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      GenericTextfield<
                        IndividualsModel,
                        IndividualsBloc,
                        IndividualsState
                      >(
                        key: const ValueKey('person_field'),
                        controller: _personController,
                        title: tr.supplier,
                        hintText: tr.supplier,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.supplier);
                          }
                          return null;
                        },
                        bloc: context.read<IndividualsBloc>(),
                        fetchAllFunction: (bloc) =>
                            bloc.add(LoadIndividualsEvent()),
                        searchFunction: (bloc, query) =>
                            bloc.add(LoadIndividualsEvent()),
                        itemBuilder: (context, ind) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "${ind.perName ?? ''} ${ind.perLastName ?? ''}",
                          ),
                        ),
                        itemToString: (individual) =>
                            "${individual.perName} ${individual.perLastName}",
                        stateToLoading: (state) =>
                            state is IndividualLoadingState,
                        stateToItems: (state) {
                          if (state is IndividualLoadedState) {
                            return state.individuals;
                          }
                          return [];
                        },
                        onSelected: (value) {
                          _personController.text =
                              "${value.perName} ${value.perLastName}";
                          context.read<PurchaseInvoiceBloc>().add(
                            SelectSupplierEvent(value),
                          );
                          context.read<AccountsBloc>().add(
                            LoadAccountsEvent(ownerId: value.perId),
                          );
                          setState(() {
                            signatory = value.perId;
                          });
                        },
                        showClearButton: true,
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                        builder: (context, state) {
                          if (state is PurchaseInvoiceLoaded) {
                            final current = state;
                            return GenericTextfield<
                              AccountsModel,
                              AccountsBloc,
                              AccountsState
                            >(
                              key: const ValueKey('account_field'),
                              controller: _accountController,
                              title: tr.accounts,
                              hintText: tr.selectAccount,
                              isRequired:
                                  current.paymentMode != PaymentMode.cash,
                              validator: (value) {
                                if (current.paymentMode != PaymentMode.cash &&
                                    (value == null || value.isEmpty)) {
                                  return tr.selectCreditAccountMsg;
                                }
                                return null;
                              },
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(
                                LoadAccountsEvent(ownerId: signatory),
                              ),
                              searchFunction: (bloc, query) => bloc.add(
                                LoadAccountsEvent(ownerId: signatory),
                              ),
                              itemBuilder: (context, account) => ListTile(
                                visualDensity: VisualDensity(
                                  vertical: -4,
                                  horizontal: -4,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                title: Text(account.accName ?? ''),
                                subtitle: Text('${account.accNumber}'),
                                trailing: Text(
                                  "${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}",
                                ),
                              ),
                              itemToString: (account) =>
                                  '${account.accName} (${account.accNumber})',
                              stateToLoading: (state) =>
                                  state is AccountLoadingState,
                              stateToItems: (state) {
                                if (state is AccountLoadedState) {
                                  return state.accounts;
                                }
                                return [];
                              },
                              onSelected: (value) {
                                _accountController.text =
                                    '${value.accName} (${value.accNumber})';
                                context.read<PurchaseInvoiceBloc>().add(
                                  SelectSupplierAccountEvent(value),
                                );
                              },
                              showClearButton: true,
                            );
                          }
                          return GenericTextfield<
                            AccountsModel,
                            AccountsBloc,
                            AccountsState
                          >(
                            key: const ValueKey('account_field'),
                            controller: _accountController,
                            title: tr.accounts,
                            hintText: tr.selectAccount,
                            isRequired: false,
                            bloc: context.read<AccountsBloc>(),
                            fetchAllFunction: (bloc) => bloc.add(
                              LoadAccountsFilterEvent(
                                include: '8',
                                exclude: '',
                              ),
                            ),
                            searchFunction: (bloc, query) => bloc.add(
                              LoadAccountsFilterEvent(
                                input: query,
                                include: '8',
                                exclude: '',
                              ),
                            ),
                            itemBuilder: (context, account) => ListTile(
                              title: Text(account.accName ?? ''),
                              subtitle: Text(
                                '${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}',
                              ),
                              trailing: Text(account.actCurrency ?? ""),
                            ),
                            itemToString: (account) =>
                                '${account.accName} (${account.accNumber})',
                            stateToLoading: (state) =>
                                state is AccountLoadingState,
                            stateToItems: (state) {
                              if (state is AccountLoadedState) {
                                return state.accounts;
                              }
                              return [];
                            },
                            onSelected: (value) {
                              _accountController.text =
                                  '${value.accName} (${value.accNumber})';
                              context.read<PurchaseInvoiceBloc>().add(
                                SelectSupplierAccountEvent(value),
                              );
                            },
                            showClearButton: true,
                          );
                        },
                      ),
                      // const SizedBox(height: 8),
                      // ZTextFieldEntitled(
                      //   hint: tr.optional,
                      //   controller: _xRefController,
                      //   title: tr.invoiceNumber,
                      // ),
                    ],
                  ),
                ),

                // Items List
                Expanded(
                  child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                    builder: (context, state) {
                      if (state is PurchaseInvoiceLoaded ||
                          state is PurchaseInvoiceSaving) {
                        final current = state is PurchaseInvoiceSaving
                            ? state
                            : (state as PurchaseInvoiceLoaded);

                        if (current.items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tr.noItems,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<PurchaseInvoiceBloc>().add(
                                      AddNewPurchaseItemEvent(),
                                    );
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
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .08),
                    icon: Icons.add,
                    label: Text(AppLocalizations.of(context)!.addItem),
                    onPressed: () {
                      context.read<PurchaseInvoiceBloc>().add(
                        AddNewPurchaseItemEvent(),
                      );
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

  Widget _buildMobileItemCard(PurchaseInvoiceItem item, BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final productController = TextEditingController(text: item.productName);
    final qtyController = _qtyControllers.putIfAbsent(
      item.rowId,
      () =>
          TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
    );

    final priceController = _priceControllers.putIfAbsent(
      item.rowId,
      () => TextEditingController(
        text: item.purPrice != null && item.purPrice! > 0
            ? item.purPrice!.toAmount()
            : '',
      ),
    );

    final storageController = TextEditingController(text: item.storageName);

    return ZCover(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr.items} #${item.rowId}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    _priceControllers.remove(item.rowId);
                    _qtyControllers.remove(item.rowId);
                    context.read<PurchaseInvoiceBloc>().add(
                      RemovePurchaseItemEvent(item.rowId),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Product Selection
            GenericTextfield<ProductsModel, ProductsBloc, ProductsState>(
              title: tr.products,
              controller: productController,
              hintText: tr.products,
              isRequired: true,
              bloc: context.read<ProductsBloc>(),
              fetchAllFunction: (bloc) => bloc.add(LoadProductsEvent()),
              searchFunction: (bloc, query) => bloc.add(LoadProductsEvent()),
              itemBuilder: (context, product) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("${product.proCode} | ${product.proName}"),
              ),
              itemToString: (product) => product.proName ?? '',
              stateToLoading: (state) => state is ProductsLoadingState,
              stateToItems: (state) {
                if (state is ProductsLoadedState) return state.products;
                return [];
              },
              onSelected: (product) {
                context.read<PurchaseInvoiceBloc>().add(
                  UpdatePurchaseItemEvent(
                    rowId: item.rowId,
                    productId: product.proId.toString(),
                    productName: product.proName ?? '',
                  ),
                );
                _autoSelectFirstStorage(item.rowId);
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: tr.qty,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<PurchaseInvoiceBloc>().add(
                          UpdatePurchaseItemEvent(rowId: item.rowId, qty: 0),
                        );
                        return;
                      }
                      final qty = int.tryParse(value) ?? 0;
                      context.read<PurchaseInvoiceBloc>().add(
                        UpdatePurchaseItemEvent(rowId: item.rowId, qty: qty),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Unit Price
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      SmartThousandsDecimalFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: tr.unitPrice,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<PurchaseInvoiceBloc>().add(
                          UpdatePurchaseItemEvent(
                            rowId: item.rowId,
                            purPrice: 0,
                          ),
                        );
                        return;
                      }
                      final parsed = double.tryParse(value.replaceAll(',', ''));
                      if (parsed != null && parsed > 0) {
                        context.read<PurchaseInvoiceBloc>().add(
                          UpdatePurchaseItemEvent(
                            rowId: item.rowId,
                            purPrice: parsed,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Storage Selection
            BlocBuilder<StorageBloc, StorageState>(
              builder: (context, storageState) {
                if (storageState is StorageLoadedState &&
                    storageState.storage.isNotEmpty) {
                  if (item.storageId == 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final firstStorage = storageState.storage.first;
                      context.read<PurchaseInvoiceBloc>().add(
                        UpdatePurchaseItemEvent(
                          rowId: item.rowId,
                          storageId: firstStorage.stgId!,
                          storageName: firstStorage.stgName ?? '',
                        ),
                      );
                      storageController.text = firstStorage.stgName ?? '';
                    });
                  }
                }

                return GenericTextfield<
                  StorageModel,
                  StorageBloc,
                  StorageState
                >(
                  title: tr.storage,
                  controller: storageController,
                  hintText: tr.storage,
                  isRequired: true,
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
                    context.read<PurchaseInvoiceBloc>().add(
                      UpdatePurchaseItemEvent(
                        rowId: item.rowId,
                        storageId: storage.stgId!,
                        storageName: storage.stgName ?? '',
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.totalTitle,
                  style: TextStyle(fontSize: 14, color: color.outline),
                ),
                Text(
                  item.totalPurchase.toAmount(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.primary,
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

    return BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
      builder: (context, state) {
        if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
          final current = state is PurchaseInvoiceSaving
              ? state
              : (state as PurchaseInvoiceLoaded);

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
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
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

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.grandTotal),
                    Text(
                      "${current.subtotal.toAmount()} $baseCurrency",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Payment Breakdown
                if (current.paymentMode == PaymentMode.cash) ...[
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

                // Account Information
                if (current.supplierAccount != null &&
                    current.creditAmount > 0) ...[
                  const Divider(height: 16),
                  Text(
                    '${current.supplierAccount!.accNumber} | ${current.supplierAccount!.accName}',
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
                      Text(tr.invoiceAmount),
                      Text(
                        current.creditAmount.toAmount(),
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.newBalance),
                      Text(
                        (current.currentBalance + current.creditAmount)
                            .toAmount(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getBalanceColor(
                            current.currentBalance + current.creditAmount,
                          ),
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

  void _showPaymentModeDialog(PurchaseInvoiceLoaded current) {
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
                child: Icon(
                  Icons.money,
                  color: current.paymentMode == PaymentMode.cash
                      ? color.primary
                      : color.outline,
                ),
              ),
              title: Text(tr.cashPayment),
              subtitle: Text(tr.cashPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.cash
                  ? Icon(Icons.check, color: color.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _accountController.clear();
                context.read<PurchaseInvoiceBloc>().add(
                  ClearSupplierAccountEvent(),
                );
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.primary.withValues(alpha: .05),
                child: Icon(
                  Icons.credit_card,
                  color: current.paymentMode == PaymentMode.credit
                      ? color.primary
                      : color.outline,
                ),
              ),
              title: Text(tr.accountCredit),
              subtitle: Text(tr.accountCreditSubtitle),
              trailing: current.paymentMode == PaymentMode.credit
                  ? Icon(Icons.check, color: color.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                // context.read<PurchaseInvoiceBloc>().add(
                //   UpdatePurchasePaymentEvent(0),
                // );
                setState(() {});
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.primary.withValues(alpha: .05),
                child: Icon(
                  Icons.payments,
                  color: current.paymentMode == PaymentMode.mixed
                      ? color.primary
                      : color.outline,
                ),
              ),
              title: Text(tr.combinedPayment),
              subtitle: Text(tr.combinedPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.mixed
                  ? Icon(Icons.check, color: color.primary)
                  : null,
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

  void _showMixedPaymentDialog(
    BuildContext context,
    PurchaseInvoiceLoaded current,
  ) {
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
              "${tr.grandTotal}: ${current.subtotal.toAmount()}",
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
                Utils.showOverlayMessage(
                  context,
                  message: 'Account payment must be greater than 0',
                  isError: true,
                );
                return;
              }

              if (creditPayment >= current.subtotal) {
                Utils.showOverlayMessage(
                  context,
                  message:
                      'Account payment must be less than total amount for mixed payment',
                  isError: true,
                );
                return;
              }

              // context.read<PurchaseInvoiceBloc>().add(
              //   UpdatePurchasePaymentEvent(creditPayment, isCreditAmount: true),
              // );
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
      case PaymentMode.cash:
        return AppLocalizations.of(context)!.cash;
      case PaymentMode.credit:
        return AppLocalizations.of(context)!.creditTitle;
      case PaymentMode.mixed:
        return AppLocalizations.of(context)!.combinedPayment;
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

  void _autoSelectFirstStorage(String rowId) {
    final storageState = context.read<StorageBloc>().state;
    if (storageState is StorageLoadedState && storageState.storage.isNotEmpty) {
      final firstStorage = storageState.storage.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(
            rowId: rowId,
            storageId: firstStorage.stgId!,
            storageName: firstStorage.stgName ?? '',
          ),
        );
      });
    }
  }

  void _saveInvoice(BuildContext context, PurchaseInvoiceLoaded state) {
    if (!state.isFormValid) {
      Utils.showOverlayMessage(
        context,
        message: 'Please fill all required fields correctly',
        isError: true,
      );
      return;
    }

    final completer = Completer<String>();

    context.read<PurchaseInvoiceBloc>().add(
      SavePurchaseInvoiceEvent(
        usrName: _userName ?? '',
        orderName: "Purchase",

        ordPersonal: state.supplier!.perId!,
        xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,

        completer: completer,
      ),
    );
  }

  void _onPrint({String? invoiceNumber}) {
    final state = context.read<PurchaseInvoiceBloc>().state;

    PurchaseInvoiceLoaded? current;

    if (state is PurchaseInvoiceLoaded) {
      current = state;
    } else if (state is PurchaseInvoiceSaved && state.invoiceData != null) {
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(
        context,
        message: 'Cannot print: No invoice data available',
        isError: true,
      );
      return;
    }

    // Now current is not null, we can safely use it
    // Check if currency conversion is needed
    final needsConversion = current.supplierAccount?.actCurrency != null &&
        baseCurrency != null &&
        baseCurrency != current.supplierAccount!.actCurrency;

    // Get company info
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
      statementDate: DateTime.now().toFullDateTime,
    );

    // Get company logo
    final base64Logo = companyState.company.comLogo;
    if (base64Logo != null && base64Logo.isNotEmpty) {
      try {
        company.comLogo = base64Decode(base64Logo);
      } catch (e) {
        // Handle error silently
      }
    }

    // Prepare invoice items for print with local amount
    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return PurchaseInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        unitPrice: item.purPrice ?? 0.0,
        batch: item.stkBatch,
        unit: '',
        total: item.totalPurchase,
        storageName: item.storageName,
        localAmount: item.localAmount, // Single item local amount (unit price * exchange rate)
        localCurrency: current?.supplierAccount?.actCurrency ?? current?.toCurrency,
        exchangeRate: current?.exchangeRate, // Pass exchange rate
      );
    }).toList();

    // Calculate total local amount
    final totalLocalAmount = current.totalLocalAmount;

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
            invoiceType: "Purchase",
            invoiceNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: current?.supplier?.perName ?? "",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion ? (current.supplierAccount?.actCurrency ?? current.toCurrency) : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
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
            invoiceType: "Purchase",
            invoiceNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: current?.supplier?.perName ?? "",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company,
            selectedPrinter: selectedPrinter,
            pageFormat: pageFormat,
            copies: copies,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion ? (current.supplierAccount?.actCurrency ?? current.toCurrency) : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().createInvoiceDocument(
            invoiceType: "Purchase",
            invoiceNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: current?.supplier?.perName ?? "",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion ? (current.supplierAccount?.actCurrency ?? current.toCurrency) : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
          );
        },
      ),
    );
  }
}

// Tablet Version
class _TabletPurchaseOrderView extends StatefulWidget {
  const _TabletPurchaseOrderView();

  @override
  State<_TabletPurchaseOrderView> createState() =>
      _TabletPurchaseOrderViewState();
}
class _TabletPurchaseOrderViewState extends State<_TabletPurchaseOrderView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _userName;
  String? baseCurrency;
  int? signatory;
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseInvoiceBloc>().add(InitializePurchaseInvoiceEvent());
    });

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
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
    _userName = login.usrName ?? "";

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          _userName = state.loginData.usrName ?? '';
        }
      },
      child: BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
        listener: (context, state) {
          if (state is PurchaseInvoiceError) {
            Utils.showOverlayMessage(
              context,
              message: state.message,
              isError: true,
            );
          }
          if (state is PurchaseInvoiceSaved) {
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
                if (savedInvoiceNumber != null &&
                    savedInvoiceNumber.isNotEmpty) {
                  _onPrint(invoiceNumber: savedInvoiceNumber);
                }
              });
            } else {
              Utils.showOverlayMessage(
                context,
                message: "Failed to create invoice",
                isError: true,
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(tr.purchaseEntry),
            actions: [
              IconButton(icon: const Icon(Icons.print), onPressed: _onPrint),
              BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                builder: (context, state) {
                  if (state is PurchaseInvoiceLoaded ||
                      state is PurchaseInvoiceSaving) {
                    final current = state is PurchaseInvoiceSaving
                        ? state
                        : (state as PurchaseInvoiceLoaded);
                    final isSaving = state is PurchaseInvoiceSaving;

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
                  // Supplier and Account Selection - Row layout for tablet
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child:
                            GenericTextfield<
                              IndividualsModel,
                              IndividualsBloc,
                              IndividualsState
                            >(
                              key: const ValueKey('person_field'),
                              controller: _personController,
                              title: tr.supplier,
                              hintText: tr.supplier,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return tr.required(tr.supplier);
                                }
                                return null;
                              },
                              bloc: context.read<IndividualsBloc>(),
                              fetchAllFunction: (bloc) =>
                                  bloc.add(LoadIndividualsEvent()),
                              searchFunction: (bloc, query) =>
                                  bloc.add(LoadIndividualsEvent()),
                              itemBuilder: (context, ind) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "${ind.perName ?? ''} ${ind.perLastName ?? ''}",
                                ),
                              ),
                              itemToString: (individual) =>
                                  "${individual.perName} ${individual.perLastName}",
                              stateToLoading: (state) =>
                                  state is IndividualLoadingState,
                              stateToItems: (state) {
                                if (state is IndividualLoadedState) {
                                  return state.individuals;
                                }
                                return [];
                              },
                              onSelected: (value) {
                                _personController.text =
                                    "${value.perName} ${value.perLastName}";
                                context.read<PurchaseInvoiceBloc>().add(
                                  SelectSupplierEvent(value),
                                );
                                context.read<AccountsBloc>().add(
                                  LoadAccountsEvent(ownerId: value.perId),
                                );
                                setState(() {
                                  signatory = value.perId;
                                });
                              },
                              showClearButton: true,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                          builder: (context, state) {
                            if (state is PurchaseInvoiceLoaded) {
                              final current = state;
                              return GenericTextfield<
                                AccountsModel,
                                AccountsBloc,
                                AccountsState
                              >(
                                key: const ValueKey('account_field'),
                                controller: _accountController,
                                title: tr.accounts,
                                hintText: tr.selectAccount,
                                isRequired:
                                    current.paymentMode != PaymentMode.cash,
                                validator: (value) {
                                  if (current.paymentMode != PaymentMode.cash &&
                                      (value == null || value.isEmpty)) {
                                    return tr.selectCreditAccountMsg;
                                  }
                                  return null;
                                },
                                bloc: context.read<AccountsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(
                                  LoadAccountsEvent(ownerId: signatory),
                                ),
                                searchFunction: (bloc, query) => bloc.add(
                                  LoadAccountsEvent(ownerId: signatory),
                                ),
                                itemBuilder: (context, account) => ListTile(
                                  visualDensity: VisualDensity(
                                    vertical: -4,
                                    horizontal: -4,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  title: Text(account.accName ?? ''),
                                  subtitle: Text('${account.accNumber}'),
                                  trailing: Text(
                                    "${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}",
                                  ),
                                ),
                                itemToString: (account) =>
                                    '${account.accName} (${account.accNumber})',
                                stateToLoading: (state) =>
                                    state is AccountLoadingState,
                                stateToItems: (state) {
                                  if (state is AccountLoadedState) {
                                    return state.accounts;
                                  }
                                  return [];
                                },
                                onSelected: (value) {
                                  _accountController.text =
                                      '${value.accName} (${value.accNumber})';
                                  context.read<PurchaseInvoiceBloc>().add(
                                    SelectSupplierAccountEvent(value),
                                  );
                                },
                                showClearButton: true,
                              );
                            }
                            return GenericTextfield<
                              AccountsModel,
                              AccountsBloc,
                              AccountsState
                            >(
                              key: const ValueKey('account_field'),
                              controller: _accountController,
                              title: tr.accounts,
                              hintText: tr.selectAccount,
                              isRequired: false,
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(
                                LoadAccountsFilterEvent(
                                  include: '8',
                                  exclude: '',
                                ),
                              ),
                              searchFunction: (bloc, query) => bloc.add(
                                LoadAccountsFilterEvent(
                                  input: query,
                                  include: '8',
                                  exclude: '',
                                ),
                              ),
                              itemBuilder: (context, account) => ListTile(
                                title: Text(account.accName ?? ''),
                                subtitle: Text(
                                  '${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}',
                                ),
                                trailing: Text(account.actCurrency ?? ""),
                              ),
                              itemToString: (account) =>
                                  '${account.accName} (${account.accNumber})',
                              stateToLoading: (state) =>
                                  state is AccountLoadingState,
                              stateToItems: (state) {
                                if (state is AccountLoadedState) {
                                  return state.accounts;
                                }
                                return [];
                              },
                              onSelected: (value) {
                                _accountController.text =
                                    '${value.accName} (${value.accNumber})';
                                context.read<PurchaseInvoiceBloc>().add(
                                  SelectSupplierAccountEvent(value),
                                );
                              },
                              showClearButton: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ZTextFieldEntitled(
                    hint: tr.optional,
                    controller: _xRefController,
                    title: tr.invoiceNumber,
                  ),
                  const SizedBox(height: 16),

                  // Items Header
                  _buildItemsHeader(context),
                  const SizedBox(height: 8),

                  // Items List
                  Expanded(
                    child:
                        BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                          builder: (context, state) {
                            if (state is PurchaseInvoiceLoaded ||
                                state is PurchaseInvoiceSaving) {
                              final current = state is PurchaseInvoiceSaving
                                  ? state
                                  : (state as PurchaseInvoiceLoaded);
                              if (current.items.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 64,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        tr.noItems,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          context
                                              .read<PurchaseInvoiceBloc>()
                                              .add(AddNewPurchaseItemEvent());
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
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                  ),

                  // Summary Section
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildTabletSummarySection(context),
                  ),

                  // Add Item Button
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ZOutlineButton(
                      width: 200,
                      height: 45,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .08),
                      icon: Icons.add,
                      label: Text(AppLocalizations.of(context)!.addItem),
                      onPressed: () {
                        context.read<PurchaseInvoiceBloc>().add(
                          AddNewPurchaseItemEvent(),
                        );
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
    TextStyle? title = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: color.surface);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: title)),
          Expanded(flex: 3, child: Text(locale.products, style: title)),
          SizedBox(width: 80, child: Text(locale.qty, style: title)),
          SizedBox(width: 120, child: Text(locale.unitPrice, style: title)),
          SizedBox(width: 100, child: Text(locale.totalTitle, style: title)),
          SizedBox(width: 150, child: Text(locale.storage, style: title)),
          SizedBox(width: 60, child: Text(locale.actions, style: title)),
        ],
      ),
    );
  }

  Widget _buildTabletItemCard(PurchaseInvoiceItem item, BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final productController = TextEditingController(text: item.productName);
    final qtyController = _qtyControllers.putIfAbsent(
      item.rowId,
      () =>
          TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
    );

    final priceController = _priceControllers.putIfAbsent(
      item.rowId,
      () => TextEditingController(
        text: item.purPrice != null && item.purPrice! > 0
            ? item.purPrice!.toAmount()
            : '',
      ),
    );

    final storageController = TextEditingController(text: item.storageName);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Row layout
            Row(
              children: [
                // Row Number
                SizedBox(
                  width: 40,
                  child: Text(
                    item.rowId.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Product Selection
                Expanded(
                  flex: 3,
                  child:
                      GenericUnderlineTextfield<ProductsModel, ProductsBloc, ProductsState>(
                        title: "",
                        controller: productController,
                        hintText: tr.products,
                        bloc: context.read<ProductsBloc>(),
                        fetchAllFunction: (bloc) =>
                            bloc.add(LoadProductsEvent()),
                        searchFunction: (bloc, query) =>
                            bloc.add(LoadProductsEvent()),
                        itemBuilder: (context, product) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "${product.proCode} | ${product.proName}",
                          ),
                        ),
                        itemToString: (product) => product.proName ?? '',
                        stateToLoading: (state) =>
                            state is ProductsLoadingState,
                        stateToItems: (state) {
                          if (state is ProductsLoadedState) {
                            return state.products;
                          }
                          return [];
                        },
                        onSelected: (product) {
                          context.read<PurchaseInvoiceBloc>().add(
                            UpdatePurchaseItemEvent(
                              rowId: item.rowId,
                              productId: product.proId.toString(),
                              productName: product.proName ?? '',
                            ),
                          );
                          _autoSelectFirstStorage(item.rowId);
                        },
                      ),
                ),

                // Quantity
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<PurchaseInvoiceBloc>().add(
                          UpdatePurchaseItemEvent(rowId: item.rowId, qty: 0),
                        );
                        return;
                      }
                      final qty = int.tryParse(value) ?? 0;
                      context.read<PurchaseInvoiceBloc>().add(
                        UpdatePurchaseItemEvent(rowId: item.rowId, qty: qty),
                      );
                    },
                  ),
                ),

                // Unit Price
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: priceController,
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
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<PurchaseInvoiceBloc>().add(
                          UpdatePurchaseItemEvent(
                            rowId: item.rowId,
                            purPrice: 0,
                          ),
                        );
                        return;
                      }
                      final parsed = double.tryParse(value.replaceAll(',', ''));
                      if (parsed != null && parsed > 0) {
                        context.read<PurchaseInvoiceBloc>().add(
                          UpdatePurchaseItemEvent(
                            rowId: item.rowId,
                            purPrice: parsed,
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
                    item.totalPurchase.toAmount(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ),

                // Storage
                SizedBox(
                  width: 150,
                  child: BlocBuilder<StorageBloc, StorageState>(
                    builder: (context, storageState) {
                      if (storageState is StorageLoadedState &&
                          storageState.storage.isNotEmpty) {
                        if (item.storageId == 0) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final firstStorage = storageState.storage.first;
                            context.read<PurchaseInvoiceBloc>().add(
                              UpdatePurchaseItemEvent(
                                rowId: item.rowId,
                                storageId: firstStorage.stgId!,
                                storageName: firstStorage.stgName ?? '',
                              ),
                            );
                            storageController.text = firstStorage.stgName ?? '';
                          });
                        }
                      }

                      return GenericUnderlineTextfield<
                        StorageModel,
                        StorageBloc,
                        StorageState
                      >(
                        title: "",
                        controller: storageController,
                        hintText: tr.storage,
                        bloc: context.read<StorageBloc>(),
                        fetchAllFunction: (bloc) =>
                            bloc.add(LoadStorageEvent()),
                        searchFunction: (bloc, query) =>
                            bloc.add(LoadStorageEvent()),
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
                          context.read<PurchaseInvoiceBloc>().add(
                            UpdatePurchaseItemEvent(
                              rowId: item.rowId,
                              storageId: storage.stgId!,
                              storageName: storage.stgName ?? '',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Actions
                SizedBox(
                  width: 60,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () {
                      _priceControllers.remove(item.rowId);
                      _qtyControllers.remove(item.rowId);
                      context.read<PurchaseInvoiceBloc>().add(
                        RemovePurchaseItemEvent(item.rowId),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletSummarySection(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
      builder: (context, state) {
        if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
          final current = state is PurchaseInvoiceSaving
              ? state
              : (state as PurchaseInvoiceLoaded);

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
                    Text(
                      tr.paymentMethod,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => _showPaymentModeDialog(current),
                      child: Row(
                        children: [
                          Text(
                            _getPaymentModeLabel(current.paymentMode),
                            style: TextStyle(color: color.primary),
                          ),
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
                  value: current.subtotal,
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
                if (current.supplierAccount != null &&
                    current.creditAmount > 0) ...[
                  Divider(color: color.outline.withValues(alpha: .2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${current.supplierAccount!.accNumber} | ${current.supplierAccount!.accName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                    value: current.currentBalance + current.creditAmount,
                    isBold: true,
                    color: _getBalanceColor(
                      current.currentBalance + current.creditAmount,
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

  Widget _buildSummaryRow({
    required String label,
    required double value,
    bool isBold = false,
    Color? color,
  }) {
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

  void _showPaymentModeDialog(PurchaseInvoiceLoaded current) {
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
                child: Icon(
                  Icons.money,
                  color: current.paymentMode == PaymentMode.cash
                      ? color.primary
                      : color.outline,
                ),
              ),
              title: Text(tr.cashPayment),
              subtitle: Text(tr.cashPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.cash
                  ? Icon(Icons.check, color: color.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _accountController.clear();
                context.read<PurchaseInvoiceBloc>().add(
                  ClearSupplierAccountEvent(),
                );
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.primary.withValues(alpha: .05),
                child: Icon(
                  Icons.credit_card,
                  color: current.paymentMode == PaymentMode.credit
                      ? color.primary
                      : color.outline,
                ),
              ),
              title: Text(tr.accountCredit),
              subtitle: Text(tr.accountCreditSubtitle),
              trailing: current.paymentMode == PaymentMode.credit
                  ? Icon(Icons.check, color: color.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                // context.read<PurchaseInvoiceBloc>().add(
                //   UpdatePurchasePaymentEvent(0),
                // );
                setState(() {});
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: color.primary.withValues(alpha: .05),
                child: Icon(
                  Icons.payments,
                  color: current.paymentMode == PaymentMode.mixed
                      ? color.primary
                      : color.outline,
                ),
              ),
              title: Text(tr.combinedPayment),
              subtitle: Text(tr.combinedPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.mixed
                  ? Icon(Icons.check, color: color.primary)
                  : null,
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

  void _showMixedPaymentDialog(
    BuildContext context,
    PurchaseInvoiceLoaded current,
  ) {
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
              "${tr.grandTotal}: ${current.subtotal.toAmount()}",
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
                Utils.showOverlayMessage(
                  context,
                  message: 'Account payment must be greater than 0',
                  isError: true,
                );
                return;
              }

              if (creditPayment >= current.subtotal) {
                Utils.showOverlayMessage(
                  context,
                  message:
                      'Account payment must be less than total amount for mixed payment',
                  isError: true,
                );
                return;
              }

              // context.read<PurchaseInvoiceBloc>().add(
              //   UpdatePurchasePaymentEvent(creditPayment, isCreditAmount: true),
              // );
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
      case PaymentMode.cash:
        return AppLocalizations.of(context)!.cash;
      case PaymentMode.credit:
        return AppLocalizations.of(context)!.creditTitle;
      case PaymentMode.mixed:
        return AppLocalizations.of(context)!.combinedPayment;
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

  void _autoSelectFirstStorage(String rowId) {
    final storageState = context.read<StorageBloc>().state;
    if (storageState is StorageLoadedState && storageState.storage.isNotEmpty) {
      final firstStorage = storageState.storage.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(
            rowId: rowId,
            storageId: firstStorage.stgId!,
            storageName: firstStorage.stgName ?? '',
          ),
        );
      });
    }
  }

  void _saveInvoice(BuildContext context, PurchaseInvoiceLoaded state) {
    if (!state.isFormValid) {
      Utils.showOverlayMessage(
        context,
        message: 'Please fill all required fields correctly',
        isError: true,
      );
      return;
    }

    final completer = Completer<String>();

    context.read<PurchaseInvoiceBloc>().add(
      SavePurchaseInvoiceEvent(
        usrName: _userName ?? '',
        orderName: "Purchase",
        ordPersonal: state.supplier!.perId!,
        xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
        completer: completer,
      ),
    );
  }

  void _onPrint({String? invoiceNumber}) {
    final state = context.read<PurchaseInvoiceBloc>().state;

    PurchaseInvoiceLoaded? current;

    if (state is PurchaseInvoiceLoaded) {
      current = state;
    } else if (state is PurchaseInvoiceSaved && state.invoiceData != null) {
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(
        context,
        message: 'Cannot print: No invoice data available',
        isError: true,
      );
      return;
    }

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
      statementDate: DateTime.now().toFullDateTime,
    );

    final base64Logo = companyState.company.comLogo;
    if (base64Logo != null && base64Logo.isNotEmpty) {
      try {
        company.comLogo = base64Decode(base64Logo);
      } catch (e) {
        // Handle error silently
      }
    }

    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return PurchaseInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        batch: item.stkBatch,
        unit: '',
        unitPrice: item.purPrice ?? 0.0,
        total: item.totalPurchase,
        storageName: item.storageName,
      );
    }).toList();

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<dynamic>(
        data: null,
        company: company,
        buildPreview:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return InvoicePrintService().printInvoicePreview(
                invoiceType: "Purchase",
                invoiceNumber: invoiceNumber ?? "",
                reference: _xRefController.text,
                invoiceDate: DateTime.now(),
                customerSupplierName: current!.supplier?.perName ?? "",
                items: invoiceItems,
                grandTotal: current.subtotal,
                cashPayment: current.cashPayment,
                creditAmount: current.creditAmount,
                account: current.supplierAccount,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
                currency: baseCurrency,
                isSale: false,
              );
            },
        onPrint:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return InvoicePrintService().printInvoiceDocument(
                invoiceType: "Purchase",
                invoiceNumber: invoiceNumber ?? "",
                reference: _xRefController.text,
                invoiceDate: DateTime.now(),
                customerSupplierName: current!.supplier?.perName ?? "",
                items: invoiceItems,
                grandTotal: current.subtotal,
                cashPayment: current.cashPayment,
                creditAmount: current.creditAmount,
                account: current.supplierAccount,
                language: language,
                orientation: orientation,
                company: company,
                selectedPrinter: selectedPrinter,
                pageFormat: pageFormat,
                copies: copies,
                currency: baseCurrency,
                isSale: false,
              );
            },
        onSave:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return InvoicePrintService().createInvoiceDocument(
                invoiceType: "Purchase",
                invoiceNumber: invoiceNumber ?? "",
                reference: _xRefController.text,
                invoiceDate: DateTime.now(),
                customerSupplierName: current!.supplier?.perName ?? "",
                items: invoiceItems,
                grandTotal: current.subtotal,
                cashPayment: current.cashPayment,
                creditAmount: current.creditAmount,
                account: current.supplierAccount,
                language: language,
                orientation: orientation,
                company: company,
                pageFormat: pageFormat,
                currency: baseCurrency,
                isSale: false,
              );
            },
      ),
    );
  }
}


