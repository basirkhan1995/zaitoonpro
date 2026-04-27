
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Generic/underline_searchable_textfield.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/thousand_separator.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/button.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_stock_model.dart';
import '../../../../../../../Features/Other/cover.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'bloc/goods_shift_bloc.dart';
import 'model/shift_model.dart';


class AddGoodsShiftView extends StatefulWidget {
  const AddGoodsShiftView({super.key});

  @override
  State<AddGoodsShiftView> createState() => _AddGoodsShiftViewState();
}

class _AddGoodsShiftViewState extends State<AddGoodsShiftView> {
  final List<TextEditingController> _productControllers = [];
  final List<TextEditingController> _fromStorageControllers = [];
  final List<TextEditingController> _toStorageControllers = [];
  final List<TextEditingController> _qtyControllers = [];
  final List<TextEditingController> _purchasePriceControllers = [];

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _userName;
  String? baseCurrency;
  final List<ShiftRecord> _records = [];

  final List<ProductsStockModel?> _selectedProducts = [];
  final List<StorageModel?> _selectedFromStorages = [];
  final List<StorageModel?> _selectedToStorages = [];

  bool _isSaving = false;
  bool _hasError = false;
  String? _errorMessage;

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
    for (final controller in _fromStorageControllers) {
      controller.dispose();
    }
    for (final controller in _toStorageControllers) {
      controller.dispose();
    }
    for (final controller in _qtyControllers) {
      controller.dispose();
    }
    for (final controller in _purchasePriceControllers) {
      controller.dispose();
    }
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addEmptyItem() {
    _productControllers.add(TextEditingController());
    _fromStorageControllers.add(TextEditingController());
    _toStorageControllers.add(TextEditingController());
    _qtyControllers.add(TextEditingController(text: "1"));
    _purchasePriceControllers.add(TextEditingController(text: "0.00"));

    _selectedProducts.add(null);
    _selectedFromStorages.add(null);
    _selectedToStorages.add(null);

    _records.add(ShiftRecord(
      stkProduct: 0,
      fromStorageId: 0,
      toStorageId: 0,
      stkQuantity: "1",
      stkPurPrice: "0.00",
    ));
  }

  void _removeItem(int index) {
    if (_records.length <= 1) {
      Utils.showOverlayMessage(context, message: 'Must have at least one item', isError: true);
      return;
    }

    setState(() {
      _productControllers.removeAt(index);
      _fromStorageControllers.removeAt(index);
      _toStorageControllers.removeAt(index);
      _qtyControllers.removeAt(index);
      _purchasePriceControllers.removeAt(index);
      _selectedProducts.removeAt(index);
      _selectedFromStorages.removeAt(index);
      _selectedToStorages.removeAt(index);
      _records.removeAt(index);
    });
  }

  void _updateRecord(int index, {
    int? productId,
    int? fromStorage,
    int? toStorage,
    double? quantity,
    double? purchasePrice,
  }) {
    final record = _records[index];

    _records[index] = record.copyWith(
      stkProduct: productId ?? record.stkProduct,
      fromStorage: fromStorage ?? record.fromStorageId,
      toStorage: toStorage ?? record.toStorageId,
      stkQuantity: quantity?.toStringAsFixed(2) ?? record.stkQuantity,
      stkPurPrice: purchasePrice?.toStringAsFixed(2) ?? record.stkPurPrice,
    );

    setState(() {});
  }

