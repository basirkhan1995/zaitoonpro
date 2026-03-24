import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Other/znavigator.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchATAT/bloc/fetch_atat_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchATAT/fetch_atat.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchGLAT/Ui/glat_view.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchGLAT/bloc/glat_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchTRPT/Ui/trpt_view.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchTRPT/bloc/trpt_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/TxnByReference/bloc/txn_reference_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/TxnByReference/txn_reference.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/bloc/transactions_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/model/transaction_model.dart';
import '../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../Localizations/Bloc/localizations_bloc.dart';
import '../GetOrder/bloc/order_txn_bloc.dart';
import '../GetOrder/txn_oder.dart';
import '../ProjectTxn/bloc/project_txn_bloc.dart';
import '../ProjectTxn/project_txn.dart';

class PendingTransactionsView extends StatelessWidget {
  const PendingTransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Desktop(),
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
  final Set<String> _selectedRefs = {}; // selecting by trnReference
  bool _isLoadingDialog = false;
  String? _loadingRef;
  String? myLocale;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Track copied state for each reference
  final Map<String, bool> _copiedStates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      myLocale = context.read<LocalizationBloc>().state.languageCode;
      context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('pending'));
    });
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

  void _toggleSelection(dynamic record) {
    setState(() {
      final ref = record.trnReference!;

      if (_selectedRefs.contains(ref)) {
        _selectedRefs.remove(ref);
        if (_selectedRefs.isEmpty) {}
      } else {
        _selectedRefs.add(ref);
      }
    });
  }

  bool isSearch = false;

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
              ZNavigator.goto(ProjectTxnView(reference: state.txn.transaction?.trnReference ?? ""),);
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
              ZNavigator.goto(OrderTxnView(reference: state.data.trnReference ?? ""),);
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
              ZNavigator.goto(TrptView(reference: state.trpt.shdTrnRef ?? ""),);
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
              ZNavigator.goto(GlatView());
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
              ZNavigator.goto(FetchAtatView());
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
              ZNavigator.goto(TxnReferenceView());
            } else if (state is TxnReferenceErrorState) {
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
      ],
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(
                tr.pendingTransactions,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      isSearch =! isSearch;
                    });
                  },
                ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('pending'));
                    },
                  ),
              ],
            ),
            body: Column(
              children: [
                // Search Bar
                if(isSearch)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ZSearchField(
                    icon: Icons.search_rounded,
                    controller: searchController,
                    hint: "${tr.search} ${tr.pendingTransactions.toLowerCase()}",
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pending_actions_rounded,
                                  size: 16,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$totalCount ${tr.pendingTransactions}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Hint text
                          Expanded(
                            child: Text(
                              tr.pendingTransactionHint,
                              style: TextStyle(
                                fontSize: 12,
                                color: color.onSurface.withAlpha(150),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      if (state is TransactionErrorState) {
                        Utils.showOverlayMessage(
                          context,
                          title: tr.accessDenied,
                          message: state.message,
                          isError: true,
                        );
                      }
                      if (state is TransactionSuccessState) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
                          context.read<TransactionsBloc>().add(
                            LoadAllTransactionsEvent('pending'),
                          );
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
                                tr.errorTitle,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: color.onSurface.withAlpha(150),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ZOutlineButton(
                                icon: Icons.refresh_rounded,
                                onPressed: () {
                                  context.read<TransactionsBloc>().add(
                                    LoadAllTransactionsEvent('pending'),
                                  );
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
                          final maker = item.maker?.toLowerCase() ?? '';

                          return reference.contains(query) ||
                              type.contains(query) ||
                              maker.contains(query);
                        }).toList();

                        if (filteredList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  query.isEmpty ? Icons.pending_actions_rounded : Icons.search_off_rounded,
                                  size: 64,
                                  color: color.onSurface.withAlpha(80),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  query.isEmpty ? tr.noTransactionFound : tr.noDataFound,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                                if (query.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '"$query"',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: color.onSurface.withAlpha(150),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ZOutlineButton(
                                    icon: Icons.clear_rounded,
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {});
                                    },
                                    label: Text(tr.clearFilters),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('pending'));
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final txn = filteredList[index];
                              final reference = txn.trnReference ?? "";
                              final isSelected = _selectedRefs.contains(reference);
                              final isLoadingThisItem = _isLoadingDialog && _loadingRef == reference;
                              final isCopied = _copiedStates[reference] ?? false;

                              return _buildTransactionCard(
                                txn: txn,
                                isSelected: isSelected,
                                isLoading: isLoadingThisItem,
                                isCopied: isCopied,
                                reference: reference,
                                color: color,
                                tr: tr,
                                onTap: () => _handleTransactionTap(txn),
                                onLongPress: () => _toggleSelection(txn),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(20),
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
                      Text(
                        'Loading...',
                        style: TextStyle(fontSize: 16),
                      ),
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
    required bool isSelected,
    required bool isLoading,
    required bool isCopied,
    required String reference,
    required ColorScheme color,
    required AppLocalizations tr,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onCopy,
  }) {
    // Determine transaction type color and icon
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
      case 'SLRY':
        typeColor = Colors.purple;
        typeIcon = Icons.attach_money_rounded;
        break;
      case 'CRFX':
        typeColor = Colors.pink;
        typeIcon = Icons.currency_exchange_rounded;
        break;
      case 'PRJT':
        typeColor = Colors.brown;
        typeIcon = Icons.account_tree_rounded;
        break;
    }

    return ZCover(
      margin: const EdgeInsets.only(bottom: 8),
      radius: 12,
      color: color.surface,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          onLongPress: isLoading ? null : onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Loading overlay
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.surface.withAlpha(200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),

              // Main content
              Opacity(
                opacity: isLoading ? 0.5 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Type Chip
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(6),
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
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Reference Number with Copy
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
                                const SizedBox(height: 4),
                                Text(
                                  reference,
                                  style: const TextStyle(
                                    fontSize: 16,
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

                      const SizedBox(height: 5),

                      // Date and Maker Row
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
                                Expanded(
                                  child: Text(
                                    txn.trnEntryDate?.toFormattedDate() ?? '',
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

                          // Maker
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
                                  Text(
                                    txn.maker!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: color.onSurface.withAlpha(200),
                                    ),
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                    ],
                  ),
                ),
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
  final Set<String> _selectedRefs = {};
  bool _selectionMode = false;
  bool _isLoadingDialog = false;
  String? _loadingRef;
  String? myLocale;

  final Map<String, bool> _copiedStates = {};

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      myLocale = context.read<LocalizationBloc>().state.languageCode;
      context.read<TransactionsBloc>().add(LoadAllTransactionsEvent('pending'));
    });
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

  // Method to copy reference to clipboard
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
                title: tr.noData,
                message: state.error,
                isError: true,
              );
            }
          },
        ),
      ],
      child: Stack(
        children: [
          Scaffold(
            body: Column(
              children: [
                if (_selectionMode)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 8,
                      children: [
                        ZOutlineButton(
                          width: 150,
                          icon: Icons.check_box_rounded,
                          label: Text(
                            "${tr.authorize} (${_selectedRefs.length})",
                          ),
                        ),
                        ZOutlineButton(
                          isActive: true,
                          backgroundHover: Theme.of(
                            context,
                          ).colorScheme.error,
                          width: 120,
                          icon: Icons.delete_outline_rounded,
                          label: Text(
                            "${tr.delete} (${_selectedRefs.length})",
                          ),
                        ),
                        ZOutlineButton(
                          width: 100,
                          onPressed: () {
                            setState(() {
                              _selectionMode = false;
                              _selectedRefs.clear();
                            });
                          },
                          isActive: true,
                          label: Text(tr.cancel),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                          flex: 5,
                          child: ListTile(
                            tileColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                            title: Text(tr.pendingTransactions,style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(tr.pendingTransactionHint),
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
                            LoadAllTransactionsEvent('pending'),
                          );
                        },
                        label: Text(tr.refresh),
                      ),
                    ],
                  ),
                ),

                // HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .9)
                  ),
                  child: Row(
                    children: [
                      // SELECT-ALL CHECKBOX
                      if (_selectionMode)
                        SizedBox(
                          width: 40,
                          child: BlocBuilder<TransactionsBloc, TransactionsState>(
                            builder: (context, state) {
                              if (state is! TransactionLoadedState) {
                                return const SizedBox();
                              }

                              final allSelected =
                                  _selectedRefs.length == state.txn.length;

                              return Checkbox(
                                value: allSelected && _selectionMode,
                                onChanged: (v) => _toggleSelectAll(state.txn),
                              );
                            },
                          ),
                        ),

                      SizedBox(
                        width: 140,
                        child: Text(
                          tr.txnDate,
                          style: titleStyle,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              tr.referenceNumber,
                              style: titleStyle,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.content_copy,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          tr.txnType,
                          style: titleStyle,
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 110,
                        child: Text(
                          tr.maker,
                          style: titleStyle,
                        ),
                      ),
                    ],
                  ),
                ),


                // BODY
                Expanded(
                  child: BlocConsumer<TransactionsBloc, TransactionsState>(
                    listener: (context, state) {
                      if (state is TransactionErrorState) {
                        Utils.showOverlayMessage(
                          context,
                          title: tr.accessDenied,
                          message: state.message,
                          isError: true,
                        );
                      }
                      if (state is TransactionSuccessState) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
                          context.read<TransactionsBloc>().add(
                            LoadAllTransactionsEvent('pending'),
                          );
                        });
                      }
                    },
                    builder: (context, state) {
                      if (state is TransactionErrorState) {
                        return NoDataWidget(
                          message: state.message,
                          onRefresh: () {
                            context.read<TransactionsBloc>().add(
                              LoadAllTransactionsEvent('pending'),
                            );
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
                          return name.contains(query);
                        }).toList();

                        if (filteredList.isEmpty) {
                          return NoDataWidget(
                            message: tr.noTransactionFound,
                            onRefresh: () {
                              context.read<TransactionsBloc>().add(
                                LoadAllTransactionsEvent('pending'),
                              );
                            },
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final txn = filteredList[index];
                            final reference = txn.trnReference ?? "";
                            final isSelected = _selectedRefs.contains(reference);
                            final isLoadingThisItem = _isLoadingDialog && _loadingRef == reference;
                            final isCopied = _copiedStates[reference] ?? false;

                            return InkWell(
                              onTap: isLoadingThisItem ? null : () => _handleTransactionTap(txn),
                              onLongPress: () {
                                _toggleSelection(txn);
                              },
                              hoverColor: Theme.of(context).primaryColor.withAlpha(13),
                              child: Container(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary.withAlpha(38)
                                    : index.isOdd
                                    ? Theme.of(context).colorScheme.primary.withAlpha(15)
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 5,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_selectionMode)
                                    // CHECKBOX
                                      SizedBox(
                                        width: 40,
                                        child: Checkbox(
                                          visualDensity: const VisualDensity(
                                            vertical: -4,
                                          ),
                                          value: isSelected,
                                          onChanged: (v) => _toggleSelection(txn),
                                        ),
                                      ),

                                    SizedBox(
                                      width: 140,
                                      child: Row(
                                        children: [
                                          if (isLoadingThisItem)
                                            Container(
                                              width: 16,
                                              height: 16,
                                              margin: EdgeInsets.only(
                                                  right: myLocale == "en" ? 8 : 0,
                                                  left: myLocale == "en" ? 0 : 8),
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          Flexible(
                                            child: Text(
                                              txn.trnEntryDate!.toFullDateTime,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),

                                    // Reference column with copy button on the left
                                    Expanded(
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 28, // Fixed width
                                            height: 28, // Fixed height
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _copyToClipboard(reference, context),
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
                                                        key: ValueKey<bool>(isCopied), // Important for AnimatedSwitcher
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
                                            child: Text(
                                              reference,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        Utils.getTxnCode(
                                          txn: txn.trnType ?? "",
                                          context: context,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    const SizedBox(width: 20),
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        txn.maker ?? "",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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

  /// Toggle a single item by trnReference
  void _toggleSelection(dynamic record) {
    setState(() {
      final ref = record.trnReference!;

      if (_selectedRefs.contains(ref)) {
        _selectedRefs.remove(ref);
        if (_selectedRefs.isEmpty) _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedRefs.add(ref);
      }
    });
  }

  /// Select all / Unselect all
  void _toggleSelectAll(List data) {
    setState(() {
      if (_selectedRefs.length == data.length) {
        _selectedRefs.clear();
        _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedRefs.clear();
        _selectedRefs.addAll(data.map((e) => e.trnReference!));
      }
    });
  }
}