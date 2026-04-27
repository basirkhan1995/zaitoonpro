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
import 'package:zaitoonpro/Features/Widgets/section_title.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Reminder/add_edit_reminders.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/bloc/sale_invoice_bloc.dart';
import '../../../../../../../Features/Generic/complex_textfield.dart';
import '../../../../../../../Features/Generic/stock_product_field.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Other/utils.dart';
import '../../../../../../../Features/Other/zForm_dialog.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/Widgets/amount_display.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import '../../../../Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import '../../../../Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import '../../../../Settings/Ui/Stock/Ui/Products/model/product_stock_model.dart';
import '../../../../Settings/features/Visibility/bloc/settings_visible_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../Print/print.dart';
import '../Print/stock_document.dart';
import 'model/sale_invoice_items.dart';

class NewSaleView extends StatelessWidget {
  final int? orderId;
  const NewSaleView({super.key,this.orderId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _DesktopNewSaleView(orderId),
      desktop: _DesktopNewSaleView(orderId),
      tablet: _DesktopNewSaleView(orderId),
    );
  }
}


class _DesktopNewSaleView extends StatefulWidget {
  final int? orderId;
  const _DesktopNewSaleView(this.orderId);

  @override
  State<_DesktopNewSaleView> createState() => _DesktopNewSaleViewState();
}
class _DesktopNewSaleViewState extends State<_DesktopNewSaleView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _generalDiscountController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final TextEditingController _extraChargesController = TextEditingController();

  final List<List<FocusNode>> _rowFocusNodes = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  String? _userName;
  String? baseCurrency;
  int? signatory;
  bool _isEditMode = false;

  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _pcsControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, TextEditingController> _localeAmountControllers = {};
  int? _selectedAccountNumber;
  Timer? _debounce;
  bool toggleProfit = true;

  void _onExchangeRateChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final rate = double.tryParse(value.replaceAll(',', ''));
      final state = context.read<SaleInvoiceBloc>().state;

      if (rate != null && rate > 0 && state is SaleInvoiceLoaded) {
        final current = state;
        if (current.exchangeRate != rate &&
            current.fromCurrency != null &&
            current.toCurrency != null) {
          context.read<SaleInvoiceBloc>().add(
            UpdateExchangeRateEvent(
              rate: rate,
              fromCurrency: current.fromCurrency!,
              toCurrency: current.toCurrency!,
            ),
          );
        }
      }
    });
  }

  Future<void> _fetchExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      if (mounted) {
        context.read<SaleInvoiceBloc>().add(
          UpdateExchangeRateEvent(
            rate: -1,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
          ),
        );
        _exchangeRateController.text = AppLocalizations.of(context)!.loading;
      }

      await context.read<SaleInvoiceBloc>().fetchExchangeRate(fromCurrency, toCurrency);
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context: context,
          title: "Error",
          message: "Failed to fetch exchange rate: $e",
          type: ToastType.error,
        );
        context.read<SaleInvoiceBloc>().add(
          UpdateExchangeRateEvent(
            rate: 1.0,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
          ),
        );
        _exchangeRateController.text = "1.0000";
      }
    }
  }

  void _updateControllersFromState(SaleInvoiceState state) {
    if (state is SaleInvoiceLoaded) {
      if (state.exchangeRate != null && state.exchangeRate! > 0) {
        if (_exchangeRateController.text != state.exchangeRate!.toStringAsFixed(4)) {
          _exchangeRateController.text = state.exchangeRate!.toStringAsFixed(4);
        }
      }

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

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      final auth = authState.loginData;
      baseCurrency = auth.company?.comLocalCcy ?? "";
      company.comName = auth.company?.comName ?? "";
      company.comAddress = auth.company?.comAddress ?? "";
      company.compPhone = auth.company?.comPhone ?? "";
      company.comEmail = auth.company?.comEmail ?? "";
      company.slogan = auth.company?.comDetails ?? '';

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


    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saleBloc = context.read<SaleInvoiceBloc>();
      final exchangeBloc = context.read<ExchangeRateBloc>();

      // Set base currency on bloc
      if (baseCurrency != null && baseCurrency!.isNotEmpty) {
        saleBloc.setBaseCurrency(baseCurrency!);
      }

      saleBloc.setExchangeRateBloc(exchangeBloc);

      if (widget.orderId != null) {
        _isEditMode = true;
        saleBloc.add(LoadSaleInvoiceForEditEvent(
          orderId: widget.orderId!,
          baseCurrency: baseCurrency ?? 'USD',
        ));
      } else {
        saleBloc.add(InitializeSaleInvoiceEvent());
      }

      _clearAllControllers();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final row in _rowFocusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    _accountController.dispose();
    _personController.dispose();
    _xRefController.dispose();
    _remarkController.dispose();
    _generalDiscountController.dispose();
    _exchangeRateController.dispose();
    _extraChargesController.dispose();

    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (final controller in _pcsControllers.values) {
      controller.dispose();
    }
    for (final controller in _discountControllers.values) {
      controller.dispose();
    }
    for (final controller in _localeAmountControllers.values) {
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
      child: BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
        listener: (context, state) {
          if (state is SaleInvoiceError) {
            ToastManager.show(
              context: context,
              title: tr.errorTitle,
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is SaleInvoiceSaved) {
            Navigator.of(context).pop();
            if (state.success) {
              String? savedInvoiceNumber = state.invoiceNumber;
              ToastManager.show(
                context: context,
                title: tr.successTitle,
                message: tr.successPurchaseInvoiceMsg,
                type: ToastType.success,
              );
              _clearAllControllers();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onSalePrint(invoiceNumber: savedInvoiceNumber);
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
          // Add this BEFORE your existing SaleInvoiceLoaded case
          if (state is SaleInvoiceLoaded && _isEditMode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Set customer name
              if (state.customer != null) {
                _personController.text = state.customer!.perName ?? '';
                signatory = state.customer!.perId;
              }

              // Set account (SHOW ACCOUNT NUMBER ONLY since name is empty)
              if (state.customerAccount != null) {
                _accountController.text = '${state.customerAccount!.accNumber}';
                _selectedAccountNumber = state.customerAccount!.accNumber;
              }

              // Set reference and remark
              _xRefController.text = state.xRef ?? '';
              _remarkController.text = state.remark ?? '';

              // Set exchange rate
              if (state.exchangeRate != null && state.exchangeRate! > 0) {
                _exchangeRateController.text = state.exchangeRate!.toStringAsFixed(4);
              }

              _isEditMode = false; // Reset flag
            });
          }


          if (state is SaleInvoiceLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusNewRowIfNeeded(state);
              _updateControllersFromState(state);
            });
          }
          if (state is SaleInvoiceLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusNewRowIfNeeded(state);
              _updateControllersFromState(state);
            });
          }
        },

        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            titleSpacing: 0,
            title: Text(tr.saleEntry,style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            actionsPadding: EdgeInsets.symmetric(horizontal: 10),
            actions: [
              if (_accountController.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                ZOutlineButton(
                  icon: Icons.alarm_rounded,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AddEditReminderView(
                          accNumber: _selectedAccountNumber,
                          dueParameter: "Receivable",
                          isEnable: true,
                        );
                      },
                    );
                  },
                  label: Text(tr.setReminder),
                ),
              ],
              const SizedBox(width: 8),
              ZOutlineButton(
                icon: Icons.refresh,
                onPressed: _resetForm,
                label: Text(tr.newSale),
              ),
              const SizedBox(width: 8),
              ZOutlineButton(
                icon: Icons.receipt,
                onPressed: () => _onPrintStockPaper(),
                label: Text(tr.stockPaper),
              ),
              const SizedBox(width: 8),
              ZOutlineButton(
                icon: FontAwesomeIcons.print,
                onPressed: () => _onSalePrint(invoiceNumber: null),
                label: Text(tr.print.toUpperCase()),
              ),
              const SizedBox(width: 8),

              if(widget.orderId == null)...[
                BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                  builder: (context, state) {
                    if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                      final current = state is SaleInvoiceSaving ? state : (state as SaleInvoiceLoaded);
                      final isSaving = state is SaleInvoiceSaving;

                      return ZOutlineButton(
                        isActive: true,
                        icon: Icons.save_rounded,
                        onPressed: (isSaving)
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
                        ) : Text(tr.saveTitle),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ] else ...[
                BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                  builder: (context, state) {
                    if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                      final current = state is SaleInvoiceSaving ? state : (state as SaleInvoiceLoaded);
                      final isSaving = state is SaleInvoiceSaving;

                      return ZOutlineButton(
                        isActive: true,
                        icon: Icons.refresh,
                        onPressed: (isSaving)
                            ? null  // Just disable the button, no error message
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
                            : Text(tr.update.toUpperCase()),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ]
            ],
          ),
          body: ZCover(
            color: Theme.of(context).colorScheme.surface,
            borderColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            shadowColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            margin: EdgeInsets.all(8),
            radius: 10,
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer and Account Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
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
                              if (state is IndividualLoadedState) {
                                return state.individuals;
                              }
                              return [];
                            },
                            onSelected: (value) {
                              _personController.text = "${value.perName} ${value.perLastName}";
                              context.read<SaleInvoiceBloc>().add(SelectCustomerEvent(value));
                              context.read<AccountsBloc>().add(LoadAccountsEvent(ownerId: value.perId));
                              setState(() {
                                signatory = value.perId;
                                company.partyAddress = value.addName;
                                company.partyPhone = value.perPhone;
                                company.partyCity = value.addCity;
                                company.partyProvince = value.addProvince;
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
                                return GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
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
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          tr.balance,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ),
                                        Text(
                                          "${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}",
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                      ],
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
                                    setState(() {
                                      _accountController.text = '${value.accName} (${value.accNumber})';
                                      _selectedAccountNumber = value.accNumber;
                                    });
                                    context.read<SaleInvoiceBloc>().add(SelectCustomerAccountEvent(value));
                                    final authState = context.read<AuthBloc>().state;
                                    if (authState is AuthenticatedState) {
                                      final baseCurr = authState.loginData.company?.comLocalCcy ?? '';
                                      final accountCurrency = value.actCurrency ?? '';

                                      if (baseCurr.isNotEmpty && accountCurrency.isNotEmpty && baseCurr != accountCurrency) {
                                        _fetchExchangeRate(baseCurr, accountCurrency);
                                      } else {
                                        context.read<SaleInvoiceBloc>().add(
                                          UpdateExchangeRateEvent(
                                            rate: 1.0,
                                            fromCurrency: baseCurr,
                                            toCurrency: accountCurrency,
                                          ),
                                        );
                                        _exchangeRateController.text = "1.0000";
                                      }
                                    }
                                  },
                                  showClearButton: true,
                                );
                              }
                              return GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                                key: const ValueKey('account_field'),
                                controller: _accountController,
                                title: tr.accounts,
                                hintText: tr.selectAccount,
                                isRequired: false,
                                bloc: context.read<AccountsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(LoadAccountsFilterEvent(include: '8', exclude: '')),
                                searchFunction: (bloc, query) => bloc.add(LoadAccountsFilterEvent(input: query, include: '8', exclude: '')),
                                itemBuilder: (context, account) => ListTile(
                                  title: Text(account.accName ?? ''),
                                  subtitle: Text('${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}'),
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
                                    _accountController.text = '${value.accName} (${value.accNumber})';
                                    _selectedAccountNumber = value.accNumber;
                                  });

                                  context.read<SaleInvoiceBloc>().add(SelectCustomerAccountEvent(value));

                                  final authState = context.read<AuthBloc>().state;
                                  if (authState is AuthenticatedState) {
                                    final baseCurr = authState.loginData.company?.comLocalCcy ?? '';
                                    final accountCurrency = value.actCurrency ?? '';

                                    if (baseCurr.isNotEmpty && accountCurrency.isNotEmpty && baseCurr != accountCurrency) {
                                      _fetchExchangeRate(baseCurr, accountCurrency);
                                    } else {
                                      context.read<SaleInvoiceBloc>().add(
                                        UpdateExchangeRateEvent(
                                          rate: 1.0,
                                          fromCurrency: baseCurr,
                                          toCurrency: accountCurrency,
                                        ),
                                      );
                                      _exchangeRateController.text = "1.0000";
                                    }
                                  }
                                },
                                showClearButton: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (_needsLocalConversion(context)) ...[
                          BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                            builder: (context, state) {
                              if (state is SaleInvoiceLoaded && state.needsExchangeRate) {
                                final isLoading = state.isExchangeRateLoading;
                                return Expanded(
                                  child: ZTextFieldEntitled(
                                    controller: _exchangeRateController,
                                    isRequired: true,
                                    title: tr.exchangeRate,
                                    hint: isLoading ? tr.loading : tr.exchangeRate,
                                    isEnabled: !isLoading,
                                    validator: (value){
                                      if(value.isEmpty){
                                        return tr.required(tr.exchangeRate);
                                      }
                                      return null;
                                    },
                                    compactMode: true,
                                    onSubmit: _onExchangeRateChanged,
                                    trailing: isLoading ? Container(
                                      padding: EdgeInsets.all(2),
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : null,
                                    inputFormat: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}'))],
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ],
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: ZTextFieldEntitled(
                            controller: _remarkController,
                            title: tr.remark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    _buildItemsHeader(context),
                    const SizedBox(height: 8),

                    Expanded(
                      child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                        builder: (context, state) {
                          if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
                            final current = state is SaleInvoiceSaving ? state : (state as SaleInvoiceLoaded);
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
                                  index: index,
                                  context: context,
                                );
                              },
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
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

  void _resetForm() {
    _clearAllControllers();
    context.read<SaleInvoiceBloc>().add(ResetSaleInvoiceEvent());
    _rowFocusNodes.clear();
    _priceControllers.clear();
    _qtyControllers.clear();
    _pcsControllers.clear();
    _discountControllers.clear();
    _localeAmountControllers.clear();
    context.read<SaleInvoiceBloc>().add(InitializeSaleInvoiceEvent());
  }

  void _clearAllControllers() {
    _accountController.clear();
    _personController.clear();
    _xRefController.clear();
    _remarkController.clear();
    _generalDiscountController.clear();
    _exchangeRateController.clear();
    _extraChargesController.clear();
    _priceControllers.clear();
    _qtyControllers.clear();
    _pcsControllers.clear();
    _discountControllers.clear();
    _localeAmountControllers.clear();
  }

  String _getAccountCurrency(BuildContext context) {
    final state = context.read<SaleInvoiceBloc>().state;
    if (state is SaleInvoiceLoaded && state.customerAccount != null) {
      return state.customerAccount!.actCurrency ?? '';
    }
    return '';
  }

  Widget _buildItemsHeader(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? title = Theme.of(context).textTheme.titleSmall?.copyWith(color: color.surface);
    final visibility = context.read<SettingsVisibleBloc>().state;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
           const SizedBox(width: 30, child: Text('#', textAlign: TextAlign.center)),
          Expanded(child: Text(locale.products, style: title)),
            SizedBox(width: 80, child: Text(locale.qty)),
            if(visibility.isWholeSale)
            SizedBox(width: 80, child: Text(locale.batchTitle)),
            SizedBox(width: 80, child: Text(locale.unit)),
          SizedBox(width: 120, child: Text("${locale.unitPrice} ($baseCurrency)")),
          if (_needsLocalConversion(context))
            SizedBox(width: 120, child: Text("${locale.unitPrice} (${_getAccountCurrency(context)})")),
            SizedBox(width: 140, child: Text(locale.discountTitle)),
          SizedBox(width: 140, child: Text("${locale.totalTitle} ($baseCurrency)")),
            SizedBox(width: 60, child: Text(locale.actions)),
        ].map((child) => DefaultTextStyle(style: title!, child: child)).toList(),
      ),
    );
  }

  Widget _buildItemRow({
    required BuildContext context,
    required SaleInvoiceItem item,
    required List<FocusNode> nodes,
    required bool isLastRow,
    required int index,
  }) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final productController = TextEditingController(text: item.productName);
    final headerProductController = TextEditingController(text: item.productName);

    final qtyController = _qtyControllers.putIfAbsent(
      item.rowId,
          () => TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
    );
    final salePriceController = _priceControllers.putIfAbsent(
      "sale_${item.rowId}",
          () => TextEditingController(
        text: item.salePrice != null && item.salePrice! > 0 ? item.salePrice!.toAmount() : '',
      ),
    );
    final discountController = _discountControllers.putIfAbsent(
      "sale_${item.rowId}",
          () => TextEditingController(
        text: item.discount != null && item.discount! > 0 ? item.discount!.toAmount() : '',
      ),
    );
    final batchController = _pcsControllers.putIfAbsent(
      "sale_${item.rowId}",
          () => TextEditingController(
        text: item.batch != null && item.batch! > 0 ? item.batch!.toAmount() : '',
      ),
    );
    final unitController = TextEditingController(text: item.unit ?? '');
    final localAmountController = _getLocalAmountController(item);

    void addProduct(ProductsStockModel product) {
      if (!mounted) return;

      final salePrice = double.tryParse(product.sellPrice?.toAmount() ?? "0.0") ?? 0.0;
      final averagePrice = double.tryParse(product.averagePrice?.toAmount() ?? "0.0") ?? 0.0;
      final landedPrice = double.tryParse(product.recentLandedPurPrice?.toAmount() ?? "0.0") ?? 0.0;
      final purchasePrice = double.tryParse(product.recentPurPrice?.toAmount() ?? "0.0") ?? 0.0;
      final batch = product.stkQtyInBatch;

      context.read<SaleInvoiceBloc>().add(
        UpdateSaleItemEvent(
          rowId: item.rowId,
          productId: product.proId.toString(),
          productName: product.proName ?? '',
          storageId: product.stkStorage,
          storageName: product.stgName ?? '',
          purPrice: averagePrice,
          salePrice: salePrice,
          landedPrice: landedPrice,
          purchasePrice: purchasePrice,
          batch: batch ?? 0,
        ),
      );

      if (product.proUnit != null && product.proUnit!.isNotEmpty) {
        context.read<SaleInvoiceBloc>().add(UpdateItemUnitEvent(rowId: item.rowId, unit: product.proUnit!));
        unitController.text = product.proUnit!;
      }

      if (batch != null && batch > 0) {
        batchController.text = batch.toString();
      }

      salePriceController.text = salePrice.toAmount();
      _updateLocalAmountText(item, localAmountController);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nodes.length > 1 && nodes[1].canRequestFocus) {
          nodes[1].requestFocus();
        }
      });
    }

    void onProductSelected(ProductsStockModel? product) {
      if (product == null) return;

      final currentState = context.read<SaleInvoiceBloc>().state;
      if (currentState is! SaleInvoiceLoaded) return;

      final productId = product.proId.toString();
      final batch = product.stkQtyInBatch;

      // Check for duplicate
      final isDuplicate = currentState.items.any((item) =>
      item.productId == productId && item.batch == batch
      );

      if (isDuplicate) {
        // Store the selected product
        final selectedProduct = product;

        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: .6),
          builder: (dialogContext) {
            final FocusNode dialogFocusNode = FocusNode();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              dialogFocusNode.requestFocus();
            });

            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Focus(
                focusNode: dialogFocusNode,
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.escape) {
                      Navigator.pop(dialogContext);
                      productController.clear();
                      headerProductController.clear();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (nodes.isNotEmpty && nodes[0].canRequestFocus) {
                          nodes[0].requestFocus();
                        }
                      });
                      return KeyEventResult.handled;
                    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                      Navigator.pop(dialogContext);
                      addProduct(selectedProduct);
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: AlertDialog(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  content: Container(
                    width: 450,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [


                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr.duplicateProduct.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,

                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr.itemAlreadyExists,
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Product info card
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutQuad,
                                builder: (context, opacity, child) {
                                  return Opacity(
                                    opacity: opacity,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.inventory_2_rounded,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            tr.productDetails.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.primary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        selectedProduct.proName ?? '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (batch != null && batch > 0) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.local_offer_outlined,
                                                size: 12,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${tr.batchTitle}: $batch',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Warning message
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.error.withValues(alpha: .2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        tr.duplicateEntry,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ZOutlineButton(
                                      backgroundHover: Theme.of(context).colorScheme.error,
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                        productController.clear();
                                        headerProductController.clear();
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (nodes.isNotEmpty && nodes[0].canRequestFocus) {
                                            nodes[0].requestFocus();
                                          }
                                        });
                                      },

                                      label: Text(
                                        tr.cancel.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: ZOutlineButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                        addProduct(selectedProduct);
                                      },
                                      isActive: true,
                                      label: Text(
                                        tr.addAgain,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
        return;
      }

      // No duplicate - add product directly
      addProduct(product);
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
              SizedBox(width: 30, child: Text((index + 1).toString(), textAlign: TextAlign.center)),
              Expanded(
                child: ProductSearchField<ProductsStockModel, ProductsBloc, ProductsState>(
                  controller: productController,
                  headerSearchController: headerProductController,
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
                  getProductId: (product) => product.proId?.toString(),
                  getProductName: (product) => product.proName,
                  getProductCode: (product) => product.proCode,
                  getStorageId: (product) => product.stkStorage,
                  getStorageName: (product) => product.stgName,
                  getAvailable: (product) => product.available,
                  getBatch: (product) => product.stkQtyInBatch,
                  getLandedPrice: (product) => product.recentLandedPurPrice,
                  getProductUnit: (product) => product.proUnit,
                  getAveragePrice: (product) => product.averagePrice,
                  getRecentPrice: (product) => product.recentPurPrice,
                  getSellPrice: (product) => product.sellPrice,
                  onProductSelected: onProductSelected,
                  onSubmit: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (nodes.length > 1 && nodes[1].canRequestFocus) {
                        nodes[1].requestFocus();
                      }
                    });
                  },
                  openOverlayOnFocus: item.productId.isEmpty,
                  showAllOnFocus: true,
                ),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: qtyController,
                  focusNode: nodes[1],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(hintText: tr.qty, border: InputBorder.none, isDense: true),
                  onChanged: (value) {
                    final qty = int.tryParse(value) ?? 0;
                    context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(rowId: item.rowId, qty: qty));
                    _updateLocalAmountText(item, localAmountController);
                  },
                  onSubmitted: (_) => nodes[2].requestFocus(),
                ),
              ),
              if(visibility.isWholeSale)
              SizedBox(
                width: 80,
                child: TextField(
                  controller: batchController,
                  readOnly: true,
                  decoration: InputDecoration(hintText: tr.batchTitle, border: InputBorder.none, isDense: true),
                ),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: unitController,
                  readOnly: true,
                  decoration: InputDecoration(hintText: tr.unit, border: InputBorder.none, isDense: true),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: salePriceController,
                  focusNode: nodes[2],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                  decoration: InputDecoration(hintText: tr.unitPrice, border: InputBorder.none, isDense: true),
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 0;
                    context.read<SaleInvoiceBloc>().add(UpdateSaleItemEvent(rowId: item.rowId, salePrice: price));
                    _updateLocalAmountText(item, localAmountController);
                  },
                  onSubmitted: (_) {
                    if (isLastRow) {
                      _addNewRowAndFocus();
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (index + 1 < _rowFocusNodes.length) {
                          _rowFocusNodes[index + 1][0].requestFocus();
                        }
                      });
                    }
                  },
                ),
              ),
              if (_needsLocalConversion(context))
                SizedBox(
                  width: 120,
                  child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
                    builder: (context, state) {
                      if (state is SaleInvoiceLoaded && state.isExchangeRateLoading) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return TextField(
                        controller: localAmountController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: tr.localAmount,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: TextStyle(color: color.primary, fontWeight: FontWeight.w500),
                      );
                    },
                  ),
                ),
              SizedBox(
                width: 140,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: discountController,
                        focusNode: nodes[3],
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                        decoration: InputDecoration(
                          hintText: tr.discountTitle,
                          border: InputBorder.none,
                          isDense: true,
                          suffixText: item.discountType == DiscountType.percentage ? '%' : null,
                        ),
                        onChanged: (value) {
                          final discount = double.tryParse(value) ?? 0;
                          context.read<SaleInvoiceBloc>().add(UpdateItemDiscountValueEvent(rowId: item.rowId, discountValue: discount));
                        },
                        onSubmitted: (_) {
                          if (isLastRow) {
                            _addNewRowAndFocus();
                          } else {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (index + 1 < _rowFocusNodes.length) {
                                _rowFocusNodes[index + 1][0].requestFocus();
                              }
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(item.discountType == DiscountType.percentage ? Icons.percent : Icons.attach_money, size: 16),
                      onPressed: () {
                        final newType = item.discountType == DiscountType.percentage ? DiscountType.amount : DiscountType.percentage;
                        context.read<SaleInvoiceBloc>().add(UpdateItemDiscountTypeEvent(rowId: item.rowId, discountType: newType));
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.totalSale.toAmount(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color.primary)),
                    if (item.discountAmount > 0) Text('(-${item.discountAmount.toAmount()})', style: const TextStyle(fontSize: 10, color: Colors.red)),
                  ],
                ),
              ),
              SizedBox(
                width: 67,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    _priceControllers.remove("sale_${item.rowId}");
                    _qtyControllers.remove(item.rowId);
                    _discountControllers.remove("sale_${item.rowId}");
                    _pcsControllers.remove("sale_${item.rowId}");
                    _localeAmountControllers.remove(item.rowId);
                    context.read<SaleInvoiceBloc>().add(RemoveSaleItemEvent(item.rowId));
                  },
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
                  onPressed: _addNewRowAndFocus,
                ),
              ],
            ),
          ),
      ],
    );
  }
  bool _needsLocalConversion(BuildContext context) {
    final state = context.read<SaleInvoiceBloc>().state;
    if (state is SaleInvoiceLoaded && state.customerAccount != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        final baseCurrency = authState.loginData.company?.comLocalCcy ?? '';
        final accountCurrency = state.customerAccount!.actCurrency ?? '';
        return baseCurrency.isNotEmpty && accountCurrency.isNotEmpty && baseCurrency != accountCurrency;
      }
    }
    return false;
  }

  String _getLocalAmountText(SaleInvoiceItem item) {
    final state = context.read<SaleInvoiceBloc>().state;
    if (state is SaleInvoiceLoaded) {
      if (state.isExchangeRateLoading) return AppLocalizations.of(context)!.loading;
      final rate = state.safeExchangeRate;
      if (rate > 0) {
        // Use the item's singleLocalAmount which accounts for unit price * exchange rate
        final localAmount = item.singleLocalAmount;
        if (localAmount > 0) return localAmount.toAmount();
      }
    }
    return '';
  }

  TextEditingController _getLocalAmountController(SaleInvoiceItem item) {
    final controller = _localeAmountControllers.putIfAbsent(
      item.rowId,
          () => TextEditingController(),
    );
    final newText = _getLocalAmountText(item);
    if (controller.text != newText) {
      controller.text = newText;
    }
    return controller;
  }

  void _updateLocalAmountText(SaleInvoiceItem item, TextEditingController controller) {
    final newText = _getLocalAmountText(item);
    if (controller.text != newText) {
      controller.text = newText;
    }
  }

  void _addNewRowAndFocus() {
    // Check if the last row has a product selected before adding new row
    final state = context.read<SaleInvoiceBloc>().state;
    if (state is SaleInvoiceLoaded && state.items.isNotEmpty) {
      final lastItem = state.items.last;
      if (lastItem.productId.isEmpty) {
        // Last row is empty, don't add new row
        return;
      }
    }
    context.read<SaleInvoiceBloc>().add(AddNewSaleItemEvent());
  }

  void _synchronizeFocusNodes(int itemCount) {
    while (_rowFocusNodes.length < itemCount) {
      _rowFocusNodes.add([
        FocusNode(),
        FocusNode(),
        FocusNode(),
        FocusNode(),
      ]);
    }
    while (_rowFocusNodes.length > itemCount) {
      final removed = _rowFocusNodes.removeLast();
      for (final node in removed) {
        node.dispose();
      }
    }
  }

  void _focusNewRowIfNeeded(SaleInvoiceLoaded state) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      for (int i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        if (item.productId.isEmpty) {
          if (i < _rowFocusNodes.length && _rowFocusNodes[i].isNotEmpty) {
            _rowFocusNodes[i][0].requestFocus();
            context.read<ProductsBloc>().add(LoadProductsStockEvent());
            break;
          }
        }
      }
    });
  }

  Widget _buildProfitSection({
    required SaleInvoiceLoaded current,
    required String baseCurr,
    required String profitLabel,
  }) {
    final isProfit = current.totalProfit >= 0;
    final color = isProfit ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: .05),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(profitLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    toggleProfit = !toggleProfit;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(toggleProfit ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                toggleProfit ? "••••••" : "${current.totalProfit.toAmount()} $baseCurr",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
              ),
              Text(
                toggleProfit ? "••••" : "${current.profitPercentage.toStringAsFixed(1)}%",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
  String _getBalanceStatus(double balance) {
    if (balance < 0) return AppLocalizations.of(context)!.debtor;
    if (balance > 0) return AppLocalizations.of(context)!.creditor;
    return AppLocalizations.of(context)!.noAccountsFound;
  }
  Widget _buildSummarySection(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final visibility = context.read<SettingsVisibleBloc>().state;

    return BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
      builder: (context, state) {
        if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
          final current = state is SaleInvoiceSaving ? state : (state as SaleInvoiceLoaded);
          final bool hasCreditAccount = current.customerAccount != null && current.creditAmount > 0;
          final bool needsConversion = current.needsExchangeRate;
          final bool isLoading = current.isExchangeRateLoading;

          final String baseCurr = baseCurrency ?? '';
          final String accountCurr = current.customerAccount?.actCurrency ?? '';

          // Calculate account amounts correctly
          final double remainingAmountInAccountCurrency = hasCreditAccount
              ? current.creditAmountLocal
              : 0.0;

          // New balance calculation
          final double newBalanceInAccountCurrency = hasCreditAccount
              ? current.currentBalance - remainingAmountInAccountCurrency
              : 0.0;

          return ZCover(
            padding: const EdgeInsets.all(15),
            radius: 10,
            borderColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            shadowColor: Theme.of(context).colorScheme.surfaceContainer,
            color: Theme.of(context).colorScheme.surface,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Icon(Icons.summarize_outlined),
                              Text(tr.invoiceSummary.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(height: 1, color: color.outline.withValues(alpha: .5)),
                          const SizedBox(height: 4),


                          _buildSummaryRow(label: tr.subtotal, fontSize: 17, value: current.subtotal, currency: baseCurr),

                          if (current.totalItemDiscount > 0)
                            _buildSummaryRow(label: tr.itemDiscounts, value: -current.totalItemDiscount, color: Colors.red, currency: baseCurr),

                          if (current.totalItemDiscount > 0)
                            _buildSummaryRow(label: tr.afterItemDiscount, value: current.totalAfterItemDiscount, isBold: true, currency: baseCurr),

                          // Display general discount as text (not editable)
                          if (current.generalDiscountAmount > 0)
                            _buildSummaryRow(
                              label: tr.generalDiscount,
                              value: -current.generalDiscountAmount,
                              color: Colors.red,
                              currency: baseCurr,
                            ),

                          // Display extra charges as text (not editable)
                          if (current.extraCharges > 0)
                            _buildSummaryRow(
                              label: tr.extraCharges,
                              value: current.extraCharges,
                              color: Colors.orange,
                              currency: baseCurr,
                            ),

                          const SizedBox(height: 5),
                          Divider(height: 1, color: color.outline.withValues(alpha: .5)),
                          const SizedBox(height: 5),
                          _buildSummaryRow(label: tr.grandTotal, value: current.grandTotal, isBold: true, fontSize: 17, currency: baseCurr),

                          if (needsConversion && !isLoading)
                            _buildSummaryRow(
                              label: '${tr.grandTotal} (${current.toCurrency})',
                              value: current.grandTotalLocal,
                              fontSize: 14,
                              color: color.primary.withValues(alpha: .8),
                              currency: current.toCurrency ?? '',
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 12),
                  VerticalDivider(width: 20, thickness: 1, color: color.outline.withValues(alpha: .2)),
                  SizedBox(width: 12),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                  spacing: 8,
                                children: [
                                  Icon(Icons.payment_rounded),
                                  Text(tr.paymentDetails.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              InkWell(
                                onTap: () => _showPaymentDialog(current),
                                child: Row(
                                  children: [
                                    Text(_getPaymentModeLabel(current.paymentMode).toUpperCase(),
                                        style: TextStyle(color: color.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.more_vert_rounded, size: 18, color: color.primary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(height: 1, color: color.outline.withValues(alpha: .5)),
                          const SizedBox(height: 8),

                          if (current.paymentMode == PaymentMode.cash) ...[
                            AmountDisplay(
                                title: tr.cashReceipt,
                                baseAmount: current.cashPayment,
                                baseCurrency: baseCurr,
                                convertedAmount: (current.cashCurrency != null && current.cashCurrency!.isNotEmpty && current.cashCurrency != baseCurr)?
                                current.cashPayment * current.cashExchangeRate : null,
                                convertedCurrency: current.cashCurrency,
                            ),

                          ]
                          else if(current.paymentMode == PaymentMode.credit)...[
                            AmountDisplay(
                              title: tr.accountPayment,
                              baseAmount: current.creditAmount,
                              baseCurrency: baseCurr,
                              convertedAmount: (needsConversion && !isLoading) ? current.creditAmountLocal : null,
                              convertedCurrency: current.toCurrency,
                              fontSize: 16,
                              baseColor: Colors.green.withValues(alpha: .9),
                            ),
                          ]
                          else if (current.paymentMode == PaymentMode.mixed) ...[
                              AmountDisplay(
                                title: tr.cashReceipt,
                                baseAmount: current.cashPayment,
                                baseCurrency: baseCurr,
                                convertedAmount:
                                (current.cashCurrency != null && current.cashCurrency!.isNotEmpty && current.cashCurrency != baseCurr) ?
                                current.cashPayment * current.cashExchangeRate : null,
                                convertedCurrency: current.cashCurrency,
                                fontSize: 16,
                                baseColor: Colors.green.withValues(alpha: .9),
                              ),

                              if(needsConversion && !isLoading)...[
                                Divider(),
                                AmountDisplay(
                                  title: tr.accountPayment,
                                  baseAmount: current.creditAmount,
                                  baseCurrency: baseCurr,
                                  convertedAmount: (needsConversion && !isLoading) ? current.creditAmountLocal : null,
                                  convertedCurrency: current.toCurrency,
                                  fontSize: 16,
                                  baseColor: Colors.green.withValues(alpha: .9),
                                ),
                              ]

                          ],

                          if (visibility.benefit && current.totalPurchaseCost > 0) ...[
                            const SizedBox(height: 8),
                            _buildProfitSection(
                              current: current,
                              baseCurr: baseCurr,
                              profitLabel: tr.pAndLTitle.toUpperCase(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Account Information Section
                  if (hasCreditAccount) ...[
                    SizedBox(width: 12),
                    VerticalDivider(width: 20, thickness: 1, color: color.outline.withValues(alpha: .2)),
                    SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Icon(FontAwesomeIcons.buildingColumns,size: 20),
                                Text(tr.accountInformation.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 11),
                            Divider(height: 1, color: color.outline.withValues(alpha: .5)),
                            const SizedBox(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(current.customerAccount!.accName ?? '', style: const TextStyle(fontSize: 15)),
                                      Text('#${current.customerAccount!.accNumber}', style: TextStyle(fontSize: 17, color: color.outline)),
                                    ],
                                  ),

                                  _buildSummaryRow(
                                    label: tr.currentBalance,
                                    value: current.currentBalance,
                                    fontSize: 15,
                                    currency: accountCurr,
                                  ),

                                  AmountDisplay(
                                      title: tr.amountAddedToAR,
                                      baseColor: Theme.of(context).colorScheme.error,
                                      baseAmount: current.creditAmount,
                                      baseCurrency: baseCurr,
                                      convertedCurrency: accountCurr,
                                      isPositive: true,
                                      showSign: true,
                                      convertedAmount: (needsConversion && !isLoading) ? remainingAmountInAccountCurrency : null,
                                  ),

                                  const SizedBox(height: 8),
                                  Divider(height: 1, color: color.outline.withValues(alpha: .5)),
                                  const SizedBox(height: 4),

                                  _buildSummaryRow(
                                    label: "${tr.newBalance} | ${_getBalanceStatus(current.newBalance)}",
                                    value: newBalanceInAccountCurrency,
                                    isBold: true,
                                    fontSize: 17,
                                    color: newBalanceInAccountCurrency < 0 ? Colors.red : Colors.green,
                                    currency: accountCurr,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildSummaryRow({
    required String label,
    required double value,
    bool isBold = false,
    Color? color,
    double fontSize = 14,
    required String currency,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('${value.toAmount()} $currency',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(SaleInvoiceLoaded current) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context,setState) {
          return SalePaymentDialog(state: current);
        }
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

  void _saveInvoice(BuildContext context, SaleInvoiceLoaded state) {
    // Check if customer exists
    if (state.customer == null) {
      ToastManager.show(
        context: context,
        title: AppLocalizations.of(context)!.errorTitle,
        message: AppLocalizations.of(context)!.selectCustomer,
        type: ToastType.error,
      );
      return;
    }

    // If payment is cash but no cash amount set, open dialog to set it
  if (state.paymentMode == PaymentMode.cash) {
      if(state.cashPayment <= 0 || state.cashPaymentLocal <=0 && state.cashPayment != state.grandTotal || state.cashPaymentLocal != state.grandTotalLocal){
        _showPaymentDialog(state);
      }
      return;
    }

    // Let Bloc handle all validation and show errors
    final completer = Completer<String>();
    context.read<SaleInvoiceBloc>().add(
      SaveSaleInvoiceEvent(
        usrName: _userName ?? '',
        orderName: "Sale",
        ordPersonal: state.customer!.perId!,
        xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
        remark: _remarkController.text.isNotEmpty ? _remarkController.text : null,
        completer: completer,
      ),
    );
  }

  void _onSalePrint({String? invoiceNumber}) {

    final visibilityState = context.read<SettingsVisibleBloc>().state;
    final state = context.read<SaleInvoiceBloc>().state;
    SaleInvoiceLoaded? current;

    if (state is SaleInvoiceLoaded) {
      current = state;
    } else if (state is SaleInvoiceSaved && state.invoiceData != null) {
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(context, message: 'Cannot print: No invoice data available', isError: true);
      return;
    }

    final needsConversion = current.needsExchangeRate;

    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return SaleInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        unitPrice: item.salePrice ?? 0.0,
        total: item.totalSale,
        batch: item.batch ?? 0,
        unit: item.unit ?? '',
        storageName: item.storageName,
        purchasePrice: item.purPrice ?? 0.0,
        profit: (item.salePrice ?? 0.0) - (item.purPrice ?? 0.0),
        localAmount: needsConversion ? item.singleLocalAmount : null,
        localCurrency: needsConversion ? current?.toCurrency : null,
        exchangeRate: needsConversion ? current?.safeExchangeRate : null,
      );
    }).toList();

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<dynamic>(
        data: null,
        company: company,
        buildPreview: ({required data, required language, required orientation, required pageFormat}) {
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
            company: company.copyWith(visible: visibilityState),
            pageFormat: pageFormat,
            currency: baseCurrency,
            isSale: true,
            totalLocalAmount: needsConversion ? current.totalLocalAmount : null,
            localCurrency: needsConversion ? current.toCurrency : null,
            exchangeRate: needsConversion ? current.safeExchangeRate : null,
            subtotal: current.subtotal,
            totalItemDiscount: current.totalItemDiscount,
            generalDiscount: current.generalDiscountAmount,
            extraCharges: current.extraCharges,
          );
        },
        onPrint: ({required data, required language, required orientation, required pageFormat, required selectedPrinter, required copies, required pages}) {
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
            company: company.copyWith(visible: visibilityState),
            selectedPrinter: selectedPrinter,
            pageFormat: pageFormat,
            copies: copies,
            currency: baseCurrency,
            isSale: true,
            totalLocalAmount: needsConversion ? current.totalLocalAmount : null,
            localCurrency: needsConversion ? current.toCurrency : null,
            exchangeRate: needsConversion ? current.safeExchangeRate : null,
            subtotal: current.subtotal,
            totalItemDiscount: current.totalItemDiscount,
            generalDiscount: current.generalDiscountAmount,
            extraCharges: current.extraCharges,
          );
        },
        onSave: ({required data, required language, required orientation, required pageFormat}) {
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
            company: company.copyWith(visible: visibilityState),
            pageFormat: pageFormat,
            currency: baseCurrency,
            isSale: true,
            totalLocalAmount: needsConversion ? current.totalLocalAmount : null,
            localCurrency: needsConversion ? current.toCurrency : null,
            exchangeRate: needsConversion ? current.safeExchangeRate : null,
            subtotal: current.subtotal,
            totalItemDiscount: current.totalItemDiscount,
            generalDiscount: current.generalDiscountAmount,
            extraCharges: current.extraCharges,
          );
        },
      ),
    );
  }

  void _onPrintStockPaper({String? invoiceNumber}) {
    final state = context.read<SaleInvoiceBloc>().state;
    SaleInvoiceLoaded? current;

    if (state is SaleInvoiceLoaded) {
      current = state;
    } else if (state is SaleInvoiceSaved && state.invoiceData != null) {
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(context, message: 'Cannot print: No invoice data available', isError: true);
      return;
    }

    // Convert to StockDocumentItem (only needs: productName, quantity, batch, storageName)
    final List<StockDocumentItem> stockItems = current.items.map((item) {
      return SaleStockItem(
        unit: item.unit ?? '',
        productName: item.productName,
        quantity: item.qty.toDouble(),
        batch: item.batch ?? 0,
        storageName: item.storageName,
      );
    }).toList();

    // Calculate total quantity
    final double totalQuantity = stockItems.fold(0.0, (sum, item) => sum + item.quantity);

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<dynamic>(
        data: null,
        company: company,
        buildPreview: ({required data, required language, required orientation, required pageFormat}) {
          return StockDocumentPrintService().previewStockDocument(
            documentType: "Sale",
            documentNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            documentDate: DateTime.now(),
            customerSupplierName: current!.customer?.perName ?? "",
            items: stockItems,
            totalQuantity: totalQuantity,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
            driverName: null,        // Leave empty for manual writing
            executedBy: null,        // Leave empty for manual writing
            authorizedBy: null,      // Leave empty for manual writing
          );
        },
        onPrint: ({required data, required language, required orientation, required pageFormat, required selectedPrinter, required copies, required pages}) {
          return StockDocumentPrintService().printStockDocument(
            documentType: "Sale",
            documentNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            documentDate: DateTime.now(),
            customerSupplierName: current!.customer?.perName ?? "",
            items: stockItems,
            totalQuantity: totalQuantity,
            language: language,
            orientation: orientation,
            company: company,
            selectedPrinter: selectedPrinter,
            pageFormat: pageFormat,
            copies: copies,
            driverName: null,        // Leave empty for manual writing
            executedBy: null,        // Leave empty for manual writing
            authorizedBy: null,      // Leave empty for manual writing
          );
        },
        onSave: ({required data, required language, required orientation, required pageFormat}) {
          return StockDocumentPrintService().createStockDocument(
            documentType: "Sale",
            documentNumber: invoiceNumber ?? "",
            reference: _xRefController.text,
            documentDate: DateTime.now(),
            customerSupplierName: current!.customer?.perName ?? "",
            items: stockItems,
            totalQuantity: totalQuantity,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
            driverName: null,        // Leave empty for manual writing
            executedBy: null,        // Leave empty for manual writing
            authorizedBy: null,      // Leave empty for manual writing
          );
        },
      ),
    );
  }
}

class SalePaymentDialog extends StatefulWidget {
  final SaleInvoiceLoaded state;

  const SalePaymentDialog({super.key, required this.state});

  @override
  State<SalePaymentDialog> createState() => _SalePaymentDialogState();
}
class _SalePaymentDialogState extends State<SalePaymentDialog> {
  late TextEditingController _cashPaymentController;
  late TextEditingController _exchangeRateController;
  late TextEditingController _extraChargesController;
  late TextEditingController _cashExchangeRateController;
  late TextEditingController _remainingDiscountController;
  late TextEditingController _generalDiscountController;

  Timer? _debounce;
  late StreamSubscription _blocSubscription;

  String _selectedCashCurrency = '';
  double _cashExchangeRate = 1.0;
  bool _isLoadingCashRate = false;
  String _baseCurrency = '';

  // Track current cash amount in selected currency
  double _currentCashAmountInSelectedCurrency = 0.0;

  // Track if we're in pure cash mode (no account selected)
  bool get _isPureCashMode => widget.state.customerAccount == null;

  // Track current state to rebuild when bloc updates
  SaleInvoiceLoaded _currentState = const SaleInvoiceLoaded(
    items: [],
    payments: [],
    cashPayment: 0.0,
    paymentMode: PaymentMode.cash,
    extraCharges: 0.0,
    generalDiscount: 0.0,
    cashExchangeRate: 1.0,
  );

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

    // Calculate initial cash amount in selected currency
    double grandTotalInSelectedCurrency = _currentState.grandTotal * _cashExchangeRate;

    if (_isPureCashMode) {
      // In pure cash mode, amount should be the full grand total in selected currency
      _currentCashAmountInSelectedCurrency = grandTotalInSelectedCurrency;
    } else {
      _currentCashAmountInSelectedCurrency = _currentState.cashPayment * _cashExchangeRate;
    }

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

    _generalDiscountController = TextEditingController(
      text: _currentState.generalDiscount > 0 ? _currentState.generalDiscount.toString() : '',
    );

    _cashExchangeRateController = TextEditingController(
      text: _cashExchangeRate.toStringAsFixed(4),
    );

    _extraChargesController = TextEditingController(
      text: _currentState.extraCharges > 0 ? _currentState.extraCharges.toString() : '',
    );

    _remainingDiscountController = TextEditingController();

    // Set initial cash currency if not set
    if (_currentState.cashCurrency == null || _currentState.cashCurrency!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // For pure cash mode, set the cash payment to full grand total
        if (_isPureCashMode) {
          context.read<SaleInvoiceBloc>().add(UpdateCashPaymentEvent(_currentState.grandTotal));
          context.read<SaleInvoiceBloc>().add(UpdateCashCurrencyEvent(
            currency: _baseCurrency,
            exchangeRate: 1.0,
          ));
        } else {
          context.read<SaleInvoiceBloc>().add(UpdateCashCurrencyEvent(
            currency: _baseCurrency,
            exchangeRate: 1.0,
          ));
        }
      });
    } else if (_isPureCashMode && _currentState.cashPayment != _currentState.grandTotal) {
      // Ensure cash payment matches grand total in pure cash mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SaleInvoiceBloc>().add(UpdateCashPaymentEvent(_currentState.grandTotal));
      });
    }

    // LISTEN to bloc state changes to update dialog when exchange rate changes
    _blocSubscription = context.read<SaleInvoiceBloc>().stream.listen((state) {
      if (state is SaleInvoiceLoaded && mounted) {
        setState(() {
          _currentState = state;

          // Update exchange rate controller if changed
          final newRate = _currentState.exchangeRate != null && _currentState.exchangeRate! > 0
              ? _currentState.exchangeRate!.toStringAsFixed(8)
              : '';
          if (_exchangeRateController.text != newRate) {
            _exchangeRateController.text = newRate;
          }

          // Update cash amount if needed
          if (_isPureCashMode) {
            // In pure cash mode, ensure cash payment matches grand total
            final expectedCashInSelectedCurrency = _currentState.grandTotal * _cashExchangeRate;
            if (_currentCashAmountInSelectedCurrency != expectedCashInSelectedCurrency) {
              _currentCashAmountInSelectedCurrency = expectedCashInSelectedCurrency;
              _cashPaymentController.text = expectedCashInSelectedCurrency.toStringAsFixed(2);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _blocSubscription.cancel();
    _cashPaymentController.dispose();
    _exchangeRateController.dispose();
    _extraChargesController.dispose();
    _cashExchangeRateController.dispose();
    _generalDiscountController.dispose();
    _remainingDiscountController.dispose();
    super.dispose();
  }

  void _updateCashPayment(double amountInSelectedCurrency) {
    if (_isPureCashMode) {
      // In pure cash mode, we don't allow manual editing of the amount
      // The amount should always be the full grand total
      // Just refresh the display with the correct amount
      final correctAmount = _currentState.grandTotal * _cashExchangeRate;
      if (_currentCashAmountInSelectedCurrency != correctAmount) {
        setState(() {
          _currentCashAmountInSelectedCurrency = correctAmount;
          _cashPaymentController.text = correctAmount.toStringAsFixed(2);
        });
      }
      return;
    }

    setState(() {
      _currentCashAmountInSelectedCurrency = amountInSelectedCurrency;
    });

    final amountInBaseCurrency = amountInSelectedCurrency / _cashExchangeRate;
    context.read<SaleInvoiceBloc>().add(UpdateCashPaymentEvent(amountInBaseCurrency));
  }

  void _updateCashCurrencyAndRate(String currency, double rate) {
    setState(() {
      _selectedCashCurrency = currency;
      _cashExchangeRate = rate;
      _cashExchangeRateController.text = rate.toStringAsFixed(8);

      // Update displayed amount with new rate
      double newAmountInSelectedCurrency;

      if (_isPureCashMode) {
        // In pure cash mode, the amount should be grand total converted to new currency
        newAmountInSelectedCurrency = _currentState.grandTotal * rate;
      } else {
        final currentAmountInBase = _currentState.cashPayment;
        newAmountInSelectedCurrency = currentAmountInBase * rate;
      }

      _currentCashAmountInSelectedCurrency = newAmountInSelectedCurrency;
      _cashPaymentController.text = newAmountInSelectedCurrency > 0
          ? newAmountInSelectedCurrency.toStringAsFixed(2)
          : '';
    });

    context.read<SaleInvoiceBloc>().add(UpdateCashCurrencyEvent(
      currency: currency,
      exchangeRate: rate,
    ));
  }

  double get _cashAmountInBase {
    if (_isPureCashMode) {
      // In pure cash mode, return the grand total in base currency
      return _currentState.grandTotal;
    }
    return _currentCashAmountInSelectedCurrency / _cashExchangeRate;
  }

  // Get remaining amount in BASE CURRENCY that still needs to be paid
  double get _remainingAmountInBase {
    if (_isPureCashMode) {
      return 0.0; // No remaining amount in pure cash mode
    }
    final grandTotal = _currentState.grandTotal;
    final cashAmount = _cashAmountInBase;
    return (grandTotal - cashAmount).clamp(0, grandTotal);
  }

  // Get remaining amount in ACCOUNT CURRENCY (if account is selected)
  double get _remainingAmountInAccountCurrency {
    if (_currentState.customerAccount == null) return 0.0;
    return _remainingAmountInBase * _currentState.safeExchangeRate;
  }

  double get _newBalanceInAccountCurrency {
    if (_currentState.customerAccount == null) return 0.0;
    final currentBalance = _currentState.currentBalance;
    return currentBalance - _remainingAmountInAccountCurrency;
  }

  PaymentMode get _calculatedPaymentMode {
    if (_isPureCashMode) {
      return PaymentMode.cash;
    }

    final grandTotal = _currentState.grandTotal;
    final cashAmount = _cashAmountInBase;

    if (cashAmount <= 0) {
      return PaymentMode.credit;
    } else if (cashAmount >= grandTotal) {
      return PaymentMode.cash;
    } else {
      return PaymentMode.mixed;
    }
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
      final rateStr = await context.read<SaleInvoiceBloc>().repo.getSingleRate(
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
    if (_currentState.customerAccount != null) {
      context.read<SaleInvoiceBloc>().add(
        UpdateExchangeRateManuallyEvent(
          rate: rate,
          fromCurrency: _baseCurrency,
          toCurrency: _currentState.customerAccount!.actCurrency ?? '',
        ),
      );
    }
  }

  void _updateCashExchangeRate(double rate) {
    if (rate > 0) {
      _updateCashCurrencyAndRate(_selectedCashCurrency, rate);
    }
  }

  void _updateExtraCharges(double value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SaleInvoiceBloc>().add(UpdateExtraChargesEvent(value));
    });
  }

  void _onConfirm() {
    if (_isPureCashMode) {
      // In pure cash mode, ensure the full grand total is set as cash payment
      context.read<SaleInvoiceBloc>().add(UpdateCashPaymentEvent(_currentState.grandTotal));
    } else {
      // Update the cash payment with the entered amount
      final finalCashAmount = _cashAmountInBase;
      context.read<SaleInvoiceBloc>().add(UpdateCashPaymentEvent(finalCashAmount));
    }

    // Close the dialog - user will click main Save button to save invoice
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final needsAccountConversion = _currentState.needsExchangeRate;
    final grandTotal = _currentState.grandTotal;
    final cashAmountInBase = _cashAmountInBase;
    final remainingAmountInBase = _remainingAmountInBase;

    final remainingAmountInAccountCurrency = _remainingAmountInAccountCurrency;
    final newBalanceInAccountCurrency = _newBalanceInAccountCurrency;
    final paymentMode = _calculatedPaymentMode;
    final isPaymentComplete = remainingAmountInBase <= 0.01 || _isPureCashMode;

    final bool isActionEnabled;
    if (_isPureCashMode) {
      // Pure cash mode - always enabled since amount is set automatically
      isActionEnabled = true;
    } else if (_currentState.customerAccount == null) {
      // No account selected - must pay full amount in cash
      isActionEnabled = remainingAmountInBase <= 0.01;
    } else {
      // Account selected - any cash amount is valid
      isActionEnabled = true;
    }

    final bool needsCashConversion = _selectedCashCurrency.isNotEmpty &&
        _baseCurrency.isNotEmpty &&
        _selectedCashCurrency != _baseCurrency;

    final accountCurrency = _currentState.customerAccount?.actCurrency ?? '';

    return ZFormDialog(
      title: "${tr.payment} - ${_getPaymentModeLabel(paymentMode)}",
      icon: Icons.payment,
      width: 600,
      actionLabel: Text(tr.confirm),
      isActionTrue: isActionEnabled,
      onAction: _onConfirm,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
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
                      label: tr.subtotal.toUpperCase(),
                      value: _currentState.subtotal,
                      currency: _baseCurrency,
                      isBold: true,
                    ),
                    if (_currentState.totalItemDiscount > 0)
                      _infoRow(
                        label: tr.itemDiscounts,
                        value: -_currentState.totalItemDiscount,
                        currency: _baseCurrency,
                        color: Colors.red,
                      ),
                    if (_currentState.totalAfterItemDiscount != _currentState.subtotal)
                      _infoRow(
                        label: tr.afterItemDiscount,
                        value: _currentState.totalAfterItemDiscount,
                        currency: _baseCurrency,
                        isBold: true,
                      ),

                    // General Discount Field
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr.generalDiscount,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_currentState.generalDiscountType == DiscountType.percentage ? Icons.percent : Icons.monetization_on_outlined, size: 16),
                          onPressed: () {
                            final newType = _currentState.generalDiscountType == DiscountType.percentage
                                ? DiscountType.amount
                                : DiscountType.percentage;
                            context.read<SaleInvoiceBloc>().add(UpdateGeneralDiscountEvent(
                              discountValue: _currentState.generalDiscount,
                              discountType: newType,
                            ));
                          },
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _generalDiscountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                            decoration: InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              isDense: true,
                              suffixText: _currentState.generalDiscountType == DiscountType.percentage ? '%' : _baseCurrency,
                            ),
                            textAlign: TextAlign.end,
                            onChanged: (value) {
                              final discount = double.tryParse(value.replaceAll(',', '')) ?? 0;
                              context.read<SaleInvoiceBloc>().add(UpdateGeneralDiscountEvent(
                                discountValue: discount,
                                discountType: _currentState.generalDiscountType,
                              ));
                            },
                          ),
                        ),
                      ],
                    ),

                    // Extra Charges Field
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr.extraCharges,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 40),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _extraChargesController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                            decoration: InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              isDense: true,
                              suffixText: _baseCurrency,
                            ),
                            textAlign: TextAlign.end,
                            onChanged: (value) {
                              final charges = double.tryParse(value.replaceAll(',', '')) ?? 0;
                              _updateExtraCharges(charges);
                            },
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 15),
                    _infoRow(
                      label: tr.grandTotal,
                      value: grandTotal,
                      currency: _baseCurrency,
                      isBold: true,
                      fontSize: 20,
                    ),
                    if (needsAccountConversion && _currentState.exchangeRate != null && _currentState.exchangeRate! > 0 && _currentState.toCurrency != null)
                      _infoRow(
                        label: "${tr.grandTotal} (${_currentState.toCurrency})",
                        value: grandTotal * _currentState.safeExchangeRate,
                        currency: _currentState.toCurrency!,
                        fontSize: 14,
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
                    title: _isPureCashMode
                        ? "${tr.cashAmount} ($_selectedCashCurrency) - Full Amount"
                        : "${tr.cashAmount} ($_selectedCashCurrency)",
                    hint: "0.00",
                    readOnly: _isPureCashMode, // Make read-only in pure cash mode
                    defaultCurrencyCode: _selectedCashCurrency,
                    fieldType: ZTextFieldType.currency,
                    onCurrencyChanged: _onCashCurrencyChanged,
                    inputFormat: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    onChanged: (value) {
                      if (_isPureCashMode) {
                        // In pure cash mode, don't allow editing, just refresh with correct amount
                        final correctAmount = grandTotal * _cashExchangeRate;
                        if (_cashPaymentController.text != correctAmount.toStringAsFixed(2)) {
                          _cashPaymentController.text = correctAmount.toStringAsFixed(2);
                        }
                        return;
                      }

                      final amountInSelectedCurrency =
                          double.tryParse(value.replaceAll(',', '')) ?? 0;

                      _updateCashPayment(amountInSelectedCurrency);
                    },
                    showFlag: true,
                    showClearButton: true,
                    showSymbol: false,
                    isRequired: true,
                    onSubmit: (e) => _onConfirm(),
                  ),

                  // Exchange Rate Section for Cash
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
                            readOnly: _isPureCashMode, // Make read-only in pure cash mode
                            inputFormat: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}'))
                            ],
                            onChanged: (value) {
                              if (_isPureCashMode) return; // Don't allow rate changes in pure cash mode

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
                      ],
                    ),
                    SizedBox(height: 10),
                    Divider(color: Theme.of(context).colorScheme.primary, endIndent: 4, indent: 4, thickness: 1.5),
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
                            Icon(Icons.summarize_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                            Text(
                              tr.paymentSummary.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AmountDisplay(
                            title: tr.cashReceipt,
                            baseAmount: cashAmountInBase,
                            baseCurrency: _baseCurrency,
                            convertedAmount: (needsCashConversion && cashAmountInBase > 0)
                                ? _currentCashAmountInSelectedCurrency
                                : null,
                            convertedCurrency: _selectedCashCurrency
                        ),

                        if (!_isPureCashMode && _currentState.customerAccount != null && remainingAmountInBase > 0) ...[
                          AmountDisplay(
                            title: tr.accountPayment,
                            baseAmount: remainingAmountInBase,
                            baseCurrency: _baseCurrency,
                            convertedAmount: (needsAccountConversion && remainingAmountInBase > 0)
                                ? remainingAmountInAccountCurrency
                                : null,
                            convertedCurrency: accountCurrency,
                          ),
                        ],

                        const Divider(height: 12),
                        if (needsCashConversion && paymentMode == PaymentMode.cash)
                          _infoRow(
                            label: tr.totalReceivable,
                            value: cashAmountInBase + remainingAmountInBase,
                            currency: _baseCurrency,
                            fontSize: 17,
                            isBold: true,
                            color: isPaymentComplete ? Colors.green : Colors.red,
                          ),

                        if (!_isPureCashMode && paymentMode == PaymentMode.mixed)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              "Cash + Account Receivable",
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                            ),
                          ),
                        if (!_isPureCashMode && paymentMode == PaymentMode.cash && _currentState.customerAccount != null && isPaymentComplete)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              "Full Cash Payment",
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ),
                        if (!_isPureCashMode && paymentMode == PaymentMode.credit && _currentState.customerAccount != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              "Total Invoice Amount Added to Receivable",
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Account Payment Exchange Rate Section
                  if (needsAccountConversion && !_isPureCashMode && _currentState.toCurrency != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: _exchangeRateController,
                            title: "${tr.exchangeRate} ($_baseCurrency → ${_currentState.toCurrency})",
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
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Credit Account Section
              if (!_isPureCashMode && _currentState.customerAccount != null && remainingAmountInBase > 0)
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
                              Icon(Icons.credit_card, size: 20, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(tr.accountInformation.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text("${_currentState.customerAccount?.accName} (${_currentState.customerAccount?.accNumber})", style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      AmountDisplay(
                        title: tr.amountAddedToAR,
                        baseAmount: remainingAmountInBase,
                        baseCurrency: _baseCurrency,
                        convertedAmount: (widget.state.fromCurrency != widget.state.toCurrency && remainingAmountInBase > 0)
                            ? remainingAmountInAccountCurrency
                            : null,
                        isPositive: true,
                        showSign: true,
                        baseColor: Colors.green,
                        signColor: Colors.green,
                        convertedCurrency: accountCurrency,
                      ),
                      const SizedBox(height: 4),
                      Divider(),
                      const SizedBox(height: 4),
                      _infoRow(
                        label: tr.currentBalance,
                        value: _currentState.currentBalance,
                        currency: accountCurrency,
                        fontSize: 15,
                      ),
                      _infoRow(
                        label: tr.newBalance,
                        value: newBalanceInAccountCurrency,
                        currency: accountCurrency,
                        isBold: true,
                        fontSize: 17,
                        color: newBalanceInAccountCurrency < 0 ? Colors.red : Colors.green,
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

  String _getPaymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return AppLocalizations.of(context)!.cash;
      case PaymentMode.credit:
        return AppLocalizations.of(context)!.creditTitle;
      case PaymentMode.mixed:
        return AppLocalizations.of(context)!.mixedTitle;
    }
  }

  Widget _infoRow({
    required String label,
    required double value,
    required String currency,
    bool isBold = false,
    FontWeight? fontWeight,
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
                  fontWeight: isBold ? FontWeight.bold : (fontWeight ?? FontWeight.normal)
              )
          ),
          Text(
            "${value.toAmount()} $currency",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : (fontWeight ?? FontWeight.normal),
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
//
//class _MobileNewSaleView extends StatefulWidget {
//   const _MobileNewSaleView();
//
//   @override
//   State<_MobileNewSaleView> createState() => _MobileNewSaleViewState();
// }
// class _MobileNewSaleViewState extends State<_MobileNewSaleView> {
//   final TextEditingController _accountController = TextEditingController();
//   final TextEditingController _personController = TextEditingController();
//   final TextEditingController _xRefController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   Uint8List _companyLogo = Uint8List(0);
//   final company = ReportModel();
//   String? _userName;
//   String? baseCurrency;
//   int? signatory;
//   int? _selectedAccountNumber;
//
//   // Track controllers for each row
//   final Map<String, TextEditingController> _priceControllers = {};
//   final Map<String, TextEditingController> _qtyControllers = {};
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<SaleInvoiceBloc>().add(InitializeSaleInvoiceEvent());
//     });
//
//     final companyState = context.read<AuthBloc>().state;
//     if (companyState is AuthenticatedState) {
//       final auth = companyState.loginData;
//       baseCurrency = auth.company?.comLocalCcy ?? "";
//       company.comName = auth.company?.comName ?? "";
//       company.comAddress = auth.company?.comAddress ?? "";
//       company.compPhone = auth.company?.comPhone ?? "";
//       company.comEmail = auth.company?.comEmail ?? "";
//       company.statementDate = DateTime.now().toFullDateTime;
//       final base64Logo = auth.company?.comLogo;
//       if (base64Logo != null && base64Logo.isNotEmpty) {
//         try {
//           _companyLogo = base64Decode(base64Logo);
//           company.comLogo = _companyLogo;
//         } catch (e) {
//           _companyLogo = Uint8List(0);
//         }
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _accountController.dispose();
//     _personController.dispose();
//     _xRefController.dispose();
//     _scrollController.dispose();
//
//     // Dispose all controllers
//     for (final controller in _priceControllers.values) {
//       controller.dispose();
//     }
//     for (final controller in _qtyControllers.values) {
//       controller.dispose();
//     }
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final tr = AppLocalizations.of(context)!;
//     final state = context.watch<AuthBloc>().state;
//
//     if (state is! AuthenticatedState) {
//       return const SizedBox();
//     }
//
//     final login = state.loginData;
//     _userName = login.usrName ?? "";
//
//     return BlocListener<AuthBloc, AuthState>(
//       listener: (context, state) {
//         if (state is AuthenticatedState) {
//           _userName = state.loginData.usrName ?? '';
//         }
//       },
//       child: BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
//         listener: (context, state) {
//           if (state is SaleInvoiceError) {
//             Utils.showOverlayMessage(
//               context,
//               message: state.message,
//               isError: true,
//             );
//           }
//           if (state is SaleInvoiceSaved) {
//             Navigator.of(context).pop();
//             if (state.success) {
//               String? savedInvoiceNumber = state.invoiceNumber;
//
//               Utils.showOverlayMessage(
//                 context,
//                 title: tr.successTitle,
//                 message: tr.successPurchaseInvoiceMsg,
//                 isError: false,
//               );
//               _accountController.clear();
//               _personController.clear();
//               _xRefController.clear();
//
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (savedInvoiceNumber != null &&
//                     savedInvoiceNumber.isNotEmpty) {
//                   _onSalePrint(invoiceNumber: savedInvoiceNumber);
//                 }
//               });
//             } else {
//               Utils.showOverlayMessage(
//                 context,
//                 message: "Failed to create invoice",
//                 isError: true,
//               );
//             }
//           }
//         },
//         child: Scaffold(
//           backgroundColor: Theme.of(context).colorScheme.surface,
//           appBar: AppBar(
//             titleSpacing: 0,
//             title: Text(tr.saleEntry),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.print),
//                 onPressed: () => _onSalePrint(invoiceNumber: null),
//               ),
//               BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//                 builder: (context, state) {
//                   if (state is SaleInvoiceLoaded ||
//                       state is SaleInvoiceSaving) {
//                     final current = state is SaleInvoiceSaving
//                         ? state
//                         : (state as SaleInvoiceLoaded);
//                     final isSaving = state is SaleInvoiceSaving;
//
//                     return IconButton(
//                       icon: isSaving
//                           ? SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Theme.of(context).colorScheme.primary,
//                               ),
//                             )
//                           : const Icon(Icons.save),
//                       onPressed: (isSaving || !current.isFormValid)
//                           ? null
//                           : () => _saveInvoice(context, current),
//                     );
//                   }
//                   return const SizedBox();
//                 },
//               ),
//             ],
//           ),
//           body: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 // Customer and Account Selection
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     children: [
//                       GenericTextfield<
//                         IndividualsModel,
//                         IndividualsBloc,
//                         IndividualsState
//                       >(
//                         key: const ValueKey('person_field'),
//                         controller: _personController,
//                         title: tr.customer,
//                         hintText: tr.customer,
//                         isRequired: true,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return tr.required(tr.customer);
//                           }
//                           return null;
//                         },
//                         bloc: context.read<IndividualsBloc>(),
//                         fetchAllFunction: (bloc) =>
//                             bloc.add(const LoadIndividualsEvent()),
//                         searchFunction: (bloc, query) =>
//                             bloc.add(LoadIndividualsEvent(search: query)),
//                         itemBuilder: (context, ind) => Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text(
//                             "${ind.perName ?? ''} ${ind.perLastName ?? ''}",
//                           ),
//                         ),
//                         itemToString: (individual) =>
//                             "${individual.perName} ${individual.perLastName}",
//                         stateToLoading: (state) =>
//                             state is IndividualLoadingState,
//                         stateToItems: (state) {
//                           if (state is IndividualLoadedState) {
//                             return state.individuals;
//                           }
//                           return [];
//                         },
//                         onSelected: (value) {
//                           _personController.text =
//                               "${value.perName} ${value.perLastName}";
//                           context.read<SaleInvoiceBloc>().add(
//                             SelectCustomerEvent(value),
//                           );
//                           context.read<AccountsBloc>().add(
//                             LoadAccountsEvent(ownerId: value.perId),
//                           );
//                           setState(() {
//                             signatory = value.perId;
//                           });
//                         },
//                         showClearButton: true,
//                       ),
//                       const SizedBox(height: 8),
//                       BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//                         builder: (context, state) {
//                           if (state is SaleInvoiceLoaded) {
//                             final current = state;
//                             return GenericTextfield<
//                               AccountsModel,
//                               AccountsBloc,
//                               AccountsState
//                             >(
//                               key: const ValueKey('account_field'),
//                               controller: _accountController,
//                               title: tr.accounts,
//                               hintText: tr.selectAccount,
//                               isRequired:
//                                   current.paymentMode != PaymentMode.cash,
//                               validator: (value) {
//                                 if (current.paymentMode != PaymentMode.cash &&
//                                     (value == null || value.isEmpty)) {
//                                   return tr.selectCreditAccountMsg;
//                                 }
//                                 return null;
//                               },
//                               bloc: context.read<AccountsBloc>(),
//                               fetchAllFunction: (bloc) => bloc.add(
//                                 LoadAccountsEvent(ownerId: signatory),
//                               ),
//                               searchFunction: (bloc, query) => bloc.add(
//                                 LoadAccountsEvent(ownerId: signatory),
//                               ),
//                               itemBuilder: (context, account) => ListTile(
//                                 visualDensity: VisualDensity(
//                                   vertical: -4,
//                                   horizontal: -4,
//                                 ),
//                                 contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 5,
//                                 ),
//                                 title: Text(account.accName ?? ''),
//                                 subtitle: Text('${account.accNumber}'),
//                                 trailing: Text(
//                                   "${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}",
//                                 ),
//                               ),
//                               itemToString: (account) =>
//                                   '${account.accName} (${account.accNumber})',
//                               stateToLoading: (state) =>
//                                   state is AccountLoadingState,
//                               stateToItems: (state) {
//                                 if (state is AccountLoadedState) {
//                                   return state.accounts;
//                                 }
//                                 return [];
//                               },
//                               onSelected: (value) {
//                                 setState(() {
//                                   _accountController.text =
//                                       '${value.accName} (${value.accNumber})';
//                                   _selectedAccountNumber = value.accNumber;
//                                 });
//                                 context.read<SaleInvoiceBloc>().add(
//                                   SelectCustomerAccountEvent(value),
//                                 );
//                               },
//                               showClearButton: true,
//                             );
//                           }
//                           return GenericTextfield<
//                             AccountsModel,
//                             AccountsBloc,
//                             AccountsState
//                           >(
//                             key: const ValueKey('account_field'),
//                             controller: _accountController,
//                             title: tr.accounts,
//                             hintText: tr.selectAccount,
//                             isRequired: false,
//                             bloc: context.read<AccountsBloc>(),
//                             fetchAllFunction: (bloc) => bloc.add(
//                               LoadAccountsFilterEvent(
//                                 include: '8',
//                                 exclude: '',
//                               ),
//                             ),
//                             searchFunction: (bloc, query) => bloc.add(
//                               LoadAccountsFilterEvent(
//                                 input: query,
//                                 include: '8',
//                                 exclude: '',
//                               ),
//                             ),
//                             itemBuilder: (context, account) => ListTile(
//                               title: Text(account.accName ?? ''),
//                               subtitle: Text(
//                                 '${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}',
//                               ),
//                               trailing: Text(account.actCurrency ?? ""),
//                             ),
//                             itemToString: (account) =>
//                                 '${account.accName} (${account.accNumber})',
//                             stateToLoading: (state) =>
//                                 state is AccountLoadingState,
//                             stateToItems: (state) {
//                               if (state is AccountLoadedState) {
//                                 return state.accounts;
//                               }
//                               return [];
//                             },
//                             onSelected: (value) {
//                               setState(() {
//                                 _accountController.text = value.accNumber
//                                     .toString();
//                               });
//                               context.read<SaleInvoiceBloc>().add(
//                                 SelectCustomerAccountEvent(value),
//                               );
//                             },
//                             showClearButton: true,
//                           );
//                         },
//                       ),
//                       if (_accountController.text.isNotEmpty) ...[
//                         const SizedBox(height: 8),
//                         ZOutlineButton(
//                           width: double.infinity,
//                           icon: Icons.alarm_rounded,
//                           onPressed: () {
//                             showDialog(
//                               context: context,
//                               builder: (context) {
//                                 return AddEditReminderView(
//                                   accNumber: _selectedAccountNumber,
//                                   dueParameter: "Receivable",
//                                   isEnable: true,
//                                 );
//                               },
//                             );
//                           },
//                           label: Text(tr.setReminder),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//
//                 // Items List
//                 Expanded(
//                   child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//                     builder: (context, state) {
//                       if (state is SaleInvoiceLoaded ||
//                           state is SaleInvoiceSaving) {
//                         final current = state is SaleInvoiceSaving
//                             ? state
//                             : (state as SaleInvoiceLoaded);
//
//                         if (current.items.isEmpty) {
//                           return Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.shopping_cart_outlined,
//                                   size: 64,
//                                   color: Theme.of(context).colorScheme.outline,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   tr.noItems,
//                                   style: Theme.of(
//                                     context,
//                                   ).textTheme.titleMedium,
//                                 ),
//                                 const SizedBox(height: 8),
//                                 ElevatedButton.icon(
//                                   onPressed: () {
//                                     context.read<SaleInvoiceBloc>().add(
//                                       AddNewSaleItemEvent(),
//                                     );
//                                   },
//                                   icon: const Icon(Icons.add),
//                                   label: Text(tr.addItem),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }
//
//                         return ListView.builder(
//                           controller: _scrollController,
//                           padding: const EdgeInsets.all(12),
//                           itemCount: current.items.length,
//                           itemBuilder: (context, index) {
//                             final item = current.items[index];
//                             return _buildMobileItemCard(item, context);
//                           },
//                         );
//                       }
//                       return const Center(child: CircularProgressIndicator());
//                     },
//                   ),
//                 ),
//
//                 // Summary Section
//                 _buildMobileSummarySection(context),
//
//                 // Add Item Button
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: ZOutlineButton(
//                     width: double.infinity,
//                     height: 45,
//                     backgroundColor: Theme.of(
//                       context,
//                     ).colorScheme.primary.withValues(alpha: .08),
//                     icon: Icons.add,
//                     label: Text(AppLocalizations.of(context)!.addItem),
//                     onPressed: () {
//                       context.read<SaleInvoiceBloc>().add(
//                         AddNewSaleItemEvent(),
//                       );
//                       // Scroll to bottom
//                       WidgetsBinding.instance.addPostFrameCallback((_) {
//                         _scrollController.animateTo(
//                           _scrollController.position.maxScrollExtent,
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeOut,
//                         );
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMobileItemCard(SaleInvoiceItem item, BuildContext context) {
//     final tr = AppLocalizations.of(context)!;
//     final color = Theme.of(context).colorScheme;
//     final visibility = context.read<SettingsVisibleBloc>().state;
//     final productController = TextEditingController(text: item.productName);
//     final qtyController = _qtyControllers.putIfAbsent(
//       item.rowId,
//       () =>
//           TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
//     );
//
//     final salePriceController = _priceControllers.putIfAbsent(
//       "sale_${item.rowId}",
//       () => TextEditingController(
//         text: item.salePrice != null && item.salePrice! > 0
//             ? item.salePrice!.toAmount()
//             : '',
//       ),
//     );
//
//     return ZCover(
//       margin: const EdgeInsets.only(bottom: 5),
//       child: Padding(
//         padding: const EdgeInsets.all(5),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   '${tr.items} #${item.rowId.length}',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: color.primary,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete_outline),
//                   onPressed: () {
//                     _priceControllers.remove("sale_${item.rowId}");
//                     _qtyControllers.remove(item.rowId);
//                     context.read<SaleInvoiceBloc>().add(
//                       RemoveSaleItemEvent(item.rowId),
//                     );
//                   },
//                 ),
//               ],
//             ),
//
//             // Product Selection using GenericUnderlineTextfield
//             GenericTextfield<ProductsStockModel, ProductsBloc, ProductsState>(
//               title: tr.products,
//               controller: productController,
//               hintText: tr.products,
//               isRequired: true,
//               bloc: context.read<ProductsBloc>(),
//               fetchAllFunction: (bloc) =>
//                   bloc.add(LoadProductsStockEvent(noStock: 1)),
//               searchFunction: (bloc, query) =>
//                   bloc.add(LoadProductsStockEvent(input: query)),
//               itemBuilder: (context, product) => ListTile(
//                 tileColor: Colors.transparent,
//                 title: Text(product.proName ?? ''),
//                 subtitle: Wrap(
//                   spacing: 8,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 4,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: color.primary.withValues(alpha: .1),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         '${tr.purchasePrice}: ${product.averagePrice?.toAmount() ?? ""}',
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 4,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: color.primary.withValues(alpha: .1),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         '${tr.salePriceBrief}: ${product.sellPrice?.toAmount() ?? ""}',
//                       ),
//                     ),
//                   ],
//                 ),
//                 trailing: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       product.available?.toAmount() ?? "",
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       product.stgName ?? "",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Theme.of(context).colorScheme.outline,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               itemToString: (product) => product.proName ?? '',
//               stateToLoading: (state) => state is ProductsLoadingState,
//               stateToItems: (state) {
//                 if (state is ProductsStockLoadedState) return state.products;
//                 return [];
//               },
//               onSelected: (product) {
//                 final purchasePrice =
//                     double.tryParse(
//                       product.averagePrice?.toAmount() ?? "0.0",
//                     ) ??
//                     0.0;
//                 final salePrice =
//                     double.tryParse(product.sellPrice?.toAmount() ?? "0.0") ??
//                     0.0;
//
//                 context.read<SaleInvoiceBloc>().add(
//                   UpdateSaleItemEvent(
//                     rowId: item.rowId,
//                     productId: product.proId.toString(),
//                     productName: product.proName ?? '',
//                     storageId: product.stkStorage,
//                     storageName: product.stgName ?? '',
//                     purPrice: purchasePrice,
//                     salePrice: salePrice,
//                   ),
//                 );
//
//                 salePriceController.text = salePrice.toAmount();
//               },
//             ),
//
//             const SizedBox(height: 12),
//
//             // Quantity and Price Row
//             Row(
//               children: [
//                 // Quantity
//                 Expanded(
//                   child: TextFormField(
//                     controller: qtyController,
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     decoration: InputDecoration(
//                       labelText: tr.qty,
//                       border: const OutlineInputBorder(),
//                       isDense: true,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 12,
//                       ),
//                     ),
//                     onChanged: (value) {
//                       if (value.isEmpty) {
//                         context.read<SaleInvoiceBloc>().add(
//                           UpdateSaleItemEvent(rowId: item.rowId, qty: 0),
//                         );
//                         return;
//                       }
//                       final qty = int.tryParse(value) ?? 0;
//                       context.read<SaleInvoiceBloc>().add(
//                         UpdateSaleItemEvent(rowId: item.rowId, qty: qty),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//
//                 // Sale Price
//                 Expanded(
//                   flex: 3,
//                   child: TextFormField(
//                     controller: salePriceController,
//                     keyboardType: const TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
//                     ],
//                     decoration: InputDecoration(
//                       labelText: tr.unitPrice,
//                       border: const OutlineInputBorder(),
//                       isDense: true,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 12,
//                       ),
//                     ),
//                     onChanged: (value) {
//                       if (value.isEmpty) {
//                         context.read<SaleInvoiceBloc>().add(
//                           UpdateSaleItemEvent(rowId: item.rowId, salePrice: 0),
//                         );
//                         return;
//                       }
//                       final parsed = double.tryParse(value);
//                       if (parsed != null && parsed > 0) {
//                         context.read<SaleInvoiceBloc>().add(
//                           UpdateSaleItemEvent(
//                             rowId: item.rowId,
//                             salePrice: parsed,
//                           ),
//                         );
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // Totals Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // Total
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       tr.totalTitle,
//                       style: TextStyle(fontSize: 12, color: color.outline),
//                     ),
//                     Text(
//                       item.totalSale.toAmount(),
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: color.primary,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 // Profit if available
//                 if (item.purPrice != null &&
//                     item.purPrice! > 0 &&
//                     item.salePrice != null &&
//                     item.salePrice! > 0)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       if (visibility.benefit) ...[
//                         Text(
//                           tr.profit,
//                           style: TextStyle(fontSize: 12, color: color.outline),
//                         ),
//                         Text(
//                           (item.totalSale - item.totalPurchase).toAmount(),
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: (item.totalSale - item.totalPurchase) >= 0
//                                 ? Colors.green
//                                 : Colors.red,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//
//                 // Storage
//                 if (item.storageName.isNotEmpty)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: color.primary.withValues(alpha: .1),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       item.storageName,
//                       style: TextStyle(fontSize: 12, color: color.primary),
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMobileSummarySection(BuildContext context) {
//     final color = Theme.of(context).colorScheme;
//     final tr = AppLocalizations.of(context)!;
//     final visibility = context.read<SettingsVisibleBloc>().state;
//     return BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//       builder: (context, state) {
//         if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
//           final current = state is SaleInvoiceSaving
//               ? state
//               : (state as SaleInvoiceLoaded);
//
//           return Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: color.surface,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: .05),
//                   blurRadius: 4,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Payment Method
//                 InkWell(
//                   onTap: () => _showPaymentModeDialog(current),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 8,
//                       horizontal: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: color.primary.withValues(alpha: .05),
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           tr.paymentMethod,
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         Row(
//                           children: [
//                             Text(
//                               _getPaymentModeLabel(current.paymentMode),
//                               style: TextStyle(color: color.primary),
//                             ),
//                             const SizedBox(width: 4),
//                             Icon(Icons.edit, size: 16, color: color.primary),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//
//                 // Totals
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(tr.grandTotal),
//                     Text(
//                       "${current.grandTotal.toAmount()} $baseCurrency",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: color.primary,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//
//                 // Profit
//                 if (visibility.benefit) ...[
//                   if (current.totalPurchaseCost > 0)
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(tr.profit),
//                         Text(
//                           "${current.totalProfit.toAmount()} $baseCurrency (${current.profitPercentage.toStringAsFixed(2)}%)",
//                           style: TextStyle(
//                             color: current.totalProfit >= 0
//                                 ? Colors.green
//                                 : Colors.red,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                 ],
//
//                 // Payment breakdown
//                 if (current.paymentMode == PaymentMode.cash) ...[
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(tr.cashReceipt),
//                       Text(
//                         current.cashPayment.toAmount(),
//                         style: const TextStyle(color: Colors.green),
//                       ),
//                     ],
//                   ),
//                 ] else if (current.paymentMode == PaymentMode.credit) ...[
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(tr.accountPayment),
//                       Text(
//                         current.creditAmount.toAmount(),
//                         style: const TextStyle(color: Colors.orange),
//                       ),
//                     ],
//                   ),
//                 ] else if (current.paymentMode == PaymentMode.mixed) ...[
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(tr.accountPayment),
//                       Text(
//                         current.creditAmount.toAmount(),
//                         style: const TextStyle(color: Colors.orange),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(tr.cashPayment),
//                       Text(
//                         current.cashPayment.toAmount(),
//                         style: const TextStyle(color: Colors.green),
//                       ),
//                     ],
//                   ),
//                 ],
//
//                 // Account info if available
//                 if (current.customerAccount != null &&
//                     current.creditAmount > 0) ...[
//                   const Divider(height: 12),
//                   Text(
//                     '${current.customerAccount!.accNumber} | ${current.customerAccount!.accName}',
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(tr.currentBalance),
//                       Text(
//                         current.currentBalance.toAmount(),
//                         style: TextStyle(
//                           color: _getBalanceColor(current.currentBalance),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(tr.newBalance),
//                       Text(
//                         (current.currentBalance - current.creditAmount)
//                             .toAmount(),
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: _getBalanceColor(
//                             current.currentBalance - current.creditAmount,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ],
//             ),
//           );
//         }
//         return const SizedBox();
//       },
//     );
//   }
//
//   void _showPaymentModeDialog(SaleInvoiceLoaded current) {
//     final tr = AppLocalizations.of(context)!;
//     final color = Theme.of(context).colorScheme;
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (context) => Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               tr.selectPaymentMethod,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: color.primary.withValues(alpha: .05),
//                 child: Icon(
//                   Icons.money,
//                   color: current.paymentMode == PaymentMode.cash
//                       ? color.primary
//                       : color.outline,
//                 ),
//               ),
//               title: Text(tr.cashPayment),
//               subtitle: Text(tr.cashPaymentSubtitle),
//               trailing: current.paymentMode == PaymentMode.cash
//                   ? Icon(Icons.check, color: color.primary)
//                   : null,
//               onTap: () {
//                 Navigator.pop(context);
//                 _accountController.clear();
//                 context.read<SaleInvoiceBloc>().add(
//                   ClearCustomerAccountEvent(),
//                 );
//               },
//             ),
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: color.primary.withValues(alpha: .05),
//                 child: Icon(
//                   Icons.credit_card,
//                   color: current.paymentMode == PaymentMode.credit
//                       ? color.primary
//                       : color.outline,
//                 ),
//               ),
//               title: Text(tr.accountCredit),
//               subtitle: Text(tr.accountCreditSubtitle),
//               trailing: current.paymentMode == PaymentMode.credit
//                   ? Icon(Icons.check, color: color.primary)
//                   : null,
//               onTap: () {
//                 Navigator.pop(context);
//                 context.read<SaleInvoiceBloc>().add(
//                   UpdateSaleReceivePaymentEvent(0),
//                 );
//                 setState(() {});
//               },
//             ),
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: color.primary.withValues(alpha: .05),
//                 child: Icon(
//                   Icons.payments,
//                   color: current.paymentMode == PaymentMode.mixed
//                       ? color.primary
//                       : color.outline,
//                 ),
//               ),
//               title: Text(tr.combinedPayment),
//               subtitle: Text(tr.combinedPaymentSubtitle),
//               trailing: current.paymentMode == PaymentMode.mixed
//                   ? Icon(Icons.check, color: color.primary)
//                   : null,
//               onTap: () {
//                 Navigator.pop(context);
//                 _showMixedPaymentDialog(context, current);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showMixedPaymentDialog(
//     BuildContext context,
//     SaleInvoiceLoaded current,
//   ) {
//     final controller = TextEditingController();
//     final tr = AppLocalizations.of(context)!;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(tr.combinedPayment),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: controller,
//               decoration: const InputDecoration(
//                 labelText: "Account (Credit) Payment Amount",
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.number,
//               inputFormatters: [SmartThousandsDecimalFormatter()],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "${tr.grandTotal}: ${current.grandTotal.toAmount()}",
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(tr.cancel),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final cleaned = controller.text.replaceAll(',', '');
//               final creditPayment = double.tryParse(cleaned) ?? 0;
//
//               if (creditPayment <= 0) {
//                 Utils.showOverlayMessage(
//                   context,
//                   message: 'Account payment must be greater than 0',
//                   isError: true,
//                 );
//                 return;
//               }
//
//               if (creditPayment >= current.grandTotal) {
//                 Utils.showOverlayMessage(
//                   context,
//                   message:
//                       'Account payment must be less than total amount for mixed payment',
//                   isError: true,
//                 );
//                 return;
//               }
//
//               context.read<SaleInvoiceBloc>().add(
//                 UpdateSaleReceivePaymentEvent(
//                   creditPayment,
//                   isCreditAmount: true,
//                 ),
//               );
//               Navigator.pop(context);
//             },
//             child: Text(tr.submit),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _getPaymentModeLabel(PaymentMode mode) {
//     switch (mode) {
//       case PaymentMode.cash:
//         return AppLocalizations.of(context)!.cash;
//       case PaymentMode.credit:
//         return AppLocalizations.of(context)!.creditTitle;
//       case PaymentMode.mixed:
//         return AppLocalizations.of(context)!.combinedPayment;
//     }
//   }
//
//   Color _getBalanceColor(double balance) {
//     if (balance < 0) {
//       return Colors.red;
//     } else if (balance > 0) {
//       return Colors.green;
//     } else {
//       return Colors.grey;
//     }
//   }
//
//   void _saveInvoice(BuildContext context, SaleInvoiceLoaded state) {
//     if (!state.isFormValid) {
//       Utils.showOverlayMessage(
//         context,
//         message: 'Please fill all required fields correctly',
//         isError: true,
//       );
//       return;
//     }
//     final completer = Completer<String>();
//     context.read<SaleInvoiceBloc>().add(
//       SaveSaleInvoiceEvent(
//         usrName: _userName ?? '',
//         orderName: "Sale",
//         ordPersonal: state.customer!.perId!,
//         xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
//         items: state.items,
//         completer: completer,
//       ),
//     );
//   }
//
//   void _onSalePrint({String? invoiceNumber}) {
//     final state = context.read<SaleInvoiceBloc>().state;
//     SaleInvoiceLoaded? current;
//
//     if (state is SaleInvoiceLoaded) {
//       current = state;
//     } else if (state is SaleInvoiceSaved && state.invoiceData != null) {
//       current = state.invoiceData;
//     }
//
//     if (current == null) {
//       Utils.showOverlayMessage(context, message: 'Cannot print: No invoice data available', isError: true);
//       return;
//     }
//
//     final needsConversion = current.needsExchangeRate;
//
//     final List<InvoiceItem> invoiceItems = current.items.map((item) {
//       return SaleInvoiceItemForPrint(
//         productName: item.productName,
//         quantity: item.qty.toDouble(),
//         unitPrice: item.salePrice ?? 0.0,
//         total: item.totalSale,
//         batch: item.batch ?? 0,
//         storageName: item.storageName,
//         purchasePrice: item.purPrice ?? 0.0,
//         profit: (item.salePrice ?? 0.0) - (item.purPrice ?? 0.0),
//         localAmount: needsConversion ? item.singleLocalAmount : null,
//         localCurrency: needsConversion ? current?.toCurrency : null,
//         exchangeRate: needsConversion ? current?.safeExchangeRate : null,
//       );
//     }).toList();
//
//     showDialog(
//       context: context,
//       builder: (_) => PrintPreviewDialog<dynamic>(
//         data: null,
//         company: company,
//         buildPreview: ({required data, required language, required orientation, required pageFormat}) {
//           return InvoicePrintService().printInvoicePreview(
//             invoiceType: "Sale",
//             invoiceNumber: invoiceNumber ?? "",
//             reference: _xRefController.text,
//             invoiceDate: DateTime.now(),
//             customerSupplierName: current!.customer?.perName ?? "",
//             items: invoiceItems,
//             grandTotal: current.grandTotal,
//             cashPayment: current.cashPayment,
//             creditAmount: current.creditAmount,
//             account: current.customerAccount,
//             language: language,
//             orientation: orientation,
//             company: company,
//             pageFormat: pageFormat,
//             currency: baseCurrency,
//             isSale: true,
//             totalLocalAmount: needsConversion ? current.totalLocalAmount : null,
//             localCurrency: needsConversion ? current.toCurrency : null,
//             exchangeRate: needsConversion ? current.safeExchangeRate : null,
//             subtotal: current.subtotal,
//             totalItemDiscount: current.totalItemDiscount,
//             generalDiscount: current.generalDiscountAmount,
//             extraCharges: current.extraCharges,
//           );
//         },
//         onPrint: ({required data, required language, required orientation, required pageFormat, required selectedPrinter, required copies, required pages}) {
//           return InvoicePrintService().printInvoiceDocument(
//             invoiceType: "Sale",
//             invoiceNumber: invoiceNumber ?? "",
//             reference: _xRefController.text,
//             invoiceDate: DateTime.now(),
//             customerSupplierName: current!.customer?.perName ?? "",
//             items: invoiceItems,
//             grandTotal: current.grandTotal,
//             cashPayment: current.cashPayment,
//             creditAmount: current.creditAmount,
//             account: current.customerAccount,
//             language: language,
//             orientation: orientation,
//             company: company,
//             selectedPrinter: selectedPrinter,
//             pageFormat: pageFormat,
//             copies: copies,
//             currency: baseCurrency,
//             isSale: true,
//             totalLocalAmount: needsConversion ? current.totalLocalAmount : null,
//             localCurrency: needsConversion ? current.toCurrency : null,
//             exchangeRate: needsConversion ? current.safeExchangeRate : null,
//             subtotal: current.subtotal,
//             totalItemDiscount: current.totalItemDiscount,
//             generalDiscount: current.generalDiscountAmount,
//             extraCharges: current.extraCharges,
//           );
//         },
//         onSave: ({required data, required language, required orientation, required pageFormat}) {
//           return InvoicePrintService().createInvoiceDocument(
//             invoiceType: "Sale",
//             invoiceNumber: invoiceNumber ?? "",
//             reference: _xRefController.text,
//             invoiceDate: DateTime.now(),
//             customerSupplierName: current!.customer?.perName ?? "",
//             items: invoiceItems,
//             grandTotal: current.grandTotal,
//             cashPayment: current.cashPayment,
//             creditAmount: current.creditAmount,
//             account: current.customerAccount,
//             language: language,
//             orientation: orientation,
//             company: company,
//             pageFormat: pageFormat,
//             currency: baseCurrency,
//             isSale: true,
//             totalLocalAmount: needsConversion ? current.totalLocalAmount : null,
//             localCurrency: needsConversion ? current.toCurrency : null,
//             exchangeRate: needsConversion ? current.safeExchangeRate : null,
//             subtotal: current.subtotal,
//             totalItemDiscount: current.totalItemDiscount,
//             generalDiscount: current.generalDiscountAmount,
//             extraCharges: current.extraCharges,
//           );
//         },
//       ),
//     );
//   }
// }
//
// // Tablet Version (Enhanced Mobile Version)
// class _TabletNewSaleView extends StatefulWidget {
//   const _TabletNewSaleView();
//
//   @override
//   State<_TabletNewSaleView> createState() => _TabletNewSaleViewState();
// }
// class _TabletNewSaleViewState extends State<_TabletNewSaleView> {
//   final TextEditingController _accountController = TextEditingController();
//   final TextEditingController _personController = TextEditingController();
//   final TextEditingController _xRefController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   Uint8List _companyLogo = Uint8List(0);
//   final company = ReportModel();
//   String? _userName;
//   String? baseCurrency;
//   int? signatory;
//   int? _selectedAccountNumber;
//
//   final Map<String, TextEditingController> _priceControllers = {};
//   final Map<String, TextEditingController> _qtyControllers = {};
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<SaleInvoiceBloc>().add(InitializeSaleInvoiceEvent());
//     });
//
//     final companyState = context.read<CompanyProfileBloc>().state;
//     if (companyState is CompanyProfileLoadedState) {
//       baseCurrency = companyState.company.comLocalCcy ?? "";
//       company.comName = companyState.company.comName ?? "";
//       company.comAddress = companyState.company.addName ?? "";
//       company.compPhone = companyState.company.comPhone ?? "";
//       company.comEmail = companyState.company.comEmail ?? "";
//       company.statementDate = DateTime.now().toFullDateTime;
//       final base64Logo = companyState.company.comLogo;
//       if (base64Logo != null && base64Logo.isNotEmpty) {
//         try {
//           _companyLogo = base64Decode(base64Logo);
//           company.comLogo = _companyLogo;
//         } catch (e) {
//           _companyLogo = Uint8List(0);
//         }
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _accountController.dispose();
//     _personController.dispose();
//     _xRefController.dispose();
//     _scrollController.dispose();
//
//     for (final controller in _priceControllers.values) {
//       controller.dispose();
//     }
//     for (final controller in _qtyControllers.values) {
//       controller.dispose();
//     }
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final tr = AppLocalizations.of(context)!;
//     final state = context.watch<AuthBloc>().state;
//
//     if (state is! AuthenticatedState) {
//       return const SizedBox();
//     }
//
//     final login = state.loginData;
//     _userName = login.usrName ?? "";
//
//     return BlocListener<AuthBloc, AuthState>(
//       listener: (context, state) {
//         if (state is AuthenticatedState) {
//           _userName = state.loginData.usrName ?? '';
//         }
//       },
//       child: BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
//         listener: (context, state) {
//           if (state is SaleInvoiceError) {
//             Utils.showOverlayMessage(
//               context,
//               message: state.message,
//               isError: true,
//             );
//           }
//           if (state is SaleInvoiceSaved) {
//             Navigator.of(context).pop();
//             if (state.success) {
//               String? savedInvoiceNumber = state.invoiceNumber;
//
//               Utils.showOverlayMessage(
//                 context,
//                 title: tr.successTitle,
//                 message: tr.successPurchaseInvoiceMsg,
//                 isError: false,
//               );
//               _accountController.clear();
//               _personController.clear();
//               _xRefController.clear();
//
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (savedInvoiceNumber != null &&
//                     savedInvoiceNumber.isNotEmpty) {
//                   _onSalePrint(invoiceNumber: savedInvoiceNumber);
//                 }
//               });
//             } else {
//               Utils.showOverlayMessage(
//                 context,
//                 message: "Failed to create invoice",
//                 isError: true,
//               );
//             }
//           }
//         },
//         child: Scaffold(
//           backgroundColor: Theme.of(context).colorScheme.surface,
//           appBar: AppBar(
//             title: Text(tr.saleEntry),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.print),
//                 onPressed: () => _onSalePrint(invoiceNumber: null),
//               ),
//               BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//                 builder: (context, state) {
//                   if (state is SaleInvoiceLoaded ||
//                       state is SaleInvoiceSaving) {
//                     final current = state is SaleInvoiceSaving
//                         ? state
//                         : (state as SaleInvoiceLoaded);
//                     final isSaving = state is SaleInvoiceSaving;
//
//                     return IconButton(
//                       icon: isSaving
//                           ? SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Theme.of(context).colorScheme.primary,
//                               ),
//                             )
//                           : const Icon(Icons.save),
//                       onPressed: (isSaving || !current.isFormValid)
//                           ? null
//                           : () => _saveInvoice(context, current),
//                     );
//                   }
//                   return const SizedBox();
//                 },
//               ),
//             ],
//           ),
//           body: Form(
//             key: _formKey,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   // Customer and Account Selection - Row layout for tablet
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child:
//                             GenericTextfield<
//                               IndividualsModel,
//                               IndividualsBloc,
//                               IndividualsState
//                             >(
//                               key: const ValueKey('person_field'),
//                               controller: _personController,
//                               title: tr.customer,
//                               hintText: tr.customer,
//                               isRequired: true,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return tr.required(tr.customer);
//                                 }
//                                 return null;
//                               },
//                               bloc: context.read<IndividualsBloc>(),
//                               fetchAllFunction: (bloc) =>
//                                   bloc.add(const LoadIndividualsEvent()),
//                               searchFunction: (bloc, query) =>
//                                   bloc.add(LoadIndividualsEvent(search: query)),
//                               itemBuilder: (context, ind) => Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(
//                                   "${ind.perName ?? ''} ${ind.perLastName ?? ''}",
//                                 ),
//                               ),
//                               itemToString: (individual) =>
//                                   "${individual.perName} ${individual.perLastName}",
//                               stateToLoading: (state) =>
//                                   state is IndividualLoadingState,
//                               stateToItems: (state) {
//                                 if (state is IndividualLoadedState) {
//                                   return state.individuals;
//                                 }
//                                 return [];
//                               },
//                               onSelected: (value) {
//                                 _personController.text =
//                                     "${value.perName} ${value.perLastName}";
//                                 context.read<SaleInvoiceBloc>().add(
//                                   SelectCustomerEvent(value),
//                                 );
//                                 context.read<AccountsBloc>().add(
//                                   LoadAccountsEvent(ownerId: value.perId),
//                                 );
//                                 setState(() {
//                                   signatory = value.perId;
//                                 });
//                               },
//                               showClearButton: true,
//                             ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//                           builder: (context, state) {
//                             if (state is SaleInvoiceLoaded) {
//                               final current = state;
//                               return GenericTextfield<
//                                 AccountsModel,
//                                 AccountsBloc,
//                                 AccountsState
//                               >(
//                                 key: const ValueKey('account_field'),
//                                 controller: _accountController,
//                                 title: tr.accounts,
//                                 hintText: tr.selectAccount,
//                                 isRequired:
//                                     current.paymentMode != PaymentMode.cash,
//                                 validator: (value) {
//                                   if (current.paymentMode != PaymentMode.cash &&
//                                       (value == null || value.isEmpty)) {
//                                     return tr.selectCreditAccountMsg;
//                                   }
//                                   return null;
//                                 },
//                                 bloc: context.read<AccountsBloc>(),
//                                 fetchAllFunction: (bloc) => bloc.add(
//                                   LoadAccountsEvent(ownerId: signatory),
//                                 ),
//                                 searchFunction: (bloc, query) => bloc.add(
//                                   LoadAccountsEvent(ownerId: signatory),
//                                 ),
//                                 itemBuilder: (context, account) => ListTile(
//                                   visualDensity: VisualDensity(
//                                     vertical: -4,
//                                     horizontal: -4,
//                                   ),
//                                   contentPadding: EdgeInsets.symmetric(
//                                     horizontal: 5,
//                                   ),
//                                   title: Text(account.accName ?? ''),
//                                   subtitle: Text('${account.accNumber}'),
//                                   trailing: Text(
//                                     "${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}",
//                                   ),
//                                 ),
//                                 itemToString: (account) =>
//                                     '${account.accName} (${account.accNumber})',
//                                 stateToLoading: (state) =>
//                                     state is AccountLoadingState,
//                                 stateToItems: (state) {
//                                   if (state is AccountLoadedState) {
//                                     return state.accounts;
//                                   }
//                                   return [];
//                                 },
//                                 onSelected: (value) {
//                                   setState(() {
//                                     _accountController.text =
//                                         '${value.accName} (${value.accNumber})';
//                                     _selectedAccountNumber = value.accNumber;
//                                   });
//                                   context.read<SaleInvoiceBloc>().add(
//                                     SelectCustomerAccountEvent(value),
//                                   );
//                                 },
//                                 showClearButton: true,
//                               );
//                             }
//                             return GenericTextfield<
//                               AccountsModel,
//                               AccountsBloc,
//                               AccountsState
//                             >(
//                               key: const ValueKey('account_field'),
//                               controller: _accountController,
//                               title: tr.accounts,
//                               hintText: tr.selectAccount,
//                               isRequired: false,
//                               bloc: context.read<AccountsBloc>(),
//                               fetchAllFunction: (bloc) => bloc.add(
//                                 LoadAccountsFilterEvent(
//                                   include: '8',
//                                   exclude: '',
//                                 ),
//                               ),
//                               searchFunction: (bloc, query) => bloc.add(
//                                 LoadAccountsFilterEvent(
//                                   input: query,
//                                   include: '8',
//                                   exclude: '',
//                                 ),
//                               ),
//                               itemBuilder: (context, account) => ListTile(
//                                 title: Text(account.accName ?? ''),
//                                 subtitle: Text(
//                                   '${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}',
//                                 ),
//                                 trailing: Text(account.actCurrency ?? ""),
//                               ),
//                               itemToString: (account) =>
//                                   '${account.accName} (${account.accNumber})',
//                               stateToLoading: (state) =>
//                                   state is AccountLoadingState,
//                               stateToItems: (state) {
//                                 if (state is AccountLoadedState) {
//                                   return state.accounts;
//                                 }
//                                 return [];
//                               },
//                               onSelected: (value) {
//                                 setState(() {
//                                   _accountController.text = value.accNumber
//                                       .toString();
//                                 });
//                                 context.read<SaleInvoiceBloc>().add(
//                                   SelectCustomerAccountEvent(value),
//                                 );
//                               },
//                               showClearButton: true,
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (_accountController.text.isNotEmpty) ...[
//                     const SizedBox(height: 12),
//                     ZOutlineButton(
//                       width: 200,
//                       icon: Icons.alarm_rounded,
//                       onPressed: () {
//                         showDialog(
//                           context: context,
//                           builder: (context) {
//                             return AddEditReminderView(
//                               accNumber: _selectedAccountNumber,
//                               dueParameter: "Receivable",
//                               isEnable: true,
//                             );
//                           },
//                         );
//                       },
//                       label: Text(tr.setReminder),
//                     ),
//                   ],
//                   const SizedBox(height: 16),
//
//                   // Items Header
//                   _buildItemsHeader(context),
//                   const SizedBox(height: 8),
//
//                   // Items List - Using card layout but more compact than mobile
//                   Expanded(
//                     child: BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//                       builder: (context, state) {
//                         if (state is SaleInvoiceLoaded ||
//                             state is SaleInvoiceSaving) {
//                           final current = state is SaleInvoiceSaving
//                               ? state
//                               : (state as SaleInvoiceLoaded);
//
//                           if (current.items.isEmpty) {
//                             return Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.shopping_cart_outlined,
//                                     size: 64,
//                                     color: Theme.of(
//                                       context,
//                                     ).colorScheme.outline,
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Text(
//                                     tr.noItems,
//                                     style: Theme.of(
//                                       context,
//                                     ).textTheme.titleMedium,
//                                   ),
//                                   const SizedBox(height: 8),
//                                   ElevatedButton.icon(
//                                     onPressed: () {
//                                       context.read<SaleInvoiceBloc>().add(
//                                         AddNewSaleItemEvent(),
//                                       );
//                                     },
//                                     icon: const Icon(Icons.add),
//                                     label: Text(tr.addItem),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }
//
//                           return ListView.builder(
//                             controller: _scrollController,
//                             itemCount: current.items.length,
//                             itemBuilder: (context, index) {
//                               final item = current.items[index];
//                               return _buildTabletItemCard(item, context);
//                             },
//                           );
//                         }
//                         return const Center(child: CircularProgressIndicator());
//                       },
//                     ),
//                   ),
//
//                   // Summary Section - Row layout for tablet
//                   Padding(
//                     padding: const EdgeInsets.only(top: 16),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: _buildTabletSummarySection(context),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           flex: 1,
//                           child: _buildTabletProfitSummarySection(context),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // Add Item Button
//                   Padding(
//                     padding: const EdgeInsets.only(top: 16),
//                     child: ZOutlineButton(
//                       width: 200,
//                       height: 45,
//                       backgroundColor: Theme.of(
//                         context,
//                       ).colorScheme.primary.withValues(alpha: .08),
//                       icon: Icons.add,
//                       label: Text(AppLocalizations.of(context)!.addItem),
//                       onPressed: () {
//                         context.read<SaleInvoiceBloc>().add(
//                           AddNewSaleItemEvent(),
//                         );
//                         WidgetsBinding.instance.addPostFrameCallback((_) {
//                           _scrollController.animateTo(
//                             _scrollController.position.maxScrollExtent,
//                             duration: const Duration(milliseconds: 300),
//                             curve: Curves.easeOut,
//                           );
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildItemsHeader(BuildContext context) {
//     final locale = AppLocalizations.of(context)!;
//     final color = Theme.of(context).colorScheme;
//     TextStyle? title = Theme.of(
//       context,
//     ).textTheme.titleSmall?.copyWith(color: color.surface);
//
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//       decoration: BoxDecoration(
//         color: color.primary,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Row(
//         children: [
//           SizedBox(width: 30, child: Text('#', style: title)),
//           Expanded(flex: 3, child: Text(locale.products, style: title)),
//           SizedBox(width: 80, child: Text(locale.qty, style: title)),
//           SizedBox(width: 100, child: Text(locale.unitPrice, style: title)),
//           SizedBox(width: 100, child: Text(locale.totalTitle, style: title)),
//           SizedBox(width: 100, child: Text(locale.storage, style: title)),
//           SizedBox(width: 60, child: Text(locale.actions, style: title)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTabletItemCard(SaleInvoiceItem item, BuildContext context) {
//     final tr = AppLocalizations.of(context)!;
//     final color = Theme.of(context).colorScheme;
//
//     final productController = TextEditingController(text: item.productName);
//     final qtyController = _qtyControllers.putIfAbsent(
//       item.rowId,
//       () =>
//           TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
//     );
//
//     final salePriceController = _priceControllers.putIfAbsent(
//       "sale_${item.rowId}",
//       () => TextEditingController(
//         text: item.salePrice != null && item.salePrice! > 0
//             ? item.salePrice!.toAmount()
//             : '',
//       ),
//     );
//
//     final storageController = TextEditingController(text: item.storageName);
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//             // Desktop-like row layout but adapted for tablet
//             Row(
//               children: [
//                 // Row Number
//                 SizedBox(
//                   width: 30,
//                   child: Text(
//                     item.rowId.toString(),
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//
//                 // Product Selection
//                 Expanded(
//                   flex: 3,
//                   child:
//                       GenericTextfield<
//                         ProductsStockModel,
//                         ProductsBloc,
//                         ProductsState
//                       >(
//                         title: "",
//                         controller: productController,
//                         hintText: tr.products,
//                         bloc: context.read<ProductsBloc>(),
//                         fetchAllFunction: (bloc) =>
//                             bloc.add(LoadProductsStockEvent(noStock: 1)),
//                         searchFunction: (bloc, query) =>
//                             bloc.add(LoadProductsStockEvent(input: query)),
//                         itemBuilder: (context, product) => ListTile(
//                           tileColor: Colors.transparent,
//                           title: Text(product.proName ?? ''),
//                           subtitle: Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 4,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: color.primary.withValues(alpha: .1),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   '${tr.purchasePrice}: ${product.averagePrice?.toAmount() ?? ""}',
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 4,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: color.primary.withValues(alpha: .1),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   '${tr.salePriceBrief}: ${product.sellPrice?.toAmount() ?? ""}',
//                                 ),
//                               ),
//                             ],
//                           ),
//                           trailing: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text(
//                                 product.available?.toAmount() ?? "",
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               Text(
//                                 product.stgName ?? "",
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Theme.of(context).colorScheme.outline,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         itemToString: (product) => product.proName ?? '',
//                         stateToLoading: (state) =>
//                             state is ProductsLoadingState,
//                         stateToItems: (state) {
//                           if (state is ProductsStockLoadedState) {
//                             return state.products;
//                           }
//                           return [];
//                         },
//                         onSelected: (product) {
//                           final purchasePrice =
//                               double.tryParse(
//                                 product.averagePrice?.toAmount() ?? "0.0",
//                               ) ??
//                               0.0;
//                           final salePrice =
//                               double.tryParse(
//                                 product.sellPrice?.toAmount() ?? "0.0",
//                               ) ??
//                               0.0;
//
//                           context.read<SaleInvoiceBloc>().add(
//                             UpdateSaleItemEvent(
//                               rowId: item.rowId,
//                               productId: product.proId.toString(),
//                               productName: product.proName ?? '',
//                               storageId: product.stkStorage,
//                               storageName: product.stgName ?? '',
//                               purPrice: purchasePrice,
//                               salePrice: salePrice,
//                             ),
//                           );
//
//                           salePriceController.text = salePrice.toAmount();
//                           storageController.text = product.stgName ?? '';
//                         },
//                       ),
//                 ),
//
//                 // Quantity
//                 SizedBox(
//                   width: 80,
//                   child: TextFormField(
//                     controller: qtyController,
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     decoration: const InputDecoration(
//                       border: InputBorder.none,
//                       isDense: true,
//                     ),
//                     onChanged: (value) {
//                       if (value.isEmpty) {
//                         context.read<SaleInvoiceBloc>().add(
//                           UpdateSaleItemEvent(rowId: item.rowId, qty: 0),
//                         );
//                         return;
//                       }
//                       final qty = int.tryParse(value) ?? 0;
//                       context.read<SaleInvoiceBloc>().add(
//                         UpdateSaleItemEvent(rowId: item.rowId, qty: qty),
//                       );
//                     },
//                   ),
//                 ),
//
//                 // Sale Price
//                 SizedBox(
//                   width: 100,
//                   child: TextFormField(
//                     controller: salePriceController,
//                     keyboardType: const TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
//                     ],
//                     decoration: const InputDecoration(
//                       border: InputBorder.none,
//                       isDense: true,
//                     ),
//                     onChanged: (value) {
//                       if (value.isEmpty) {
//                         context.read<SaleInvoiceBloc>().add(
//                           UpdateSaleItemEvent(rowId: item.rowId, salePrice: 0),
//                         );
//                         return;
//                       }
//                       final parsed = double.tryParse(value);
//                       if (parsed != null && parsed > 0) {
//                         context.read<SaleInvoiceBloc>().add(
//                           UpdateSaleItemEvent(
//                             rowId: item.rowId,
//                             salePrice: parsed,
//                           ),
//                         );
//                       }
//                     },
//                   ),
//                 ),
//
//                 // Total
//                 SizedBox(
//                   width: 100,
//                   child: Text(
//                     item.totalSale.toAmount(),
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: color.primary,
//                     ),
//                   ),
//                 ),
//
//                 // Storage
//                 SizedBox(
//                   width: 100,
//                   child: Text(
//                     item.storageName,
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                 ),
//
//                 // Actions
//                 SizedBox(
//                   width: 60,
//                   child: IconButton(
//                     icon: const Icon(Icons.delete_outline, size: 20),
//                     onPressed: () {
//                       _priceControllers.remove("sale_${item.rowId}");
//                       _qtyControllers.remove(item.rowId);
//                       context.read<SaleInvoiceBloc>().add(
//                         RemoveSaleItemEvent(item.rowId),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//
//             // Profit info if available (shown below the row for tablet)
//             if (item.purPrice != null &&
//                 item.purPrice! > 0 &&
//                 item.salePrice != null &&
//                 item.salePrice! > 0)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8, left: 30),
//                 child: Row(
//                   children: [
//                     Text(
//                       '${tr.profit}: ${(item.totalSale - item.totalPurchase).toAmount()}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: (item.totalSale - item.totalPurchase) >= 0
//                             ? Colors.green
//                             : Colors.red,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTabletSummarySection(BuildContext context) {
//     final color = Theme.of(context).colorScheme;
//     final tr = AppLocalizations.of(context)!;
//
//     return BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//       builder: (context, state) {
//         if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
//           final current = state is SaleInvoiceSaving
//               ? state
//               : (state as SaleInvoiceLoaded);
//
//           return Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: color.surface,
//               border: Border.all(color: color.outline.withValues(alpha: .3)),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       tr.paymentMethod,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     InkWell(
//                       onTap: () => _showPaymentModeDialog(current),
//                       child: Row(
//                         children: [
//                           Text(
//                             _getPaymentModeLabel(current.paymentMode),
//                             style: TextStyle(color: color.primary),
//                           ),
//                           const SizedBox(width: 4),
//                           Icon(Icons.edit, size: 16, color: color.primary),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Divider(color: color.outline.withValues(alpha: .2)),
//
//                 // Grand Total
//                 _buildSummaryRow(
//                   label: tr.grandTotal,
//                   value: current.grandTotal,
//                   isBold: true,
//                 ),
//                 Divider(color: color.outline.withValues(alpha: .2)),
//
//                 // Payment Breakdown
//                 if (current.paymentMode == PaymentMode.cash) ...[
//                   _buildSummaryRow(
//                     label: tr.cashPayment,
//                     value: current.cashPayment,
//                     color: Colors.green,
//                   ),
//                 ] else if (current.paymentMode == PaymentMode.credit) ...[
//                   _buildSummaryRow(
//                     label: tr.accountPayment,
//                     value: current.creditAmount,
//                     color: Colors.orange,
//                   ),
//                 ] else if (current.paymentMode == PaymentMode.mixed) ...[
//                   _buildSummaryRow(
//                     label: tr.accountPayment,
//                     value: current.creditAmount,
//                     color: Colors.orange,
//                   ),
//                   const SizedBox(height: 4),
//                   _buildSummaryRow(
//                     label: tr.cashPayment,
//                     value: current.cashPayment,
//                     color: Colors.green,
//                   ),
//                 ],
//
//                 // Account Information
//                 if (current.customerAccount != null &&
//                     current.creditAmount > 0) ...[
//                   Divider(color: color.outline.withValues(alpha: .2)),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 4.0),
//                     child: Text(
//                       '${current.customerAccount!.accNumber} | ${current.customerAccount!.accName}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   _buildSummaryRow(
//                     label: tr.currentBalance,
//                     value: current.currentBalance,
//                     color: _getBalanceColor(current.currentBalance),
//                   ),
//                   const SizedBox(height: 4),
//                   _buildSummaryRow(
//                     label: tr.invoiceAmount,
//                     value: current.creditAmount,
//                     color: Colors.orange,
//                   ),
//                   const SizedBox(height: 4),
//                   _buildSummaryRow(
//                     label: tr.newBalance,
//                     value: current.currentBalance - current.creditAmount,
//                     isBold: true,
//                     color: _getBalanceColor(
//                       current.currentBalance - current.creditAmount,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         }
//         return const SizedBox();
//       },
//     );
//   }
//
//   Widget _buildTabletProfitSummarySection(BuildContext context) {
//     final color = Theme.of(context).colorScheme;
//     final tr = AppLocalizations.of(context)!;
//
//     return BlocBuilder<SaleInvoiceBloc, SaleInvoiceState>(
//       builder: (context, state) {
//         if (state is SaleInvoiceLoaded || state is SaleInvoiceSaving) {
//           final current = state is SaleInvoiceSaving
//               ? state
//               : (state as SaleInvoiceLoaded);
//
//           return Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: color.surface,
//               border: Border.all(color: color.outline.withValues(alpha: .3)),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       tr.profitSummary,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Icon(Icons.ssid_chart, size: 22, color: color.primary),
//                   ],
//                 ),
//                 Divider(color: color.outline.withValues(alpha: .2)),
//                 _buildSummaryRow(
//                   label: tr.totalCost,
//                   value: current.totalPurchaseCost,
//                   color: color.primary.withValues(alpha: .9),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildSummaryRow(
//                   label: tr.profit,
//                   value: current.totalProfit,
//                   color: current.totalProfit >= 0 ? Colors.green : Colors.red,
//                   isBold: true,
//                 ),
//                 if (current.totalPurchaseCost > 0) ...[
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text('${tr.profit} %'),
//                       Text(
//                         '${current.profitPercentage.toStringAsFixed(2)}%',
//                         style: TextStyle(
//                           color: current.totalProfit >= 0
//                               ? Colors.green
//                               : Colors.red,
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ],
//             ),
//           );
//         }
//         return const SizedBox();
//       },
//     );
//   }
//
//   Widget _buildSummaryRow({
//     required String label,
//     required double value,
//     bool isBold = false,
//     Color? color,
//   }) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//             fontSize: isBold ? 16 : 14,
//           ),
//         ),
//         Text(
//           "${value.toAmount()} $baseCurrency",
//           style: TextStyle(
//             fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//             fontSize: isBold ? 16 : 14,
//             color: color ?? Theme.of(context).colorScheme.primary,
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _showPaymentModeDialog(SaleInvoiceLoaded current) {
//     final tr = AppLocalizations.of(context)!;
//     final color = Theme.of(context).colorScheme;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(tr.selectPaymentMethod),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: color.primary.withValues(alpha: .05),
//                 child: Icon(
//                   Icons.money,
//                   color: current.paymentMode == PaymentMode.cash
//                       ? color.primary
//                       : color.outline,
//                 ),
//               ),
//               title: Text(tr.cashPayment),
//               subtitle: Text(tr.cashPaymentSubtitle),
//               trailing: current.paymentMode == PaymentMode.cash
//                   ? Icon(Icons.check, color: color.primary)
//                   : null,
//               onTap: () {
//                 Navigator.pop(context);
//                 _accountController.clear();
//                 context.read<SaleInvoiceBloc>().add(
//                   ClearCustomerAccountEvent(),
//                 );
//               },
//             ),
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: color.primary.withValues(alpha: .05),
//                 child: Icon(
//                   Icons.credit_card,
//                   color: current.paymentMode == PaymentMode.credit
//                       ? color.primary
//                       : color.outline,
//                 ),
//               ),
//               title: Text(tr.accountCredit),
//               subtitle: Text(tr.accountCreditSubtitle),
//               trailing: current.paymentMode == PaymentMode.credit
//                   ? Icon(Icons.check, color: color.primary)
//                   : null,
//               onTap: () {
//                 Navigator.pop(context);
//                 context.read<SaleInvoiceBloc>().add(
//                   UpdateSaleReceivePaymentEvent(0),
//                 );
//                 setState(() {});
//               },
//             ),
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: color.primary.withValues(alpha: .05),
//                 child: Icon(
//                   Icons.payments,
//                   color: current.paymentMode == PaymentMode.mixed
//                       ? color.primary
//                       : color.outline,
//                 ),
//               ),
//               title: Text(tr.combinedPayment),
//               subtitle: Text(tr.combinedPaymentSubtitle),
//               trailing: current.paymentMode == PaymentMode.mixed
//                   ? Icon(Icons.check, color: color.primary)
//                   : null,
//               onTap: () {
//                 Navigator.pop(context);
//                 _showMixedPaymentDialog(context, current);
//               },
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(tr.cancel),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showMixedPaymentDialog(
//     BuildContext context,
//     SaleInvoiceLoaded current,
//   ) {
//     final controller = TextEditingController();
//     final tr = AppLocalizations.of(context)!;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(tr.combinedPayment),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: controller,
//               decoration: const InputDecoration(
//                 labelText: "Account (Credit) Payment Amount",
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.number,
//               inputFormatters: [SmartThousandsDecimalFormatter()],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "${tr.grandTotal}: ${current.grandTotal.toAmount()}",
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(tr.cancel),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final cleaned = controller.text.replaceAll(',', '');
//               final creditPayment = double.tryParse(cleaned) ?? 0;
//
//               if (creditPayment <= 0) {
//                 Utils.showOverlayMessage(
//                   context,
//                   message: 'Account payment must be greater than 0',
//                   isError: true,
//                 );
//                 return;
//               }
//
//               if (creditPayment >= current.grandTotal) {
//                 Utils.showOverlayMessage(
//                   context,
//                   message:
//                       'Account payment must be less than total amount for mixed payment',
//                   isError: true,
//                 );
//                 return;
//               }
//
//               context.read<SaleInvoiceBloc>().add(
//                 UpdateSaleReceivePaymentEvent(
//                   creditPayment,
//                   isCreditAmount: true,
//                 ),
//               );
//               Navigator.pop(context);
//             },
//             child: Text(tr.submit),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _getPaymentModeLabel(PaymentMode mode) {
//     switch (mode) {
//       case PaymentMode.cash:
//         return AppLocalizations.of(context)!.cash;
//       case PaymentMode.credit:
//         return AppLocalizations.of(context)!.creditTitle;
//       case PaymentMode.mixed:
//         return AppLocalizations.of(context)!.combinedPayment;
//     }
//   }
//
//   Color _getBalanceColor(double balance) {
//     if (balance < 0) {
//       return Colors.red;
//     } else if (balance > 0) {
//       return Colors.green;
//     } else {
//       return Colors.grey;
//     }
//   }
//
//   void _saveInvoice(BuildContext context, SaleInvoiceLoaded state) {
//     if (!state.isFormValid) {
//       Utils.showOverlayMessage(
//         context,
//         message: 'Please fill all required fields correctly',
//         isError: true,
//       );
//       return;
//     }
//     final completer = Completer<String>();
//     context.read<SaleInvoiceBloc>().add(
//       SaveSaleInvoiceEvent(
//         usrName: _userName ?? '',
//         orderName: "Sale",
//         ordPersonal: state.customer!.perId!,
//         xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
//         items: state.items,
//         completer: completer,
//       ),
//     );
//   }
//
//   void _onSalePrint({String? invoiceNumber}) {
//     final state = context.read<SaleInvoiceBloc>().state;
//
//     SaleInvoiceLoaded? current;
//
//     if (state is SaleInvoiceLoaded) {
//       current = state;
//     } else if (state is SaleInvoiceSaved && state.invoiceData != null) {
//       current = state.invoiceData;
//     }
//
//     if (current == null) {
//       Utils.showOverlayMessage(
//         context,
//         message: 'Cannot print: No invoice data available',
//         isError: true,
//       );
//       return;
//     }
//
//     final List<InvoiceItem> invoiceItems = current.items.map((item) {
//       return SaleInvoiceItemForPrint(
//         productName: item.productName,
//         quantity: item.qty.toDouble(),
//         unitPrice: item.salePrice ?? 0.0,
//         total: item.totalSale,
//         batch: 1,
//         storageName: item.storageName,
//         purchasePrice: item.purPrice ?? 0.0,
//         profit: (item.salePrice ?? 0.0) - (item.purPrice ?? 0.0),
//       );
//     }).toList();
//
//     showDialog(
//       context: context,
//       builder: (_) => PrintPreviewDialog<dynamic>(
//         data: null,
//         company: company,
//         buildPreview:
//             ({
//               required data,
//               required language,
//               required orientation,
//               required pageFormat,
//             }) {
//               return InvoicePrintService().printInvoicePreview(
//                 invoiceType: "Sale",
//                 invoiceNumber: invoiceNumber ?? "",
//                 reference: _xRefController.text,
//                 invoiceDate: DateTime.now(),
//                 customerSupplierName: current!.customer?.perName ?? "",
//                 items: invoiceItems,
//                 grandTotal: current.grandTotal,
//                 cashPayment: current.cashPayment,
//                 creditAmount: current.creditAmount,
//                 account: current.customerAccount,
//                 language: language,
//                 orientation: orientation,
//                 company: company,
//                 pageFormat: pageFormat,
//                 currency: baseCurrency,
//                 isSale: true,
//               );
//             },
//         onPrint:
//             ({
//               required data,
//               required language,
//               required orientation,
//               required pageFormat,
//               required selectedPrinter,
//               required copies,
//               required pages,
//             }) {
//               return InvoicePrintService().printInvoiceDocument(
//                 invoiceType: "Sale",
//                 invoiceNumber: invoiceNumber ?? "",
//                 reference: _xRefController.text,
//                 invoiceDate: DateTime.now(),
//                 customerSupplierName: current!.customer?.perName ?? "",
//                 items: invoiceItems,
//                 grandTotal: current.grandTotal,
//                 cashPayment: current.cashPayment,
//                 creditAmount: current.creditAmount,
//                 account: current.customerAccount,
//                 language: language,
//                 orientation: orientation,
//                 company: company,
//                 selectedPrinter: selectedPrinter,
//                 pageFormat: pageFormat,
//                 copies: copies,
//                 currency: baseCurrency,
//                 isSale: true,
//               );
//             },
//         onSave:
//             ({
//               required data,
//               required language,
//               required orientation,
//               required pageFormat,
//             }) {
//               return InvoicePrintService().createInvoiceDocument(
//                 invoiceType: "Sale",
//                 invoiceNumber: invoiceNumber ?? "",
//                 reference: _xRefController.text,
//                 invoiceDate: DateTime.now(),
//                 customerSupplierName: current!.customer?.perName ?? "",
//                 items: invoiceItems,
//                 grandTotal: current.grandTotal,
//                 cashPayment: current.cashPayment,
//                 creditAmount: current.creditAmount,
//                 account: current.customerAccount,
//                 language: language,
//                 orientation: orientation,
//                 company: company,
//                 pageFormat: pageFormat,
//                 currency: baseCurrency,
//                 isSale: true,
//               );
//             },
//       ),
//     );
//   }
// }