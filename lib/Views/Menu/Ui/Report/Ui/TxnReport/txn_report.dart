import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/features/users_drop.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../Features/Other/utils.dart';
import '../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../Transport/Shipments/features/status_drop.dart';
import 'bloc/txn_report_bloc.dart';
import 'features/txn_type_drop.dart';
import 'model/txn_report_model.dart';

class TransactionReportView extends StatelessWidget {
  const TransactionReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Mobile(),
      desktop: _Desktop(),
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
  String? myLocale;

  int? status;
  String? currency;
  String? maker;
  String? checker;
  String? txnType;

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now().toFormattedDate();
    toDate = DateTime.now().toFormattedDate();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<TxnReportBloc>().add(ResetTxnReportEvent());
  }

  bool get hasAnyFilter {
    return status != null ||
        currency != null ||
        maker != null ||
        checker != null ||
        txnType != null;
  }

  void _clearFilters() {
    setState(() {
      maker = null;
      checker = null;
      txnType = null;
      currency = null;
      status = null;
      fromDate = DateTime.now().toFormattedDate();
      toDate = DateTime.now().toFormattedDate();
    });
    context.read<TxnReportBloc>().add(ResetTxnReportEvent());
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;

    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      estimatedContentHeight: 600,
      bodyBuilder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 8),

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

                const SizedBox(height: 16),

                /// 🔹 Maker
                UserDropdown(
                  title: tr.maker,
                  isMulti: false,
                  onSingleChanged: (e) {
                    setSheetState(() {
                      maker = e?.usrName;
                    });
                  },
                  onMultiChanged: (e) {},
                ),
                const SizedBox(height: 12),

                /// 🔹 Checker
                UserDropdown(
                  title: tr.checker,
                  isMulti: false,
                  onSingleChanged: (e) {
                    setSheetState(() {
                      checker = e?.usrName;
                    });
                  },
                  onMultiChanged: (e) {},
                ),
                const SizedBox(height: 12),

                /// 🔹 Transaction Type
                TxnTypeDropDown(
                  title: tr.txnType,
                  isMulti: false,
                  onSingleChanged: (e) {
                    setSheetState(() {
                      txnType = e?.trntCode;
                    });
                  },
                  onMultiChanged: (e) {},
                ),
                const SizedBox(height: 12),

                /// 🔹 Currency
                CurrencyDropdown(
                  title: tr.currencyTitle,
                  isMulti: false,
                  onSingleChanged: (e) {
                    setSheetState(() {
                      currency = e?.ccyCode;
                    });
                  },
                  onMultiChanged: (e) {},
                ),
                const SizedBox(height: 12),

                /// 🔹 Status
                StatusDropdown(
                  value: status,
                  onChanged: (v) {
                    setSheetState(() => status = v);
                  },
                ),

                const SizedBox(height: 12),

                /// 🔹 Buttons
                Row(
                  children: [
                    if (hasAnyFilter)
                      Expanded(
                        child: ZOutlineButton(
                          backgroundHover:
                          Theme.of(context).colorScheme.error,
                          onPressed: () {
                            setSheetState(() {
                              maker = null;
                              checker = null;
                              txnType = null;
                              currency = null;
                              status = null;
                              fromDate = DateTime.now().toFormattedDate();
                              toDate = DateTime.now().toFormattedDate();
                            });
                            setState(() {});
                          },
                          label: Text(tr.clear),
                        ),
                      ),

                    if (hasAnyFilter) const SizedBox(width: 8),

                    Expanded(
                      child: ZOutlineButton(
                        isActive: true,
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<TxnReportBloc>().add(
                            LoadTxnReportEvent(
                              fromDate: fromDate,
                              toDate: toDate,
                              checker: checker,
                              maker: maker,
                              status: status,
                              txnType: txnType,
                              currency: currency,
                            ),
                          );
                        },
                        label: Text(tr.apply),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
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
        titleSpacing: 0,
        title: Text(tr.transactionReport),
        actionsPadding: EdgeInsets.symmetric(horizontal: 8),
        actions: [
          if (hasAnyFilter)
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
          if (hasAnyFilter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: "${tr.fromDate}: $fromDate",
                      color: color.primary,
                      onRemove: () {
                        setState(() {
                          fromDate = DateTime.now().toFormattedDate();
                        });
                      },
                    ),
                    _buildFilterChip(
                      label: "${tr.toDate}: $toDate",
                      color: color.primary,
                      onRemove: () {
                        setState(() {
                          toDate = DateTime.now().toFormattedDate();
                        });
                      },
                    ),
                    if (maker != null)
                      _buildFilterChip(
                        label: "${tr.maker}: $maker",
                        color: color.secondary,
                        onRemove: () {
                          setState(() {
                            maker = null;
                          });
                        },
                      ),
                    if (checker != null)
                      _buildFilterChip(
                        label: "${tr.checker}: $checker",
                        color: color.tertiary,
                        onRemove: () {
                          setState(() {
                            checker = null;
                          });
                        },
                      ),
                    if (txnType != null)
                      _buildFilterChip(
                        label: "${tr.txnType}: $txnType",
                        color: Colors.purple,
                        onRemove: () {
                          setState(() {
                            txnType = null;
                          });
                        },
                      ),
                    if (currency != null)
                      _buildFilterChip(
                        label: "${tr.currencyTitle}: $currency",
                        color: Colors.orange,
                        onRemove: () {
                          setState(() {
                            currency = null;
                          });
                        },
                      ),
                    if (status != null)
                      _buildFilterChip(
                        label: "${tr.status}: ${status == 1 ? tr.active : tr.inactive}",
                        color: status == 1 ? Colors.green : color.error,
                        onRemove: () {
                          setState(() {
                            status = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: BlocBuilder<TxnReportBloc, TxnReportState>(
              builder: (context, state) {
                if (state is TxnReportInitial) {
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
                          tr.transactionReport,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Select filters above and Apply to view transactions.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color.outline),
                        ),
                        const SizedBox(height: 15),
                        ZOutlineButton(
                          onPressed: _showFilterBottomSheet,
                          icon: Icons.filter_list,
                          isActive: true,
                          label: Text(tr.applyFilter),
                        ),
                      ],
                    ),
                  );
                }
                if (state is TxnReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TxnReportErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: color.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.error,
                            style: TextStyle(color: color.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is TxnReportLoadedState) {
                  if (state.txn.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.txn.length,
                    itemBuilder: (context, index) {
                      final txn = state.txn[index];
                      return _buildMobileTransactionCard(txn, index);
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
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransactionCard(TransactionReportModel txn, int index) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final isEven = index.isEven;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.outline.withValues(alpha: .1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isEven ? color.primary.withValues(alpha: .02) : color.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - ID and Status
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
                      "#${txn.no}",
                      style: TextStyle(
                        color: color.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: txn.status == 1
                          ? Colors.green.withValues(alpha: .1)
                          : color.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      txn.statusText ?? "",
                      style: TextStyle(
                        color: txn.status == 1 ? Colors.green : color.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date - FIXED: Use toDateTime getter properly
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: color.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    txn.timing != null
                        ? (txn.timing is DateTime
                        ? (txn.timing as DateTime).toDateTime
                        : txn.timing.toString())
                        : "",
                    style: TextStyle(
                      fontSize: 13,
                      color: color.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Reference
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    size: 14,
                    color: color.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${tr.referenceNumber}: ${txn.reference ?? ""}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Type, Maker, Checker in a row
              Row(
                children: [
                  // Transaction Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.txnType,
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.secondary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            txn.type ?? "",
                            style: TextStyle(
                              fontSize: 12,
                              color: color.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Maker
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          tr.maker,
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          txn.maker ?? "",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Checker
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tr.checker,
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          txn.checker ?? "",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Amount - EXACTLY as in desktop
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.amount,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.outline,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        txn.actualAmount.toAmount(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color.primary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        txn.currency ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: Utils.currencyColors(txn.currency ?? ""),
                          fontWeight: FontWeight.w500,
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
  String? myLocale;
  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now().toFormattedDate();
    toDate   = DateTime.now().toFormattedDate();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<TxnReportBloc>().add(ResetTxnReportEvent());
  }
  bool get hasAnyFilter {
    return status != null ||
        currency != null ||
        maker != null ||
        checker != null ||
        txnType != null;
  }

  int? status;
  String? currency;
  String? maker;
  String? checker;
  String? txnType;
  @override
  Widget build(BuildContext context) {
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text("${tr.transactions} ${tr.report}"),
       titleSpacing: 0,
       actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          if (hasAnyFilter)
          ZOutlineButton(
              isActive: true,
              onPressed: (){
                setState(() {
                  maker = null;
                  checker = null;
                  txnType = null;
                  currency = null;
                  status = null;
                   fromDate = DateTime.now().toFormattedDate();
                   toDate = DateTime.now().toFormattedDate();
                });
                context.read<TxnReportBloc>().add(ResetTxnReportEvent());
              },
              icon: Icons.filter_alt_off_outlined,
              label: Text(tr.clearFilters)),
          SizedBox(width: 8),
          ZOutlineButton(
              onPressed: (){},
              icon: Icons.print,
              label: Text(tr.print)),
          SizedBox(width: 8),
          ZOutlineButton(
              onPressed: (){
                context.read<TxnReportBloc>().add(LoadTxnReportEvent(
                  fromDate: fromDate,
                  toDate: toDate,
                  checker: checker,
                  maker: maker,
                  status: status,
                  txnType: txnType,
                  currency: currency,
                ));
              },
              isActive: true,
              icon: Icons.filter_alt,
              label: Text(tr.apply)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
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
                Expanded(
                  child: UserDropdown(
                    title: tr.maker,
                    isMulti: false,
                    onSingleChanged: (e) {
                      setState(() {
                        maker = e?.usrName;
                      });
                    },
                    onMultiChanged: (e) {},
                  ),
                ),
                Expanded(
                  child: UserDropdown(
                    isMulti: false,
                    title: tr.checker,
                    onSingleChanged: (e) {
                      setState(() {
                        checker = e?.usrName;
                      });
                    },
                    onMultiChanged: (e) {},
                  ),
                ),
                Expanded(
                  child: TxnTypeDropDown(
                    title: tr.txnType,
                    isMulti: false,
                    onSingleChanged: (e) {
                      setState(() {
                        txnType = e?.trntCode;
                      });
                    },
                    onMultiChanged: (e) {},
                  ),
                ),
                Expanded(
                  child: CurrencyDropdown(
                    isMulti: false,
                    title: tr.currencyTitle,
                    onSingleChanged: (e) {
                      setState(() {
                        currency = e?.ccyCode;
                      });
                    },
                    onMultiChanged: (e) {},
                  ),
                ),
                Expanded(
                  child: StatusDropdown(
                    value: status,
                    items: [
                      StatusItem(null, tr.all),
                      StatusItem(1, tr.authorizedTitle),
                      StatusItem(0, tr.pendingTitle),
                    ],
                    onChanged: (v) {
                      setState(() => status = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 40,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .9)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 5),
            child: Row(
              children: [
                SizedBox(
                    width: 180,
                    child: Text(tr.date,style: titleStyle)),
                Expanded(
                    child: Text(tr.referenceNumber,style: titleStyle)),
                SizedBox(
                    width: 200,
                    child: Text(tr.txnType,style: titleStyle)),
                SizedBox(
                    width: 120,
                    child: Text(tr.maker,style: titleStyle)),
                SizedBox(
                    width: 120,
                    child: Text(tr.checker,style: titleStyle)),
                SizedBox(
                    width: 120,
                    child: Text(tr.status,style: titleStyle)),
                SizedBox(
                    width: 150,
                    child: Text(tr.amount,style: titleStyle, textAlign: myLocale == "en"? TextAlign.right : TextAlign.left)),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TxnReportBloc, TxnReportState>(
              builder: (context, state) {
                if(state is TxnReportInitial){
                  return NoDataWidget(
                    title: "Transaction Report",
                    message: "Select filters above and click Apply to view transactions.",
                    enableAction: false,
                  );
                }
                if(state is TxnReportLoadingState){
                  return Center(child: CircularProgressIndicator());
                }
                if(state is TxnReportErrorState){
                  return NoDataWidget(
                    title: "Error",
                    message: state.error,
                    enableAction: false,
                  );
                }if(state is TxnReportLoadedState){
                  if(state.txn.isEmpty){
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                      itemCount: state.txn.length,
                      itemBuilder: (context,index){
                      final txn = state.txn[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: index.isEven? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 180,
                                  child: Text(txn.timing?.toDateTime ?? "")),
                              Expanded(
                                  child: Text(txn.reference.toString())),

                              SizedBox(
                                  width: 200,
                                  child: Text(txn.type.toString())),
                              SizedBox(
                                  width: 120,
                                  child: Text(txn.maker.toString())),
                              SizedBox(
                                  width: 120,
                                  child: Text(txn.checker.toString())),
                              SizedBox(
                                  width: 120,
                                  child: Text(txn.statusText??"")),
                              SizedBox(
                                  width: 150,
                                  child: Text("${txn.actualAmount.toAmount()} ${txn.currency}", textAlign: myLocale == "en"? TextAlign.right : TextAlign.left)),
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
