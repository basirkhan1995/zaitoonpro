import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/txn_status_widget.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stock/Ui/GoodsShift/shift_details.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Features/Other/utils.dart';
import '../../../../../../Features/Widgets/no_data_widget.dart';
import 'bloc/goods_shift_bloc.dart';

class GoodsShiftView extends StatelessWidget {
  const GoodsShiftView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileGoodsShiftView(),
      tablet: _TabletGoodsShiftView(),
      desktop: _DesktopGoodsShiftView(),
    );
  }
}

// Mobile View
class _MobileGoodsShiftView extends StatefulWidget {
  const _MobileGoodsShiftView();

  @override
  State<_MobileGoodsShiftView> createState() => _MobileGoodsShiftViewState();
}

class _MobileGoodsShiftViewState extends State<_MobileGoodsShiftView> {
  String? baseCurrency;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthenticatedState) {
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
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

              // Goods Shifts List
              Expanded(
                child: BlocConsumer<GoodsShiftBloc, GoodsShiftState>(
                  listener: (context, state) {
                    if (state is GoodsShiftDeletedState) {
                      Utils.showOverlayMessage(
                        context,
                        message: state.message,
                        isError: false,
                      );
                      context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
                    }
                    if (state is GoodsShiftSavedState) {
                      Utils.showOverlayMessage(
                        context,
                        message: state.message,
                        isError: false,
                      );
                      context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
                    }
                    if (state is GoodsShiftErrorState) {
                      Utils.showOverlayMessage(
                        context,
                        message: state.error,
                        isError: true,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is GoodsShiftLoadingState ||
                        state is GoodsShiftSavingState ||
                        state is GoodsShiftDeletingState) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is GoodsShiftErrorState) {
                      return NoDataWidget(
                        imageName: 'error.png',
                        message: state.error,
                        onRefresh: onRefresh,
                      );
                    }

                    if (state is GoodsShiftLoadedState) {
                      final query = searchController.text.toLowerCase().trim();
                      final filteredList = state.shifts.where((item) {
                        final ref = item.ordTrnRef?.toLowerCase() ?? '';
                        final ordId = item.ordId?.toString() ?? '';
                        final account = item.account?.toString() ?? '';
                        final amount = item.amount?.toLowerCase() ?? '';
                        final status = item.trnStateText?.toLowerCase() ?? '';
                        return ref.contains(query) ||
                            ordId.contains(query) ||
                            account.contains(query) ||
                            amount.contains(query) ||
                            status.contains(query);
                      }).toList();

                      if (filteredList.isEmpty) {
                        return NoDataWidget(
                          message: tr.noDataFound,
                          onRefresh: onRefresh,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final shift = filteredList[index];

                          return ZCover(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            radius: 4,
                            child: InkWell(
                              onTap: () {
                                Utils.goto(
                                  context,
                                  GoodsShiftDetailView(shiftId: shift.ordId!),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Row with ID and Date
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.primary.withValues(alpha: .1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "#${shift.ordId}",
                                            style: TextStyle(
                                              color: color.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            shift.ordEntryDate != null
                                                ? shift.ordEntryDate.toFormattedDate()
                                                : "",
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Reference Number
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt,
                                          size: 16,
                                          color: color.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            shift.ordTrnRef ?? "-",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Account
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance,
                                          size: 16,
                                          color: color.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            shift.account?.toString() ?? "-",
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Amount and Status Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            shift.amount != null
                                                ? "${shift.totalAmount.toAmount()} $baseCurrency"
                                                : "-",
                                            style: TextStyle(
                                              color: color.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        TransactionStatusBadge(
                                          status: shift.trnStateText ?? "",
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

                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Tablet View
class _TabletGoodsShiftView extends StatefulWidget {
  const _TabletGoodsShiftView();

  @override
  State<_TabletGoodsShiftView> createState() => _TabletGoodsShiftViewState();
}

class _TabletGoodsShiftViewState extends State<_TabletGoodsShiftView> {
  String? baseCurrency;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthenticatedState) {
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Header with Title and Search
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.shift,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            tr.ordersSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: color.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
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
                    const SizedBox(width: 8),
                    ZOutlineButton(
                      toolTip: "F5",
                      width: 100,
                      icon: Icons.refresh,
                      onPressed: onRefresh,
                      label: Text(tr.refresh),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: .9),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text(tr.id, style: titleStyle)),
                      SizedBox(
                        width: 90,
                        child: Text(tr.date, style: titleStyle),
                      ),
                      Expanded(
                        child: Text(tr.referenceNumber, style: titleStyle),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(tr.accountTitle, style: titleStyle),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(tr.amount, style: titleStyle),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(tr.status, style: titleStyle),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // Goods Shifts List
                Expanded(
                  child: BlocConsumer<GoodsShiftBloc, GoodsShiftState>(
                    listener: (context, state) {
                      if (state is GoodsShiftDeletedState) {
                        Utils.showOverlayMessage(
                          context,
                          message: state.message,
                          isError: false,
                        );
                        context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
                      }
                      if (state is GoodsShiftSavedState) {
                        Utils.showOverlayMessage(
                          context,
                          message: state.message,
                          isError: false,
                        );
                        context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
                      }
                      if (state is GoodsShiftErrorState) {
                        Utils.showOverlayMessage(
                          context,
                          message: state.error,
                          isError: true,
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is GoodsShiftLoadingState ||
                          state is GoodsShiftSavingState ||
                          state is GoodsShiftDeletingState) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is GoodsShiftErrorState) {
                        return NoDataWidget(
                          imageName: 'error.png',
                          message: state.error,
                          onRefresh: onRefresh,
                        );
                      }

                      if (state is GoodsShiftLoadedState) {
                        final query = searchController.text.toLowerCase().trim();
                        final filteredList = state.shifts.where((item) {
                          final ref = item.ordTrnRef?.toLowerCase() ?? '';
                          final ordId = item.ordId?.toString() ?? '';
                          final account = item.account?.toString() ?? '';
                          final amount = item.amount?.toLowerCase() ?? '';
                          final status = item.trnStateText?.toLowerCase() ?? '';
                          return ref.contains(query) ||
                              ordId.contains(query) ||
                              account.contains(query) ||
                              amount.contains(query) ||
                              status.contains(query);
                        }).toList();

                        if (filteredList.isEmpty) {
                          return NoDataWidget(
                            message: tr.noDataFound,
                            onRefresh: onRefresh,
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final shift = filteredList[index];

                            return InkWell(
                              onTap: () {
                                Utils.goto(
                                  context,
                                  GoodsShiftDetailView(shiftId: shift.ordId!),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? color.primary.withValues(alpha: .05)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(shift.ordId.toString()),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        shift.ordEntryDate != null
                                            ? shift.ordEntryDate.toFormattedDate()
                                            : "",
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        shift.ordTrnRef ?? "-",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        shift.account?.toString() ?? "-",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        shift.amount != null
                                            ? "${shift.totalAmount.toAmount()} $baseCurrency"
                                            : "-",
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: TransactionStatusBadge(
                                        status: shift.trnStateText ?? "",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }

                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Desktop View - Keep exactly as original
class _DesktopGoodsShiftView extends StatefulWidget {
  const _DesktopGoodsShiftView();

  @override
  State<_DesktopGoodsShiftView> createState() => _DesktopGoodsShiftViewState();
}

class _DesktopGoodsShiftViewState extends State<_DesktopGoodsShiftView> {
  String? baseCurrency;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthenticatedState) {
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        tileColor: Colors.transparent,
                        title: Text(
                          tr.shift,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20),
                        ),
                        subtitle: Text(
                          tr.ordersSubtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
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
                      toolTip: "F5",
                      width: 120,
                      icon: Icons.refresh,
                      onPressed: onRefresh,
                      label: Text(tr.refresh),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .9),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text(tr.id, style: titleStyle)),
                    SizedBox(
                      width: 100,
                      child: Text(tr.date, style: titleStyle),
                    ),
                    Expanded(
                      child: Text(tr.referenceNumber, style: titleStyle),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(tr.accountTitle, style: titleStyle),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(tr.amount, style: titleStyle),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(tr.status, style: titleStyle),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocConsumer<GoodsShiftBloc, GoodsShiftState>(
                  listener: (context, state) {
                    if (state is GoodsShiftDeletedState) {
                      Utils.showOverlayMessage(
                        context,
                        message: state.message,
                        isError: false,
                      );
                      context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
                    }
                    if (state is GoodsShiftSavedState) {
                      Utils.showOverlayMessage(
                        context,
                        message: state.message,
                        isError: false,
                      );
                      context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());
                    }
                    if (state is GoodsShiftErrorState) {
                      Utils.showOverlayMessage(
                        context,
                        message: state.error,
                        isError: true,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is GoodsShiftLoadingState ||
                        state is GoodsShiftSavingState ||
                        state is GoodsShiftDeletingState) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is GoodsShiftErrorState) {
                      return NoDataWidget(
                        imageName: 'error.png',
                        message: state.error,
                        onRefresh: onRefresh,
                      );
                    }

                    if (state is GoodsShiftLoadedState) {
                      final query = searchController.text.toLowerCase().trim();
                      final filteredList = state.shifts.where((item) {
                        final ref = item.ordTrnRef?.toLowerCase() ?? '';
                        final ordId = item.ordId?.toString() ?? '';
                        final account = item.account?.toString() ?? '';
                        final amount = item.amount?.toLowerCase() ?? '';
                        final status = item.trnStateText?.toLowerCase() ?? '';
                        return ref.contains(query) ||
                            ordId.contains(query) ||
                            account.contains(query) ||
                            amount.contains(query) ||
                            status.contains(query);
                      }).toList();

                      if (filteredList.isEmpty) {
                        return NoDataWidget(
                          message: tr.noDataFound,
                          onRefresh: onRefresh,
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final shift = filteredList[index];

                          return InkWell(
                            onTap: () {
                              Utils.goto(
                                context,
                                GoodsShiftDetailView(shiftId: shift.ordId!),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? color.primary.withValues(alpha: .05)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(shift.ordId.toString()),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      shift.ordEntryDate != null
                                          ? shift.ordEntryDate.toFormattedDate()
                                          : "",
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      shift.ordTrnRef ?? "-",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      shift.account?.toString() ?? "-",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      shift.amount != null
                                          ? "${shift.totalAmount.toAmount()} $baseCurrency"
                                          : "-",
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: TransactionStatusBadge(
                                      status: shift.trnStateText ?? "",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}