import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/shortcut.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/add_edit_gl.dart';
import '../../../../../../Features/Other/alert_dialog.dart';
import '../../../../../../Features/Other/utils.dart';
import '../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';
import 'bloc/gl_accounts_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

class GlAccountsView extends StatelessWidget {
  const GlAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(), tablet: _Desktop(), desktop: _Desktop());
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  String? myLocale;
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      myLocale = Localizations.localeOf(context).languageCode;
      context.read<GlAccountsBloc>().add(LoadGlAccountEvent());
    });
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  void _onScroll() {
    // Add debug print to check if listener is working
    // print('Scroll offset: ${_scrollController.offset}, Direction: ${_scrollController.position.userScrollDirection}');

    if (_scrollController.hasClients) {
      if (_scrollController.offset > 100 && _scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        // Scrolling down and past threshold - hide FAB
        if (_isFabVisible) {
          setState(() {
            _isFabVisible = false;
          });
        }
      } else if (_scrollController.offset < 50 || _scrollController.position.userScrollDirection == ScrollDirection.forward) {
        // Scrolling up or near the top - show FAB
        if (!_isFabVisible) {
          setState(() {
            _isFabVisible = true;
          });
        }
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
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
            tooltip: 'F1',
            child: const Icon(Icons.add),
          ),
        ),
      ),
      body: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                tr.glAccountsComplete,
                style: textTheme.titleSmall?.copyWith(color: color.outline),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
                child: ZSearchField(
                  controller: searchController,
                  hint: AppLocalizations.of(context)!.accNameOrNumber,
                  title: '',
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
            ),

            const SizedBox(height: 4),
            Expanded(
              child: BlocConsumer<GlAccountsBloc, GlAccountsState>(
                listener: (context, state) {
                  if (state is GlSuccessState) {
                    Navigator.of(context).pop();
                  }
                  if (state is GlAccountsErrorState) {
                    Utils.showOverlayMessage(
                        context,
                        message: state.message,
                        isError: true
                    );
                  }
                },
                builder: (context, state) {
                  if (state is GlAccountsLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is GlAccountLoadedState) {
                    final query = searchController.text.toLowerCase().trim();

                    final filteredList = state.gl.where((item) {
                      final name = item.accName?.toLowerCase() ?? '';
                      final number = item.accNumber?.toString() ?? '';
                      return name.contains(query) || number.contains(query);
                    }).toList();

                    if (filteredList.isEmpty) {
                      return NoDataWidget(
                        message: tr.noDataFound,
                        onRefresh: () {
                          context.read<GlAccountsBloc>().add(LoadGlAccountEvent());
                        },
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<GlAccountsBloc>().add(LoadGlAccountEvent());
                      },
                      child: ListView.builder(
                        controller: _scrollController, // 🔴 THIS WAS MISSING - FIXED
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final gl = filteredList[index];
                          return InkWell(
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return ZAlertDialog(
                                    title: tr.areYouSure,
                                    content: "Do you want to delete this code?",
                                    onYes: () {
                                      context.read<GlAccountsBloc>().add(
                                          DeleteGlEvent(gl.accNumber!)
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AddEditGl(model: gl);
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: .05)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                spacing: 10,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gl.accName ?? "",
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        Text(
                                          gl.accNumber.toString(),
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              color: color.outline
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Utils.glCategories(
                                            category: gl.accCategory!,
                                            locale: tr
                                        ),
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: color.outline
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        gl.acgName ?? "",
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontSize: 11
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
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
            )
          ],
        ),
      ),
    );
  }

  Future<void> onRefresh() async {
    context.read<GlAccountsBloc>().add(LoadGlAccountEvent());
  }

  void onAdd() {
    showDialog(
      context: context,
      builder: (context) {
        return AddEditGl();
      },
    );
  }
}


class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  String? myLocale;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      myLocale = Localizations.localeOf(context).languageCode;
      context.read<GlAccountsBloc>().add(LoadGlAccountEvent());
    });
    super.initState();
  }
  final searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      flex: 5,
                      child: Text(tr.glAccountsComplete,style: textTheme.titleLarge?.copyWith(color: color.outline))),
                  Expanded(
                    flex: 3,
                    child: ZSearchField(
                      controller: searchController,
                      hint: AppLocalizations.of(context)!.accNameOrNumber,
                      title: '',
                      end: searchController.text.isNotEmpty? InkWell(
                          splashColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: (){
                            setState(() {
                              searchController.clear();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.clear,size: 15,),
                          )) : SizedBox(),
                      onChanged: (e){
                        setState(() {
                        });
                      },
                      icon: FontAwesomeIcons.magnifyingGlass,
                    ),
                  ),
                  ZOutlineButton(
                      toolTip: 'F1',
                      width: 110,
                      icon: Icons.refresh,
                      onPressed: onRefresh,
                      label: Text(AppLocalizations.of(context)!.refresh)),
                  ZOutlineButton(
                      toolTip: 'F5',
                      width: 110,
                      isActive: true,
                      icon: Icons.add,
                      onPressed: onAdd,
                      label: Text(AppLocalizations.of(context)!.newKeyword)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 5),
              child: Row(
                children: [
                  Text(tr.accountNumber,style: textTheme.titleMedium?.copyWith(color: color.outline)),
                  SizedBox(width: 55),
                  Expanded(child: Text(tr.accountName,style: textTheme.titleMedium?.copyWith(color: color.outline))),
                  SizedBox(
                    width: 150,
                    child: Text(tr.categoryTitle,style: textTheme.titleMedium?.copyWith(color: color.outline)),
                  ),
                  SizedBox(
                    width: 185,
                    child: Text(tr.subCategory,style: textTheme.titleMedium?.copyWith(color: color.outline)),
                  ),

                ],
              ),
            ),
            Divider(endIndent: 2,indent: 2,color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),),

            Expanded(
              child: BlocConsumer<GlAccountsBloc, GlAccountsState>(
                listener: (context,state){
                  if(state is GlSuccessState){
                    Navigator.of(context).pop();
                  }
                  if(state is GlAccountsErrorState){
                    Utils.showOverlayMessage(context, message: state.message, isError: true);
                  }
                },
                builder: (context, state) {
                  if(state is GlAccountsLoadingState){
                   return Center(child: CircularProgressIndicator());
                  }
                  if(state is GlAccountLoadedState){
                    final query = searchController.text.toLowerCase().trim();

                    final filteredList = state.gl.where((item) {
                      final name = item.accName?.toLowerCase() ?? '';
                      final number = item.accNumber?.toString() ?? '';
                      return name.contains(query.toLowerCase()) || number.contains(query);
                    }).toList();

                    return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context,index){
                          final gl = filteredList[index];
                          return InkWell(
                            onTap: (){
                              showDialog(context: context, builder: (context){
                                return AddEditGl(model: gl);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 0,horizontal: 8),
                              decoration: BoxDecoration(
                                color: index.isEven ? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent,
                              ),
                              child: Row(
                                spacing: 10,
                                children: [
                                  SizedBox(
                                      width: 80,
                                      child: Text(gl.accNumber.toString(),style: Theme.of(context).textTheme.titleMedium)),
                                   myLocale == "en"? SizedBox(width: 50) : SizedBox(width: 20),
                                  Expanded(child: Text(gl.accName??"",style: Theme.of(context).textTheme.titleMedium)),
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                        Utils.glCategories(category: gl.accCategory!,locale: tr),
                                        style: Theme.of(context).textTheme.titleMedium,
                                        textAlign: TextAlign.center),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                        gl.acgName??"",
                                        style: Theme.of(context).textTheme.titleMedium,
                                        textAlign: TextAlign.center),
                                  ),

                                  SizedBox(
                                    width: 50,
                                    child: IconButton(
                                        onPressed: (){
                                          showDialog(context: context, builder: (context){
                                            return ZAlertDialog(title: tr.areYouSure,
                                                content: "Do wanna delete this code?",
                                                onYes: (){
                                                  context.read<GlAccountsBloc>().add(DeleteGlEvent(gl.accNumber!));
                                                });
                                          });
                                        },
                                        icon: Icon(Icons.delete_outline_rounded,color: color.outline,size: 20,)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                  }
                  return SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onRefresh(){
    context.read<GlAccountsBloc>().add(LoadGlAccountEvent());
  }

  void onAdd(){
    showDialog(context: context, builder: (context){
      return AddEditGl();
    });
  }
}

