import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Generic/rounded_searchable_textfield.dart';
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
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../Features/Generic/stock_product_field.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../bloc/estimate_bloc.dart';
import '../model/estimate_model.dart';

class AddEstimateView extends StatefulWidget {
  const AddEstimateView({super.key});

  @override
  State<AddEstimateView> createState() => _AddEstimateViewState();
}

class _AddEstimateViewState extends State<AddEstimateView> {
  final List<TextEditingController> _productControllers = [];
  final List<TextEditingController> _qtyControllers = [];
  final List<TextEditingController> _salePriceControllers = [];
  final List<TextEditingController> _storageControllers = [];

  // Keep only purchase price controller for display
  final List<TextEditingController> _purchasePriceControllers = [];
  // Remove profit controller since we'll display it differently

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();

  String? _userName;
  String? baseCurrency;
  int? _selectedCustomerId;
  final List<EstimateRecord> _records = [];

  // For storing selected product details
  final List<ProductsStockModel?> _selectedProducts = [];
  final List<StorageModel?> _selectedStorages = [];

  // Local state for saving
  bool _isSaving = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Start with one empty item
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
    for (final controller in _qtyControllers) {
      controller.dispose();
    }
    for (final controller in _salePriceControllers) {
      controller.dispose();
    }
    for (final controller in _storageControllers) {
      controller.dispose();
    }
    for (final controller in _purchasePriceControllers) {
      controller.dispose();
    }
    _customerController.dispose();
    _xRefController.dispose();
    super.dispose();
  }

  void _addEmptyItem() {
    _productControllers.add(TextEditingController());
    _qtyControllers.add(TextEditingController(text: "1"));
    _salePriceControllers.add(TextEditingController(text: "0.00"));
    _storageControllers.add(TextEditingController());
    _purchasePriceControllers.add(TextEditingController(text: "0.00"));

    _selectedProducts.add(null);
    _selectedStorages.add(null);

    _records.add(EstimateRecord(
      tstId: 0,
      tstOrder: 0,
      tstProduct: 0,
      tstStorage: 0,
      tstQuantity: "1",
      tstPurPrice: "0.00",
      tstSalePrice: "0.00",
    ));
  }

  void _removeItem(int index) {
    if (_records.length <= 1) {
      Utils.showOverlayMessage(context, message: 'Must have at least one item', isError: true);
      return;
    }

    setState(() {
      _productControllers.removeAt(index);
      _qtyControllers.removeAt(index);
      _salePriceControllers.removeAt(index);
      _storageControllers.removeAt(index);
      _purchasePriceControllers.removeAt(index);
      _selectedProducts.removeAt(index);
      _selectedStorages.removeAt(index);
      _records.removeAt(index);
    });
  }

  void _updateRecord(int index, {
    int? productId,
    double? quantity,
    double? salePrice,
    double? purchasePrice,
    int? storageId,
  }) {
    final record = _records[index];

    _records[index] = record.copyWith(
      tstProduct: productId ?? record.tstProduct,
      tstQuantity: quantity?.toStringAsFixed(2) ?? record.tstQuantity,
      tstSalePrice: salePrice?.toStringAsFixed(2) ?? record.tstSalePrice,
      tstPurPrice: purchasePrice?.toStringAsFixed(2) ?? record.tstPurPrice,
      tstStorage: storageId ?? record.tstStorage,
    );

    setState(() {}); // Update UI
  }

  double get _grandTotal {
    double total = 0.0;
    for (final record in _records) {
      total += record.total;
    }
    return total;
  }

  double get _totalCost {
    double total = 0.0;
    for (final record in _records) {
      total += record.totalPurchase;
    }
    return total;
  }

  double get _totalProfit {
    double total = 0.0;
    for (final record in _records) {
      total += record.profit;
    }
    return total;
  }

  double get _profitPercentage {
    if (_totalCost == 0) return 0.0;
    return (_totalProfit / _totalCost) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocListener<EstimateBloc, EstimateState>(
      listener: (context, state) {
        if (state is EstimateError) {
          Utils.showOverlayMessage(context, message: state.message, isError: true);
          setState(() {
            _isSaving = false;
            _hasError = true;
            _errorMessage = state.message;
          });
        }
        if (state is EstimateSaved) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: false,
          );
          Navigator.pop(context);
        }
        if (state is EstimateSaving) {
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
          title: Text('${tr.newKeyword} ${tr.estimate}'),
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
                  _qtyControllers.clear();
                  _salePriceControllers.clear();
                  _storageControllers.clear();
                  _purchasePriceControllers.clear();
                  _selectedProducts.clear();
                  _selectedStorages.clear();
                  _addEmptyItem();
                  _customerController.clear();
                  _xRefController.clear();
                  _selectedCustomerId = null;
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
              onPressed: _isSaving ? null : _createEstimate,
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Customer and Reference
                  Row(
                    children: [
                      Expanded(
                        child: GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                          controller: _customerController,
                          title: tr.customer,
                          hintText: tr.customer,
                          isRequired: true,
                          bloc: context.read<IndividualsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                          searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
                          itemBuilder: (context, ind) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("${ind.perName ?? ''} ${ind.perLastName ?? ''}"),
                          ),
                          itemToString: (individual) => "${individual.perName ?? ''} ${individual.perLastName ?? ''}",
                          stateToLoading: (state) => state is IndividualLoadingState,
                          stateToItems: (state) {
                            if (state is IndividualLoadedState) return state.individuals;
                            return [];
                          },
                          onSelected: (value) {
                            _selectedCustomerId = value.perId;
                            _customerController.text = "${value.perName} ${value.perLastName}";
                          },
                        //  enabled: !_isSaving,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: tr.referenceNumber,
                          controller: _xRefController,
                        //  enabled: !_isSaving,
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

                  // Summary sections in row (like sale invoice)
                  _buildProfitSummarySection(tr)
                ],
              ),
            ),

            // Show saving overlay if saving
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: TextStyle(color: color.surface))),
          Expanded(child: Text(tr.products, style: TextStyle(color: color.surface))),
          SizedBox(width: 80, child: Text(tr.qty, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text(tr.costPrice, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text(tr.salePrice, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text(tr.totalTitle, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text(tr.profit, style: TextStyle(color: color.surface))),
          SizedBox(width: 150, child: Text(tr.storage, style: TextStyle(color: color.surface))),
          SizedBox(width: 60, child: Text(tr.actions, style: TextStyle(color: color.surface))),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final record = _records[index];
    final tr = AppLocalizations.of(context)!;

    // Calculate profit color
    final profitColor = record.profit >= 0 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color.outline.withAlpha(50))),
        color: index.isOdd? color.outline.withValues(alpha: .06) : Colors.transparent
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text((index + 1).toString())),

          Expanded(
            child: ProductSearchField<ProductsStockModel, ProductsBloc, ProductsState>(
              controller: _productControllers[index],
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

              // Just provide the field getters - no need to build UI!
              getProductId: (product) => product.proId?.toString(),
              getProductName: (product) => product.proName,
              getProductCode: (product) => product.proCode,
              getStorageId: (product) => product.stkStorage,
              getStorageName: (product) => product.stgName,
              getAvailable: (product) => product.available,
              getAveragePrice: (product) => product.averagePrice,
              getRecentPrice: (product) => product.recentPurPrice,
              getSellPrice: (product) => product.sellPrice,
              getBatch: (product)=> product.stkQtyInBatch,

              // Handle selection
              onProductSelected: (product) {
                if (product != null) {
                  final purchasePrice = double.tryParse(
                    product.averagePrice?.replaceAll(',', '') ?? "0.0",
                  ) ?? 0.0;
                  final salePrice = double.tryParse(
                    product.sellPrice?.replaceAll(',', '') ?? "0.0",
                  ) ?? 0.0;

                  _storageControllers[index].text = product.stgName ?? '';
                  _salePriceControllers[index].text = salePrice.toAmount();
                  _purchasePriceControllers[index].text = purchasePrice.toAmount();

                  _updateRecord(index,
                    productId: product.proId,
                    salePrice: salePrice,
                    purchasePrice: purchasePrice,
                    storageId: product.stkStorage,
                  );
                } else {

                  _storageControllers[index].clear();
                  _salePriceControllers[index].clear();
                  _purchasePriceControllers[index].clear();

                  _updateRecord(index,
                    productId: null,
                    salePrice: 0,
                    purchasePrice: 0,
                    storageId: null,
                  );

                }
              },

              enabled: !_isSaving,
            ),
          ),

          // Product
          // Expanded(
          //   child: GenericUnderlineTextfield<ProductsStockModel, ProductsBloc, ProductsState>(
          //     controller: _productControllers[index],
          //     hintText: tr.products,
          //     bloc: context.read<ProductsBloc>(),
          //     fetchAllFunction: (bloc) => bloc.add(LoadProductsStockEvent()),
          //     searchFunction: (bloc, query) => bloc.add(LoadProductsStockEvent(input: query)),
          //     itemBuilder: (context, product) => ListTile(
          //       title: Text(product.proName ?? ''),
          //       subtitle: Row(
          //         spacing: 5,
          //         children: [
          //           Wrap(
          //             children: [
          //               ZCover(radius: 0,child: Text(tr.purchasePrice,style: title),),
          //               ZCover(radius: 0,child: Text(product.averagePrice?.toAmount()??"")),
          //             ],
          //           ),
          //           Wrap(
          //             children: [
          //               ZCover(radius: 0,child: Text(tr.salePriceBrief,style: title)),
          //               ZCover(radius: 0,child: Text(product.sellPrice?.toAmount()??"")),
          //             ],
          //           ),
          //         ],
          //       ),
          //       trailing: Column(
          //         mainAxisAlignment: MainAxisAlignment.end,
          //         crossAxisAlignment: CrossAxisAlignment.end,
          //         children: [
          //           Text(product.available?.toAmount()??"",style: TextStyle(fontSize: 18),),
          //           Text(product.stgName??"",style: TextStyle(
          //             color: Theme.of(context).colorScheme.outline,
          //           ),),
          //         ],
          //       ),
          //     ),
          //     itemToString: (product) => product.proName ?? '',
          //     stateToLoading: (state) => state is ProductsLoadingState,
          //     stateToItems: (state) {
          //       if (state is ProductsStockLoadedState) return state.products;
          //       return [];
          //     },
          //     onSelected: (product) {
          //       final purchasePrice = double.tryParse(
          //         product.averagePrice?.replaceAll(',', '') ?? "0.0",
          //       ) ?? 0.0;
          //       final salePrice = double.tryParse(
          //         product.sellPrice?.replaceAll(',', '') ?? "0.0",
          //       ) ?? 0.0;
          //
          //       _selectedProducts[index] = product;
          //       _storageControllers[index].text = product.stgName ?? '';
          //       _salePriceControllers[index].text = salePrice.toAmount();
          //       _purchasePriceControllers[index].text = purchasePrice.toAmount();
          //
          //       _updateRecord(index,
          //         productId: product.proId,
          //         salePrice: salePrice,
          //         purchasePrice: purchasePrice,
          //         storageId: product.stkStorage,
          //       );
          //     },
          //     title: '',
          //    // enabled: !_isSaving,
          //   ),
          // ),

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

          // Purchase Price (Cost Price) - Read-only
          SizedBox(
            width: 120,
            child: TextField(
              controller: _purchasePriceControllers[index],
              readOnly: true,
              decoration: InputDecoration(
                hintText: tr.costPrice,
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(color: Colors.blue),
              enabled: !_isSaving,
            ),
          ),

          // Sale Price - Editable
          SizedBox(
            width: 120,
            child: TextField(
              controller: _salePriceControllers[index],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                SmartThousandsDecimalFormatter(),
              ],
              decoration: InputDecoration(
                hintText: tr.salePrice,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                final price = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                _updateRecord(index, salePrice: price);
              },
              enabled: !_isSaving,
            ),
          ),

          // Total and Profit Display - Like Sale Invoice
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Total (Total Sale)
                Text(
                  record.total.toAmount(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color.primary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profit/Benefit
                if (record.purchasePrice > 0)
                  Text(
                    record.profit.toAmount(),
                    style: TextStyle(
                      fontSize: 14,
                      color: profitColor,
                    ),
                  ),
                // Profit Percentage
                if (record.purchasePrice > 0)
                  Text(
                    '(${record.profitPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: profitColor,
                    ),
                  ),
              ],
            ),
          ),
          // Storage
          SizedBox(
            width: 150,
            child: GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
              controller: _storageControllers[index],
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
                _selectedStorages[index] = storage;
                _updateRecord(index, storageId: storage.stgId);
              },
              title: '',
             // enabled: !_isSaving,
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

  Widget _buildProfitSummarySection(AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final profitColor = _totalProfit >= 0 ? Colors.green : Colors.red;

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
              Text(tr.profitSummary, style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.ssid_chart, size: 22, color: color.primary),
            ],
          ),
          Divider(color: color.outline.withValues(alpha: .2)),

          // Total Cost
          _buildSummaryRow(
            label: tr.totalCost,
            value: _totalCost,
            color: Colors.blue,
          ),

          // Total Profit
          _buildSummaryRow(
            label: tr.profit,
            value: _totalProfit,
            color: profitColor,
            isBold: true,
          ),

          // Profit Percentage
          if (_totalCost > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${tr.profit} %', style: const TextStyle(fontSize: 16)),
                Text(
                  '${_profitPercentage.toAmount(decimal: 2)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: profitColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

          Divider(color: color.outline.withValues(alpha: .2)),

          // Grand Total
          _buildSummaryRow(
            label: tr.grandTotal,
            value: _grandTotal,
            isBold: true,
          ),
        ],
      ),
    );
  }
  Widget _buildSummaryRow({
    required String label,
    required double value,
    bool isBold = false,
    Color? color,
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
            "${value.toAmount()} $baseCurrency",
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

  void _createEstimate() {
    if (_userName == null) {
      Utils.showOverlayMessage(context, message: 'User not authenticated', isError: true);
      return;
    }

    if (_selectedCustomerId == null) {
      Utils.showOverlayMessage(context, message: 'Please select a customer', isError: true);
      return;
    }

    // Validate items
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];
      if (record.tstProduct == null || record.tstProduct == 0) {
        Utils.showOverlayMessage(context, message: 'Please select a product for item ${i + 1}', isError: true);
        return;
      }
      if (record.tstStorage == null || record.tstStorage == 0) {
        Utils.showOverlayMessage(context, message: 'Please select a storage for item ${i + 1}', isError: true);
        return;
      }
      final qty = record.quantity;
      if (qty <= 0) {
        Utils.showOverlayMessage(context, message: 'Please enter a valid quantity for item ${i + 1}', isError: true);
        return;
      }
      final price = record.salePrice;
      if (price <= 0) {
        Utils.showOverlayMessage(context, message: 'Please enter a valid price for item ${i + 1}', isError: true);
        return;
      }
    }

    // Create the estimate
    context.read<EstimateBloc>().add(AddEstimateEvent(
      usrName: _userName!,
      perID: _selectedCustomerId!,
      xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
      records: _records,
    ));
  }
}