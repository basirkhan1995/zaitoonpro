// add_adjustment.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Generic/rounded_searchable_textfield.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/button.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Features/Generic/underline_searchable_textfield.dart';
import '../../../../../../Features/Other/cover.dart';
import '../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import '../../../Settings/Ui/Stock/Ui/Products/model/product_stock_model.dart';
import '../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'bloc/adjustment_bloc.dart';
import 'model/adj_items.dart';

class AddAdjustmentView extends StatefulWidget {
  const AddAdjustmentView({super.key});

  @override
  State<AddAdjustmentView> createState() => _AddAdjustmentViewState();
}

class _AddAdjustmentViewState extends State<AddAdjustmentView> {
  final List<TextEditingController> _productControllers = [];
  final List<TextEditingController> _storageControllers = [];
  final List<TextEditingController> _qtyControllers = [];
  final List<TextEditingController> _priceControllers = [];

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();

  String? _userName;
  String? baseCurrency;
  final List<AdjustmentItem> _items = [];

  final List<ProductsStockModel?> _selectedProducts = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addEmptyItem();

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _userName = authState.loginData.usrName;
    }
  }

  @override
  void dispose() {
    for (final controller in _productControllers) {
      controller.dispose();
    }
    for (final controller in _storageControllers) {
      controller.dispose();
    }
    for (final controller in _qtyControllers) {
      controller.dispose();
    }
    for (final controller in _priceControllers) {
      controller.dispose();
    }
    _accountController.dispose();
    _xRefController.dispose();
    super.dispose();
  }

  void _addEmptyItem() {
    _productControllers.add(TextEditingController());
    _storageControllers.add(TextEditingController());
    _qtyControllers.add(TextEditingController(text: "1"));
    _priceControllers.add(TextEditingController(text: "0.00"));

    _selectedProducts.add(null);

    _items.add(AdjustmentItem.empty());
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      Utils.showOverlayMessage(
        context,
        message: 'Must have at least one item',
        isError: true,
      );
      return;
    }

    setState(() {
      _productControllers.removeAt(index);
      _storageControllers.removeAt(index);
      _qtyControllers.removeAt(index);
      _priceControllers.removeAt(index);
      _selectedProducts.removeAt(index);
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, AdjustmentItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  double get _totalValue {
    return _items.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocListener<AdjustmentBloc, AdjustmentState>(
      listener: (context, state) {
        if (state is AdjustmentErrorState) {
          Utils.showOverlayMessage(
            context,
            message: state.error,
            isError: true,
          );
          setState(() {
            _isSaving = false;
          });
        }
        if (state is AdjustmentSavedState) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: false,
          );
          Navigator.pop(context);
        }
        if (state is AdjustmentSavingState) {
          setState(() {
            _isSaving = true;
          });
        }
      },
      child: Scaffold(
        backgroundColor: color.surface,
        appBar: AppBar(
          backgroundColor: color.surface,
          title: Text('${tr.newKeyword} ${tr.adjustment}'),
          titleSpacing: 0,
          actionsPadding: const EdgeInsets.all(8),
          actions: [
            ZOutlineButton(
              width: 110,
              height: 38,
              icon: Icons.print,
              label: Text(tr.print),
              onPressed: null,
            ),
            const SizedBox(width: 8),
            ZButton(
              width: 110,
              height: 38,
              label: Text(tr.submit),
              onPressed: _isSaving ? null : _createAdjustment,
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Account and Reference
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                          controller: _accountController,
                          title: 'Expense Account',
                          hintText: tr.accNameOrNumber,
                          bloc: context.read<AccountsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(
                            LoadAccountsFilterEvent(
                              include: "11,12",
                              ccy: baseCurrency,
                              exclude: "",
                            ),
                          ),
                          searchFunction: (bloc, query) => bloc.add(
                            LoadAccountsFilterEvent(
                              include: "11,12",
                              ccy: baseCurrency,
                              input: query,
                              exclude: "",
                            ),
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please select an expense account';
                            }
                            return null;
                          },
                          itemBuilder: (context, account) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${account.accNumber} | ${account.accName}",
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                          stateToLoading: (state) => state is AccountLoadingState,
                          loadingBuilder: (context) => const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          stateToItems: (state) {
                            if (state is AccountLoadedState) {
                              return state.accounts;
                            }
                            return [];
                          },
                          onSelected: (value) {
                            setState(() {
                              _accountController.text = value.accNumber.toString();
                            });
                          },
                          noResultsText: tr.noDataFound,
                          showClearButton: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: tr.referenceNumber,
                          controller: _xRefController,
                          hint: 'Optional reference',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Items header
                  _buildItemsHeader(tr),

                  // Items list
                  ...List.generate(_items.length, (index) {
                    return _buildItemRow(index, tr);
                  }),

                  // Add item button
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ZOutlineButton(
                          width: 120,
                          icon: Icons.add,
                          label: Text(tr.addItem),
                          onPressed: _isSaving
                              ? null
                              : () {
                            setState(() {
                              _addEmptyItem();
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Summary section
                  _buildSummarySection(tr),
                ],
              ),
            ),

            if (_isSaving)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: .3),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsHeader(AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: TextStyle(color: color.surface))),
          Expanded(flex: 4, child: Text(tr.products, style: TextStyle(color: color.surface))),
          Expanded(flex: 3, child: Text(tr.storage, style: TextStyle(color: color.surface))),
          SizedBox(width: 80, child: Text(tr.qty, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text('Unit Cost', style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text('Total Cost', style: TextStyle(color: color.surface))),
          SizedBox(width: 60, child: Text(tr.actions, style: TextStyle(color: color.surface))),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final item = _items[index];
    final textTheme = Theme.of(context).textTheme;
    TextStyle? title = textTheme.titleSmall?.copyWith(color: color.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color.outline.withAlpha(50))),
        color: index.isOdd ? color.outline.withValues(alpha: .06) : Colors.transparent,
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text((index + 1).toString())),

          // Product
          Expanded(
            flex: 4,
            child: GenericUnderlineTextfield<ProductsStockModel, ProductsBloc, ProductsState>(
              controller: _productControllers[index],
              hintText: tr.products,
              bloc: context.read<ProductsBloc>(),
              fetchAllFunction: (bloc) => bloc.add(LoadProductsStockEvent()),
              searchFunction: (bloc, query) => bloc.add(LoadProductsStockEvent()),
              itemBuilder: (context, product) => ListTile(
                title: Text(product.proName ?? ''),
                subtitle: Wrap(
                  children: [
                    ZCover(
                      radius: 0,
                      child: Text(tr.recentPrice, style: title),
                    ),
                    ZCover(
                      radius: 0,
                      child: Text(product.recentPrice?.toAmount() ?? ""),
                    ),
                    ZCover(
                      radius: 0,
                      child: Text(tr.purchasePrice, style: title),
                    ),
                    ZCover(
                      radius: 0,
                      child: Text(product.averagePrice?.toAmount() ?? ""),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.available?.toAmount() ?? "",
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      product.stgName ?? "",
                      style: TextStyle(
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
                final purchasePrice = double.tryParse(
                  product.averagePrice?.replaceAll(',', '') ?? "0.0",
                ) ?? 0.0;

                _selectedProducts[index] = product;
                _storageControllers[index].text = product.stgName ?? '';
                _priceControllers[index].text = purchasePrice.toAmount();

                final updatedItem = item.copyWith(
                  productId: product.proId.toString(),
                  productName: product.proName ?? '',
                  storageId: product.stkStorage ?? 0,
                  storageName: product.stgName ?? '',
                  purPrice: purchasePrice,
                );
                _updateItem(index, updatedItem);
              },
              title: '',
              enabled: !_isSaving,
            ),
          ),

          // Storage (auto-filled from product selection)
          Expanded(
            flex: 3,
            child: TextField(
              controller: _storageControllers[index],
              decoration: InputDecoration(
                hintText: tr.storage,
                border: InputBorder.none,
                isDense: true,
              ),
              readOnly: true,
              enabled: !_isSaving,
            ),
          ),

          // Quantity
          SizedBox(
            width: 80,
            child: TextField(
              controller: _qtyControllers[index],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: tr.qty,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0.0;
                final updatedItem = item.copyWith(quantity: qty);
                _updateItem(index, updatedItem);
              },
              enabled: !_isSaving,
            ),
          ),

          // Unit Price (auto-filled from product, but editable)
          SizedBox(
            width: 120,
            child: TextField(
              controller: _priceControllers[index],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: tr.unitPrice,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                final price = double.tryParse(value) ?? 0.0;
                final updatedItem = item.copyWith(purPrice: price);
                _updateItem(index, updatedItem);
              },
              enabled: !_isSaving,
            ),
          ),

          // Total Value
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.totalCost.toAmount(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color.primary,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          SizedBox(
            width: 60,
            child: IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: color.error),
              onPressed: _isSaving ? null : () => _removeItem(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;

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
              Text(tr.summary, style: const TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.summarize, size: 22, color: color.primary),
            ],
          ),
          Divider(color: color.outline.withValues(alpha: .2)),

          // Total Items
          _buildSummaryRow(
            label: tr.totalItems,
            value: _items.length.toString(),
            isAmount: false,
          ),

          // Total Value
          _buildSummaryRow(
            label: tr.totalTitle,
            value: _totalValue.toAmount(),
            isBold: true,
            suffix: baseCurrency,
          ),

          Divider(color: color.outline.withValues(alpha: .2)),

          // Expense Account
          if (_accountController.text.isNotEmpty)
            _buildSummaryRow(
              label: 'Expense Account',
              value: _accountController.text,
              isAmount: false,
            ),

          if (_xRefController.text.isNotEmpty)
            _buildSummaryRow(
              label: tr.referenceNumber,
              value: _xRefController.text,
              isAmount: false,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool isBold = false,
    bool isAmount = true,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            isAmount && suffix != null ? "$value $suffix" : value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _createAdjustment() {
    if (_userName == null) {
      Utils.showOverlayMessage(
        context,
        message: 'User not authenticated',
        isError: true,
      );
      return;
    }

    // Validate expense account
    final accountText = _accountController.text.trim();
    if (accountText.isEmpty) {
      Utils.showOverlayMessage(
        context,
        message: 'Please select an expense account',
        isError: true,
      );
      return;
    }

    final account = int.tryParse(accountText);
    if (account == null) {
      Utils.showOverlayMessage(
        context,
        message: 'Invalid account number',
        isError: true,
      );
      return;
    }

    // Validate items
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.productId.isEmpty) {
        Utils.showOverlayMessage(
          context,
          message: 'Please select a product for item ${i + 1}',
          isError: true,
        );
        return;
      }
      if (item.storageId == 0) {
        Utils.showOverlayMessage(
          context,
          message: 'Please select a storage for item ${i + 1}',
          isError: true,
        );
        return;
      }
      if (item.quantity <= 0) {
        Utils.showOverlayMessage(
          context,
          message: 'Please enter a valid quantity for item ${i + 1}',
          isError: true,
        );
        return;
      }
      if (item.purPrice == null || item.purPrice! <= 0) {
        Utils.showOverlayMessage(
          context,
          message: 'Please enter a valid price for item ${i + 1}',
          isError: true,
        );
        return;
      }
    }

    // Prepare records for API
    final records = _items.map((item) => item.toRecordMap()).toList();

    // Generate reference if not provided
    final xRef = _xRefController.text.isNotEmpty
        ? _xRefController.text
        : 'ADJ-${DateTime.now().millisecondsSinceEpoch}';

    // Create the adjustment
    context.read<AdjustmentBloc>().add(AddAdjustmentEvent(
      usrName: _userName!,
      xReference: xRef,
      xAccount: account,
      records: records,
    ));
  }
}