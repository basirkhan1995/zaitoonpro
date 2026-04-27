import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Generic/rounded_searchable_textfield.dart';
import 'package:zaitoonpro/Features/Generic/underline_searchable_textfield.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/thousand_separator.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/button.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/bloc/storage_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Storage/model/storage_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_stock_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../../Features/Other/alert_dialog.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../bloc/estimate_bloc.dart';
import '../../model/estimate_model.dart';

class EstimateDetailView extends StatefulWidget {
  final int estimateId;
  const EstimateDetailView({super.key, required this.estimateId});

  @override
  State<EstimateDetailView> createState() => _EstimateDetailViewState();
}

class _EstimateDetailViewState extends State<EstimateDetailView> {
  String? _userName;
  String? baseCurrency;
  double _totalAmount = 0.0;

  // Edit mode variables
  bool _isEditing = false;
  final List<TextEditingController> _qtyControllers = [];
  final List<TextEditingController> _salePriceControllers = [];
  final List<TextEditingController> _storageControllers = [];
  final List<TextEditingController> _productControllers = [];
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final Map<int, int> _qtyCursorPositions = {};
  final Map<int, int> _priceCursorPositions = {};

  // Selected data
  IndividualsModel? _selectedCustomer;
  final List<ProductsStockModel?> _selectedProducts = [];
  final List<StorageModel?> _selectedStorages = [];
  List<EstimateRecord> _records = [];

  // Payment variables
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  AccountsModel? _selectedAccount;
  final TextEditingController _creditAmountController = TextEditingController();
  double _remainingAmount = 0.0;

