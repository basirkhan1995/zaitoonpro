import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/features/branch_dropdown.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/Cardx/bloc/stock_record_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/StockAvailability/features/storage_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Stock/Ui/Products/model/product_model.dart';
import '../../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../../Features/Date/z_range_picker.dart';
import '../../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../../../../../Localizations/Bloc/localizations_bloc.dart';
import '../../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../../Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../Stock/Ui/OrderScreen/GetOrderById/order_by_id.dart';
import '../../../../../Stock/Ui/OrderScreen/NewPurchase/new_purchase.dart';
import '../../../../../Stock/Ui/OrderScreen/NewSale/new_sale.dart';
import '../features/in_out_drop.dart';
import '../features/stock_summary_widget.dart';

class StockRecordReportView extends StatelessWidget {
  const StockRecordReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      desktop: _Desktop(),
      tablet: _Mobile(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  late String fromDate;
  late String toDate;
  int? storageId;
  int? productId;

  final _productController = TextEditingController();

  String? myLocale;
  String? baseCcy;
  final _personController = TextEditingController();
  int? partyId;
  @override
  void initState() {
    super.initState();
    baseCcy = _getBaseCurrency();
    fromDate = DateTime.now().subtract(const Duration(days: 30)).toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<StockRecordBloc>().add(ResetStockRecordEvent());
  }

  bool get hasFilter {
    return storageId != null ||
        productId != null ||
        _productController.text.isNotEmpty;
  }

  String? _getBaseCurrency() {
    try {
      final companyState = context.read<CompanyProfileBloc>().state;
      if (companyState is CompanyProfileLoadedState) {
        return companyState.company.comLocalCcy;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;

    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      estimatedContentHeight: 480,
      bodyBuilder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 8),

                /// 🔹 Product
                GenericTextField<ProductsModel, ProductsBloc, ProductsState>(
                  key: const ValueKey('filter_product_field'),
                  controller: _productController,
                  title: tr.products,
                  hintText: tr.products,
                  bloc: context.read<ProductsBloc>(),
                  fetchAllFunction: (bloc) =>
                      bloc.add(LoadProductsEvent()),
                  searchFunction: (bloc, query) =>
                      bloc.add(LoadProductsEvent()),
                  itemBuilder: (context, pro) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                    Text("${pro.proCode} | ${pro.proName ?? ''}"),
                  ),
                  itemToString: (pro) =>
                  "${pro.proCode} | ${pro.proName ?? ''}",
                  stateToLoading: (state) =>
                  state is ProductsLoadingState,
                  stateToItems: (state) {
                    if (state is ProductsLoadedState) {
                      return state.products;
                    }
                    return [];
                  },
                  onSelected: (value) {
                    setSheetState(() {
                      productId = value.proId;
                    });
                  },
                  showClearButton: true,
                ),

                const SizedBox(height: 16),
                Expanded(
                  flex: 4,
                  child: GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                    controller: _personController,
                    title: tr.party,
                    hintText: tr.party,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr.required(tr.party);
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
                      setState(() {
                        partyId = value.perId;
                      });
                    },
                    showClearButton: true,
                  ),
                ),
                const SizedBox(height: 16),
                /// 🔹 Branch
                BranchDropdown(
                  showAllOption: true,
                  title: tr.branch,
                  onBranchSelected: (e) {
                    setSheetState(() {
                      storageId = e?.brcId;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// 🔹 Storage
                StorageDropDown(
                  title: tr.storage,
                  onChanged: (e) {
                    setSheetState(() {
                      storageId = e?.stgId;
                    });
                  },
                ),

                const SizedBox(height: 16),
                StockMovementDropDown(
                  title: tr.movement,
                  onChanged: (value) {
                    if(productId !=null && _productController.text.isNotEmpty){
                      context.read<StockRecordBloc>().add(LoadStockRecordEvent(
                          fromDate: fromDate,
                          toDate: toDate,
                          productId: productId,
                          storageId: storageId,
                          partyId: partyId,
                          inOut: value
                      ));
                    }else{
                      ToastManager.show(context: context,
                          title: tr.noProductSelectedTitle,
                          message: tr.noProductSelectedMsg, type: ToastType.info);
                    }
                  },
                  initiallySelected: StockMovementType.all, // Default to show both
                ),
                const SizedBox(height: 16),
                /// 🔹 Date Range
                Row(
                  children: [
                    Expanded(
                      child: ZDatePicker(
                        label: tr.fromDate,
                        value: fromDate,
                        onDateChanged: (v) {
                          setSheetState(() {
                            fromDate = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ZDatePicker(
                        label: tr.toDate,
                        value: toDate,
                        onDateChanged: (v) {
                          setSheetState(() {
                            toDate = v;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// 🔹 Apply Button
                ZOutlineButton(
                  width: double.infinity,
                  isActive: true,
                  onPressed: () {
                    Navigator.pop(context);

                    if (productId != null && _productController.text.isNotEmpty) {
                      context.read<StockRecordBloc>().add(
                        LoadStockRecordEvent(
                          fromDate: fromDate,
                          toDate: toDate,
                          productId: productId,
                          storageId: storageId,
                          partyId: partyId
                        ),
                      );
                    } else {
                      ToastManager.show(context: context,
                          title: tr.noProductSelectedTitle,
                          message: tr.noProductSelectedMsg, type: ToastType.info);
                    }
                  },
                  label: Text(tr.apply),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(tr.stockRecord),
        titleSpacing: 0,
        actions: [
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                setState(() {
                  productId = null;
                  storageId = null;
                  _productController.clear();
                  fromDate = DateTime.now().toFormattedDate();
                  toDate = DateTime.now().toFormattedDate();
                });
                context.read<StockRecordBloc>().add(ResetStockRecordEvent());
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected Filters
          if (hasFilter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_productController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _productController.text,
                          style: TextStyle(fontSize: 12, color: color.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Summary Box (only shows when data is loaded)
          BlocBuilder<StockRecordBloc, StockRecordState>(
            builder: (context, state) {
              if (state is StockRecordLoadedState && state.cardX.isNotEmpty) {
                return StockMovementSummary(
                  records: state.cardX,
                  baseCurrency: baseCcy ?? '',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: BlocBuilder<StockRecordBloc, StockRecordState>(
              builder: (context, state) {
                if (state is StockRecordErrorState) {
                  return NoDataWidget(
                    imageName: "error.png",
                    title: tr.accessDenied,
                    message: state.error,
                    onRefresh: () {},
                  );
                }
                if (state is StockRecordLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is StockRecordInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr.productMovement,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Stock IN & OUT Record",
                          style: TextStyle(color: color.outline),
                        ),
                      ],
                    ),
                  );
                }
                if (state is StockRecordLoadedState) {
                  if (state.cardX.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.cardX.length,
                    itemBuilder: (context, index) {
                      final stock = state.cardX[index];
                      return ZCover(
                        radius: 8,
                        color: color.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            Utils.goto(
                              context,
                              OrderByIdView(
                                orderId: stock.orderId!,
                                ordName: stock.entryType == "IN" ? "Purchase" : "Sale",
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "#${stock.orderId}",
                                      style: TextStyle(
                                        color: color.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: stock.entryType == "IN"
                                            ? Colors.green.withValues(alpha: .1)
                                            : color.error.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        stock.entryType ?? "",
                                        style: TextStyle(
                                          color: stock.entryType == "IN"
                                              ? Colors.green
                                              : color.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Date: ${stock.entryDate.toFormattedDate()}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Party: ${stock.fullname}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Storage: ${stock.storageName}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Qty",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          stock.quantity.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "Price",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          "${stock.price.toAmount()} $baseCcy",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "Balance",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          stock.runningQuantity.toAmount(decimal: 4),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  late String fromDate;
  late String toDate;
  int? storageId;
  int? productId;

  final _productController = TextEditingController();
  final _personController = TextEditingController();

  String? myLocale;
  String? baseCcy;
  int? partyId;
  @override
  void initState() {
    super.initState();
    baseCcy = _getBaseCurrency();

    final now = DateTime.now();
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    fromDate = lastMonthStart.toFormattedDate();
    toDate = lastMonthEnd.toFormattedDate();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<StockRecordBloc>().add(ResetStockRecordEvent());
  }

  bool get hasFilter {
    return storageId != null ||
        productId != null ||
        _productController.text.isNotEmpty;
  }

  String? _getBaseCurrency() {
    try {
      final companyState = context.read<CompanyProfileBloc>().state;
      if (companyState is CompanyProfileLoadedState) {
        return companyState.company.comLocalCcy;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  void onSelection(){
    if(productId !=null && _productController.text.isNotEmpty){
      context.read<StockRecordBloc>().add(LoadStockRecordEvent(
          fromDate: fromDate,
          toDate: toDate,
          productId: productId,
          storageId: storageId,
          partyId: partyId
      ));
    }else{
      ToastManager.show(context: context,
          title: AppLocalizations.of(context)!.noProductSelectedTitle,
          message: AppLocalizations.of(context)!.noProductSelectedMsg, type: ToastType.info);
    }
  }
  String _formatQuantity(double? qty, String? type) {
    if (qty == null) return "";

    final formatted = qty.toStringAsFixed(0);

    if (type == "IN") {
      return "+$formatted";
    } else if (type == "OUT") {
      return "-$formatted";
    }
    return formatted;
  }
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.surface);
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr.stockRecord),
        titleSpacing: 0,
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          if(hasFilter)...[
            ZOutlineButton(
              onPressed: () {
                setState(() {
                  productId = null;
                  storageId = null;
                  _productController.clear();
                  fromDate = DateTime.now().toFormattedDate();
                  toDate = DateTime.now().toFormattedDate();
                });
                context.read<StockRecordBloc>().add(ResetStockRecordEvent());
              },
              backgroundHover: Theme.of(context).colorScheme.error,
              isActive: true,
              icon: Icons.filter_alt_off_outlined,
              label: Text(tr.clearFilters),
            ),
            SizedBox(width: 8),
          ],
          SizedBox(width: 8),
          ZOutlineButton(
            onPressed: () {
              if(productId !=null && _productController.text.isNotEmpty){
                context.read<StockRecordBloc>().add(LoadStockRecordEvent(
                  fromDate: fromDate,
                  toDate: toDate,
                  productId: productId,
                  storageId: storageId,
                  partyId: partyId
                ));
              }else{
                ToastManager.show(context: context,
                    title: tr.noProductSelectedTitle,
                    message: tr.noProductSelectedMsg, type: ToastType.info);
              }
            },
            isActive: true,
            icon: Icons.filter_alt_outlined,
            label: Text(tr.apply),
          ),
        ],
      ),

      body: Column(
        children: [
          //Filter section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 4,
                  child:
                      GenericTextField<ProductsModel, ProductsBloc, ProductsState>(
                        controller: _productController,
                        title: tr.products,
                        hintText: tr.products,
                        isRequired: true,
                        bloc: context.read<ProductsBloc>(),
                        fetchAllFunction: (bloc) => bloc.add(LoadProductsEvent()),
                        searchFunction: (bloc, query) => bloc.add(LoadProductsEvent()),
                        itemBuilder: (context, ind) {
                          if (ind.proId == null) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                tr.all,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "${ind.proCode} | ${ind.proName ?? ''}",
                            ),
                          );
                        },
                        itemToString: (pro) => "${pro.proCode} | ${pro.proName ?? ''}",
                        stateToLoading: (state) => state is ProductsLoadingState,
                        stateToItems: (state) {
                          if (state is ProductsLoadedState) {
                            return state.products;
                          }
                          return [];
                        },
                        onSelected: (value) {
                          setState(() {
                            productId = value.proId;
                          });
                        },
                        showClearButton: true,
                      ),
                ),
                Expanded(
                  flex: 4,
                  child: GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                    controller: _personController,
                    title: tr.party,
                    hintText: tr.party,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr.required(tr.party);
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
                      setState(() {
                        partyId = value.perId;
                      });
                    },
                    showClearButton: true,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: BranchDropdown(
                    showAllOption: true,
                    title: tr.branch,
                    onBranchSelected: (e) {
                      setState(() {
                        storageId = e?.brcId;
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: StorageDropDown(
                    title: tr.storage,
                    onChanged: (e) {
                      setState(() {
                        storageId = e?.stgId;
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: StockMovementDropDown(
                    title: tr.movement,
                    onChanged: (value) {
                      if(productId !=null && _productController.text.isNotEmpty){
                        context.read<StockRecordBloc>().add(LoadStockRecordEvent(
                            fromDate: fromDate,
                            toDate: toDate,
                            productId: productId,
                            storageId: storageId,
                            partyId: partyId,
                            inOut: value
                        ));
                      }else{
                        ToastManager.show(context: context,
                            title: tr.noProductSelectedTitle,
                            message: tr.noProductSelectedMsg, type: ToastType.info);
                      }
                    },
                    initiallySelected: StockMovementType.all,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ZRangeDatePicker(
                    label: tr.selectDate,
                    initialStartDate: DateTime.tryParse(fromDate),
                    initialEndDate: DateTime.tryParse(toDate),
                    startValue: fromDate,
                    endValue: toDate,
                    onStartDateChanged: (startDate) {
                      setState(() {
                        fromDate = startDate;
                      });
                    },
                    onEndDateChanged: (endDate) {
                      setState(() {
                        toDate = endDate;
                      });
                      onSelection();
                    },
                    disablePastDate: false,
                    minYear: 2000,
                    maxYear: 2100,
                  ),
                ),

              ],
            ),
          ),

          SizedBox(height: 10),
          //Header Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15,vertical: 8),
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .9),
            ),
            child: Row (
                children: [
              SizedBox(
                  width: 40,
                  child: Text("#",style: titleStyle)),
                  SizedBox(
                      width: 100,
                      child: Text(tr.date,style: titleStyle)),

                  Expanded(
                      child: Text(tr.party,style: titleStyle)),
                  SizedBox(
                      width: 180,
                      child: Text(tr.storage,style: titleStyle, textAlign: TextAlign.center)),
                  SizedBox(
                      width: 80,
                      child: Text(tr.inAndOut,style: titleStyle, textAlign: TextAlign.center)),
                  SizedBox(
                      width: 120,
                      child: Text(tr.qty,style: titleStyle, textAlign: TextAlign.center)),
                  SizedBox(
                      width: 120,
                      child: Text(tr.batchTitle,style: titleStyle, textAlign: TextAlign.center)),
                  SizedBox(
                      width: 120,
                      child: Text(tr.rate,style: titleStyle, textAlign: TextAlign.center)),
                  SizedBox(
                      width: 120,
                      child: Text(tr.stockBalance,style: titleStyle, textAlign: TextAlign.center)),
            ]),
          ),

          Expanded(
            child: BlocBuilder<StockRecordBloc, StockRecordState>(
              builder: (context, state) {
                if(state is StockRecordErrorState){
                  return NoDataWidget(
                    imageName: "error.png",
                    title: tr.accessDenied,
                    message: state.error,
                    onRefresh: (){}
                  );
                }
                if(state is StockRecordLoadingState){
                  return Center(child: CircularProgressIndicator());
                }

                if(state is StockRecordInitial){
                  return NoDataWidget(
                      title: "Inventory Report",
                      message: "Stock IN & OUT Record",
                      enableAction: false,
                  );
                }
                if(state is StockRecordLoadedState){
                  if(state.cardX.isEmpty){
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                      itemCount: state.cardX.length,
                      itemBuilder: (context,index){
                       final stock = state.cardX[index];
                        return InkWell(
                          highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                          onTap: (){
                            Utils.goto(
                                context,
                                stock.entryType == "OUT"? NewSaleView(orderId: stock.orderId, ref: null) : NewPurchaseOrderView(orderId: stock.orderId)
                            );
                          },
                          child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 15,vertical: 8),
                          margin: EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: index.isEven ? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 40,
                                  child: Text(stock.orderId.toString())),
                              SizedBox(
                                  width: 100,
                                  child: Text(stock.entryDate.toFormattedDate())),
                              Expanded(
                                  child: Text(stock.fullname.toString())),

                              SizedBox(
                                  width: 180,
                                  child: Text(stock.storageName.toString(), textAlign: TextAlign.center)),
                              SizedBox(
                                  width: 80,
                                  child: Text(stock.entryType.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                    color: stock.entryType == "IN"? Colors.green : color.error,
                                  )),
                              ),

                              SizedBox(
                                width: 120,
                                child: Text(
                                  textAlign: TextAlign.center,
                                  _formatQuantity(double.tryParse(stock.quantity??""), stock.entryType),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: stock.entryType == "IN" ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                              SizedBox(
                                  width: 120,
                                  child: Text(stock.batch.toAmount(decimal: 0), textAlign: TextAlign.center)),

                              SizedBox(
                                  width: 120,
                                  child: Text("${stock.price.toAmount()} $baseCcy", textAlign: TextAlign.center)),

                              SizedBox(
                                width: 120,
                                child: Text(
                                    stock.runningQuantity??"",
                                    textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: stock.entryType == "IN" ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                                                ),
                        );
                  });
                }
                return const SizedBox();
              },
            ),
          ),

          // Summary Box (only shows when data is loaded)
          BlocBuilder<StockRecordBloc, StockRecordState>(
            builder: (context, state) {
              if (state is StockRecordLoadedState && state.cardX.isNotEmpty) {
                return StockMovementSummary(
                  records: state.cardX,
                  baseCurrency: baseCcy ?? '',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
