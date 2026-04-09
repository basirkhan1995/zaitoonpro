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
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Generic/underline_searchable_textfield.dart';
import '../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../Features/Other/utils.dart';
import '../../../../../../../Features/Other/zForm_dialog.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
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
  State<_DesktopPurchaseOrderView> createState() => _DesktopPurchaseOrderViewState();
}
class _DesktopPurchaseOrderViewState extends State<_DesktopPurchaseOrderView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final TextEditingController _remark = TextEditingController();
  final List<List<FocusNode>> _rowFocusNodes = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  void _showExpensesDialog(BuildContext context) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context,setState) {
            return ExpensesDialog(

            );
          }
        ),
      );
    }
  }
  String? _userName;
  String? baseCurrency;
  int? signatory;
  final Map<String, TextEditingController> _purchasePriceControllers = {};
  final Map<String, TextEditingController> _costPriceControllers = {};
  final Map<String, TextEditingController> _sellPriceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _batchControllers = {};

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
    for (final row in _rowFocusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    _accountController.dispose();
    _personController.dispose();
    _xRefController.dispose();


    // Dispose all price and qty controllers
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
      child: BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
        listener: (context, state) {
          if (state is PurchaseInvoiceError) {
            Utils.showOverlayMessage(context, message: state.message, isError: true);
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
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onPrint(invoiceNumber: savedInvoiceNumber);
                }
              });

            } else {
              Utils.showOverlayMessage(context, message: "Failed to create invoice", isError: true);
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(tr.purchaseEntry),
            titleSpacing: 0,
            actionsPadding: EdgeInsets.symmetric(horizontal: 12),
            actions: [
              ZOutlineButton(
                icon: Icons.outbond_outlined,
                onPressed: ()=> _showExpensesDialog(context),
                label: Text(tr.manageExpenses),
              ),
              const SizedBox(width: 8),
              ZOutlineButton(
                icon: FontAwesomeIcons.solidFilePdf,
                onPressed: _onPrint,
                label: Text("PDF"),
              ),
              const SizedBox(width: 8),
              //Save Button
              BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                  builder: (context, state) {
                    if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
                      final current = state is PurchaseInvoiceSaving ?
                      state : (state as PurchaseInvoiceLoaded);
                      final isSaving = state is PurchaseInvoiceSaving;

                      return ZOutlineButton(
                        isActive: true,
                        icon: Icons.save_rounded,
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
                            : Text(tr.saveTitle),
                      );
                    }
                    return const SizedBox();
                  }
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Form(
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
                            if (state is IndividualLoadedState) return state.individuals;
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
                        flex:2,
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
                                  _accountController.text = '${value.accName} (${value.accNumber})';
                                  context.read<PurchaseInvoiceBloc>().add(SelectSupplierAccountEvent(value));
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
                        child: CurrencyDropdown(
                          title: tr.invoiceCurrency,
                            onSingleChanged: (e){},
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ZTextFieldEntitled(
                            controller: _xRefController,
                            title: tr.invoiceNumber
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: ZTextFieldEntitled(
                            controller: _remark,
                            title: tr.remark,
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 8),
                  // Items Header
                  _buildItemsHeader(context),
                  const SizedBox(height: 8),
                  // In your build method, replace the Expanded child that contains the ListView
                  Expanded(
                    child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                      builder: (context, state) {
                        if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
                          final current = state is PurchaseInvoiceSaving
                              ? state
                              : (state as PurchaseInvoiceLoaded);
                          _synchronizeFocusNodes(current.items.length);

                          return SingleChildScrollView(
                            child: Column(
                              children: [

                                // Items List
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

                                const SizedBox(height: 16),

                                // Payment Summary Section
                                Row(
                                  children: [
                                    _buildSummarySection(context),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),

                  // Summary Section
                  //_buildSummarySection(context),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('#', style: title),
          )),
          Expanded(child: Text(locale.products, style: title)),
          SizedBox(width: 100, child: Text(locale.qty, style: title)),
          SizedBox(width: 100, child: Text(locale.batchTitle, style: title)),
          SizedBox(width: 100, child: Text(locale.totalTitle, style: title)),
          SizedBox(width: 150, child: Text(locale.unitPrice, style: title)),
          SizedBox(width: 150, child: Text(locale.localeAmount, style: title)),
          SizedBox(width: 150, child: Text(locale.salePercentage, style: title)),
          SizedBox(width: 150, child: Text(locale.landedPrice, style: title)),
          SizedBox(width: 180, child: Text(locale.storage, style: title)),
          SizedBox(width: 60, child: Text(locale.actions, style: title)),
        ],
      ),
    );
  }
  Widget _buildItemRow({required BuildContext context, required PurchaseInvoiceItem item, required List<FocusNode> nodes, required bool isLastRow,}) {
    final rowIndex = _rowFocusNodes.indexOf(nodes);

    return _PurchaseItemRow(
      item: item,
      nodes: nodes,
      isLastRow: isLastRow,
      rowIndex: rowIndex,
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
          final current = state is PurchaseInvoiceSaving ?
          state : (state as PurchaseInvoiceLoaded);

          // Calculate total expenses
          final totalExpenses = current.expenses.fold(0.0, (sum, expense) => sum + expense.amount);

          return Container(
            padding: const EdgeInsets.all(16),
            width: 500,
            decoration: BoxDecoration(
              color: color.surface,
              border: Border.all(color: color.outline.withValues(alpha: .2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.paymentMethod, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    InkWell(
                      onTap: () => _showPaymentModeDialog(current),
                      child: Row(
                        children: [
                          Text(_getPaymentModeLabel(current.paymentMode), style: TextStyle(color: color.primary)),
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

                // ✅ Add Total Expenses Section (if there are any expenses)
                if (totalExpenses > 0) ...[
                  _buildSummaryRow(
                    label: tr.totalExpense,
                    value: totalExpenses,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 4),
                ],

                // Payment Breakdown
                if (current.paymentMode == PaymentMode.cash) ...[
                  _buildSummaryRow(
                    label: AppLocalizations.of(context)!.cashPayment,
                    value: current.cashPayment,
                    color: Colors.green,
                  ),
                ] else if (current.paymentMode == PaymentMode.credit) ...[
                  _buildSummaryRow(
                    label: AppLocalizations.of(context)!.accountPayment,
                    value: current.creditAmount,
                    color: Colors.orange,
                  ),
                ] else if (current.paymentMode == PaymentMode.mixed) ...[
                  _buildSummaryRow(
                    label: AppLocalizations.of(context)!.accountPayment,
                    value: current.creditAmount,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    label: AppLocalizations.of(context)!.cashPayment,
                    value: current.cashPayment,
                    color: Colors.green,
                  ),
                ],

                const SizedBox(height: 4),
                Divider(color: color.outline.withValues(alpha: .2)),
                const SizedBox(height: 4),

                // Grand Total (original)
                _buildSummaryRow(
                  label: tr.grandTotal,
                  value: current.grandTotal,
                  isBold: true,
                ),

                // ✅ Optional: Show Grand Total + Expenses (Total Cost)
                if (totalExpenses > 0) ...[
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    label: "Total Cost (with Expenses)",
                    value: current.grandTotal + totalExpenses,
                    isBold: true,
                    color: Colors.purple,
                  ),
                ],

                // Account Information
                if (current.supplierAccount != null) ...[
                  const SizedBox(height: 4),
                  Divider(color: color.outline.withValues(alpha: .2)),

                  // Account details
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${current.supplierAccount!.accNumber} | ${current.supplierAccount!.accName}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Current Balance
                  _buildSummaryRow(
                    label: AppLocalizations.of(context)!.currentBalance,
                    value: current.currentBalance,
                    color: _getBalanceColor(current.currentBalance),
                  ),

                  if (current.creditAmount > 0) ...[
                    const SizedBox(height: 4),
                    _buildSummaryRow(
                      label: tr.invoiceAmount,
                      value: current.creditAmount,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 4),
                    _buildSummaryRow(
                      label: AppLocalizations.of(context)!.newBalance,
                      value: current.currentBalance + current.creditAmount,
                      isBold: true,
                      color: _getBalanceColor(current.currentBalance + current.creditAmount),
                    ),

                    // Status
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr.status,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _getBalanceStatus(current.currentBalance + current.creditAmount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getBalanceColor(current.currentBalance + current.creditAmount),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
  Color _getBalanceColor(double balance) {
    if (balance < 0) {
      return Colors.red; // Negative = Debtor (supplier owes us)
    } else if (balance > 0) {
      return Colors.green; // Positive = Creditor (we owe supplier)
    } else {
      return Colors.grey; // Zero balance
    }
  }
  String _getBalanceStatus(double balance) {
    if (balance < 0) {
      return AppLocalizations.of(context)!.debtor; // Supplier owes us
    } else if (balance > 0) {
      return AppLocalizations.of(context)!.creditor; // We owe supplier
    } else {
      return AppLocalizations.of(context)!.noAccountsFound;
    }
  }
  Widget _buildSummaryRow({required String label, required double value, bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
          ),
        ),
        Text(
          "${value.toAmount()} $baseCurrency",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
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

  void _showPaymentModeDialog(PurchaseInvoiceLoaded current) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => ZFormDialog(
        isActionTrue: false,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        title: tr.selectPaymentMethod,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            _paymentCard(
              title: tr.cashPayment,
              subtitle: tr.cashPaymentSubtitle,
              icon: Icons.payments_rounded,
              selected: current.paymentMode == PaymentMode.cash,
              color: color,
              onTap: () {
                Navigator.pop(context);
                _accountController.clear();
                context.read<PurchaseInvoiceBloc>().add(ClearSupplierAccountEvent());
              },
            ),

            _paymentCard(
              title: tr.accountCredit,
              subtitle: tr.accountCreditSubtitle,
              icon: Icons.account_balance_wallet_rounded,
              selected: current.paymentMode == PaymentMode.credit,
              color: color,
              onTap: () {
                Navigator.pop(context);
                context.read<PurchaseInvoiceBloc>().add(UpdatePurchasePaymentEvent(0));
                setState(() {});
              },
            ),

            _paymentCard(
              title: tr.combinedPayment,
              subtitle: tr.combinedPaymentSubtitle,
              icon: Icons.sync_alt_rounded,
              selected: current.paymentMode == PaymentMode.mixed,
              color: color,
              onTap: () {
                Navigator.pop(context);
                _showMixedPaymentDialog(context, current);
              },
            ),
          ],
        ),
        onAction: () => Navigator.pop(context),
      ),
    );
  }
  void _showMixedPaymentDialog(BuildContext context, PurchaseInvoiceLoaded current) {
    final controller = TextEditingController();
    final tr = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {

            double credit = double.tryParse(
                controller.text.replaceAll(',', '')) ??
                0;

            double cash = current.grandTotal - credit;

            return ZFormDialog(
              title: tr.combinedPayment,
              padding: EdgeInsets.all(12),
              actionLabel: Text(tr.submit),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  ZTextFieldEntitled(
                    title: "Credit Amount",
                    controller: controller,
                    hint: "Enter credit amount",
                    inputFormat: [SmartThousandsDecimalFormatter()],
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),

                  ZCover(
                    padding: const EdgeInsets.all(14),
                    radius: 8,
                    child: Column(
                      children: [

                        _amountRow(tr.grandTotal, current.grandTotal),

                        const Divider(height: 20),

                        _amountRow("Credit", credit, color: Colors.orange),

                        const SizedBox(height: 6),

                        _amountRow(tr.cashPayment, cash, color: Colors.green),
                      ],
                    ),
                  ),
                ],
              ),

              onAction: () {
                if (credit <= 0) {
                  Utils.showOverlayMessage(context,
                      message: 'Enter valid credit amount',
                      isError: true);
                  return;
                }

                if (credit >= current.grandTotal) {
                  Utils.showOverlayMessage(context,
                      message: 'Credit must be less than total',
                      isError: true);
                  return;
                }

                context.read<PurchaseInvoiceBloc>().add(
                  UpdatePurchasePaymentEvent(
                    credit,
                    isCreditAmount: true,
                  ),
                );

                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
  Widget _paymentCard({required String title, required String subtitle, required IconData icon, required bool selected, required ColorScheme color, required VoidCallback onTap,}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.primary : color.outline.withValues(alpha: .3),
            width: selected ? 1.5 : 1,
          ),
          color: selected ? color.primary.withValues(alpha: .06) : color.surface,
        ),
        child: Row(
          children: [

            CircleAvatar(
              radius: 22,
              backgroundColor: color.primary.withValues(alpha: .1),
              child: Icon(
                icon,
                size: 22,
                color: selected ? color.primary : color.outline,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.onSurface.withValues(alpha: .6),
                      )),
                ],
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(Icons.check_circle, color: color.primary, key: const ValueKey(1))
                  : const SizedBox(key: ValueKey(2)),
            )
          ],
        ),
      ),
    );
  }
  Widget _amountRow(String label, double value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),

        Text(
          value.toAmount(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
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
  void _autoSelectFirstStorage(BuildContext context, String rowId) {
    final storageState = context.read<StorageBloc>().state;
    if (storageState is StorageLoadedState && storageState.storage.isNotEmpty) {
      final firstStorage = storageState.storage.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
          rowId: rowId,
          storageId: firstStorage.stgId!,
          storageName: firstStorage.stgName ?? '',
        ));
      });
    }
  }
  void _saveInvoice(BuildContext context, PurchaseInvoiceLoaded state) {
    // Additional validation
    if (!state.isFormValid) {
      Utils.showOverlayMessage(context, message: 'Please fill all required fields correctly', isError: true);
      return;
    }

    final completer = Completer<String>();

    context.read<PurchaseInvoiceBloc>().add(SavePurchaseInvoiceEvent(
      usrName: _userName ?? '',
      expenses: state.expenses,
      orderName: "Purchase",
      remark: _remark.text,
      ordPersonal: state.supplier!.perId!,
      xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
      items: state.items,
      completer: completer,
    ));
  }
  void _onPrint({String? invoiceNumber}) {
    final state = context.read<PurchaseInvoiceBloc>().state;

    // Handle both loaded and saved states
    PurchaseInvoiceLoaded? current;

    if (state is PurchaseInvoiceLoaded) {
      current = state;
    } else if (state is PurchaseInvoiceSaved && state.invoiceData != null) {
      // Use the saved invoice data
      current = state.invoiceData;
    }

    if (current == null) {
      Utils.showOverlayMessage(context,
          message: 'Cannot print: No invoice data available',
          isError: true);
      return;
    }

    // Get company info
    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is! CompanyProfileLoadedState) {
      Utils.showOverlayMessage(context, message: 'Company information not available', isError: true);
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

    // Prepare invoice items for print
    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return PurchaseInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        unitPrice: item.purPrice ?? 0.0,
        batch: item.stkBatch,
        total: item.totalPurchase,
        storageName: item.storageName,
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
              invoiceType: "Purchase",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.supplierAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: false
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
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
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
              isSale: false
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
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.supplierAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: false
          );
        },
      ),
    );
  }
}

class _PurchaseItemRow extends StatefulWidget {
  final PurchaseInvoiceItem item;
  final List<FocusNode> nodes;
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

  @override
  void initState() {
    super.initState();
    _landedPriceController = TextEditingController(
      text: widget.item.landedPrice != null && widget.item.landedPrice! > 0
          ? widget.item.landedPrice!.toAmount()
          : '',
    );

    _storageController = TextEditingController(text: widget.item.storageName);
  }

  @override
  void didUpdateWidget(_PurchaseItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update landed price controller when item's landed price changes
    if (widget.item.landedPrice != oldWidget.item.landedPrice) {
      final newValue = widget.item.landedPrice != null && widget.item.landedPrice! > 0
          ? widget.item.landedPrice!.toAmount()
          : '';

      if (_landedPriceController.text != newValue) {
        _landedPriceController.text = newValue;
      }
    }

    // Update storage controller when storage name changes
    if (widget.item.storageName != oldWidget.item.storageName) {
      if (_storageController.text != widget.item.storageName) {
        _storageController.text = widget.item.storageName;
      }
    }
  }

  @override
  void dispose() {
    _landedPriceController.dispose();
    _storageController.dispose();
    super.dispose();
  }

  void focusNext(int index) {
    if (index + 1 < widget.nodes.length) {
      widget.nodes[index + 1].requestFocus();
    }
  }

  FocusNode? safeNode(int index) {
    return (index >= 0 && index < widget.nodes.length) ? widget.nodes[index] : null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    final productController = TextEditingController(text: widget.item.productName);
    final qtyController = widget.qtyControllers.putIfAbsent(
      widget.item.rowId,
          () => TextEditingController(text: widget.item.qty > 0 ? widget.item.qty.toString() : ''),
    );
    final batchController = widget.batchControllers.putIfAbsent(
      widget.item.rowId,
          () => TextEditingController(text: widget.item.stkBatch > 0 ? widget.item.stkBatch.toString() : ''),
    );
    final sellPriceController = widget.sellPriceControllers.putIfAbsent(
      widget.item.rowId,
          () => TextEditingController(text: widget.item.sellPriceAmount > 0 ? widget.item.sellPriceAmount.toString() : ''),
    );
    final priceController = widget.purchasePriceControllers.putIfAbsent(
      widget.item.rowId,
          () => TextEditingController(text: widget.item.purPrice != null && widget.item.purPrice! > 0 ? widget.item.purPrice!.toAmount() : ''),
    );

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
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

              /// Product
              Expanded(
                child: GenericUnderlineTextfield<ProductsModel, ProductsBloc, ProductsState>(
                  title: "",
                  controller: productController,
                  hintText: locale.products,
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
                    if (state is ProductsLoadedState) {
                      return state.products;
                    }
                    return [];
                  },
                  onSelected: (product) {
                    widget.onProductSelected(
                      widget.item.rowId,
                      product.proId.toString(),
                      product.proName ?? '',
                    );
                    focusNext(0);
                  },
                ),
              ),

              /// Qty
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
                  onSubmitted: (_) => focusNext(1),
                ),
              ),

              /// Batch
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
                  onSubmitted: (_) => focusNext(2),
                ),
              ),

              /// Total (qty * batch)
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

              /// Unit Price
              SizedBox(
                width: 150,
                child: TextField(
                  controller: priceController,
                  focusNode: safeNode(3),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: locale.unitPrice,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value.replaceAll(',', '')) ?? 0;
                    widget.onPurchasePriceChanged(widget.item.rowId, parsed);
                  },
                  onSubmitted: (_) => focusNext(3),
                ),
              ),


              /// Local Amount
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _landedPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: locale.localeAmount,
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

              /// Sell Price
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
                  onSubmitted: (_) => focusNext(4),
                ),
              ),

              /// Landed Price (Read-only)
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _landedPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

              /// Storage
              SizedBox(
                width: 180,
                child: BlocBuilder<StorageBloc, StorageState>(
                  builder: (context, state) {
                    final storageFocus = safeNode(5);

                    if (state is StorageLoadedState && state.storage.isNotEmpty && widget.item.storageId == 0) {
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
                      },
                    );
                  },
                ),
              ),

              /// Delete
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

        /// Add button
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
                    context.read<PurchaseInvoiceBloc>().add(AddNewPurchaseItemEvent());
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Mobile Version
class _MobilePurchaseOrderView extends StatefulWidget {
  const _MobilePurchaseOrderView();

