import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/alert_dialog.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/shortcut.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/Ui/add_edit_ccy.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/bloc/currencies_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flag/flag.dart';
import '../../../../../../../../../Features/Generic/shimmer.dart';
import '../../../../../../../../../Features/Other/cover.dart';
import '../../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../../Features/Widgets/search_field.dart';
import 'package:flutter/services.dart';

class CurrenciesView extends StatelessWidget {
  const CurrenciesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Mobile(), tablet: _Desktop(), desktop: _Desktop());
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
    });
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  void _onScroll() {
    // Add a small threshold to prevent flickering
    if (_scrollController.offset > 100 && _scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // Scrolling down and past threshold - hide FAB
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward || _scrollController.offset < 50) {
      // Scrolling up or near the top - show FAB
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

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);

    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): onAdd,
      const SingleActivator(LogicalKeyboardKey.f5): onRefresh,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(
          0,
          _isFabVisible ? 0 : 100,
          0,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton(
              onPressed: onAdd,
              child: const Icon(Icons.add)
          ),
        ),
      ),
      body: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ZSearchField(
                controller: searchController,
                title: '',
                hint: tr.search,
                end: searchController.text.isNotEmpty
                    ? InkWell(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    setState(() {
                      searchController.clear();
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.clear, size: 15),
                  ),
                )
                    : const SizedBox(),
                onChanged: (e) {
                  setState(() {});
                },
                icon: FontAwesomeIcons.magnifyingGlass,
              ),
            ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .9)
              ),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text(tr.flag,style: titleStyle)),
                  SizedBox(
                    width: 60,
                    child: Text(
                      tr.currencyCode,
                      style: titleStyle,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 70,
                    child: Text(
                      tr.symbol,
                      style: titleStyle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text(
                      tr.status,
                      style: titleStyle,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<CurrenciesBloc, CurrenciesState>(
                builder: (context, state) {
                  if (state is CurrenciesLoadingState) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (state is CurrenciesErrorState) {
                    return NoDataWidget(
                      message: state.message,
                      onRefresh: () {
                        context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
                      },
                    );
                  }
                  if (state is CurrenciesLoadedState) {
                    final query = searchController.text.toLowerCase().trim();
                    final filteredCcy = state.ccy.where((item) {
                      final ccyCode = item.ccyCode?.toLowerCase() ?? '';
                      final ccyName = item.ccyName?.toLowerCase() ?? '';
                      return ccyCode.contains(query) || ccyName.contains(query);
                    }).toList();

                    if (filteredCcy.isEmpty) {
                      return NoDataWidget(
                        message: tr.noDataFound,
                        onRefresh: onRefresh,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredCcy.length,
                        itemBuilder: (context, index) {
                          final ccy = filteredCcy[index];
                          return InkWell(
                            hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                            highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AddEditCurrencyView(currency: ccy);
                                  }
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: index.isOdd
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: .05)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Flag.fromString(
                                      ccy.ccyCountryCode ?? "",
                                      height: 20,
                                      width: 30,
                                      borderRadius: 2,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      ccy.ccyCode ?? "",
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  const Spacer(),
                                  ZCover(
                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                    child: Text(
                                      ccy.ccySymbol ?? "",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  SizedBox(
                                    width: 70,
                                    child: Checkbox(
                                      visualDensity: const VisualDensity(vertical: -4),
                                      value: ccy.ccyStatus == 1,
                                      onChanged: (e) {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return ZAlertDialog(
                                                title: tr.areYouSure,
                                                content: tr.currencyActivationMessage,
                                                onYes: () {
                                                  context.read<CurrenciesBloc>().add(
                                                      UpdateCcyStatusEvent(
                                                          ccyCode: ccy.ccyCode!,
                                                          status: e ?? false
                                                      )
                                                  );
                                                },
                                              );
                                            }
                                        );
                                      },
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
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onRefresh() async {
    context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
  }

  void onAdd() {
    showDialog(
        context: context,
        builder: (context) {
          return AddEditCurrencyView();
        }
    );
  }
}


class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final searchController = TextEditingController();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);

    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): onAdd,
      const SingleActivator(LogicalKeyboardKey.f5): onRefresh,
    };
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  Expanded(
                      flex: 5,
                      child: Text(tr.allCurrencies,style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.outline),)),
                  Expanded(
                    flex: 3,
                    child: ZSearchField(
                      controller: searchController,
                      title: '',
                      hint: tr.search,
                      end: searchController.text.isNotEmpty
                          ? InkWell(
                        splashColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          setState(() {
                            searchController.clear();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                          ),
                          child: Icon(Icons.clear, size: 15),
                        ),
                      ) : SizedBox(),
                      onChanged: (e) {
                        setState(() {});
                      },
                      icon: FontAwesomeIcons.magnifyingGlass,
                    ),
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      ZOutlineButton(
                        toolTip: 'F5',
                        width: 110,
                        icon: Icons.refresh,
                        label: Text(AppLocalizations.of(context)!.refresh),
                        onPressed: onRefresh
                      ),
                      ZOutlineButton(
                        toolTip: 'F1',
                        isActive: true,
                        width: 110,
                        label: Text(AppLocalizations.of(context)!.newKeyword),
                        onPressed: onAdd
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 5),
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .9)
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      tr.flag,
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      tr.currencyCode,
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: Text(
                      tr.currencyTitle,
                      style: titleStyle,
                    ),
                  ),

                  SizedBox(
                    width: 170,
                    child: Text(
                      tr.ccyLocalName,
                      style: titleStyle,
                    ),
                  ),

                  Spacer(),
                  SizedBox(
                    width: 70,
                    child: Text(
                      tr.symbol,
                      style: titleStyle,
                    ),
                  ),

                  SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text(
                      tr.status,
                      style: titleStyle,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<CurrenciesBloc, CurrenciesState>(
                builder: (context, state) {
                  if(state is CurrenciesLoadingState){
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  } if(state is CurrenciesErrorState){
                    return NoDataWidget(
                      message: state.message,
                      onRefresh: (){
                        context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
                      },
                    );
                  } if(state is CurrenciesLoadedState){

                    final query = searchController.text.toLowerCase().trim();
                    final filteredCcy = state.ccy.where((item) {
                      final ccyCode = item.ccyCode?.toLowerCase() ?? '';
                      final ccyName = item.ccyName?.toLowerCase() ?? '';
                      return ccyCode.contains(query) || ccyName.contains(query);
                    }).toList();

                    return ListView.builder(
                        itemCount: filteredCcy.length,
                        itemBuilder: (context,index){
                          final ccy = filteredCcy[index];
                        return InkWell(
                          hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                          highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                          onTap: (){
                            showDialog(context: context, builder: (context){
                              return AddEditCurrencyView(currency: ccy);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: index.isOdd
                                  ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: .05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Flag.fromString(
                                    ccy.ccyCountryCode??"",
                                    height: 20,
                                    width: 30,
                                    borderRadius: 2,
                                    fit: BoxFit.fill,
                                  ),
                                ),

                                SizedBox(width: 20),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    ccy.ccyCode ?? "",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),

                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    ccy.ccyName ?? "",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                SizedBox(
                                  width: 190,
                                  child: Text(
                                    ccy.ccyLocalName ?? "",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Spacer(),
                                ZCover(
                                  margin: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(
                                    ccy.ccySymbol ?? "",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                SizedBox(width: 30),
                                SizedBox(
                                  width: 70,
                                  child: Checkbox(
                                      visualDensity: VisualDensity(vertical: -4),
                                      value: ccy.ccyStatus == 1,
                                      onChanged: (e){
                                        showDialog(context: context, builder: (context){
                                          return ZAlertDialog(
                                            title: tr.areYouSure,
                                            content: tr.currencyActivationMessage,
                                            onYes: () {
                                              context.read<CurrenciesBloc>().add(UpdateCcyStatusEvent(ccyCode: ccy.ccyCode!,status: e ?? false));
                                              },
                                          );
                                        });
                                      }),
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
          ],
        ),
      ),
    );
  }
  void onRefresh(){
    context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
  }

  void onAdd(){
    showDialog(context: context, builder: (context){
      return AddEditCurrencyView();
    });
  }
}

