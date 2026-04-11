import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/Ui/Accounts/edit_add.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../../Features/Generic/shimmer.dart';
import '../../../../../../../../Features/Other/cover.dart';
import '../../../../../../../../Features/Widgets/mobile_acc_card.dart';
import '../../../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
class AccountsByPerIdView extends StatelessWidget {
  final IndividualsModel ind;
  const AccountsByPerIdView({super.key, required this.ind});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(ind),
      tablet: _Desktop(ind),
      desktop: _Desktop(ind),
    );
  }
}

class _Mobile extends StatefulWidget {
  final IndividualsModel ind;
  const _Mobile(this.ind);

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsBloc>().add(
        LoadAccountsEvent(ownerId: widget.ind.perId),
      );
    });

    _scrollController.addListener(_onScroll);
    super.initState();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // Scrolling down - hide FAB
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      // Scrolling up - show FAB
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AccountsAddEditView(perId: widget.ind.perId);
                },
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar (optional - you can add if needed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13.0,vertical: 4),
            child: ZSearchField(
              controller: searchController,
              hint: locale.search,
              onChanged: (value) => setState(() {}),
              icon: FontAwesomeIcons.magnifyingGlass,
              title: '',
            ),
          ),
          Expanded(
            child: BlocConsumer<AccountsBloc, AccountsState>(
              listener: (context, state) {
                if (state is AccountSuccessState) {
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                if (state is AccountLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AccountErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: () {
                      context.read<AccountsBloc>().add(
                        LoadAccountsEvent(ownerId: widget.ind.perId),
                      );
                    },
                  );
                }
                if (state is AccountLoadedState) {
                  final query = searchController.text.toLowerCase().trim();
                  final q = query.toLowerCase();

                  final filteredList = state.accounts.where((item) {
                    final name = item.accName?.toLowerCase() ?? '';
                    final number = (item.accNumber ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(q) || number.contains(q);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(message: locale.noDataFound);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<AccountsBloc>().add(
                        LoadAccountsEvent(ownerId: widget.ind.perId),
                      );
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final acc = filteredList[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4,
                          ),
                          child: MobileAccountCard(
                            showBalanceDetails: true,
                            accountName: acc.accName ?? '',
                            accountNumber: acc.accNumber?.toString() ?? '',
                            currencyCode: acc.actCurrency ?? '',
                            availableBalance: acc.accAvailBalance
                                .toDoubleAmount(),
                            currentBalance: acc.accBalance.toDoubleAmount(),
                            status: MobileStatus(
                              label: acc.accStatus == 1
                                  ? locale.active
                                  : locale.blocked,
                              color: acc.accStatus == 1
                                  ? Colors.green
                                  : Colors.red,
                              backgroundColor:
                              (acc.accStatus == 1
                                  ? Colors.green
                                  : Colors.red)
                                  .withValues(alpha: .1),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AccountsAddEditView(
                                  model: acc,
                                  perId: widget.ind.perId,
                                ),
                              );
                            },
                            accentColor: Utils.currencyColors(
                              acc.actCurrency ?? "",
                            ),
                          ),
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
    );
  }
}

class _Desktop extends StatefulWidget {
  final IndividualsModel ind;
  const _Desktop(this.ind);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsBloc>().add(
        LoadAccountsEvent(ownerId: widget.ind.perId),
      );
    });
    super.initState();
  }

  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: ZSearchField(
                    icon: FontAwesomeIcons.magnifyingGlass,
                    controller: searchController,
                    hint: locale.accNameOrNumber,
                    onChanged: (e) {
                      setState(() {});
                    },
                    title: "",
                  ),
                ),
                ZOutlineButton(
                  width: 120,
                  icon: Icons.refresh,
                  onPressed: onRefresh,
                  label: Text(locale.refresh),
                ),
                ZOutlineButton(
                  width: 120,
                  isActive: true,
                  icon: Icons.add,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AccountsAddEditView(perId: widget.ind.perId);
                      },
                    );
                  },
                  label: Text(locale.newKeyword),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<AccountsBloc, AccountsState>(
              listener: (context, state) {
                if (state is AccountSuccessState) {
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                final textTheme = Theme.of(context).textTheme;
                final color = Theme.of(context).colorScheme;

                final amountTitle = textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: color.outline,
                );

                final amountStyle = textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                );


                if (state is AccountLoadingState) {
                  return UniversalShimmer.accountList(
                    itemCount: 8,
                    useAlternatingColors: true,
                  );
                }

                if (state is AccountErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: () {
                      context.read<AccountsBloc>().add(
                        LoadAccountsEvent(ownerId: widget.ind.perId),
                      );
                    },
                  );
                }

                if (state is AccountLoadedState) {
                  final query = searchController.text.toLowerCase().trim();
                  final q = query.toLowerCase();

                  final filteredList = state.accounts.where((item) {
                    final name = item.accName?.toLowerCase() ?? '';
                    final number = (item.accNumber ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(q) || number.contains(q);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(message: locale.noDataFound);
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final acc = filteredList[index];
                      bool isAvailableEqualCurrent = acc.accAvailBalance == acc.accBalance;

                      return InkWell(
                        highlightColor: color.primary.withValues(alpha: .06),
                        hoverColor: color.primary.withValues(alpha: .06),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AccountsAddEditView(
                                model: acc,
                                perId: widget.ind.perId,
                              );
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: index.isOdd
                                ? color.primary.withValues(alpha: .06)
                                : Colors.transparent,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15.0,
                              vertical: 3,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Utils.currencyColors(
                                    acc.actCurrency ?? "",
                                  ),
                                  radius: 22,
                                  child: Text(
                                    acc.accName?.getFirstLetter ?? "",
                                    style: TextStyle(
                                      color: color.surface,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.accName ?? "",
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(right: 3.0),
                                            child: ZCover(
                                              color: color.surface,
                                              child: Text(acc.accNumber.toString()),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 3.0),
                                            child: ZCover(
                                              color: color.surface,
                                              child: Text(acc.actCurrency.toString()),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 3.0),
                                            child: ZCover(
                                              color: color.surface,
                                              child: Text(
                                                acc.accStatus == 1 ? locale.active : locale.blocked,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isAvailableEqualCurrent)
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            locale.currentBalance,
                                            style: amountTitle,
                                            textAlign: TextAlign.right,
                                          ),
                                          Text(
                                            "${acc.accBalance?.toAmount()} ${acc.actCurrency}",
                                            style: amountStyle,
                                            textAlign: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          locale.availableBalance,
                                          style: amountTitle,
                                          textAlign: TextAlign.right,
                                        ),
                                        Text(
                                          "${acc.accAvailBalance?.toAmount()} ${acc.actCurrency}",
                                          style: amountStyle,
                                          textAlign: TextAlign.right,
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

  void onRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountsBloc>().add(
        LoadAccountsEvent(ownerId: widget.ind.perId),
      );
    });
  }
}