  @override
  State<_MobilePurchaseOrderView> createState() => _MobilePurchaseOrderViewState();
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
            Utils.showOverlayMessage(context, message: state.message, isError: true);
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
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onPrint(invoiceNumber: savedInvoiceNumber);
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
            title: Text(tr.purchaseEntry),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: _onPrint,
              ),
              BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                builder: (context, state) {
                  if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
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
                      GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
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
                          if (state is IndividualLoadedState) return state.individuals;
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
                      const SizedBox(height: 8),
                      BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
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
                                if (current.paymentMode != PaymentMode.cash &&
                                    (value == null || value.isEmpty)) {
                                  return tr.selectCreditAccountMsg;
                                }
                                return null;
                              },
                              bloc: context.read<AccountsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                              searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                              itemBuilder: (context, account) => ListTile(
                                visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                                contentPadding: EdgeInsets.symmetric(horizontal: 5),
                                title: Text(account.accName ?? ''),
                                subtitle: Text('${account.accNumber}'),
                                trailing: Text(
                                    "${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}"),
                              ),
                              itemToString: (account) => '${account.accName} (${account.accNumber})',
                              stateToLoading: (state) => state is AccountLoadingState,
                              stateToItems: (state) {
                                if (state is AccountLoadedState) return state.accounts;
                                return [];
                              },
                              onSelected: (value) {
                                _accountController.text = '${value.accName} (${value.accNumber})';
                                context.read<PurchaseInvoiceBloc>().add(SelectSupplierAccountEvent(value));
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
                            fetchAllFunction: (bloc) =>
                                bloc.add(LoadAccountsFilterEvent(include: '8', exclude: '')),
                            searchFunction: (bloc, query) => bloc.add(LoadAccountsFilterEvent(
                                input: query, include: '8', exclude: '')),
                            itemBuilder: (context, account) => ListTile(
                              title: Text(account.accName ?? ''),
                              subtitle: Text(
                                  '${account.accNumber} - ${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"}'),
                              trailing: Text(account.actCurrency ?? ""),
                            ),
                            itemToString: (account) => '${account.accName} (${account.accNumber})',
                            stateToLoading: (state) => state is AccountLoadingState,
                            stateToItems: (state) {
                              if (state is AccountLoadedState) return state.accounts;
                              return [];
                            },
                            onSelected: (value) {
                              _accountController.text = '${value.accName} (${value.accNumber})';
                              context.read<PurchaseInvoiceBloc>().add(SelectSupplierAccountEvent(value));
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
                      if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
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
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<PurchaseInvoiceBloc>().add(AddNewPurchaseItemEvent());
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
                      context.read<PurchaseInvoiceBloc>().add(AddNewPurchaseItemEvent());
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
          () => TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
    );

    final priceController = _priceControllers.putIfAbsent(
      item.rowId,
          () => TextEditingController(
          text: item.purPrice != null && item.purPrice! > 0 ? item.purPrice!.toAmount() : ''),
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
                    context.read<PurchaseInvoiceBloc>().add(RemovePurchaseItemEvent(item.rowId));
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
                context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                  rowId: item.rowId,
                  productId: product.proId.toString(),
                  productName: product.proName ?? '',
                ));
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
                        context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                          rowId: item.rowId,
                          qty: 0,
                        ));
                        return;
                      }
                      final qty = int.tryParse(value) ?? 0;
                      context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                        rowId: item.rowId,
                        qty: qty,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Unit Price
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      SmartThousandsDecimalFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: tr.unitPrice,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                          rowId: item.rowId,
                          purPrice: 0,
                        ));
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
                if (storageState is StorageLoadedState && storageState.storage.isNotEmpty) {
                  if (item.storageId == 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final firstStorage = storageState.storage.first;
                      context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                        rowId: item.rowId,
                        storageId: firstStorage.stgId!,
                        storageName: firstStorage.stgName ?? '',
                      ));
                      storageController.text = firstStorage.stgName ?? '';
                    });
                  }
                }

                return GenericTextfield<StorageModel, StorageBloc, StorageState>(
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
                    context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                      rowId: item.rowId,
                      storageId: storage.stgId!,
                      storageName: storage.stgName ?? '',
                    ));
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
                  style: TextStyle(
                    fontSize: 14,
                    color: color.outline,
                  ),
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
          final current = state is PurchaseInvoiceSaving ? state : (state as PurchaseInvoiceLoaded);

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

                // Grand Total
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
                if (current.supplierAccount != null && current.creditAmount > 0) ...[
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
                        (current.currentBalance + current.creditAmount).toAmount(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getBalanceColor(current.currentBalance + current.creditAmount),
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
                  child: Icon(Icons.money,
                      color: current.paymentMode == PaymentMode.cash ? color.primary : color.outline)),
              title: Text(tr.cashPayment),
              subtitle: Text(tr.cashPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.cash ? Icon(Icons.check, color: color.primary) : null,
              onTap: () {
                Navigator.pop(context);
                _accountController.clear();
                context.read<PurchaseInvoiceBloc>().add(ClearSupplierAccountEvent());
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
                context.read<PurchaseInvoiceBloc>().add(UpdatePurchasePaymentEvent(0));
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

  void _showMixedPaymentDialog(BuildContext context, PurchaseInvoiceLoaded current) {
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

              context.read<PurchaseInvoiceBloc>().add(UpdatePurchasePaymentEvent(
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
        context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
          rowId: rowId,
          storageId: firstStorage.stgId!,
          storageName: firstStorage.stgName ?? '',
        ));
      });
    }
  }

  void _saveInvoice(BuildContext context, PurchaseInvoiceLoaded state) {
    if (!state.isFormValid) {
      Utils.showOverlayMessage(context, message: 'Please fill all required fields correctly', isError: true);
      return;
    }

    final completer = Completer<String>();

    context.read<PurchaseInvoiceBloc>().add(SavePurchaseInvoiceEvent(
      usrName: _userName ?? '',
      orderName: "Purchase",
      expenses: state.expenses,
      ordPersonal: state.supplier!.perId!,
      xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
      items: state.items,
      completer: completer,
    ));
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
      Utils.showOverlayMessage(context,
          message: 'Cannot print: No invoice data available',
          isError: true);
      return;
    }

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is! CompanyProfileLoadedState) {
      Utils.showOverlayMessage(context, message: 'Company information not available', isError: true);
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
        unitPrice: item.purPrice ?? 0.0,
        batch: item.stkBatch,
        total: item.totalPurchase,
        storageName: item.storageName,
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
              invoiceType: "Purchase",
              invoiceNumber: invoiceNumber ?? "",
              reference: _xRefController.text,
              invoiceDate: DateTime.now(),
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.supplierAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: false);
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
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
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
              isSale: false);
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
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.supplierAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: false);
        },
      ),
    );
  }
}

