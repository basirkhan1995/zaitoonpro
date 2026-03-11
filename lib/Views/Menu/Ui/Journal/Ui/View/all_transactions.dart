import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/cover.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Features/Widgets/txn_status_widget.dart';
import 'package:zaitoon_petroleum/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/FetchGLAT/Ui/glat_view.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/GetOrder/bloc/order_txn_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/GetOrder/txn_oder.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/ProjectTxn/bloc/project_txn_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/ProjectTxn/project_txn.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/bloc/transactions_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Journal/Ui/model/transaction_model.dart';
import '../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../Features/Widgets/search_field.dart';
import '../FetchATAT/bloc/fetch_atat_bloc.dart';
import '../FetchATAT/fetch_atat.dart';
import '../FetchGLAT/bloc/glat_bloc.dart';
import '../FetchTRPT/Ui/trpt_view.dart';
import '../FetchTRPT/bloc/trpt_bloc.dart';
import '../TxnByReference/bloc/txn_reference_bloc.dart';
import '../TxnByReference/txn_reference.dart';

class AllTransactionsView extends StatelessWidget {
  const AllTransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Mobile(), tablet: _Tablet(), desktop: _Desktop());
  }
}


class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final Map<String, bool> _copiedStates = {};
  bool _isLoadingDialog = false;
  String? _loadingRef;
  String? myLocale;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('all'));
    });
    myLocale = context.read<LocalizationBloc>().state.languageCode;
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTransactionTap(dynamic txn) {
    setState(() {
      _isLoadingDialog = true;
      _loadingRef = txn.trnReference;
    });

    final handlers = <String, void Function(String)>{
      "PRJT": (ref) => context.read<ProjectTxnBloc>().add(LoadProjectTxnEvent(ref)),
      "ATAT": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "SLRY": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "PLCL": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "CRFX": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "TRPT": (ref) => context.read<TrptBloc>().add(LoadTrptEvent(ref)),
      "GLAT": (ref) => context.read<GlatBloc>().add(LoadGlatEvent(ref)),
      "SALE": (ref) => context.read<OrderTxnBloc>().add(FetchOrderTxnEvent(reference: ref)),
      "PRCH": (ref) => context.read<OrderTxnBloc>().add(FetchOrderTxnEvent(reference: ref)),
    };

    final handler = handlers[txn.trnType];
    if (handler != null) {
      handler(txn.trnReference ?? "");
    } else {
      context.read<TxnReferenceBloc>().add(FetchTxnByReferenceEvent(txn.trnReference ?? ""));
    }
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);

    setState(() {
      _copiedStates[reference] = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStates.remove(reference);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return MultiBlocListener(
      listeners: [

        BlocListener<ProjectTxnBloc, ProjectTxnState>(
          listener: (context, state) {
            if (state is ProjectTxnLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => ProjectTxnView(reference: state.txn.transaction?.trnReference ?? ""),
              );
            } else if (state is ProjectTxnErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            }
          },
        ),
        BlocListener<OrderTxnBloc, OrderTxnState>(
          listener: (context, state) {
            if (state is OrderTxnLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => OrderTxnView(reference: state.data.trnReference ?? ""),
              );
            } else if (state is OrderTxnErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            }
          },
        ),
        BlocListener<TrptBloc, TrptState>(
          listener: (context, state) {
            if (state is TrptLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => TrptView(reference: state.trpt.shdTrnRef ?? ""),
              );
            } else if (state is TrptErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.error,
                isError: true,
              );
            }
          },
        ),
        BlocListener<GlatBloc, GlatState>(
          listener: (context, state) {
            if (state is GlatLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => GlatView(),
              );
            } else if (state is GlatErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            } else if (state is GlatLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
        BlocListener<FetchAtatBloc, FetchAtatState>(
          listener: (context, state) {
            if (state is FetchATATLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => FetchAtatView(),
              );
            } else if (state is FetchATATErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            } else if (state is FetchATATLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
        BlocListener<TxnReferenceBloc, TxnReferenceState>(
          listener: (context, state) {
            if (state is TxnReferenceLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => TxnReferenceView(),
              );
            } else if (state is TxnReferenceErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.accessDenied,
                message: state.error,
                isError: true,
              );
            } else if (state is TxnReferenceLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
      ],
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(
                tr.todayTransaction,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              centerTitle: false,
              actions: [
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('all'));
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Search Bar - Sticky at top
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 8),
                  child: ZSearchField(
                    icon: Icons.search_rounded,
                    controller: searchController,
                    hint: "${tr.search} ${tr.transactions.toLowerCase()}...",
                    onChanged: (_) => setState(() {}),
                    title: "",
                  ),
                ),

                // Stats Summary
                BlocBuilder<TransactionsBloc, TransactionsState>(
                  builder: (context, state) {
                    int totalCount = 0;
                    if (state is TransactionLoadedState) {
                      totalCount = state.txn.length;
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 16,
                                  color: color.onPrimaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$totalCount ${tr.transactions}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: color.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Transactions List
                Expanded(
                  child: BlocConsumer<TransactionsBloc, TransactionsState>(
                    listener: (context, state) {
                      if (state is TransactionSuccessState) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
                          context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('all'));
                        });
                      }
                    },
                    builder: (context, state) {
                      if (state is TransactionErrorState) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: color.error.withAlpha(100),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                tr.noDataFound,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: color.onSurface.withAlpha(150),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ZOutlineButton(
                                icon: Icons.refresh_rounded,
                                onPressed: () {
                                  context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('all'));
                                },
                                label: Text(tr.refresh),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is TxnLoadingState) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (state is TransactionLoadedState) {
                        final query = searchController.text.toLowerCase().trim();
                        final filteredList = state.txn.where((item) {
                          final reference = item.trnReference?.toLowerCase() ?? '';
                          final type = item.trnType?.toLowerCase() ?? '';
                          final user = item.usrName?.toLowerCase() ?? '';
                          final status = item.trnStateText?.toLowerCase() ?? '';

                          return reference.contains(query) ||
                              type.contains(query) ||
                              user.contains(query) ||
                              status.contains(query);
                        }).toList();

                        if (filteredList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: color.onSurface.withAlpha(80),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tr.noDataFound,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (query.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'No results for "$query"',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: color.onSurface.withAlpha(150),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('all'));
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final txn = filteredList[index];
                              final isLoadingThisItem = _isLoadingDialog && _loadingRef == txn.trnReference;
                              final isCopied = _copiedStates[txn.trnReference ?? ""] ?? false;
                              final reference = txn.trnReference ?? "";

                              return _buildTransactionCard(
                                txn: txn,
                                isLoading: isLoadingThisItem,
                                isCopied: isCopied,
                                reference: reference,
                                color: color,
                                tr: tr,
                                onTap: () => _handleTransactionTap(txn),
                                onCopy: () => _copyToClipboard(reference, context),
                              );
                            },
                          ),
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Global Loading Overlay
          if (_isLoadingDialog && _loadingRef == null)
            Container(
              color: Colors.black.withAlpha(100),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required TransactionsModel txn,
    required bool isLoading,
    required bool isCopied,
    required String reference,
    required ColorScheme color,
    required AppLocalizations tr,
    required VoidCallback onTap,
    required VoidCallback onCopy,
  }) {
    // Determine transaction type color
    Color typeColor = color.primary;
    IconData typeIcon = Icons.receipt_rounded;

    switch (txn.trnType) {
      case 'SALE':
        typeColor = Colors.green;
        typeIcon = Icons.shopping_cart_rounded;
        break;
      case 'PRCH':
        typeColor = Colors.blue;
        typeIcon = Icons.shopping_bag_rounded;
        break;
      case 'PRJT':
        typeColor = Colors.purple;
        typeIcon = Icons.account_tree_rounded;
        break;
      case 'TRPT':
        typeColor = Colors.orange;
        typeIcon = Icons.local_shipping_rounded;
        break;
      case 'GLAT':
        typeColor = Colors.teal;
        typeIcon = Icons.account_balance_rounded;
        break;
      case 'ATAT':
        typeColor = Colors.indigo;
        typeIcon = Icons.swap_horiz_rounded;
        break;
    }

    return ZCover(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 5,
      color: Theme.of(context).colorScheme.surface,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                // Loading indicator overlay for this specific item
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.surface.withAlpha(200),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),

                // Main content
                Opacity(
                  opacity: isLoading ? 0.5 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Type & Status
                      Row(
                        children: [
                          // Transaction Type Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  typeIcon,
                                  size: 14,
                                  color: typeColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  Utils.getTxnCode(txn: txn.trnType ?? "", context: context),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Status Badge
                          Expanded(
                            child: TransactionStatusBadge(
                              status: txn.trnStateText ?? "",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Reference & Copy Button
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.referenceNumber,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color.onSurface.withAlpha(150),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reference,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Copy Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isLoading ? null : onCopy,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCopied
                                      ? color.primary.withAlpha(15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isCopied ? Icons.check_rounded : Icons.copy_rounded,
                                  size: 20,
                                  color: isCopied
                                      ? color.primary
                                      : color.onSurface.withAlpha(150),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Date & User Info
                      Row(
                        children: [
                          // Date
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: color.onSurface.withAlpha(150),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  txn.trnEntryDate?.toFormattedDate() ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: color.onSurface.withAlpha(200),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // User
                          if (txn.maker != null && txn.maker!.isNotEmpty)
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 14,
                                    color: color.onSurface.withAlpha(150),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      txn.maker!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: color.onSurface.withAlpha(200),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  final Map<String, bool> _copiedStates = {};
  bool _isLoadingDialog = false;
  String? _loadingRef;
  String? myLocale;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('all'));
    });
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    super.initState();
  }

  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _handleTransactionTap(dynamic txn) {
    setState(() {
      _isLoadingDialog = true;
      _loadingRef = txn.trnReference;
    });

    final handlers = <String, void Function(String)>{
      "PRJT": (ref) => context.read<ProjectTxnBloc>().add(LoadProjectTxnEvent(ref)),
      "ATAT": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "SLRY": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "PLCL": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "CRFX": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "TRPT": (ref) => context.read<TrptBloc>().add(LoadTrptEvent(ref)),
      "GLAT": (ref) => context.read<GlatBloc>().add(LoadGlatEvent(ref)),
      "SALE": (ref) => context.read<OrderTxnBloc>().add(FetchOrderTxnEvent(reference: ref)),
      "PRCH": (ref) => context.read<OrderTxnBloc>().add(FetchOrderTxnEvent(reference: ref)),
    };

    final handler = handlers[txn.trnType];
    if (handler != null) {
      handler(txn.trnReference ?? "");
    } else {
      context.read<TxnReferenceBloc>().add(FetchTxnByReferenceEvent(txn.trnReference ?? ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    return MultiBlocListener(
      listeners: [
        BlocListener<ProjectTxnBloc, ProjectTxnState>(
          listener: (context, state) {
            if (state is ProjectTxnLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => ProjectTxnView(reference: state.txn.transaction?.trnReference ?? ""),
              );
            } else if (state is ProjectTxnErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            }
          },
        ),
        BlocListener<OrderTxnBloc, OrderTxnState>(
          listener: (context, state) {
            if (state is OrderTxnLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => OrderTxnView(reference: state.data.trnReference ?? ""),
              );
            } else if (state is OrderTxnErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            }
          },
        ),
        BlocListener<TrptBloc, TrptState>(
          listener: (context, state) {
            if (state is TrptLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => TrptView(reference: state.trpt.shdTrnRef ?? ""),
              );
            } else if (state is TrptErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.error,
                isError: true,
              );
            }
          },
        ),
        BlocListener<GlatBloc, GlatState>(
          listener: (context, state) {
            if (state is GlatLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => GlatView(),
              );
            } else if (state is GlatErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            } else if (state is GlatLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
        BlocListener<FetchAtatBloc, FetchAtatState>(
          listener: (context, state) {
            if (state is FetchATATLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => FetchAtatView(),
              );
            } else if (state is FetchATATErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            } else if (state is FetchATATLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
        BlocListener<TxnReferenceBloc, TxnReferenceState>(
          listener: (context, state) {
            if (state is TxnReferenceLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => TxnReferenceView(),
              );
            } else if (state is TxnReferenceErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.accessDenied,
                message: state.error,
                isError: true,
              );
            } else if (state is TxnReferenceLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
      ],
      child: Stack(
        children: [
          Scaffold(
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                          flex: 4,
                          child: ListTile(
                            tileColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                            title: Text(tr.todayTransaction,style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(DateTime.now().compact),
                          )),
                      Expanded(
                        flex: 5,
                        child: ZSearchField(
                          icon: FontAwesomeIcons.magnifyingGlass,
                          controller: searchController,
                          hint: AppLocalizations.of(context)!.search,
                          onChanged: (e) {
                            setState(() {});
                          },
                          title: "",
                        ),
                      ),
                      ZOutlineButton(
                        width: 120,
                        icon: Icons.refresh,
                        onPressed: () {
                          context.read<TransactionsBloc>().add(
                            LoadAllTransactionsEvent('all'),
                          );
                        },
                        label: Text(tr.refresh),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .9)
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                          child: Text(tr.txnDate, style: titleStyle)),

                      Expanded(
                          child: Text(tr.referenceNumber,
                              style: titleStyle)),

                      SizedBox(
                          width: 120,
                          child: Text(tr.users,
                              style: titleStyle)),

                      SizedBox(
                          width: 115,
                          child: Text(tr.status,
                              style: titleStyle)),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocConsumer<TransactionsBloc, TransactionsState>(
                    listener: (context, state) {
                      if (state is TransactionSuccessState) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
                          context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('all'));
                        });
                      }
                    },
                    builder: (context, state) {
                      if (state is TransactionErrorState) {
                        return NoDataWidget(
                          message: state.message,
                          onRefresh: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context.read<TransactionsBloc>().add(
                                LoadAllTransactionsEvent('all'),
                              );
                            });
                          },
                        );
                      }
                      if (state is TxnLoadingState) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (state is TransactionLoadedState) {
                        final query = searchController.text.toLowerCase().trim();
                        final filteredList = state.txn.where((item) {
                          final name = item.trnReference?.toLowerCase() ?? '';
                          final status = item.trnStateText?.toLowerCase() ?? '';
                          final trnName = item.trnType?.toLowerCase() ?? '';
                          final usrName = item.usrName?.toLowerCase() ?? '';
                          return name.contains(query) ||
                              status.contains(query) ||
                              usrName.contains(query) ||
                              trnName.contains(query);
                        }).toList();
                        if (state.txn.isEmpty) {
                          return NoDataWidget(
                            message: tr.noDataFound,
                            onRefresh: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                context.read<TransactionsBloc>().add(
                                  LoadAllTransactionsEvent('all'),
                                );
                              });
                            },
                          );
                        }
                        return ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final txn = filteredList[index];
                              final isLoadingThisItem = _isLoadingDialog && _loadingRef == txn.trnReference;
                              final isCopied = _copiedStates[txn.trnReference ?? ""] ?? false;
                              final reference = txn.trnReference ?? "";
                              return Material(
                                child: InkWell(
                                  onTap: isLoadingThisItem
                                      ? null
                                      : () => _handleTransactionTap(txn),
                                  hoverColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .05),
                                  highlightColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .05),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: index.isOdd
                                            ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: .06)
                                            : Colors.transparent),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [

                                          SizedBox(
                                            width: 120,
                                            child: Row(
                                              children: [
                                                if (isLoadingThisItem)
                                                  Container(
                                                    width: 16,
                                                    height: 16,
                                                    margin: EdgeInsets.only(right: myLocale == "en"? 8 : 0, left: myLocale == "en"? 0 : 8),
                                                    child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                Text(txn.trnEntryDate?.toFormattedDate() ?? ""),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                    width: 130,
                                                    child: Text(Utils.getTxnCode(
                                                        txn: txn.trnType ?? "",
                                                        context: context))),
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: Material(
                                                        color: Colors.transparent,
                                                        child: InkWell(
                                                          onTap: () {
                                                            _copyToClipboard(reference, context);
                                                          },
                                                          borderRadius: BorderRadius.circular(4),
                                                          hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                                                          child: AnimatedContainer(
                                                            duration: const Duration(milliseconds: 100),
                                                            decoration: BoxDecoration(
                                                              color: isCopied
                                                                  ? Theme.of(context).colorScheme.primary.withAlpha(25)
                                                                  : Colors.transparent,
                                                              border: Border.all(
                                                                color: isCopied
                                                                    ? Theme.of(context).colorScheme.primary
                                                                    : Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                                                                width: 1,
                                                              ),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Center(
                                                              child: AnimatedSwitcher(
                                                                duration: const Duration(milliseconds: 300),
                                                                child: Icon(
                                                                  isCopied ? Icons.check : Icons.content_copy,
                                                                  key: ValueKey<bool>(isCopied),
                                                                  size: 15,
                                                                  color: isCopied
                                                                      ? Theme.of(context).colorScheme.primary
                                                                      : Theme.of(context).colorScheme.outline.withValues(alpha: .6),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Reference text that takes remaining space
                                                    Expanded(
                                                        child:
                                                        Text(txn.trnReference.toString())),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(
                                            width: 125,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(txn.maker ?? ""),
                                                Text(txn.checker ?? ""),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                              width: 115,
                                              child: TransactionStatusBadge(status: txn.trnStateText??"")),

                                        ],
                                      ),
                                    ),
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
          ),
          if (_isLoadingDialog && _loadingRef == null)
            Container(
              color: Colors.black.withAlpha(100),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);

    // Set copied state to true
    setState(() {
      _copiedStates[reference] = true;
    });

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStates.remove(reference);
        });
      }
    });
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {

  final Map<String, bool> _copiedStates = {};
  bool _isLoadingDialog = false;
  String? _loadingRef;
  String? myLocale;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('all'));
    });
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    super.initState();
  }

  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _handleTransactionTap(dynamic txn) {
    setState(() {
      _isLoadingDialog = true;
      _loadingRef = txn.trnReference;
    });

    final handlers = <String, void Function(String)>{
      "PRJT": (ref) => context.read<ProjectTxnBloc>().add(LoadProjectTxnEvent(ref)),
      "ATAT": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "SLRY": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "PLCL": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "CRFX": (ref) => context.read<FetchAtatBloc>().add(FetchAccToAccEvent(ref)),
      "TRPT": (ref) => context.read<TrptBloc>().add(LoadTrptEvent(ref)),
      "GLAT": (ref) => context.read<GlatBloc>().add(LoadGlatEvent(ref)),
      "SALE": (ref) => context.read<OrderTxnBloc>().add(FetchOrderTxnEvent(reference: ref)),
      "PRCH": (ref) => context.read<OrderTxnBloc>().add(FetchOrderTxnEvent(reference: ref)),
    };

    final handler = handlers[txn.trnType];
    if (handler != null) {
      handler(txn.trnReference ?? "");
    } else {
      context.read<TxnReferenceBloc>().add(FetchTxnByReferenceEvent(txn.trnReference ?? ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    return MultiBlocListener(
      listeners: [
        BlocListener<ProjectTxnBloc, ProjectTxnState>(
          listener: (context, state) {
            if (state is ProjectTxnLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => ProjectTxnView(reference: state.txn.transaction?.trnReference ?? ""),
              );
            } else if (state is ProjectTxnErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            }
          },
        ),
        BlocListener<OrderTxnBloc, OrderTxnState>(
          listener: (context, state) {
            if (state is OrderTxnLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => OrderTxnView(reference: state.data.trnReference ?? ""),
              );
            } else if (state is OrderTxnErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            }
          },
        ),
        BlocListener<TrptBloc, TrptState>(
          listener: (context, state) {
            if (state is TrptLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => TrptView(reference: state.trpt.shdTrnRef ?? ""),
              );
            } else if (state is TrptErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.error,
                isError: true,
              );
            }
          },
        ),
        BlocListener<GlatBloc, GlatState>(
          listener: (context, state) {
            if (state is GlatLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => GlatView(),
              );
            } else if (state is GlatErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            } else if (state is GlatLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
        BlocListener<FetchAtatBloc, FetchAtatState>(
          listener: (context, state) {
            if (state is FetchATATLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => FetchAtatView(),
              );
            } else if (state is FetchATATErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.noData,
                message: state.message,
                isError: true,
              );
            } else if (state is FetchATATLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
        BlocListener<TxnReferenceBloc, TxnReferenceState>(
          listener: (context, state) {
            if (state is TxnReferenceLoadedState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              showDialog(
                context: context,
                builder: (context) => TxnReferenceView(),
              );
            } else if (state is TxnReferenceErrorState) {
              setState(() {
                _isLoadingDialog = false;
                _loadingRef = null;
              });
              Utils.showOverlayMessage(
                context,
                title: tr.accessDenied,
                message: state.error,
                isError: true,
              );
            } else if (state is TxnReferenceLoadingState) {
              setState(() {
                _isLoadingDialog = true;
              });
            }
          },
        ),
      ],
      child: Stack(
        children: [
          Scaffold(
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                          flex: 6,
                          child: ListTile(
                            tileColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                            title: Text(tr.todayTransaction,style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(DateTime.now().compact),
                          )),
                      Expanded(
                        flex: 5,
                        child: ZSearchField(
                          icon: FontAwesomeIcons.magnifyingGlass,
                          controller: searchController,
                          hint: AppLocalizations.of(context)!.search,
                          onChanged: (e) {
                            setState(() {});
                          },
                          title: "",
                        ),
                      ),
                      ZOutlineButton(
                        width: 120,
                        icon: Icons.refresh,
                        onPressed: () {
                          context.read<TransactionsBloc>().add(
                            LoadAllTransactionsEvent('all'),
                          );
                        },
                        label: Text(tr.refresh),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .9)
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 100,
                          child: Text(tr.txnDate, style: titleStyle)),
                      SizedBox(width: 20),
                      Expanded(
                          child: Text(tr.referenceNumber,
                              style: titleStyle)),
                      SizedBox(
                          width: 130,
                          child: Text(tr.txnType,
                              style: titleStyle)),
                      SizedBox(width: 20),
                      SizedBox(
                          width: 110,
                          child: Text(tr.createdBy,
                              style: titleStyle)),
                      SizedBox(width: 20),
                      SizedBox(
                          width: 110,
                          child: Text(tr.checker,
                              style: titleStyle)),
                      SizedBox(width: 20),
                      SizedBox(
                          width: 110,
                          child: Text(tr.status,
                              style: titleStyle)),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocConsumer<TransactionsBloc, TransactionsState>(
                    listener: (context, state) {
                      if (state is TransactionSuccessState) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
                          context
                              .read<TransactionsBloc>()
                              .add(LoadAllTransactionsEvent('all'));
                        });
                      }
                    },
                    builder: (context, state) {
                      if (state is TransactionErrorState) {
                        return NoDataWidget(
                          message: state.message,
                          onRefresh: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context.read<TransactionsBloc>().add(
                                LoadAllTransactionsEvent('all'),
                              );
                            });
                          },
                        );
                      }
                      if (state is TxnLoadingState) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (state is TransactionLoadedState) {
                        final query = searchController.text.toLowerCase().trim();
                        final filteredList = state.txn.where((item) {
                          final name = item.trnReference?.toLowerCase() ?? '';
                          final status = item.trnStateText?.toLowerCase() ?? '';
                          final trnName = item.trnType?.toLowerCase() ?? '';
                          final usrName = item.usrName?.toLowerCase() ?? '';
                          return name.contains(query) ||
                              status.contains(query) ||
                              usrName.contains(query) ||
                              trnName.contains(query);
                        }).toList();
                        if (state.txn.isEmpty) {
                          return NoDataWidget(
                            message: tr.noDataFound,
                            onRefresh: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                context.read<TransactionsBloc>().add(
                                  LoadAllTransactionsEvent('all'),
                                );
                              });
                            },
                          );
                        }
                        return ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final txn = filteredList[index];
                              final isLoadingThisItem = _isLoadingDialog && _loadingRef == txn.trnReference;
                              final isCopied = _copiedStates[txn.trnReference ?? ""] ?? false;
                              final reference = txn.trnReference ?? "";
                              return Material(
                                child: InkWell(
                                  onTap: isLoadingThisItem
                                      ? null
                                      : () => _handleTransactionTap(txn),
                                  hoverColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .05),
                                  highlightColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .05),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: index.isOdd
                                            ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: .06)
                                            : Colors.transparent),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              children: [
                                                if (isLoadingThisItem)
                                                  Container(
                                                    width: 16,
                                                    height: 16,
                                                    margin: EdgeInsets.only(right: myLocale == "en"? 8 : 0, left: myLocale == "en"? 0 : 8),
                                                    child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                Text(txn.trnEntryDate?.toFormattedDate() ?? ""),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 20),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () {
                                                        _copyToClipboard(reference, context);
                                                      },
                                                      borderRadius: BorderRadius.circular(4),
                                                      hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                                                      child: AnimatedContainer(
                                                        duration: const Duration(milliseconds: 100),
                                                        decoration: BoxDecoration(
                                                          color: isCopied
                                                              ? Theme.of(context).colorScheme.primary.withAlpha(25)
                                                              : Colors.transparent,
                                                          border: Border.all(
                                                            color: isCopied
                                                                ? Theme.of(context).colorScheme.primary
                                                                : Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                                                            width: 1,
                                                          ),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Center(
                                                          child: AnimatedSwitcher(
                                                            duration: const Duration(milliseconds: 300),
                                                            child: Icon(
                                                              isCopied ? Icons.check : Icons.content_copy,
                                                              key: ValueKey<bool>(isCopied),
                                                              size: 15,
                                                              color: isCopied
                                                                  ? Theme.of(context).colorScheme.primary
                                                                  : Theme.of(context).colorScheme.outline.withValues(alpha: .6),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Reference text that takes remaining space
                                                Expanded(
                                                    child:
                                                    Text(txn.trnReference.toString())),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                              width: 130,
                                              child: Text(Utils.getTxnCode(
                                                  txn: txn.trnType ?? "",
                                                  context: context))),
                                          SizedBox(width: 20),
                                          SizedBox(
                                              width: 110,
                                              child: Text(txn.maker ?? "")),
                                          SizedBox(width: 20),
                                          SizedBox(
                                              width: 110,
                                              child: Text(txn.checker ?? "")),
                                          SizedBox(width: 20),
                                          SizedBox(
                                              width: 115,
                                              child: TransactionStatusBadge(status: txn.trnStateText??"")),

                                        ],
                                      ),
                                    ),
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
          ),
          if (_isLoadingDialog && _loadingRef == null)
            Container(
              color: Colors.black.withAlpha(100),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);

    // Set copied state to true
    setState(() {
      _copiedStates[reference] = true;
    });

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStates.remove(reference);
        });
      }
    });
  }
}