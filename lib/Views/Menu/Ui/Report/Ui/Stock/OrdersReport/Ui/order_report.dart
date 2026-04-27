import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/features/branch_dropdown.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Stock/OrdersReport/bloc/order_report_bloc.dart';
import '../../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../../Features/Other/utils.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../../../../../Localizations/Bloc/localizations_bloc.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../../Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../Stock/Ui/OrderScreen/GetOrderById/order_by_id.dart';

class OrderReportView extends StatelessWidget {
  final String? orderName;
  const OrderReportView({super.key,this.orderName});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(orderName),
      tablet: _Tablet(orderName),
      desktop: _Desktop(orderName),
    );
  }
}

class _Mobile extends StatefulWidget {
  final String? orderName;
  const _Mobile(this.orderName);

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  late String fromDate;
  late String toDate;
  int? branchId;
  int? customerId;
  final _personController = TextEditingController();
  final filterPersonController = TextEditingController();
  final orderId = TextEditingController();

  String? myLocale;
  String? baseCcy;

  @override
  void initState() {
    super.initState();
    baseCcy = _getBaseCurrency();
    fromDate = DateTime.now().toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<OrderReportBloc>().add(ResetOrderReportEvent());
  }

  @override
  void dispose() {
    _personController.dispose();
    filterPersonController.dispose();
    orderId.dispose();
    super.dispose();
  }

