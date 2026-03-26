import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/Ui/add_user.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/bloc/users_bloc.dart';
import '../../../../../../../../Features/Other/cover.dart';
import '../../../../../../../../Features/Other/utils.dart';
import '../../../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../../../Auth/models/login_model.dart';
import '../../../../../HR/Ui/UserDetail/user_details.dart';


class UsersByPerIdView extends StatelessWidget {
  final int perId;
  const UsersByPerIdView({super.key, required this.perId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Mobile(perId),
        tablet: _Desktop(perId),
        desktop: _Desktop(perId)
    );
  }
}


class _Mobile extends StatefulWidget {
  final int perId;
  const _Mobile(this.perId);

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  bool _isFabVisible = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersBloc>().add(LoadUsersEvent(usrOwner: widget.perId));
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 100 &&
          _scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        // Scrolling down and past threshold - hide FAB
        if (_isFabVisible) {
          setState(() {
            _isFabVisible = false;
          });
        }
      } else if (_scrollController.offset < 50 ||
          _scrollController.position.userScrollDirection == ScrollDirection.forward) {
        // Scrolling up or near the top - show FAB
        if (!_isFabVisible) {
          setState(() {
            _isFabVisible = true;
          });
        }
      }
    }
  }

  Future<void> _onRefresh() async {
    context.read<UsersBloc>().add(LoadUsersEvent(usrOwner: widget.perId));
    // Add a small delay to ensure the refresh indicator shows properly
    await Future.delayed(const Duration(milliseconds: 500));
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
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
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
            onPressed: () {
              // Add user action - you can implement this later
             showDialog(context: context, builder: (context){
               return AddUserView(indId: widget.perId);
             });
            },
            tooltip: locale.newKeyword,
            child: const Icon(Icons.add),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 5),
            child: ZSearchField(
              controller: searchController,
              hint: locale.search,
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

          const SizedBox(height: 4),

          // Users List
          Expanded(
            child: BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                if (state is UsersLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is UsersErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: _onRefresh,
                  );
                }
                if (state is UsersLoadedState) {
                  final query = searchController.text.toLowerCase().trim();

                  final filteredList = state.users.where((item) {
                    final name = item.usrName?.toLowerCase() ?? '';
                    final email = item.usrEmail?.toLowerCase() ?? '';
                    return name.contains(query) || email.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: locale.noDataFound,
                      onRefresh: _onRefresh,
                    );
                  }

                  return RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _onRefresh,
                    displacement: 40, // Add displacement for better visibility
                    color: color.primary, // Customize color
                    backgroundColor: color.surface,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(), // Force scrollable even with few items
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final user = filteredList[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4,
                          ),
                          child: MobileInfoCard(
                            imageUrl: user.usrPhoto,
                            title: user.usrName ?? '-',
                            subtitle: user.usrEmail ?? '-',
                            infoItems: [
                              MobileInfoItem(
                                icon: Icons.person_outline,
                                text: user.usrFullName ?? '-',
                              ),
                              MobileInfoItem(
                                icon: Icons.business_outlined,
                                text: user.usrBranch?.toString() ?? '-',
                              ),
                              MobileInfoItem(
                                icon: Icons.security_outlined,
                                text: user.usrRole ?? '-',
                              ),
                            ],
                            status: MobileStatus(
                              label: user.usrStatus == 1 ? locale.active : locale.blocked,
                              color: user.usrStatus == 1 ? Colors.green : Colors.red,
                              backgroundColor: (user.usrStatus == 1 ? Colors.green : Colors.red).withValues(alpha: .1),
                            ),
                            onTap: () {
                              Utils.goto(context, UserDetailsView(usr: user));
                            },
                            showActions: true,
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
  final int perId;
  const _Desktop(this.perId);

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersBloc>().add(LoadUsersEvent(usrOwner: widget.perId));
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
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    final tr = AppLocalizations.of(context)!;
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
                    hint: locale.search,
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
                if(login.hasPermission(106) ?? false)
                  ZOutlineButton(
                      toolTip: 'F5',
                      width: 120,
                      icon: Icons.add,
                      isActive: true,
                      onPressed: onAdd,
                      label: Text(locale.newKeyword)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    locale.userInformation,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                 SizedBox(width: 150, child: Text(tr.owned)),
                 SizedBox(width: 100, child: Text(tr.branch)),
                 SizedBox(width: 100, child: Text(tr.usrRole)),
                 SizedBox(width: 100, child: Text(tr.status)),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Divider(
            indent: 15,
            endIndent: 15,
            color: Theme.of(context).colorScheme.primary,
            height: 0,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                if (state is UsersLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is UsersErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: () {
                      context.read<UsersBloc>().add(
                        LoadUsersEvent(usrOwner: widget.perId),
                      );
                    },
                  );
                }
                if (state is UsersLoadedState) {
                  final query = searchController.text.toLowerCase().trim();
                  final filteredList = state.users.where((item) {
                    final name = item.usrName?.toLowerCase() ?? '';
                    return name.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: locale.noDataFound,
                      enableAction: false,
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final user = filteredList[index];

                      return InkWell(
                        highlightColor: color.primary.withValues(alpha: .06),
                        hoverColor: color.primary.withValues(alpha: .06),
                        onTap: login.hasPermission (107) ?? false ? () {
                          showDialog(context: context, builder: (context){
                            return UserDetailsView(usr: user);
                          });
                        } : null,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: color.primary.withValues(alpha: .7),
                                  radius: 23,
                                  child: Text(
                                    user.usrId.toString(),
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
                                        user.usrName ?? "",
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      ZCover(
                                        color: color.surface,
                                        child: Text(user.usrEmail ?? ""),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: Text(user.usrFullName ?? ""),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(user.usrBranch?.toString() ?? ""),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(user.usrRole ?? ""),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                      user.usrStatus == 1
                                          ? locale.active
                                          : locale.blocked
                                  ),
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
  void onAdd(){
    showDialog(context: context, builder: (context){
      return AddUserView(indId: widget.perId);
    });
  }
  void onRefresh() {
    context.read<UsersBloc>().add(LoadUsersEvent(usrOwner: widget.perId));
  }
}