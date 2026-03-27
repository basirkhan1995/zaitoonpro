import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/image_helper.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/shortcut.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/IndividualDetails/profile.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/Ui/add_edit.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../../Auth/models/login_model.dart';
import '../../../../HR/Ui/Employees/features/emp_card.dart';
import '../../IndividualDetails/Ui/Profile/ind_profile.dart';
import 'package:flutter/services.dart';

class IndividualsView extends StatelessWidget {
  const IndividualsView({super.key});

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
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onRefresh();
    });
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
        ),
      ),
      body: BlocConsumer<IndividualsBloc, IndividualsState>(
        listener: (context, state) {
          if (state is IndividualSuccessState ||
              state is IndividualSuccessImageState) {
            onRefresh();
          }
        },
        builder: (context, state) {
          if (state is IndividualLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is IndividualErrorState) {
            return NoDataWidget(
              message: state.message,
              onRefresh: () {
                context.read<IndividualsBloc>().add(
                  LoadIndividualsEvent(),
                );
              },
            );
          }
          if (state is IndividualLoadedState) {
            final query = searchController.text.toLowerCase().trim();
            final filteredList = state.individuals.where((item) {
              final firstName = item.perName?.toLowerCase() ?? '';
              final lastName = item.perLastName?.toLowerCase() ?? '';
              final fullName = "$firstName $lastName";
              final email = item.perEmail?.toLowerCase() ?? '';
              final phone = item.perPhone?.toLowerCase() ?? '';

              return fullName.contains(query) ||
                  email.contains(query) ||
                  phone.contains(query);
            }).toList();

            if (filteredList.isEmpty) {
              return NoDataWidget(
                message: tr.noDataFound,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<IndividualsBloc>().add(LoadIndividualsEvent());
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final stk = filteredList[index];

                  final firstName = stk.perName?.trim() ?? "";
                  final lastName = stk.perLastName?.trim() ?? "";
                  final fullName = "$firstName $lastName".trim();

                  // Prepare info items
                  List<MobileInfoItem> infoItems = [];

                  if (stk.perPhone != null && stk.perPhone!.isNotEmpty) {
                    infoItems.add(MobileInfoItem(
                      icon: Icons.phone,
                      text: stk.perPhone!,
                      iconColor: colorScheme.primary,
                    ));
                  }

                  if (stk.perEnidNo != null && stk.perEnidNo!.isNotEmpty) {
                    infoItems.add(MobileInfoItem(
                      icon: Icons.badge,
                      text: stk.perEnidNo!,
                      iconColor: colorScheme.secondary,
                    ));
                  }

                  if (stk.addCity != null && stk.addCity!.isNotEmpty) {
                    infoItems.add(MobileInfoItem(
                      icon: Icons.location_city_rounded,
                      text: stk.addCity!,
                      iconColor: colorScheme.tertiary,
                    ));
                  }

                  Color statusColor = colorScheme.primary;
                  Color? statusBgColor;

                  return MobileInfoCard(
                    imageUrl: stk.imageProfile,
                    title: fullName.isNotEmpty ? fullName : "—",
                    subtitle: stk.perEmail,
                    infoItems: infoItems,
                    status: MobileStatus(
                      label: Utils.genderType(
                        gender: stk.perGender ?? "",
                        locale: tr,
                      ),
                      color: statusColor,
                      backgroundColor: statusBgColor,
                    ),
                    onTap: (login.hasPermission(32) ?? false) ? () {
                      Utils.goto(
                        context,
                        IndividualsDetailsTabView(ind: stk),
                      );
                    } : null,
                    accentColor: colorScheme.primary,
                    showActions: false,
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: (login.hasPermission(106) ?? false)
          ? FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  void onAdd() {
    Utils.goto(context, IndividualAddEditView(),);
  }

  void onRefresh() {
    context.read<IndividualsBloc>().add(LoadIndividualsEvent());
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onRefresh();
    });
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): onAdd,
      const SingleActivator(LogicalKeyboardKey.f5): onRefresh,
    };

    return Scaffold(
      body: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ListTile(
                        tileColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          tr.individuals,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 20),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!.stakeholderManage,
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
                    if (login.hasPermission(106) ?? false)
                      ZOutlineButton(
                        toolTip: "F1",
                        width: 120,
                        icon: Icons.add,
                        isActive: true,
                        onPressed: onAdd,
                        label: Text(tr.newKeyword),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: BlocConsumer<IndividualsBloc, IndividualsState>(
                  listener: (context, state) {
                    if (state is IndividualSuccessState ||
                        state is IndividualSuccessImageState) {
                      onRefresh();
                    }
                  },
                  builder: (context, state) {
                    if (state is IndividualLoadingState) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is IndividualErrorState) {
                      return NoDataWidget(
                        message: state.message,
                        onRefresh: () {
                          context.read<IndividualsBloc>().add(
                            LoadIndividualsEvent(),
                          );
                        },
                      );
                    }
                    if (state is IndividualLoadedState) {
                      final query = searchController.text.toLowerCase().trim();
                      final filteredList = state.individuals.where((item) {
                        final name = item.perName?.toLowerCase() ?? '';
                        return name.contains(query);
                      }).toList();

                      if (filteredList.isEmpty) {
                        return NoDataWidget(
                          message: tr.noDataFound,
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(15),
                        gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 22,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final stk = filteredList[index];

                          final firstName = stk.perName?.trim() ?? "";
                          final lastName = stk.perLastName?.trim() ?? "";
                          final fullName = "$firstName $lastName".trim();

                          return ZCard(
                            image: ImageHelper.stakeholderProfile(
                              imageName: stk.imageProfile,
                              size: 46,
                            ),
                            title: fullName.isNotEmpty ? fullName : "—",
                            subtitle: stk.perEmail,
                            status: InfoStatus(
                              label: Utils.genderType(
                                gender: stk.perGender ?? "",
                                locale: tr,
                              ),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            infoItems: [
                              InfoItem(
                                icon: Icons.location_city_rounded,
                                text: stk.addCity ?? "-",
                              ),
                              InfoItem(
                                icon: Icons.phone,
                                text: stk.perPhone ?? "-",
                              ),

                            ],
                            onTap: (login.hasPermission(32) ?? false)
                                ? () {
                              Utils.goto(
                                context,
                                IndividualProfileView(ind: stk),
                              );
                            }
                                : null,
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
      ),
    );
  }

  void onAdd() {
    showDialog(
      context: context,
      builder: (context) {
        return IndividualAddEditView();
      },
    );
  }

  void onRefresh() {
    context.read<IndividualsBloc>().add(LoadIndividualsEvent());
  }
}