  bool get hasFilter {
    return branchId != null || customerId != null || _personController.text.isNotEmpty || orderId.text.isNotEmpty;
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

  String header(String? orderName) {
    if (orderName == null) return "";
    switch (orderName) {
      case "Purchase":
        return "${AppLocalizations.of(context)!.purchaseTitle} ${AppLocalizations.of(context)!.invoiceTitle}";
      case "Sale":
        return "${AppLocalizations.of(context)!.saleTitle} ${AppLocalizations.of(context)!.invoiceTitle}";
      case "Estimate":
        return "${AppLocalizations.of(context)!.estimateTitle} ${AppLocalizations.of(context)!.invoiceTitle}";
      default:
        return "";
    }
  }

  void _clearFilters() {
    setState(() {
      customerId = null;
      branchId = null;
      orderId.clear();
      _personController.clear();
      filterPersonController.clear();
      fromDate = DateTime.now().toFormattedDate();
      toDate = DateTime.now().toFormattedDate();
    });
    context.read<OrderReportBloc>().add(ResetOrderReportEvent());
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      estimatedContentHeight: 500,
      bodyBuilder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 8),

                /// 🔹 Party Selection
                GenericTextField<
                    IndividualsModel,
                    IndividualsBloc,
                    IndividualsState>(
                  key: const ValueKey('filter_person_field'),
                  controller: filterPersonController,
                  title: tr.party,
                  hintText: tr.party,
                  bloc: context.read<IndividualsBloc>(),
                  fetchAllFunction: (bloc) =>
                      bloc.add(LoadIndividualsEvent()),
                  searchFunction: (bloc, query) =>
                      bloc.add(LoadIndividualsEvent()),
                  showAllOption: true,
                  allOption: IndividualsModel(
                    perId: null,
                    perName: tr.all,
                    perLastName: '',
                  ),
                  itemBuilder: (context, ind) {
                    if (ind.perId == null) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          tr.all,
                          style: TextStyle(
                            color: color.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${ind.perName ?? ''} ${ind.perLastName ?? ''}",
                      ),
                    );
                  },
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
                    setSheetState(() {
                      customerId = value.perId;
                    });
                  },
                  showClearButton: true,
                ),

                const SizedBox(height: 16),

                /// 🔹 Branch Dropdown
                BranchDropdown(
                  showAllOption: true,
                  title: tr.branch,
                  onBranchSelected: (e) {
                    setSheetState(() {
                      branchId = e?.brcId;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// 🔹 Order ID
                ZTextFieldEntitled(
                  controller: orderId,
                  title: tr.orderId,
                  hint: "#123",
                  inputFormat: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
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

                /// 🔹 Buttons
                Row(
                  children: [
                    if (hasFilter)
                      Expanded(
                        child: ZOutlineButton(
                          backgroundHover:
                          Theme.of(context).colorScheme.error,
                          onPressed: () {
                            setSheetState(() {
                              customerId = null;
                              branchId = null;
                              orderId.clear();
                              filterPersonController.clear();
                              fromDate =
                                  DateTime.now().toFormattedDate();
                              toDate =
                                  DateTime.now().toFormattedDate();
                            });

                            setState(() {
                              _personController.clear();
                            });
                          },
                          label: Text(tr.clear),
                        ),
                      ),

                    if (hasFilter)
                      const SizedBox(width: 8),

                    Expanded(
                      child: ZOutlineButton(
                        isActive: true,
                        onPressed: () {
                          Navigator.pop(context);

                          setState(() {
                            if (filterPersonController
                                .text
                                .isNotEmpty) {
                              _personController.text =
                                  filterPersonController.text;
                            }
                          });

                          context.read<OrderReportBloc>().add(
                            LoadOrderReportEvent(
                              fromDate: fromDate,
                              toDate: toDate,
                              branchId: branchId,
                              orderId:
                              int.tryParse(orderId.text),
                              customerId: customerId,
                              orderName: widget.orderName,
                            ),
                          );
                        },
                        label: Text(tr.apply),
                      ),
                    ),
                  ],
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
        title: Text(header(widget.orderName)),
        titleSpacing: 0,
        actions: [
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected Filters Chips
          if (hasFilter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_personController.text.isNotEmpty)
                      _buildFilterChip(
                        label: _personController.text,
                        color: color.primary,
                        onRemove: () {
                          setState(() {
                            customerId = null;
                            _personController.clear();
                          });
                          if (!hasFilter) {
                            context.read<OrderReportBloc>().add(ResetOrderReportEvent());
                          }
                        },
                      ),
                    if (branchId != null)
                      _buildFilterChip(
                        label: "${tr.branch}: $branchId",
                        color: color.secondary,
                        onRemove: () {
                          setState(() {
                            branchId = null;
                          });
                          if (!hasFilter) {
                            context.read<OrderReportBloc>().add(ResetOrderReportEvent());
                          }
                        },
                      ),
                    if (orderId.text.isNotEmpty)
                      _buildFilterChip(
                        label: "${tr.orderId}: ${orderId.text}",
                        color: color.tertiary,
                        onRemove: () {
                          setState(() {
                            orderId.clear();
                          });
                          if (!hasFilter) {
                            context.read<OrderReportBloc>().add(ResetOrderReportEvent());
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: BlocBuilder<OrderReportBloc, OrderReportState>(
              builder: (context, state) {
                if (state is OrderReportInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 64,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          header(widget.orderName),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Filter and review orders by branch, date, order ID, or party.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color.outline),
                        ),
                        const SizedBox(height: 24),
                        ZOutlineButton(
                          isActive: true,
                          onPressed: _showFilterBottomSheet,
                          icon: Icons.filter_list,
                          label: Text(tr.apply),
                        ),
                      ],
                    ),
                  );
                }
                if (state is OrderReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is OrderReportErrorState) {
                  return NoDataWidget(
                    title: tr.accessDenied,
                    message: state.error,
                    enableAction: false,
                  );
                }
                if (state is OrderReportLoadedSate) {
                  if (state.orders.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.orders.length,
                    itemBuilder: (context, index) {
                      final ord = state.orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            Utils.goto(
                              context,
                              OrderByIdView(
                                orderId: ord.ordId!,
                                ordName: ord.ordName,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.primary.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "#${ord.ordId}",
                                        style: TextStyle(
                                          color: color.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ord.timing.toFormattedDate(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color.outline,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Party Name
                                Text(
                                  ord.fullName ?? "",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Reference (if not Estimate)
                                if (widget.orderName != "Estimate" && ord.ordTrnRef != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt,
                                        size: 14,
                                        color: color.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ord.ordTrnRef!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 4),

                                // Branch
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 14,
                                      color: color.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ord.ordBranchName ?? "",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color.outline,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),

                                // Total Amount
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.primary.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "${ord.totalBill.toAmount()} $baseCcy",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color.primary,
                                          fontSize: 16,
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

  Widget _buildFilterChip({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  final String? orderName;
  const _Tablet(this.orderName);

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  late String fromDate;
  late String toDate;
  int? branchId;
  int? customerId;
  final _personController = TextEditingController();
  final orderId = TextEditingController();

  String? myLocale;
  String? baseCcy;
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    baseCcy = _getBaseCurrency();
    fromDate = DateTime.now().toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<OrderReportBloc>().add(ResetOrderReportEvent());
  }

  @override
  void dispose() {
    _personController.dispose();
    orderId.dispose();
    super.dispose();
  }

  bool get hasFilter {
    return branchId != null || customerId != null || _personController.text.isNotEmpty || orderId.text.isNotEmpty;
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

  String header(String? orderName) {
    if (orderName == null) return "";
    switch (orderName) {
      case "Purchase":
        return "${AppLocalizations.of(context)!.purchaseTitle} ${AppLocalizations.of(context)!.invoiceTitle}";
      case "Sale":
        return "${AppLocalizations.of(context)!.saleTitle} ${AppLocalizations.of(context)!.invoiceTitle}";
      case "Estimate":
        return "${AppLocalizations.of(context)!.estimateTitle} ${AppLocalizations.of(context)!.invoiceTitle}";
      default:
        return "";
    }
  }

  void _clearFilters() {
    setState(() {
      customerId = null;
      branchId = null;
      orderId.clear();
      _personController.clear();
      fromDate = DateTime.now().toFormattedDate();
      toDate = DateTime.now().toFormattedDate();
    });
    context.read<OrderReportBloc>().add(ResetOrderReportEvent());
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(header(widget.orderName)),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              context.read<OrderReportBloc>().add(LoadOrderReportEvent(
                fromDate: fromDate,
                toDate: toDate,
                branchId: branchId,
                orderId: int.tryParse(orderId.text),
                customerId: customerId,
                orderName: widget.orderName,
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Party
                  SizedBox(
                    width: 300,
                    child: GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                      key: const ValueKey('tablet_person_field'),
                      controller: _personController,
                      title: tr.party,
                      hintText: tr.party,
                      bloc: context.read<IndividualsBloc>(),
                      fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                      searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
                      showAllOption: true,
                      allOption: IndividualsModel(
                        perId: null,
                        perName: tr.all,
                        perLastName: '',
                      ),
                      itemBuilder: (context, ind) {
                        if (ind.perId == null) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              tr.all,
                              style: TextStyle(
                                color: color.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("${ind.perName ?? ''} ${ind.perLastName ?? ''}"),
                        );
                      },
                      itemToString: (individual) => "${individual.perName} ${individual.perLastName}",
                      stateToLoading: (state) => state is IndividualLoadingState,
                      stateToItems: (state) {
                        if (state is IndividualLoadedState) return state.individuals;
                        return [];
                      },
                      onSelected: (value) {
                        setState(() {
                          customerId = value.perId;
                        });
                      },
                      showClearButton: true,
                    ),
                  ),
                  // Branch
                  SizedBox(
                    width: 200,
                    child: BranchDropdown(
                      showAllOption: true,
                      title: tr.branch,
                      onBranchSelected: (e) {
                        setState(() {
                          branchId = e?.brcId;
                        });
                      },
                    ),
                  ),
                  // Order ID
                  SizedBox(
                    width: 150,
                    child: ZTextFieldEntitled(
                      controller: orderId,
                      title: tr.orderId,
                      hint: "#",
                      inputFormat: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  // From Date
                  SizedBox(
                    width: 150,
                    child: ZDatePicker(
                      label: tr.fromDate,
                      value: fromDate,
                      onDateChanged: (v) {
                        setState(() {
                          fromDate = v;
                        });
                      },
                    ),
                  ),
                  // To Date
                  SizedBox(
                    width: 150,
                    child: ZDatePicker(
                      label: tr.toDate,
                      value: toDate,
                      onDateChanged: (v) {
                        setState(() {
                          toDate = v;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<OrderReportBloc, OrderReportState>(
              builder: (context, state) {
                if (state is OrderReportInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 80,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          header(widget.orderName),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Filter and review orders by branch, date, order ID, or party.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color.outline),
                        ),
                      ],
                    ),
                  );
                }
                if (state is OrderReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is OrderReportErrorState) {
                  return NoDataWidget(
                    title: tr.accessDenied,
                    message: state.error,
                    enableAction: false,
                  );
                }
                if (state is OrderReportLoadedSate) {
                  if (state.orders.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }

                  // Grid view for tablet
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.orders.length,
                    itemBuilder: (context, index) {
                      final ord = state.orders[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            Utils.goto(
                              context,
                              OrderByIdView(
                                orderId: ord.ordId!,
                                ordName: ord.ordName,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "#${ord.ordId}",
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
                                        color: color.primary.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        ord.timing.toFormattedDate(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: color.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Party Name
                                Text(
                                  ord.fullName ?? "",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Reference (if not Estimate)
                                if (widget.orderName != "Estimate" && ord.ordTrnRef != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt,
                                        size: 12,
                                        color: color.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ord.ordTrnRef!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color.outline,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 4),

                                // Branch
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 12,
                                      color: color.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        ord.ordBranchName ?? "",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: color.outline,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                // Total Amount
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr.totalTitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color.outline,
                                      ),
                                    ),
                                    Text(
                                      "${ord.totalBill.toAmount()} $baseCcy",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: color.primary,
                                        fontSize: 14,
                                      ),
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
  final String? orderName;
  const _Desktop(this.orderName);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  late String fromDate;
  late String toDate;
  int? branchId;
  int? customerId;
  final _personController = TextEditingController();
  final orderId = TextEditingController();

  String? myLocale;
  String? baseCcy;
  @override
  void initState() {
    super.initState();
    baseCcy = _getBaseCurrency();
    fromDate = DateTime.now().toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<OrderReportBloc>().add(ResetOrderReportEvent());
  }

  bool get hasFilter {
    return branchId !=null || customerId !=null || _personController.text.isNotEmpty;
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
  @override
  Widget build(BuildContext context) {
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.surface,
    );
    final tr = AppLocalizations.of(context)!;
    String header(String? orderName) {
      if (orderName == null) return "";
      switch (orderName) {
        case "Purchase":
          return "${tr.purchaseTitle} ${tr.invoiceTitle}";
        case "Sale":
          return "${tr.saleTitle} ${tr.invoiceTitle}";
        case "Estimate":
          return "${tr.estimateTitle} ${tr.invoiceTitle}";
        default:
          return "";
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(header(widget.orderName??"")),
        titleSpacing: 0,
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          if(hasFilter)...[
            ZOutlineButton(
              onPressed: () {
                setState(() {
                  customerId = null;
                  branchId = null;
                  orderId.clear();
                  _personController.clear();
                  fromDate = DateTime.now().toFormattedDate();
                  toDate = DateTime.now().toFormattedDate();
                });
                context.read<OrderReportBloc>().add(ResetOrderReportEvent());
              },
              backgroundHover: Theme.of(context).colorScheme.error,
              isActive: true,
              width: 140,
              icon: Icons.filter_alt_off_outlined,
              label: Text(tr.clearFilters),
            ),
            SizedBox(width: 8),
          ],
          ZOutlineButton(
            onPressed: () {},
            width: 120,
            icon: Icons.print,
            label: Text(tr.print),
          ),
          SizedBox(width: 8),
          ZOutlineButton(
            onPressed: () {
              if(widget.orderName !=null){
                context.read<OrderReportBloc>().add(LoadOrderReportEvent(
                    fromDate: fromDate,
                    toDate: toDate,
                    branchId: branchId,
                    orderId: int.tryParse(orderId.text),
                    customerId: customerId,
                    orderName: widget.orderName
                ));
              }
            },
            isActive: true,
            width: 120,
            icon: Icons.filter_alt_outlined,
            label: Text(tr.apply),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                    key: const ValueKey('person_field'),
                    controller: _personController,
                    title: tr.party,
                    hintText: tr.party,
                    bloc: context.read<IndividualsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                    searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
                    showAllOption: true,
                    allOption: IndividualsModel(
                      perId: null,
                      perName: tr.all,
                      perLastName: '',
                    ),
                    itemBuilder: (context, ind) {
                      if (ind.perId == null) {
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
                        child: Text("${ind.perName ?? ''} ${ind.perLastName ?? ''}"),
                      );
                    },
                    itemToString: (individual) => "${individual.perName} ${individual.perLastName}",
                    stateToLoading: (state) => state is IndividualLoadingState,
                    stateToItems: (state) {
                      if (state is IndividualLoadedState) return state.individuals;
                      return [];
                    },
                    onSelected: (value) {
                      setState(() {
                        customerId = value.perId;
                      });
                    },
                    showClearButton: true,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: BranchDropdown(
                      showAllOption: true,
                      title: tr.branch,
                      onBranchSelected: (e){
                        setState(() {
                          branchId = e?.brcId;
                        });
                      }),
                ),
                Expanded(
                  child: ZTextFieldEntitled(
                      controller: orderId,
                      title: tr.orderId,
                      hint: "#",
                      inputFormat: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                Expanded(
                  child: ZDatePicker(
                    label: tr.fromDate,
                    value: fromDate,
                    onDateChanged: (v) {
                      setState(() {
                        fromDate = v;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ZDatePicker(
                    label: tr.toDate,
                    value: toDate,
                    onDateChanged: (v) {
                      setState(() {
                        toDate = v;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15,vertical: 8),
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .8),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 50,
                    child: Text(tr.id,style: titleStyle)),

                SizedBox(
                    width: 100,
                    child: Text(tr.date,style: titleStyle)),

                if(widget.orderName != "Estimate")
                SizedBox(
                    width: 180,
                    child: Text(tr.referenceNumber,style: titleStyle)),
                Expanded(
                    child: Text(tr.party,style: titleStyle)),

                SizedBox(
                    width: 150,
                    child: Text(tr.branch,style: titleStyle,)),
                SizedBox(
                    width: 150,
                    child: Text(tr.totalTitle,style: titleStyle,)),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<OrderReportBloc, OrderReportState>(
              builder: (context, state) {
                if(state is OrderReportInitial){
                  return NoDataWidget(
                    title: header(widget.orderName),
                    message: "Filter and review orders by branch, date, order ID, or party.",
                    enableAction: false,
                  );
                }
                if(state is OrderReportLoadingState){
                  return Center(child: CircularProgressIndicator());
                }
                if(state is OrderReportErrorState){
                  return NoDataWidget(
                    title: tr.accessDenied,
                    message: state.error,
                    enableAction: false,
                  );
                }if(state is OrderReportLoadedSate){
                  if(state.orders.isEmpty){
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                      itemCount: state.orders.length,
                      itemBuilder: (context,index){
                       final ord = state.orders[index];
                    return InkWell(
                      onTap: (){
                        Utils.goto(
                          context,
                          OrderByIdView(orderId: ord.ordId!,ordName: ord.ordName),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15,vertical: 8),
                        margin: EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: index.isEven? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 50,
                                child: Text(ord.ordId.toString())),
                            SizedBox(
                                width: 100,
                                child: Text(ord.timing.toFormattedDate())),
                            if(widget.orderName != "Estimate")
                            SizedBox(
                                width: 180,
                                child: Text(ord.ordTrnRef ??"")),
                            Expanded(
                                child: Text(ord.fullName??"")),

                            SizedBox(
                                width: 150,
                                child: Text(ord.ordBranchName ??"")),
                            SizedBox(
                                width: 150,
                                child: Text("${ord.totalBill.toAmount()} $baseCcy" )),
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
        ],
      ),
    );
  }
}