// Tablet Version
class _TabletPurchaseOrderView extends StatefulWidget {
  const _TabletPurchaseOrderView();

  @override
  State<_TabletPurchaseOrderView> createState() => _TabletPurchaseOrderViewState();
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
            Utils.showOverlayMessage(context, message: state.message, isError: true);
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
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onPrint(invoiceNumber: savedInvoiceNumber);
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
            title: Text(tr.purchaseEntry),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: _onPrint,
              ),
              BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                builder: (context, state) {
                  if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
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
                            if (state is IndividualLoadedState) return state.individuals;
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
                      const SizedBox(width: 12),
                      Expanded(
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
                                  if (current.paymentMode != PaymentMode.cash &&
                                      (value == null || value.isEmpty)) {
                                    return tr.selectCreditAccountMsg;
                                  }
                                  return null;
                                },
                                bloc: context.read<AccountsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                                searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: signatory)),
                                itemBuilder: (context, account) => ListTile(
                                  visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 5),
                                  title: Text(account.accName ?? ''),
                                  subtitle: Text('${account.accNumber}'),
                                  trailing: Text(
                                      "${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.0"} ${account.actCurrency}"),
                                ),
                                itemToString: (account) => '${account.accName} (${account.accNumber})',
                                stateToLoading: (state) => state is AccountLoadingState,
                                stateToItems: (state) {
                                  if (state is AccountLoadedState) return state.accounts;
                                  return [];
                                },
                                onSelected: (value) {
                                  _accountController.text = '${value.accName} (${value.accNumber})';
                                  context.read<PurchaseInvoiceBloc>().add(SelectSupplierAccountEvent(value));
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
                              searchFunction: (bloc, query) => bloc.add(LoadAccountsFilterEvent(input: query, include: '8', exclude: '')),
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
                                _accountController.text = '${value.accName} (${value.accNumber})';
                                context.read<PurchaseInvoiceBloc>().add(SelectSupplierAccountEvent(value));
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
                    child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                      builder: (context, state) {
                        if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
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
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<PurchaseInvoiceBloc>().add(AddNewPurchaseItemEvent());
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
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                      icon: Icons.add,
                      label: Text(AppLocalizations.of(context)!.addItem),
                      onPressed: () {
                        context.read<PurchaseInvoiceBloc>().add(AddNewPurchaseItemEvent());
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
          () => TextEditingController(text: item.qty > 0 ? item.qty.toString() : ''),
    );

    final priceController = _priceControllers.putIfAbsent(
      item.rowId,
          () => TextEditingController(
          text: item.purPrice != null && item.purPrice! > 0 ? item.purPrice!.toAmount() : ''),
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
                  child: GenericUnderlineTextfield<ProductsModel, ProductsBloc, ProductsState>(
                    title: "",
                    controller: productController,
                    hintText: tr.products,
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
                      context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                        rowId: item.rowId,
                        productId: product.proId.toString(),
                        productName: product.proName ?? '',
                      ));
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                          rowId: item.rowId,
                          qty: 0,
                        ));
                        return;
                      }
                      final qty = int.tryParse(value) ?? 0;
                      context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                        rowId: item.rowId,
                        qty: qty,
                      ));
                    },
                  ),
                ),

                // Unit Price
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                          rowId: item.rowId,
                          purPrice: 0,
                        ));
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
                      if (storageState is StorageLoadedState && storageState.storage.isNotEmpty) {
                        if (item.storageId == 0) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final firstStorage = storageState.storage.first;
                            context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                              rowId: item.rowId,
                              storageId: firstStorage.stgId!,
                              storageName: firstStorage.stgName ?? '',
                            ));
                            storageController.text = firstStorage.stgName ?? '';
                          });
                        }
                      }

                      return GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
                        title: "",
                        controller: storageController,
                        hintText: tr.storage,
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
                          context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
                            rowId: item.rowId,
                            storageId: storage.stgId!,
                            storageName: storage.stgName ?? '',
                          ));
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
                      context.read<PurchaseInvoiceBloc>().add(RemovePurchaseItemEvent(item.rowId));
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
          final current = state is PurchaseInvoiceSaving ? state : (state as PurchaseInvoiceLoaded);

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
                if (current.supplierAccount != null && current.creditAmount > 0) ...[
                  Divider(color: color.outline.withValues(alpha: .2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${current.supplierAccount!.accNumber} | ${current.supplierAccount!.accName}',
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
                    value: current.currentBalance + current.creditAmount,
                    isBold: true,
                    color: _getBalanceColor(current.currentBalance + current.creditAmount),
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
                  child: Icon(Icons.money,
                      color: current.paymentMode == PaymentMode.cash ? color.primary : color.outline)),
              title: Text(tr.cashPayment),
              subtitle: Text(tr.cashPaymentSubtitle),
              trailing: current.paymentMode == PaymentMode.cash ? Icon(Icons.check, color: color.primary) : null,
              onTap: () {
                Navigator.pop(context);
                _accountController.clear();
                context.read<PurchaseInvoiceBloc>().add(ClearSupplierAccountEvent());
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
                context.read<PurchaseInvoiceBloc>().add(UpdatePurchasePaymentEvent(0));
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

  void _showMixedPaymentDialog(BuildContext context, PurchaseInvoiceLoaded current) {
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

              context.read<PurchaseInvoiceBloc>().add(UpdatePurchasePaymentEvent(
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
        context.read<PurchaseInvoiceBloc>().add(UpdatePurchaseItemEvent(
          rowId: rowId,
          storageId: firstStorage.stgId!,
          storageName: firstStorage.stgName ?? '',
        ));
      });
    }
  }

  void _saveInvoice(BuildContext context, PurchaseInvoiceLoaded state) {
    if (!state.isFormValid) {
      Utils.showOverlayMessage(context, message: 'Please fill all required fields correctly', isError: true);
      return;
    }

    final completer = Completer<String>();

    context.read<PurchaseInvoiceBloc>().add(SavePurchaseInvoiceEvent(
      usrName: _userName ?? '',
      orderName: "Purchase",
      expenses: state.expenses,
      ordPersonal: state.supplier!.perId!,
      xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
      items: state.items,
      completer: completer,
    ));
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
      Utils.showOverlayMessage(context,
          message: 'Cannot print: No invoice data available',
          isError: true);
      return;
    }

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is! CompanyProfileLoadedState) {
      Utils.showOverlayMessage(context, message: 'Company information not available', isError: true);
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
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.supplierAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: false);
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
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
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
              isSale: false);
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
              customerSupplierName: current!.supplier?.perName ?? "",
              items: invoiceItems,
              grandTotal: current.grandTotal,
              cashPayment: current.cashPayment,
              creditAmount: current.creditAmount,
              account: current.supplierAccount,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              currency: baseCurrency,
              isSale: false);
        },
      ),
    );
  }
}