  // Local state tracking
  EstimateModel? _currentEstimate;
  bool _isSaving = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EstimateBloc>().add(LoadEstimateByIdEvent(widget.estimateId));
    });

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
    for (final controller in _qtyControllers) {
      controller.dispose();
    }
    for (final controller in _salePriceControllers) {
      controller.dispose();
    }
    for (final controller in _storageControllers) {
      controller.dispose();
    }
    for (final controller in _productControllers) {
      controller.dispose();
    }
    _customerController.dispose();
    _xRefController.dispose();
    _creditAmountController.dispose();
    super.dispose();
  }

  void _initializeControllers(EstimateModel estimate) {
    _currentEstimate = estimate;
    _records = List.from(estimate.records ?? []);

    // Clear existing controllers
    for (final controller in _qtyControllers) {
      controller.dispose();
    }
    for (final controller in _salePriceControllers) {
      controller.dispose();
    }
    for (final controller in _storageControllers) {
      controller.dispose();
    }
    for (final controller in _productControllers) {
      controller.dispose();
    }

    _qtyControllers.clear();
    _salePriceControllers.clear();
    _storageControllers.clear();
    _productControllers.clear();
    _selectedProducts.clear();
    _selectedStorages.clear();

    // Set customer
    _customerController.text = estimate.ordPersonalName ?? '';
    _xRefController.text = estimate.ordxRef ?? '';

    // Initialize record controllers
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];

      _qtyControllers.add(TextEditingController(
          text: record.tstQuantity ?? "1"
      ));

      _salePriceControllers.add(TextEditingController(
          text: record.salePrice.toAmount()
      ));

      _storageControllers.add(TextEditingController(
          text: record.storageName ?? ''
      ));

      _productControllers.add(TextEditingController(
          text: record.productName ?? ''
      ));

      // Initialize selected items
      _selectedProducts.add(null);
      _selectedStorages.add(null);
    }

    _updateTotalAmount();
    _updateRemainingAmount();
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
      tstQuantity: quantity?.toAmount() ?? record.tstQuantity,
      tstSalePrice: salePrice?.toAmount() ?? record.tstSalePrice,
      tstPurPrice: purchasePrice?.toAmount() ?? record.tstPurPrice,
      tstStorage: storageId ?? record.tstStorage,
    );
    _updateTotalAmount();
  }

  void _updateTotalAmount() {
    double total = 0.0;
    for (final record in _records) {
      total += record.total;
    }
    setState(() {
      _totalAmount = total;
    });
  }

  void _updateRemainingAmount() {
    if (_selectedPaymentMethod == PaymentMethod.cash) {
      _remainingAmount = _totalAmount;
    } else if (_selectedPaymentMethod == PaymentMethod.credit) {
      _remainingAmount = 0.0;
    } else if (_selectedPaymentMethod == PaymentMethod.mixed) {
      final creditAmount = double.tryParse(_creditAmountController.text) ?? 0.0;
      _remainingAmount = _totalAmount - creditAmount;
      if (_remainingAmount < 0) _remainingAmount = 0.0;
    }
  }

  void _addEmptyItem() {
    setState(() {
      _qtyControllers.add(TextEditingController(text: "1"));
      _salePriceControllers.add(TextEditingController(text: "0.00"));
      _storageControllers.add(TextEditingController());
      _productControllers.add(TextEditingController());
      _selectedProducts.add(null);
      _selectedStorages.add(null);

      _records.add(EstimateRecord(
        tstId: 0,
        tstOrder: widget.estimateId,
        tstProduct: 0,
        tstStorage: 0,
        tstQuantity: "1",
        tstPurPrice: "0.00",
        tstSalePrice: "0.00",
      ));

      _updateTotalAmount();
    });
  }

  void _removeItem(int index) {
    if (_records.length <= 1) {
      Utils.showOverlayMessage(context, message: 'Must have at least one item', isError: true);
      return;
    }

    setState(() {
      _qtyControllers.removeAt(index);
      _salePriceControllers.removeAt(index);
      _storageControllers.removeAt(index);
      _productControllers.removeAt(index);
      _selectedProducts.removeAt(index);
      _selectedStorages.removeAt(index);
      _records.removeAt(index);
      _updateTotalAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EstimateBloc, EstimateState>(
      listener: (context, state) {
        if (state is EstimateError) {
          // Show error message but don't change UI
          Utils.showOverlayMessage(context, message: state.message, isError: true);
          setState(() {
            _hasError = true;
            _errorMessage = state.message;
            _isSaving = false;
          });
        }
        if (state is EstimateConverted) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: false,
          );
          Navigator.pop(context);
        }
        if (state is EstimateDeleted) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: false,
          );
          Navigator.pop(context);
        }
        if (state is EstimateSaved) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: false,
          );
          // Reload the estimate to get updated data
          context.read<EstimateBloc>().add(LoadEstimateByIdEvent(widget.estimateId));
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });
        }
        if (state is EstimateSaving) {
          setState(() {
            _isSaving = true;
            _hasError = false;
          });
        }
        if (state is EstimateDetailLoaded) {
          setState(() {
            _initializeControllers(state.estimate);
            _hasError = false;
            _isSaving = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Estimate #${widget.estimateId}'),
          actionsPadding: EdgeInsets.symmetric(horizontal: 10),
          actions: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
              child: IconButton(
                icon: Icon(Icons.print),
                onPressed: () {
                  // TODO: Implement print functionality
                },
                hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                tooltip: AppLocalizations.of(context)!.print,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
              child: IconButton(
                icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
                onPressed: _toggleEditMode,
                hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                tooltip: _isEditing ? 'Cancel Edit' : 'Edit',
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  if (_currentEstimate != null) {
                    _deleteEstimate(_currentEstimate!);
                  }
                },
                hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                tooltip: 'Delete',
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
              child: IconButton(
                icon: const Icon(Icons.cached_rounded),
                onPressed: () {
                  if (_currentEstimate != null) {
                    _showConvertToSaleDialog(_currentEstimate!);
                  }
                },
                hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                tooltip: 'Convert to Sale',
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(23),
                child: IconButton(
                  hoverColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                  onPressed: _saveChanges,
                  tooltip: 'Save Changes',
                  icon: const Icon(Icons.check),
                ),
              ),
            ],
          ],
        ),
        body: BlocBuilder<EstimateBloc, EstimateState>(
          builder: (context, state) {
            // Show loading indicator
            if (state is EstimateDetailLoading && _currentEstimate == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show error only if we don't have any estimate loaded
            if (state is EstimateError && _currentEstimate == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ZButton(
                      width: 120,
                      label: const Text('Retry'),
                      onPressed: () {
                        context.read<EstimateBloc>().add(LoadEstimateByIdEvent(widget.estimateId));
                      },
                    ),
                  ],
                ),
              );
            }

            // If we have loaded data or we're in edit mode, show content
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildHeaderInfo(),
                          if (!_isEditing && _currentEstimate != null)
                            ZOutlineButton(
                              width: 120,
                              isActive: true,
                              icon: Icons.published_with_changes_rounded,
                              label: const Text('Convert'),
                              onPressed: () => _showConvertToSaleDialog(_currentEstimate!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Customer and Reference (Editable in edit mode)
                      if (_isEditing) _buildEditableHeaderFields(),

                      // Items header
                      _buildItemsHeader(),

                      // Items list
                      _buildItemsList(),

                      // Add item button in edit mode
                      if (_isEditing)
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: ZOutlineButton(
                                width: 120,
                                icon: Icons.add,
                                label: Text(AppLocalizations.of(context)!.addItem),
                                onPressed: _addEmptyItem,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Profit Summary Section
                      _buildProfitSummarySection(),

                      // Show error banner if there's an error
                      if (_hasError && _errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final tr = AppLocalizations.of(context)!;
    final estimate = _currentEstimate ?? EstimateModel(records: _records);
    final isPending = estimate.isPending;

    return SizedBox(
      width: 500,
      child: ZCover(
        radius: 5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.customer, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(estimate.ordPersonalName ?? ''),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.referenceNumber, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(estimate.ordxRef ?? ''),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.totalInvoice, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${_totalAmount.toAmount()} $baseCurrency"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPending ? 'PENDING' : 'COMPLETED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildEditableHeaderFields() {
    final tr = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
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
                  _selectedCustomer = value;
                  _customerController.text = "${value.perName} ${value.perLastName}";
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ZTextFieldEntitled(
                title: tr.referenceNumber,
                controller: _xRefController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  Widget _buildItemsHeader() {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
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
          SizedBox(width: 120, child: Text(tr.unitPrice, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text(tr.totalTitle, style: TextStyle(color: color.surface))),
          SizedBox(width: 120, child: Text(tr.profit, style: TextStyle(color: color.surface))),
          SizedBox(width: 150, child: Text(tr.storage, style: TextStyle(color: color.surface))),
          if (_isEditing)
            SizedBox(width: 60, child: Text(tr.actions, style: TextStyle(color: color.surface))),
        ],
      ),
    );
  }
  Widget _buildItemsList() {
    final records = _records;
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? title = textTheme.titleSmall?.copyWith(color: color.primary);

    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('No items found')),
      );
    }

    return Column(
      children: records.asMap().entries.map((entry) {
        final index = entry.key;
        final record = entry.value;

        return Container(
          padding: EdgeInsets.symmetric(vertical: _isEditing? 0 : 5, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2))),
            color: index.isOdd? Theme.of(context).colorScheme.outline.withValues(alpha: .06) : Colors.transparent
          ),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text((index + 1).toString())),

              // Product
              Expanded(
                child: _isEditing
                    ? GenericUnderlineTextfield<ProductsStockModel, ProductsBloc, ProductsState>(
                  controller: _productControllers[index],
                  hintText: 'Product',
                  bloc: context.read<ProductsBloc>(),
                  fetchAllFunction: (bloc) => bloc.add(LoadProductsStockEvent()),
                  searchFunction: (bloc, query) => bloc.add(LoadProductsStockEvent()),
                  itemBuilder: (context, product) => ListTile(
                    visualDensity: VisualDensity(vertical: -2),
                    title: Text(product.proName ?? ''),
                    subtitle: Row(
                      spacing: 5,
                      children: [
                        Wrap(
                          children: [
                            ZCover(radius: 0,child: Text(tr.purchasePrice,style: title),),
                            ZCover(radius: 0,child: Text(product.averagePrice?.toAmount()??"")),
                          ],
                        ),
                        Wrap(
                          children: [
                            ZCover(radius: 0,child: Text(tr.salePriceBrief,style: title)),
                            ZCover(radius: 0,child: Text(product.sellPrice?.toAmount()??"")),
                          ],
                        ),
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
                    final salePrice = double.tryParse(
                      product.sellPrice?.replaceAll(',', '') ?? "0.0",
                    ) ?? 0.0;

                    _selectedProducts[index] = product;
                    _productControllers[index].text = product.proName ?? '';
                    _storageControllers[index].text = product.stgName ?? '';
                    _salePriceControllers[index].text = salePrice.toAmount();

                    _updateRecord(index,
                      productId: product.proId,
                      salePrice: salePrice,
                      purchasePrice: purchasePrice,
                      storageId: product.stkStorage,
                    );
                  },
                  title: '',
                )
                    : Text(record.productName ?? 'Product ${record.tstProduct}'),
              ),

              // Quantity
              SizedBox(
                width: 80,
                child: _isEditing
                    ? TextField(
                  controller: _qtyControllers[index],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final cursorPos = _qtyControllers[index].selection.baseOffset;
                    _qtyCursorPositions[index] = cursorPos;

                    final qty = double.tryParse(value) ?? 0.0;
                    _updateRecord(index, quantity: qty);

                    if (cursorPos != -1 && cursorPos <= _qtyControllers[index].text.length) {
                      Future.delayed(Duration.zero, () {
                        _qtyControllers[index].selection = TextSelection.collapsed(
                          offset: cursorPos,
                        );
                      });
                    }
                  },
                )
                    : Text(record.quantity.toStringAsFixed(2)),
              ),

              // Sale Price
              SizedBox(
                width: 120,
                child: _isEditing
                    ? TextField(
                  controller: _salePriceControllers[index],
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
                    final cursorPos = _salePriceControllers[index].selection.baseOffset;
                    _priceCursorPositions[index] = cursorPos;

                    final price = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                    _updateRecord(index, salePrice: price);

                    if (cursorPos != -1 && cursorPos <= _salePriceControllers[index].text.length) {
                      Future.delayed(Duration.zero, () {
                        _salePriceControllers[index].selection = TextSelection.collapsed(
                          offset: cursorPos,
                        );
                      });
                    }
                  },
                )
                    : Text(record.salePrice.toAmount()),
              ),

              // Total
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.total.toAmount(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Profit
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record.purchasePrice > 0 && record.salePrice > 0)
                      Text(
                        record.profit.toAmount(),
                        style: TextStyle(
                          fontSize: 14,
                          color: record.profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    if (record.purchasePrice > 0 && record.salePrice > 0)
                      Text(
                        '(${record.profitPercentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: record.profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                  ],
                ),
              ),

              // Storage
              SizedBox(
                width: 150,
                child: _isEditing
                    ? GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
                  controller: _storageControllers[index],
                  hintText: 'Storage',
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
                    _storageControllers[index].text = storage.stgName ?? '';
                    _updateRecord(index, storageId: storage.stgId);
                  },
                  title: '',
                )
                    : Text(record.storageName ?? ''),
              ),

              // Remove button in edit mode
              if (_isEditing)
                SizedBox(
                  width: 60,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _removeItem(index),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
  Widget _buildProfitSummarySection() {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    // Calculate totals from current records
    double totalPurchaseCost = 0.0;
    double totalSaleValue = 0.0;

    for (final record in _records) {
      totalPurchaseCost += record.totalPurchase;
      totalSaleValue += record.total;
    }

    final totalProfit = totalSaleValue - totalPurchaseCost;
    final profitColor = totalProfit >= 0 ? Colors.green : Colors.red;
    final profitPercentage = totalPurchaseCost > 0 ? (totalProfit / totalPurchaseCost * 100) : 0.0;

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
              Text(tr.profitSummary, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color.outline)),
              const SizedBox(width: 4),
              Icon(Icons.ssid_chart, size: 22, color: color.primary),
            ],
          ),
          Divider(color: color.outline.withValues(alpha: .2)),

          _buildProfitRow(
              label: tr.totalCost,
              value: totalPurchaseCost,
              color: color.primary.withValues(alpha: .9),
              isBold: true
          ),
          const SizedBox(height: 5),
          _buildProfitRow(
            label: tr.profit,
            value: totalProfit.toDoubleAmount(),
            color: profitColor,
            isBold: true,
          ),
          if (totalPurchaseCost > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${tr.profit} %', style: TextStyle(fontSize: 16)),
                Text(
                  '${profitPercentage.toAmount()}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: profitColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          SizedBox(height: 3),
          Divider(color: color.outline.withValues(alpha: .2)),
          SizedBox(height: 3),
          // Grand Total
          _buildProfitRow(
            label: tr.grandTotal,
            value: _totalAmount,
            isBold: true,
          ),
        ],
      ),
    );
  }
  Widget _buildProfitRow({required String label, required double value, bool isBold = false, Color? color,}) {
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
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original data if cancelled
        if (_currentEstimate != null) {
          _initializeControllers(_currentEstimate!);
        }
      }
    });
  }
  void _saveChanges() {
    if (_userName == null) {
      Utils.showOverlayMessage(context, message: 'User not authenticated', isError: true);
      return;
    }

    // Validate customer
    if (_selectedCustomer == null && _customerController.text.isEmpty) {
      Utils.showOverlayMessage(context, message: 'Please select a customer', isError: true);
      return;
    }

    // Validate items
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];
      if (record.tstProduct == 0) {
        Utils.showOverlayMessage(context, message: 'Please select a product for item ${i + 1}', isError: true);
        return;
      }
      if (record.tstStorage == 0) {
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

    if (_currentEstimate == null) return;

    // Update the estimate
    context.read<EstimateBloc>().add(UpdateEstimateEvent(
      usrName: _userName!,
      orderId: _currentEstimate!.ordId!,
      perID: _selectedCustomer?.perId ?? _currentEstimate!.ordPersonal!,
      xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
      records: _records,
    ));
  }
  void _deleteEstimate(EstimateModel estimate){
    final tr = AppLocalizations.of(context)!;
    if (_userName == null) {
      Utils.showOverlayMessage(context, message: 'User not authenticated', isError: true);
      return;
    }
    showDialog(context: context, builder: (context){
      return ZAlertDialog(title: tr.delete, content: tr.areYouSure,
          onYes: (){
            Navigator.pop(context);
            context.read<EstimateBloc>().add(DeleteEstimateEvent(
              orderId: estimate.ordId!,
              usrName: _userName!,
            ));
          });
    });
  }
  void _showConvertToSaleDialog(EstimateModel estimate) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    _selectedPaymentMethod = PaymentMethod.cash;
    _selectedAccount = null;
    _creditAmountController.clear();
    _remainingAmount = _totalAmount;

    // Create a TextEditingController for account selection
    final accountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return ZFormDialog(
            title:  'Convert to Sale',
            icon: Icons.add_card_rounded,
            padding: EdgeInsets.all(12),
            onAction: () => _convertEstimateToSale(estimate),
            actionLabel: Text(tr.submit),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Payment Method Selection (same as before)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Cash Option
                        _buildPaymentOption(
                          title: tr.cashPayment,
                          subtitle: 'Full payment in cash',
                          isSelected: _selectedPaymentMethod == PaymentMethod.cash,
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = PaymentMethod.cash;
                              _selectedAccount = null;
                              _creditAmountController.clear();
                              _remainingAmount = _totalAmount;
                            });
                          },
                        ),

                        // Credit Option
                        _buildPaymentOption(
                          title: 'Credit Payment',
                          subtitle: 'Full payment via account',
                          isSelected: _selectedPaymentMethod == PaymentMethod.credit,
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = PaymentMethod.credit;
                              _remainingAmount = 0.0;
                              _creditAmountController.text = _totalAmount.toStringAsFixed(2);
                            });
                          },
                        ),

                        // Mixed Option
                        _buildPaymentOption(
                          title: tr.combinedPayment,
                          subtitle: tr.combinedPaymentSubtitle,
                          isSelected: _selectedPaymentMethod == PaymentMethod.mixed,
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = PaymentMethod.mixed;
                              _remainingAmount = _totalAmount;
                              _creditAmountController.text = '0';
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Account Selection - FIXED SECTION
                  if (_selectedPaymentMethod != PaymentMethod.cash)
                    GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                      title: tr.accounts,
                      hintText: tr.selectCreditAccountMsg,
                      isRequired: _selectedPaymentMethod != PaymentMethod.cash,
                      bloc: context.read<AccountsBloc>(),
                      controller: accountController,
                      fetchAllFunction: (bloc) => bloc.add(LoadAccountsFilterEvent(include: '8', exclude: '')),
                      searchFunction: (bloc, query) => bloc.add(LoadAccountsFilterEvent(
                        input: query,
                        include: '8',
                        exclude: '',
                      )),
                      itemBuilder: (context, account) => ListTile(
                        title: Text(
                          account.accName ?? 'No Name',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acc #: ${account.accNumber ?? 'N/A'}',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${tr.balance}: ${account.accAvailBalance?.toAmount() ?? "0.00"} $baseCurrency',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      itemToString: (account) => '${account.accName ?? "Unknown Account"} (${account.accNumber ?? "N/A"})',
                      stateToLoading: (state) => state is AccountLoadingState,
                      stateToItems: (state) {
                        if (state is AccountLoadedState) {
                          return state.accounts;
                        }
                        return [];
                      },
                      onSelected: (value) {
                        setState(() {
                          _selectedAccount = value;
                          // Update controller text with account name
                          accountController.text = '${value.accName ?? "Unknown Account"} (${value.accNumber ?? "N/A"})';
                        });
                      },
                    ),

                  // Credit Amount
                  if (_selectedPaymentMethod != PaymentMethod.cash)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        ZTextFieldEntitled(
                          title: tr.amount,
                          controller: _creditAmountController,
                          isRequired: _selectedPaymentMethod != PaymentMethod.cash,
                          onChanged: (value) {
                            final creditAmount = double.tryParse(value) ?? 0.0;
                            setState(() {
                              if (creditAmount > _totalAmount) {
                                _creditAmountController.text = _totalAmount.toStringAsFixed(2);
                                _remainingAmount = 0.0;
                              } else {
                                _remainingAmount = _totalAmount - creditAmount;
                              }
                            });
                          },
                        ),
                      ],
                    ),

                  // Payment Summary
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${tr.totalInvoice}:', style: TextStyle(fontWeight: FontWeight.bold,color: color.surface)),
                            Text("${_totalAmount.toAmount()} $baseCurrency",style: TextStyle(color: color.surface),),
                          ],
                        ),
                        if (_selectedPaymentMethod == PaymentMethod.credit) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${tr.creditPayment}:', style: TextStyle(fontWeight: FontWeight.bold,color: color.surface)),
                              Text("${_totalAmount.toAmount()} $baseCurrency", style: TextStyle(fontWeight: FontWeight.bold,color: color.surface)),
                            ],
                          ),
                        ],
                        if (_selectedPaymentMethod == PaymentMethod.mixed) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${tr.creditPayment}:', style: TextStyle(fontWeight: FontWeight.bold,color: color.surface)),
                              Text("${(_totalAmount - _remainingAmount).toAmount()} $baseCurrency",style: TextStyle(color: color.surface),),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${tr.cashPayment}:', style: TextStyle(fontWeight: FontWeight.bold, color: color.surface)),
                              Text("${_remainingAmount.toAmount()} $baseCurrency", style: TextStyle(color: color.surface)),
                            ],
                          ),
                        ],
                        if (_selectedPaymentMethod == PaymentMethod.cash) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${tr.cashPayment}:', style: TextStyle(fontWeight: FontWeight.bold, color: color.surface)),
                              Text("${_totalAmount.toAmount()} $baseCurrency", style: TextStyle(color: color.surface)),
                            ],
                          ),
                        ],
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
  void _convertEstimateToSale(EstimateModel estimate) {
    if (_userName == null) {
      Utils.showOverlayMessage(context, message: 'User not authenticated', isError: true);
      return;
    }

    // Validation
    if (_selectedPaymentMethod != PaymentMethod.cash && _selectedAccount == null) {
      Utils.showOverlayMessage(context, message: 'Please select an account for credit payment', isError: true);
      return;
    }

    if (_selectedPaymentMethod != PaymentMethod.cash) {
      final creditAmount = double.tryParse(_creditAmountController.text) ?? 0.0;
      if (creditAmount <= 0) {
        Utils.showOverlayMessage(context, message: 'Please enter credit amount', isError: true);
        return;
      }

      if (creditAmount > _totalAmount) {
        Utils.showOverlayMessage(context, message: 'Credit amount cannot exceed total invoice', isError: true);
        return;
      }
    }

    // Prepare API parameters
    int account = 0;
    String amount = "0";

    switch (_selectedPaymentMethod) {
      case PaymentMethod.cash:
        account = 0;
        amount = "0";
        break;
      case PaymentMethod.credit:
        account = _selectedAccount?.accNumber ?? 0;
        amount = _totalAmount.toStringAsFixed(2);
        break;
      case PaymentMethod.mixed:
        account = _selectedAccount?.accNumber ?? 0;
        final creditAmount = double.tryParse(_creditAmountController.text) ?? 0.0;
        amount = creditAmount.toStringAsFixed(2);
        break;
    }

    // Send conversion request
    context.read<EstimateBloc>().add(ConvertEstimateToSaleEvent(
      usrName: _userName!,
      orderId: estimate.ordId!,
      perID: estimate.ordPersonal!,
      account: account,
      amount: amount,
      isCash: _selectedPaymentMethod == PaymentMethod.cash,
    ));

    Navigator.pop(context);
  }
  Widget _buildPaymentOption({required String title, required String subtitle, required bool isSelected, required VoidCallback onTap,}) {
    final color = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.primary.withValues(alpha: .06) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: color.outline.withValues(alpha: .1)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? color.primary : color.outline),
                color: isSelected ? color.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: color.surface)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color.primary : color.onSurface,
                  )),
                  Text(subtitle, style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? color.primary : color.outline
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PaymentMethod {
  cash,
  credit,
  mixed,
}