  double get _totalValue {
    double total = 0.0;
    for (final record in _records) {
      total += record.totalValue;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocListener<GoodsShiftBloc, GoodsShiftState>(
      listener: (context, state) {
        if (state is GoodsShiftErrorState) {
          Utils.showOverlayMessage(context, message: state.error, isError: true);
          setState(() {
            _isSaving = false;
            _hasError = true;
            _errorMessage = state.error;
          });
        }
        if (state is GoodsShiftSavedState) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: false,
          );
          Navigator.pop(context);
        }
        if (state is GoodsShiftSavingState) {
          setState(() {
            _isSaving = true;
            _hasError = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: color.surface,
        appBar: AppBar(
          backgroundColor: color.surface,
          title: Text('${tr.newKeyword} ${tr.shift}'),
          titleSpacing: 0,
          actionsPadding: const EdgeInsets.all(8),
          actions: [
            ZOutlineButton(
              icon: Icons.refresh,
              width: 110,
              height: 38,
              label: Text(tr.clear),
              onPressed: _isSaving ? null : () {
                setState(() {
                  _records.clear();
                  _productControllers.clear();
                  _fromStorageControllers.clear();
                  _toStorageControllers.clear();
                  _qtyControllers.clear();
                  _purchasePriceControllers.clear();
                  _selectedProducts.clear();
                  _selectedFromStorages.clear();
                  _selectedToStorages.clear();
                  _addEmptyItem();
                  _accountController.clear();
                  _amountController.clear();
                  _hasError = false;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(width: 8),
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
              label: Text(tr.create),
              onPressed: _isSaving ? null : _createGoodsShift,
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Account and Amount
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                          controller: _accountController,
                          title: tr.accounts,
                          hintText: tr.accNameOrNumber,
                          bloc: context.read<AccountsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(
                            LoadAccountsFilterEvent(include: "11,12",ccy: baseCurrency,exclude: ""),
                          ),
                          searchFunction: (bloc, query) => bloc.add(
                            LoadAccountsFilterEvent(
                                include: "11,12",
                                ccy: baseCurrency,
                                input: query, exclude: ""
                            ),
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return tr.required(tr.accounts);
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
                          title: tr.amount,
                          controller: _amountController,
                          hint: '0.00',
                          inputFormat: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                            SmartThousandsDecimalFormatter(),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Items header
                  _buildItemsHeader(tr),

                  // Items list
                  ...List.generate(_records.length, (index) {
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
                          onPressed: _isSaving ? null : () {
                            setState(() {
                              _addEmptyItem();
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Show error banner if there's an error
                  if (_hasError && _errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: Colors.red.shade600),
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  // Summary section
                  _buildSummarySection(tr)
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
          Expanded(flex: 5, child: Text(tr.products, style: TextStyle(color: color.surface))),
          Expanded(flex: 3, child: Text(tr.fromStorage, style: TextStyle(color: color.surface))),
          Expanded(flex: 3, child: Text(tr.toStorage, style: TextStyle(color: color.surface))),
          SizedBox(width: 80, child: Text(tr.qty, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text(tr.costPrice, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text(tr.totalCost, style: TextStyle(color: color.surface))),
          SizedBox(width: 60, child: Text(tr.actions, style: TextStyle(color: color.surface))),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final record = _records[index];
    final textTheme = Theme.of(context).textTheme;
    TextStyle? title = textTheme.titleSmall?.copyWith(color: color.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: color.outline.withAlpha(50))),
          color: index.isOdd? color.outline.withValues(alpha: .06) : Colors.transparent
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text((index + 1).toString())),

          // Product
          Expanded(
            flex: 5,
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
                    ZCover(radius: 0,child: Text(tr.costPrice,style: title),),
                    ZCover(radius: 0,child: Text(product.averagePrice?.toAmount()??"")),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(product.available?.toAmount()??"",style: TextStyle(fontSize: 18),),
                    Text(product.stgName??"",style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),),
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
                _fromStorageControllers[index].text = product.stgName ?? '';
                _purchasePriceControllers[index].text = purchasePrice.toAmount();

                _updateRecord(index,
                  productId: product.proId,
                  fromStorage: product.stkStorage,
                  purchasePrice: purchasePrice,
                );
              },
              title: '',
              enabled: !_isSaving,
            ),
          ),

          // From Storage
          Expanded(
            flex: 3,
            child: GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
              controller: _fromStorageControllers[index],
              hintText: tr.fromStorage,
              enabled: false,
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
                _selectedFromStorages[index] = storage;
                _updateRecord(index, fromStorage: storage.stgId);
              },
              title: '',
            ),
          ),

          // To Storage
          Expanded(
            flex: 3,
            child: GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
              controller: _toStorageControllers[index],
              hintText: tr.toStorage,
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
                _selectedToStorages[index] = storage;
                _updateRecord(index, toStorage: storage.stgId);
              },
              title: '',
              enabled: !_isSaving,
            ),
          ),

          // Quantity
          SizedBox(
            width: 80,
            child: TextField(
              controller: _qtyControllers[index],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: tr.qty,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0.0;
                _updateRecord(index, quantity: qty);
              },
              enabled: !_isSaving,
            ),
          ),

          // Purchase Price (Cost Price)
          SizedBox(
            width: 120,
            child: TextField(
              controller: _purchasePriceControllers[index],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                SmartThousandsDecimalFormatter(),
              ],
              decoration: InputDecoration(
                hintText: tr.costPrice,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                final price = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                _updateRecord(index, purchasePrice: price);
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
                  record.totalValue.toAmount(),
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
              Text(tr.summary, style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.summarize, size: 22, color: color.primary),
            ],
          ),
          Divider(color: color.outline.withValues(alpha: .2)),

          // Total Items
          _buildSummaryRow(
            label: tr.totalItems,
            value: _records.length.toDouble(),
            isAmount: false,
            isPercent: false,
          ),

          // Total Value
          _buildSummaryRow(
            label: tr.totalTitle,
            value: _totalValue,
            isPercent: false,
            isBold: true,
          ),

          Divider(color: color.outline.withValues(alpha: .2)),

          // Account and Amount from form
          if (_accountController.text.isNotEmpty)
            _buildSummaryRow(
              label: tr.accounts,
              value: double.tryParse(_accountController.text.replaceAll(',', '')) ?? 0.0,
              isPercent: false,
            ),

          if (_amountController.text.isNotEmpty)
            _buildSummaryRow(
              label: tr.amount,
              value: double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0,
              isPercent: false,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required double value,
    bool isBold = false,
    bool isPercent = false,
    bool isAmount = true,
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
            isPercent
                ? "${value.toAmount(decimal: 2)}%"
                : isAmount? "${value.toAmount()} $baseCurrency" : value.toAmount(),
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

  void _createGoodsShift() {
    if (_userName == null) {
      Utils.showOverlayMessage(context, message: 'User not authenticated', isError: true);
      return;
    }

    final accountText = _accountController.text.trim();
    final amountText = _amountController.text.trim();
// Case 1: If both are empty → allow (no error, continue)
    if (accountText.isEmpty && amountText.isEmpty) {
      // do nothing, just continue
    } else if (amountText.isNotEmpty && accountText.isEmpty) {
      Utils.showOverlayMessage(
        context,
        message: 'Please enter account number',
        isError: true,
      );
      return;
    } else if (accountText.isNotEmpty && amountText.isEmpty) {
      Utils.showOverlayMessage(
        context,
        message: 'Please enter amount',
        isError: true,
      );
      return;
    }

    // Validate items
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];
      if (record.stkProduct == null || record.stkProduct == 0) {
        Utils.showOverlayMessage(context, message: 'Please select a product for item ${i + 1}', isError: true);
        return;
      }
      if (record.fromStorageId == null || record.fromStorageId == 0) {
        Utils.showOverlayMessage(context, message: 'Please select from storage for item ${i + 1}', isError: true);
        return;
      }
      if (record.toStorageId == null || record.toStorageId == 0) {
        Utils.showOverlayMessage(context, message: 'Please select to storage for item ${i + 1}', isError: true);
        return;
      }
      if (record.fromStorageId == record.toStorageId) {
        Utils.showOverlayMessage(context, message: 'From and to storage cannot be same for item ${i + 1}', isError: true);
        return;
      }
      final qty = record.quantity;
      if (qty <= 0) {
        Utils.showOverlayMessage(context, message: 'Please enter a valid quantity for item ${i + 1}', isError: true);
        return;
      }
      final price = record.purchasePrice;
      if (price <= 0) {
        Utils.showOverlayMessage(context, message: 'Please enter a valid price for item ${i + 1}', isError: true);
        return;
      }
    }

    // Create the goods shift
    context.read<GoodsShiftBloc>().add(AddGoodsShiftEvent(
      usrName: _userName!,
      account: _accountController.text,
      amount: _amountController.text,
      records: _records,
    ));
  }
}