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
import '../../../../Settings/features/Visibility/bloc/settings_visible_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../../Orders/bloc/orders_bloc.dart';
import '../Print/print.dart';
import 'bloc/purchase_invoice_bloc.dart';
import 'expense_section.dart';
import 'model/purchase_invoice_items.dart';

class NewPurchaseOrderView extends StatelessWidget {
  final int? orderId;
  final String? ref;
  const NewPurchaseOrderView({super.key,this.orderId,this.ref});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _MobilePurchaseOrderView(),
      desktop:  _DesktopPurchaseOrderView(orderId,ref),
      tablet: const _TabletPurchaseOrderView(),
    );
  }
}

// Desktop Version (Original)
class _DesktopPurchaseOrderView extends StatefulWidget {
  final int? orderId;
  final String? ref;
  const _DesktopPurchaseOrderView(this.orderId,this.ref);

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
  void _confirmDeleteOrder() {
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.areYouSure),
        content: Text('Confirm Delete Order #${widget.orderId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<OrdersBloc>().add(
                DeleteOrderEvent(
                  orderId: widget.orderId!,
                  usrName: _userName??"",
                  ref: widget.ref,
                  orderName: 'Purchase',
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
  }
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
      builder: (context) => StatefulBuilder(
        builder: (context,setState) {
          return PurchasePaymentDialog(state: state);
        }
      ),
    );
  }

  String? _userName;
  String? baseCurrency = "";
  int? signatory;

  void _updateControllersFromState(PurchaseInvoiceState state) {
    if (state is PurchaseInvoiceLoaded) {
      // Update exchange rate controller if needed
      if (state.exchangeRate != null && state.exchangeRate! > 0) {
        if (_exchangeRateController.text !=
            state.exchangeRate!.toStringAsFixed(4)) {
          _exchangeRateController.text = state.exchangeRate!.toStringAsFixed(4);
        }
      }

      // Update local amount controllers for each item
      for (var i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        if (item.localAmount != null && item.localAmount! > 0) {
          final controller = _localeAmountControllers[item.rowId];
          if (controller != null &&
              controller.text != item.localAmount!.toAmount()) {
            controller.text = item.localAmount!.toAmount();
          }
        }
      }
    }
  }

  bool _needsLocalConversion(BuildContext context) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded && state.supplierAccount != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        final baseCurrency = authState.loginData.company?.comLocalCcy ?? '';
        final accountCurrency = state.supplierAccount!.actCurrency ?? '';
        return baseCurrency.isNotEmpty &&
            accountCurrency.isNotEmpty &&
            baseCurrency != accountCurrency;
      }
    }
    return false;
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

    _debounce = Timer(const Duration(milliseconds: 2000), () {
      final rate = double.tryParse(value.replaceAll(',', ''));

      if (rate != null && rate > 0) {
        final state = context.read<PurchaseInvoiceBloc>().state;

        if (state is PurchaseInvoiceLoaded && state.supplierAccount != null) {
          if (state.exchangeRate != rate) {
            context.read<PurchaseInvoiceBloc>().add(
              UpdateExchangeRateManuallyEvent(
                rate: rate,
                fromCurrency: state.fromCurrency ?? baseCurrency ?? '',
                toCurrency:
                    state.toCurrency ??
                    state.supplierAccount!.actCurrency ??
                    '',
              ),
            );
          }
        }
      }
    });
  }
  bool _isEditMode = false;
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
      if (widget.orderId != null) {
        _isEditMode = true;
        purchaseBloc.add(LoadPurchaseInvoiceForEditEvent(
          orderId: widget.orderId!,
          baseCurrency: baseCurrency ?? '',
        ));
      } else {
        purchaseBloc.add(InitializePurchaseInvoiceEvent());
      }
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
          if (state is PurchaseInvoiceLoaded && _isEditMode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Set supplier name
              if (state.supplier != null) {
                _personController.text = state.supplier!.perName ?? '';
                signatory = state.supplier!.perId;
              }

              // Set account
              if (state.supplierAccount != null) {
                _accountController.text = '${state.supplierAccount!.accNumber}';
              }

              // Set reference and remark
              _xRefController.text = state.xRef ?? '';
              _remark.text = state.remark ?? '';

              // Set exchange rate
              if (state.exchangeRate != null && state.exchangeRate! > 0) {
                _exchangeRateController.text = state.exchangeRate!.toStringAsFixed(4);
              }

              _isEditMode = false;
            });
          }
          if (state is PurchaseInvoiceInitial ||
              state is PurchaseInvoiceLoaded) {
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
              if(widget.orderId !=null && widget.orderId!> 0)
                ZOutlineButton(
                  icon: Icons.delete_outline_rounded,
                  backgroundHover: Theme.of(context).colorScheme.error,
                  onPressed: _confirmDeleteOrder,
                  label: Text(tr.delete),
                ),

              if(widget.orderId ==null)...[
                const SizedBox(width: 8),
                ZOutlineButton(
                  icon: Icons.lock_reset_outlined,
                  onPressed: _resetForm,
                  label: Text(tr.newPurchase),
                ),
              ],

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
                  if (state is PurchaseInvoiceLoaded ||
                      state is PurchaseInvoiceSaving) {
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
            borderColor: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: .3),
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
                          child:
                              GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
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
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                            builder: (context, state) {
                              if (state is PurchaseInvoiceLoaded) {
                                final current = state;
                                return GenericTextField<
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
                                    if (current.paymentMode !=
                                            PaymentMode.cash &&
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
                                    visualDensity: const VisualDensity(
                                      vertical: -4,
                                      horizontal: -4,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
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
                                    setState(() {
                                      accountCcy = value.actCurrency;
                                    });
                                    context.read<PurchaseInvoiceBloc>().add(
                                      SelectSupplierAccountEvent(value),
                                    );

                                    final companyState = context
                                        .read<CompanyProfileBloc>()
                                        .state;
                                    if (companyState
                                        is CompanyProfileLoadedState) {
                                      final baseCurr =
                                          companyState.company.comLocalCcy ??
                                          '';
                                      final accountCurrency =
                                          value.actCurrency ?? '';

                                      if (baseCurr.isNotEmpty &&
                                          accountCurrency.isNotEmpty &&
                                          baseCurr != accountCurrency) {
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
                              return GenericTextField<
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
                                  setState(() {
                                    accountCcy = value.actCurrency;
                                  });
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
                            child:
                                BlocBuilder<
                                  PurchaseInvoiceBloc,
                                  PurchaseInvoiceState
                                >(
                                  builder: (context, state) {
                                    if (state is PurchaseInvoiceLoaded) {
                                      final isLoading =
                                          state.exchangeRate == null;
                                      return ZTextFieldEntitled(
                                        showClearButton: true,
                                        controller: _exchangeRateController,
                                        title: tr.exchangeRate,
                                        hint: isLoading
                                            ? "Loading rate..."
                                            : "Enter rate",
                                        inputFormat: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d{0,6}'),
                                          ),
                                        ],
                                        onChanged: _onExchangeRateChanged,
                                        onSubmit: _onExchangeRateChanged,
                                        end: isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
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
                      child:
                          BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                            builder: (context, state) {
                              if (state is PurchaseInvoiceLoaded ||
                                  state is PurchaseInvoiceSaving) {
                                final current = state is PurchaseInvoiceSaving
                                    ? state
                                    : (state as PurchaseInvoiceLoaded);
                                _synchronizeFocusNodes(current.items.length);
                                return SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: current.items.length,
                                        itemBuilder: (context, index) {
                                          final item = current.items[index];
                                          final isLastRow =
                                              index == current.items.length - 1;
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
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                    ),

                    _buildSummarySection(context),
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
    final visibility = context.read<SettingsVisibleBloc>().state;
    final color = Theme.of(context).colorScheme;
    TextStyle? title = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: color.surface);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children:
            [
                  const SizedBox(
                    width: 40,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('#'),
                    ),
                  ),
                  Expanded(child: Text(locale.products, style: title)),
                  SizedBox(width: 100, child: Text(locale.qty)),
                  if(visibility.isWholeSale)...[
                    SizedBox(width: 100, child: Text(locale.batchTitle)),
                    SizedBox(width: 100, child: Text(locale.totalQty)),
                  ],
                  SizedBox(
                    width: 150,
                    child: Text("${locale.unitPrice} ($baseCurrency)"),
                  ),
                  if (_needsLocalConversion(context))
                    SizedBox(
                      width: 150,
                      child: Text(
                        "${locale.unitPrice} (${accountCcy ?? baseCurrency})",
                      ),
                    ),
                  SizedBox(width: 150, child: Text("${locale.salePrice} %")),
                  SizedBox(
                    width: 150,
                    child: Text("${locale.landedPrice} ($baseCurrency)"),
                  ),
                  SizedBox(width: 180, child: Text(locale.warehouse)),
                  SizedBox(width: 60, child: Text(locale.actions)),
                ]
                .map((child) => DefaultTextStyle(style: title!, child: child))
                .toList(),
      ),
    );
  }

  void _setupRowFocus(int rowIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rowIndex < _rowFocusNodes.length && _rowFocusNodes[rowIndex].isNotEmpty) {
        _rowFocusNodes[rowIndex][0].requestFocus(); // Always focus product field
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
        final effectiveBatch = batch <= 0 ? 1 : batch;
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, batch: effectiveBatch),
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
          final current = state is PurchaseInvoiceSaving
              ? state
              : (state as PurchaseInvoiceLoaded);
          final totalExpenses = current.totalExpenses;
          final needsAccountConversion = current.needsExchangeRate;
          final needsCashConversion = current.needsCashConversion;
          final bool isLoading = current.isExchangeRateLoading;
          final baseCurrency = current.fromCurrency ?? '';
          final bool needsConversion = current.needsExchangeRate;

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
                                Text(
                                  tr.invoiceSummary.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                        const SizedBox(height: 4),
                        Divider(color: color.outline.withValues(alpha: .2)),
                        const SizedBox(height: 4),

                        _buildSummaryRow(
                          label: tr.subtotal,
                          value: current.subtotal,
                          currency: baseCurrency,
                        ),

                        if (totalExpenses > 0) ...[
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            label: tr.totalExpense,
                            value: totalExpenses,
                            color: Colors.red,
                            currency: baseCurrency,
                          ),
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

                        if (needsConversion && !isLoading) ...[
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
                  VerticalDivider(
                    width: 20,
                    thickness: 1,
                    color: color.outline.withValues(alpha: .2),
                  ),
                  SizedBox(width: 12),

                  //Cash Payment
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Icon(Icons.money),
                                Text(
                                  tr.payment.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _showPaymentDialog(current),
                              child: Row(
                                children: [
                                  Text(
                                    _getPaymentModeLabel(current.paymentMode,
                                    ).toUpperCase(),
                                    style: TextStyle(
                                      color: color.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.more_vert_rounded,
                                    size: 20,
                                    color: color.primary,
                                  ),
                                ],
                              ),
                            ),
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
                            convertedAmount:
                                (needsCashConversion &&
                                    current.cashCurrency != null &&
                                    current.cashCurrency != baseCurrency)
                                ? current.cashPaymentInCashCurrency
                                : null,
                            convertedCurrency: current.cashCurrency ?? "",
                          ),
                        ] else if (current.paymentMode ==
                            PaymentMode.credit) ...[
                          AmountDisplay(
                            title: tr.creditPayment,
                            baseAmount: current.creditAmount,
                            baseCurrency: baseCurrency,
                            convertedAmount:
                                (current.supplierAccount != null &&
                                    needsAccountConversion)
                                ? current.creditAmountLocal
                                : null,
                            convertedCurrency: current.toCurrency ?? "",
                            fontSize: 15,
                          ),
                        ] else if (current.paymentMode ==
                            PaymentMode.mixed) ...[
                          AmountDisplay(
                            title: tr.cashPayment,
                            baseAmount: current.cashPayment,
                            baseCurrency: baseCurrency,
                            convertedAmount:
                                (needsCashConversion &&
                                    current.cashCurrency != null &&
                                    current.cashCurrency != baseCurrency)
                                ? current.cashPaymentInCashCurrency
                                : null,
                            convertedCurrency: current.cashCurrency ?? "",
                          ),

                          AmountDisplay(
                            title: tr.creditPayment,
                            baseAmount: current.creditAmount,
                            baseCurrency: baseCurrency,
                            convertedAmount:
                                (current.supplierAccount != null &&
                                    needsAccountConversion)
                                ? current.creditAmountLocal
                                : null,
                            convertedCurrency: current.toCurrency ?? "",
                            fontSize: 15,
                          ),
                        ],
                      ],
                    ),
                  ),


                  if(current.supplierAccount !=null)...[
                    SizedBox(width: 12),
                    VerticalDivider(
                      width: 20,
                      thickness: 1,
                      color: color.outline.withValues(alpha: .2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Icon(FontAwesomeIcons.buildingColumns, size: 19),
                              Text(
                                tr.accountInformation.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
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
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    current.supplierAccount!.actCurrency ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildSummaryRow(
                              label: tr.currentBalance,
                              value: current.currentBalance,
                              color: _getBalanceColor(current.currentBalance),
                              currency: current.supplierAccount!.actCurrency,
                            ),
                            if (current.supplierAccountPayment > 0) ...[
                              const SizedBox(height: 4),
                              _buildSummaryRow(
                                label: tr.invoiceAmount,
                                value: current.supplierAccountPayment * (current.exchangeRate ?? 1.0),
                                color: Colors.orange,
                                currency: current.supplierAccount!.actCurrency,
                              ),
                              const SizedBox(height: 4),
                              _buildSummaryRow(
                                label:
                                "${tr.newBalance} | ${_getBalanceStatus(current.newBalance)}",
                                value: current.newBalance,
                                isBold: true,
                                color: _getBalanceColor(current.newBalance),
                                currency: current.supplierAccount!.actCurrency,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
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
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
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
    final visibility = context.read<SettingsVisibleBloc>().state;
    final isWholeSale = visibility.isWholeSale;

    while (_rowFocusNodes.length < itemCount) {
      if (isWholeSale) {
        // All 6 fields visible
        _rowFocusNodes.add([
          FocusNode(), // Product
          FocusNode(), // Qty
          FocusNode(), // Batch
          FocusNode(), // Unit Price
          FocusNode(), // Sell Price
          FocusNode(), // Storage
        ]);
      } else {
        // Batch and Total Qty hidden (only 4 fields)
        _rowFocusNodes.add([
          FocusNode(), // Product
          FocusNode(), // Qty
          FocusNode(), // Unit Price (index 2 instead of 3)
          FocusNode(), // Sell Price (index 3 instead of 4)
          FocusNode(), // Storage (index 4 instead of 5)
        ]);
      }
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

    // Determine the invoice number to use
    final String finalInvoiceNumber;
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      // Case 1: After saving, use the returned invoice number
      finalInvoiceNumber = invoiceNumber;
    } else if (widget.orderId != null && widget.orderId! > 0) {
      // Case 2: When loading an existing invoice, use the widget.orderId
      finalInvoiceNumber = widget.orderId.toString();
    } else {
      // Case 3: New invoice - leave empty, API will generate
      finalInvoiceNumber = '';
    }

    final needsConversion = current.supplierAccount?.actCurrency != null &&
        baseCurrency != null &&
        baseCurrency != current.supplierAccount!.actCurrency;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      Utils.showOverlayMessage(
        context,
        message: 'Company information not available',
        isError: true,
      );
      return;
    }

    final company = ReportModel(
      comName: authState.loginData.company?.comName ?? "",
      comAddress: authState.loginData.company?.comAddress ?? "",
      compPhone: authState.loginData.company?.comPhone ?? "",
      comEmail: authState.loginData.company?.comEmail ?? "",
      slogan: authState.loginData.company?.comDetails ?? "",
      invoiceNumber: widget.orderId,
      statementDate: DateTime.now().toFullDateTime,
    );

    final base64Logo = authState.loginData.company?.comLogo;
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
            invoiceNumber: finalInvoiceNumber,  // USE finalInvoiceNumber HERE
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
            localCurrency: needsConversion
                ? (current.supplierAccount?.actCurrency ?? current.toCurrency)
                : null,
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
            invoiceNumber: finalInvoiceNumber,  // USE finalInvoiceNumber HERE
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
            localCurrency: needsConversion
                ? (current.supplierAccount?.actCurrency ?? current.toCurrency)
                : null,
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
            invoiceNumber: finalInvoiceNumber,  // USE finalInvoiceNumber HERE
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
            localCurrency: needsConversion
                ? (current.supplierAccount?.actCurrency ?? current.toCurrency)
                : null,
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
    _localAmountController = TextEditingController(text: _getLocalAmountText());
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

  bool _needsLocalConversion(BuildContext context) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded && state.supplierAccount != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        final baseCurrency = authState.loginData.company?.comLocalCcy ?? '';
        final accountCurrency = state.supplierAccount!.actCurrency ?? '';
        return baseCurrency.isNotEmpty &&
            accountCurrency.isNotEmpty &&
            baseCurrency != accountCurrency;
      }
    }
    return false;
  }

  void _updateLocalAmount() {
    final currentExchangeRate = _getCurrentExchangeRate();
    final currentPurPrice = widget.item.purPrice;

    // Check if exchange rate or purchase price changed
    if (_lastExchangeRate != currentExchangeRate ||
        _lastPurPrice != currentPurPrice) {
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
    if (widget.item.purPrice != null &&
        exchangeRate != null &&
        exchangeRate > 0) {
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

    // FIX: Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateLocalAmount();
      }
    });
  }

  @override
  void dispose() {
    _landedPriceController.dispose();
    _storageController.dispose();
    _localAmountController.dispose();
    super.dispose();
  }

  void focusNext(int currentIndex) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    final isWholeSale = visibility.isWholeSale;

    // Calculate next index based on visibility
    int nextIndex;
    if (isWholeSale) {
      // Normal flow: 0->1->2->3->4->5
      nextIndex = currentIndex + 1;
    } else {
      // Without batch: Skip index 2 (batch)
      if (currentIndex == 1) {
        // After Qty (index 1), go to Unit Price which is index 2 (was index 3 in full mode)
        nextIndex = 2;
      } else if (currentIndex == 2) {
        // After Unit Price (index 2), go to Sell Price (index 3)
        nextIndex = 3;
      } else if (currentIndex == 3) {
        // After Sell Price (index 3), go to Storage (index 4)
        nextIndex = 4;
      } else {
        nextIndex = currentIndex + 1;
      }
    }

    if (nextIndex < widget.nodes.length) {
      final nextNode = widget.nodes[nextIndex];
      Future.delayed(const Duration(milliseconds: 50), () {
        if (nextNode.canRequestFocus) {
          nextNode.requestFocus();
        }
      });
    }
  }

  FocusNode? safeNode(int index) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    final isWholeSale = visibility.isWholeSale;

    if (!isWholeSale) {
      // Remap indices when batch is hidden
      if (index == 2) {
        // Index 2 in UI (Unit Price) maps to nodes[2] in non-wholesale
        return widget.nodes.length > 2 ? widget.nodes[2] : null;
      } else if (index == 3) {
        // Index 3 in UI (Sell Price) maps to nodes[3] in non-wholesale
        return widget.nodes.length > 3 ? widget.nodes[3] : null;
      } else if (index == 4) {
        // Index 4 in UI (Storage) maps to nodes[4] in non-wholesale
        return widget.nodes.length > 4 ? widget.nodes[4] : null;
      }
    }

    // Default mapping
    return (index >= 0 && index < widget.nodes.length)
        ? widget.nodes[index]
        : null;
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
    final visibility = context.read<SettingsVisibleBloc>().state;
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
        text: widget.item.stkBatch > 0
            ? widget.item.stkBatch.toString()
            : '1', // Default to 1
      ),
    );
    final sellPriceController = widget.sellPriceControllers.putIfAbsent(
      widget.item.rowId,
      () => TextEditingController(
        text: widget.item.sellPriceAmount > 0
            ? widget.item.sellPriceAmount.toString()
            : '',
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
                  headerSearchController:
                      headerProductController, // Optional: for header sync
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
                  openOverlayOnFocus:
                      true, // Opens overlay when field gets focus
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
                  onSubmitted: (_) {
                    final visibility = context.read<SettingsVisibleBloc>().state;
                    if (visibility.isWholeSale) {
                      focusNext(2); // Move to Batch
                    } else {
                      focusNext(1); // Move to Unit Price (skipping batch)
                    }
                  },
                ),
              ),

              if(visibility.isWholeSale)...[
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
                      final effectiveBatch = batch <= 0 ? 1 : batch;
                      if (effectiveBatch != batch) {
                        batchController.text = effectiveBatch.toString();
                      }
                      widget.onBatchChanged(widget.item.rowId, effectiveBatch);
                    },
                    onSubmitted: (_) => focusNext(2), // Move to Unit Price
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
              ],

              /// Unit Price - Index 3 (or Index 2 in non-wholesale)
              SizedBox(
                width: 150,
                child: TextField(
                  controller: priceController,
                  focusNode: safeNode(visibility.isWholeSale ? 3 : 2),
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
                      _addNewRowAndFocus();
                    } else {
                      // Move to next appropriate field
                      final visibility = context.read<SettingsVisibleBloc>().state;
                      if (visibility.isWholeSale) {
                        focusNext(3); // Move to Sell Price (index 4 in full mode)
                      } else {
                        focusNext(2); // Move to Sell Price (index 3 in non-wholesale)
                      }
                    }
                  },
                ),
              ),

              /// Local Amount (read-only)
              if (_needsLocalConversion(context))
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


              /// Sell Price - Index 4 (or Index 3 in non-wholesale)
              SizedBox(
                width: 150,
                child: TextField(
                  controller: sellPriceController,
                  focusNode: safeNode(visibility.isWholeSale ? 4 : 3),
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
                  onSubmitted: (_) => focusNext(visibility.isWholeSale ? 4 : 3), // Move to Storage
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

                    return GenericUnderlineTextfield<
                      StorageModel,
                      StorageBloc,
                      StorageState
                    >(
                      title: "",
                      focusNode: storageFocus,
                      controller: _storageController,
                      hintText: locale.storage,
                      bloc: context.read<StorageBloc>(),
                      fetchAllFunction: (bloc) => bloc.add(LoadStorageEvent()),
                      searchFunction: (bloc, query) =>
                          bloc.add(LoadStorageEvent()),
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

  // Track current state to rebuild when bloc updates
  PurchaseInvoiceLoaded _currentState = PurchaseInvoiceLoaded(
    items: [],
    payments: [],
    cashPayment: 0.0,
    paymentMode: PaymentMode.cash,
  );

  late StreamSubscription _blocSubscription;

  // Track current cash amount in selected currency
  double _currentCashAmountInSelectedCurrency = 0.0;

  @override
  void initState() {
    super.initState();

    _currentState = widget.state;

    // Get base currency from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _baseCurrency = authState.loginData.company?.comLocalCcy ?? 'USD';
    }

    if (_baseCurrency.isEmpty) {
      _baseCurrency = _currentState.fromCurrency ?? 'USD';
    }

    // Load existing cash currency from state
    _selectedCashCurrency = (_currentState.cashCurrency != null && _currentState.cashCurrency!.isNotEmpty)
        ? _currentState.cashCurrency!
        : _baseCurrency;

    _cashExchangeRate = _currentState.cashExchangeRate > 0
        ? _currentState.cashExchangeRate
        : 1.0;

    // Initialize current cash amount
    _currentCashAmountInSelectedCurrency = _currentState.cashPayment * _cashExchangeRate;

    _cashPaymentController = TextEditingController(
      text: _currentCashAmountInSelectedCurrency > 0
          ? _currentCashAmountInSelectedCurrency.toStringAsFixed(2)
          : '',
    );

    _exchangeRateController = TextEditingController(
      text: _currentState.exchangeRate != null && _currentState.exchangeRate! > 0
          ? _currentState.exchangeRate!.toStringAsFixed(4)
          : '',
    );

    _cashExchangeRateController = TextEditingController(
      text: _cashExchangeRate.toStringAsFixed(4),
    );

    // LISTEN to bloc state changes to update dialog when exchange rate changes
    _blocSubscription = context.read<PurchaseInvoiceBloc>().stream.listen((state) {
      if (state is PurchaseInvoiceLoaded && mounted) {
        setState(() {
          _currentState = state;

          // Update exchange rate controller if changed
          final newRate = _currentState.exchangeRate != null && _currentState.exchangeRate! > 0
              ? _currentState.exchangeRate!.toStringAsFixed(4)
              : '';
          if (_exchangeRateController.text != newRate) {
            _exchangeRateController.text = newRate;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _blocSubscription.cancel();
    _cashPaymentController.dispose();
    _exchangeRateController.dispose();
    _cashExchangeRateController.dispose();
    super.dispose();
  }

  void _updateCashPayment(double amountInSelectedCurrency) {
    setState(() {
      _currentCashAmountInSelectedCurrency = amountInSelectedCurrency;
    });

    final amountInBaseCurrency = amountInSelectedCurrency / _cashExchangeRate;
    context.read<PurchaseInvoiceBloc>().add(
      UpdateCashPaymentEvent(amountInBaseCurrency),
    );
  }

  void _updateCashCurrencyAndRate(String currency, double rate) {
    setState(() {
      _selectedCashCurrency = currency;
      _cashExchangeRate = rate;
      _cashExchangeRateController.text = rate.toStringAsFixed(4);

      // Update displayed amount with new rate
      final currentAmountInBase = _currentState.cashPayment;
      _currentCashAmountInSelectedCurrency = currentAmountInBase * rate;
      _cashPaymentController.text = _currentCashAmountInSelectedCurrency > 0
          ? _currentCashAmountInSelectedCurrency.toStringAsFixed(2)
          : '';
    });

    context.read<PurchaseInvoiceBloc>().add(UpdateCashCurrencyEvent(
      currency: currency,
      exchangeRate: rate,
    ));
  }

  double get _cashAmountInBase => _currentCashAmountInSelectedCurrency / _cashExchangeRate;

  double get _creditAmount {
    if (_currentState.paymentMode == PaymentMode.credit) {
      return _currentState.subtotal;
    } else if (_currentState.paymentMode == PaymentMode.mixed) {
      return _currentState.subtotal - _cashAmountInBase;
    }
    return 0.0;
  }

  double get _creditAmountLocal {
    if (_currentState.exchangeRate == null || _currentState.exchangeRate == 0) return _creditAmount;
    return _creditAmount * _currentState.exchangeRate!;
  }

  void _onCashCurrencyChanged(CurrenciesModel? currency) {
    if (currency == null) return;

    final newCurrency = currency.ccyCode!;
    if (newCurrency == _selectedCashCurrency) return;

    setState(() {
      _selectedCashCurrency = newCurrency;
      _isLoadingCashRate = true;
    });

    if (_baseCurrency.isNotEmpty && newCurrency != _baseCurrency) {
      _fetchCashExchangeRate(_baseCurrency, newCurrency);
    } else {
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

      if (mounted) {
        setState(() {
          _cashExchangeRate = rate;
          _cashExchangeRateController.text = rate.toStringAsFixed(4);
          _isLoadingCashRate = false;
        });
        _updateCashCurrencyAndRate(toCurrency, rate);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cashExchangeRate = 1.0;
          _cashExchangeRateController.text = '1.0000';
          _isLoadingCashRate = false;
        });
        _updateCashCurrencyAndRate(toCurrency, 1.0);
      }
    }
  }

  void _updateExchangeRate(double rate) {
    if (_currentState.supplierAccount != null) {
      context.read<PurchaseInvoiceBloc>().add(
        UpdateExchangeRateManuallyEvent(
          rate: rate,
          fromCurrency: _baseCurrency,
          toCurrency: _currentState.supplierAccount!.actCurrency ?? '',
        ),
      );
    }
  }

  void _updateCashExchangeRate(double rate) {
    if (rate > 0) {
      _updateCashCurrencyAndRate(_selectedCashCurrency, rate);
    }
  }

  void _onConfirm() {
    // Update the cash payment with the entered amount
    final finalCashAmount = _cashAmountInBase;
    context.read<PurchaseInvoiceBloc>().add(UpdateCashPaymentEvent(finalCashAmount));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final needsAccountConversion = _currentState.needsExchangeRate;
    final grandTotal = _currentState.subtotal;
    final cashAmountInBase = _cashAmountInBase;
    final creditAmount = _creditAmount;
    final creditAmountLocal = _creditAmountLocal;
    final needsCashConversion = _selectedCashCurrency.isNotEmpty &&
        _baseCurrency.isNotEmpty &&
        _selectedCashCurrency != _baseCurrency;

    return ZFormDialog(
      title: tr.payment.toUpperCase(),
      icon: Icons.payment,
      width: 550,
      actionLabel: Text(tr.confirm),
      onAction: _onConfirm,
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
                    if (_currentState.totalExpenses > 0)
                      _infoRow(
                        label: tr.totalExpense,
                        value: _currentState.totalExpenses,
                        currency: _baseCurrency,
                        color: Colors.red,
                      ),
                    if (_currentState.totalExpenses > 0)
                      _infoRow(
                        label: tr.totalCostPludExpenses,
                        value: grandTotal + _currentState.totalExpenses,
                        currency: _baseCurrency,
                        isBold: true,
                      ),
                    if (needsAccountConversion &&
                        _currentState.exchangeRate != null &&
                        _currentState.exchangeRate! > 0 &&
                        _currentState.toCurrency != null)
                      _infoRow(
                        label: "${tr.grandTotal} (${_currentState.toCurrency})",
                        value: grandTotal * _currentState.safeExchangeRate,
                        currency: _currentState.toCurrency!,
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

              // Cash Payment Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ZGenericTextField(
                    controller: _cashPaymentController,
                    title: "${tr.cashAmount} ($_selectedCashCurrency)",
                    hint: "0.00",
                    defaultCurrencyCode: _selectedCashCurrency,
                    fieldType: ZTextFieldType.currency,
                    onCurrencyChanged: _onCashCurrencyChanged,
                    inputFormat: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (value) {
                      final amountInSelectedCurrency = double.tryParse(value.replaceAll(',', '')) ?? 0;
                      _updateCashPayment(amountInSelectedCurrency);
                    },
                    showFlag: true,
                    showClearButton: true,
                    showSymbol: false,
                    isRequired: true,
                    onSubmit: (_) => _onConfirm(),
                  ),

                  // Exchange Rate Section for Cash
                  if (needsCashConversion) ...[
                    const SizedBox(height: 8),
                    ZTextFieldEntitled(
                      controller: _cashExchangeRateController,
                      title: "${tr.exchangeRate} (1 $_baseCurrency = ? $_selectedCashCurrency)",
                      hint: "1 $_baseCurrency = ?",
                      inputFormat: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,6}'),
                        ),
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
                    const SizedBox(height: 10),
                    Divider(color: color.primary, endIndent: 4, indent: 4, thickness: 1.5),
                  ],

                  // LIVE PAYMENT SUMMARY
                  ZCover(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    radius: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.summarize_outlined, color: color.primary, size: 20),
                            Text(
                              tr.paymentSummary.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AmountDisplay(
                          title: tr.cashPayment,
                          baseAmount: cashAmountInBase,
                          baseCurrency: _baseCurrency,
                          convertedAmount: (needsCashConversion && cashAmountInBase > 0)
                              ? _currentCashAmountInSelectedCurrency
                              : null,
                          convertedCurrency: _selectedCashCurrency,
                        ),

                        if (_currentState.supplierAccount != null && creditAmount > 0) ...[
                          const Divider(height: 12),
                          AmountDisplay(
                            title: tr.amountToChargeAccount,
                            baseAmount: creditAmount,
                            baseCurrency: _baseCurrency,
                            convertedAmount: (needsAccountConversion && creditAmount > 0)
                                ? creditAmountLocal
                                : null,
                            convertedCurrency: _currentState.toCurrency,
                          ),
                        ],

                        const Divider(height: 12),
                        _infoRow(
                          label: tr.totalPayable,
                          value: cashAmountInBase + creditAmount,
                          currency: _baseCurrency,
                          fontSize: 17,
                          isBold: true,
                          color: (cashAmountInBase + creditAmount) >= grandTotal ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),

                  // Account Payment Exchange Rate Section
                  if (needsAccountConversion && _currentState.toCurrency != null) ...[
                    const SizedBox(height: 8),
                    ZTextFieldEntitled(
                      controller: _exchangeRateController,
                      title: "${tr.exchangeRate} ($_baseCurrency → ${_currentState.toCurrency})",
                      hint: "1 $_baseCurrency = ?",
                      inputFormat: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,6}'),
                        ),
                      ],
                      onChanged: (value) {
                        final rate = double.tryParse(value.replaceAll(',', '')) ?? 1.0;
                        if (rate > 0) {
                          _updateExchangeRate(rate);
                        }
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Credit Account Section
              if (_currentState.supplierAccount != null && creditAmount > 0)
                ZCover(
                  padding: const EdgeInsets.all(12),
                  radius: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.credit_card, size: 20, color: color.primary),
                              const SizedBox(width: 8),
                              Text(
                                tr.accountInformation.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            "${_currentState.supplierAccount?.accName} (${_currentState.supplierAccount?.accNumber})",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                      _infoRow(
                        label: tr.currentBalance,
                        value: _currentState.currentBalance,
                        currency: _currentState.supplierAccount!.actCurrency ?? _baseCurrency,
                        fontSize: 15,
                      ),
                      _infoRow(
                        label: tr.newBalance,
                        value: _currentState.newBalance,
                        currency: _currentState.supplierAccount!.actCurrency ?? _baseCurrency,
                        isBold: true,
                        fontSize: 17,
                        color: _currentState.newBalance < 0 ? Colors.red : Colors.green,
                      ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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
                      GenericTextField<
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
                            return GenericTextField<
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
                          return GenericTextField<
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
            GenericTextField<ProductsModel, ProductsBloc, ProductsState>(
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

                return GenericTextField<
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
    final needsConversion =
        current.supplierAccount?.actCurrency != null &&
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
        localAmount: item
            .localAmount, // Single item local amount (unit price * exchange rate)
        localCurrency:
            current?.supplierAccount?.actCurrency ?? current?.toCurrency,
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
                localCurrency: needsConversion
                    ? (current.supplierAccount?.actCurrency ??
                          current.toCurrency)
                    : null,
                exchangeRate: needsConversion ? current.exchangeRate : null,
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
                localCurrency: needsConversion
                    ? (current.supplierAccount?.actCurrency ??
                          current.toCurrency)
                    : null,
                exchangeRate: needsConversion ? current.exchangeRate : null,
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
                localCurrency: needsConversion
                    ? (current.supplierAccount?.actCurrency ??
                          current.toCurrency)
                    : null,
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
                            GenericTextField<
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
                              return GenericTextField<
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
                            return GenericTextField<
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
                      GenericUnderlineTextfield<
                        ProductsModel,
                        ProductsBloc,
                        ProductsState
                      >(
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
