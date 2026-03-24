import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/shortcut.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Users/Ui/add_user.dart';
import '../../../../../../../Features/Other/image_helper.dart';
import '../../../../../../../Features/Other/utils.dart';
import '../../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../Employees/features/emp_card.dart';
import '../../UserDetail/user_details.dart';
import '../bloc/users_bloc.dart';
import 'package:flutter/services.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

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
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    context.read<UsersBloc>().add(LoadUsersEvent());
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
    context.read<UsersBloc>().add(LoadUsersEvent());
  }

  void _onAddUser() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const AddUserView(), // No indId passed
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    final color = Theme.of(context).colorScheme;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

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
          child: FloatingActionButton.extended(
            onPressed: (login.hasPermission(106) ?? false) ? _onAddUser : null,
            tooltip: locale.newKeyword,
            icon: const Icon(Icons.add),
            label: Text(locale.newKeyword),
          ),
        ),
      ),
      body: BlocConsumer<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UsersErrorState) {
            Utils.showOverlayMessage(
              context,
              message: state.message,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          if (state is UsersLoadingState && state is! UsersLoadedState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is UsersErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: Text(locale.retry),
                  ),
                ],
              ),
            );
          }

          if (state is UsersLoadedState) {
            final users = state.users;

            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: color.outline.withValues(alpha: .3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      locale.noDataFound,
                      style: TextStyle(
                        fontSize: 16,
                        color: color.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (login.hasPermission(106) ?? false)
                      ElevatedButton.icon(
                        onPressed: _onAddUser,
                        icon: const Icon(Icons.add),
                        label: Text(locale.addUserTitle),
                      ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: color.primary,
              backgroundColor: color.surface,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: 80, // Space for FAB
                ),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final usr = users[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MobileInfoCard(
                      imageUrl: usr.usrPhoto,
                      title: usr.usrName ?? "-",
                      subtitle: usr.usrRole ?? "-",
                      infoItems: [
                        MobileInfoItem(
                          icon: Icons.person_outline,
                          text: usr.usrFullName ?? "-",
                        ),
                        MobileInfoItem(
                          icon: Icons.email_outlined,
                          text: usr.usrEmail ?? "-",
                        ),
                        MobileInfoItem(
                          icon: Icons.apartment_outlined,
                          text: usr.usrBranch?.toString() ?? "-",
                        ),
                      ],
                      status: MobileStatus(
                        label: usr.usrStatus == 1 ? locale.active : locale.blocked,
                        color: usr.usrStatus == 1 ? Colors.green : Colors.red,
                        backgroundColor: usr.usrStatus == 1
                            ? Colors.green.withValues(alpha: .1)
                            : Colors.red.withValues(alpha: .1),
                      ),
                      onTap: (login.hasPermission(107) ?? false)
                          ? () {
                        Utils.goto(context, UserDetailsView(usr: usr));
                      }
                          : null,
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
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersBloc>().add(LoadUsersEvent());
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
    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): onAdd,
      const SingleActivator(LogicalKeyboardKey.f5): onRefresh,
    };
    final locale = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return Scaffold(
      body: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Column(
          children: [
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 8),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: ZSearchField(
                      icon: FontAwesomeIcons.magnifyingGlass,
                      controller: searchController,
                      hint: locale.search,
                      onChanged: (e) {
                        setState(() {

                        });
                      },
                      title: "",
                    ),
                  ),
                  ZOutlineButton(
                      toolTip: 'F1',
                      width: 120,
                      icon: Icons.refresh,
                      onPressed: onRefresh,
                      label: Text(locale.refresh)),

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
            Expanded(
              child: BlocConsumer<UsersBloc, UsersState>(
                listener: (context,state){
                  if(state is UserSuccessState){
                    Navigator.of(context).pop();
                  }
                },
                builder: (context, state) {
                  if (state is UsersLoadingState) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (state is UsersErrorState) {
                    return NoDataWidget(
                      message: state.message,
                      onRefresh: () {
                        context.read<UsersBloc>().add(
                          LoadUsersEvent(),
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

                    if(filteredList.isEmpty){
                      return NoDataWidget(
                        message: locale.noDataFound,
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredList.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final usr = filteredList[index];

                        return ZCard(
                          // ---------- Avatar ----------
                          image: ImageHelper.stakeholderProfile(
                          imageName: usr.usrPhoto,
                          size: 46,
                        ),

                          // ---------- Title ----------
                          title: usr.usrName ?? "-",
                          subtitle: usr.usrEmail,

                          // ---------- Status ----------
                          status: InfoStatus(
                            label: usr.usrStatus == 1 ? locale.active : locale.blocked,
                            color: usr.usrStatus == 1 ? Colors.green : Colors.red,
                          ),

                          // ---------- Info Rows ----------
                          infoItems: [
                            InfoItem(
                              icon: Icons.person,
                              text: usr.usrFullName ?? "-",
                            ),
                            InfoItem(
                              icon: Icons.apartment,
                              text: usr.usrBranch?.toString() ?? "-",
                            ),
                            InfoItem(
                              icon: Icons.security,
                              text: usr.usrRole ?? "-",
                            ),
                          ],

                          // ---------- Action ----------

                          onTap: login.hasPermission(107) ?? false ? () {
                            showDialog(
                              context: context,
                              builder: (_) => UserDetailsView(usr: usr),
                            );
                          } : null,
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
    );
  }

  void onAdd(){
    showDialog(context: context, builder: (context){
      return AddUserView();
    });
  }

  void onRefresh(){
    context.read<UsersBloc>().add(LoadUsersEvent());
  }
}

