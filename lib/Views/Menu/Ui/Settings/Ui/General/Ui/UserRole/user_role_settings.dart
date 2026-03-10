import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/toast.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Features/Widgets/search_field.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_edit_role.dart';
import 'bloc/user_role_bloc.dart';

class UserRoleSettingsView extends StatelessWidget {
  const UserRoleSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _Mobile(),
      tablet: const _Mobile(),
      desktop: const _Desktop(),
    );
  }
}

// Mobile Version
class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserRoleBloc>().add(LoadUserRolesEvent());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.userRole),
        centerTitle: true,
        actions: [
          ZOutlineButton(
            label: Text(tr.refresh),
            icon: Icons.refresh,
            height: 40,
            onPressed: _onRefresh,
          ),
          const SizedBox(width: 8),
          ZOutlineButton(
            label: Text(tr.newKeyword),
            icon: Icons.add,
            isActive: true,
            height: 40,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddEditUserRoleSettingsView(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ZSearchField(
              controller: searchController,
              hint: tr.search,
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
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocConsumer<UserRoleBloc, UserRoleState>(
      listener: (context, state) {
        if (state is UserRoleSuccessState) {
          ToastManager.show(
            context: context,
            title: tr.successTitle,
            message: tr.successMessage,
            type: ToastType.success,
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state is UserRoleLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is UserRoleErrorState) {
          return NoDataWidget(
            title: tr.errorTitle,
            message: state.message,
            onRefresh: () => _onRefresh(),
          );
        }
        if (state is UserRoleLoadedState) {
          final query = searchController.text.toLowerCase().trim();

          final filteredList = state.roles.where((item) {
            final name = item.rolName?.toLowerCase() ?? '';
            final id = item.rolId?.toString() ?? '';
            return name.contains(query) || id.contains(query);
          }).toList();

          if (filteredList.isEmpty) {
            return NoDataWidget(
              title: tr.noData,
              message: tr.noDataFound,
              onRefresh: () => _onRefresh(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final role = filteredList[index];
              final statusColor = role.rolStatus == 1
                  ? Colors.green
                  : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: color.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(color: color.outline.withValues(alpha: .1)),
                ),
                child: ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AddEditUserRoleSettingsView(model: role),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        role.rolId?.toString() ?? '',
                        style: TextStyle(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    role.rolName ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        role.rolStatus == 1 ? tr.active : tr.inactive,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      context.read<UserRoleBloc>().add(
                        DeleteUserRolesEvent(role.rolId!),
                      );
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: color.error,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  void _onRefresh() {
    context.read<UserRoleBloc>().add(LoadUserRolesEvent());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}


// Desktop Version
class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserRoleBloc>().add(LoadUserRolesEvent());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(tr.userRole, style: textTheme.titleMedium),
                ),
                Expanded(
                  flex: 2,
                  child: ZSearchField(
                    controller: searchController,
                    hint: tr.search,
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
                ZOutlineButton(
                  width: 110,
                  icon: Icons.refresh,
                  onPressed: _onRefresh,
                  label: Text(tr.refresh),
                ),
                ZOutlineButton(
                  width: 110,
                  isActive: true,
                  icon: Icons.add,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AddEditUserRoleSettingsView();
                      },
                    );
                  },
                  label: Text(tr.newKeyword),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<UserRoleBloc, UserRoleState>(
              listener: (context, state) {
                if (state is UserRoleSuccessState) {
                  ToastManager.show(
                    context: context,
                    title: tr.successTitle,
                    message: tr.successMessage,
                    type: ToastType.success,
                  );
                }
              },
              builder: (context, state) {
                if (state is UserRoleLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is UserRoleErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    onRefresh: () => _onRefresh(),
                  );
                }
                if (state is UserRoleLoadedState) {
                  final query = searchController.text.toLowerCase().trim();

                  final filteredList = state.roles.where((item) {
                    final name = item.rolName?.toLowerCase() ?? '';
                    final id = item.rolId?.toString() ?? '';
                    return name.contains(query) || id.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      onRefresh: () => _onRefresh(),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final role = filteredList[index];

                      return InkWell(
                        onTap: (){
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AddEditUserRoleSettingsView(model: role);
                            },
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12,vertical: 8),
                          decoration: BoxDecoration(
                            color: index.isOdd? color.primary.withValues(alpha: .03) : Colors.transparent,
                          ),
                          child: Row(
                            children: [

                              CircleAvatar(
                                  child: Text(role.rolId.toString())),
                              SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  role.rolName??"",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),

                              IconButton(
                                  onPressed: (){
                                    context.read<UserRoleBloc>().add(
                                      DeleteUserRolesEvent(role.rolId!),
                                    );
                                  },
                                  icon: Icon(Icons.delete_outline_rounded)),
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
    );
  }

  void _onRefresh() {
    context.read<UserRoleBloc>().add(LoadUserRolesEvent());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
