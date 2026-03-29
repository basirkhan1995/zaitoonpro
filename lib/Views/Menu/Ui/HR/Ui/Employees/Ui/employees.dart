import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/shortcut.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/Ui/add_edit_employee.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/bloc/employee_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Other/image_helper.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../features/emp_card.dart';
import 'package:flutter/services.dart';

class EmployeesView extends StatelessWidget {
  const EmployeesView({super.key});

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeBloc>().add(LoadEmployeeEvent());
    });
  }

  Future<void> _onRefresh() async {
    context.read<EmployeeBloc>().add(LoadEmployeeEvent());
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: (){
            showDialog(
                context: context, builder: (context){
                return AddEditEmployeeView();
            });
          }),
      body: BlocConsumer<EmployeeBloc, EmployeeState>(
        listener: (context, state) {
          if (state is EmployeeErrorState) {
            Utils.showOverlayMessage(
              context,
              title: tr.accessDenied,
              message: state.message,
              isError: true,
            );
          }
          if (state is EmployeeSuccessState) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state is EmployeeLoadingState && state is! EmployeeLoadedState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is EmployeeErrorState) {
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: Text(tr.retry),
                  ),
                ],
              ),
            );
          }

          if (state is EmployeeLoadedState) {
            final employees = state.employees;

            if (employees.isEmpty) {
              return Center(
                child: Text(tr.noDataFound),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];

                  return MobileInfoCard(
                    imageUrl: emp.empImage,
                    title: "${emp.perName} ${emp.perLastName}",
                    subtitle: emp.empPosition,
                    infoItems: [
                      MobileInfoItem(
                        icon: Icons.apartment_outlined,
                        text: emp.empDepartment ?? "-",
                      ),
                      MobileInfoItem(
                        icon: Icons.payments_outlined,
                        text: emp.empSalary?.toAmount() ?? "-",
                      ),
                      MobileInfoItem(
                        icon: Icons.calendar_today_outlined,
                        text: emp.empHireDate?.toFormattedDate() ?? "-",
                      ),
                    ],
                    status: MobileStatus(
                      label: emp.empStatus == 1 ? tr.active : tr.inactive,
                      color: emp.empStatus == 1 ? Colors.green : Colors.red,
                      backgroundColor: emp.empStatus == 1
                          ? Colors.green.withValues(alpha: .1)
                          : Colors.red.withValues(alpha: .1),
                    ),
                    onTap: login.hasPermission(108) ?? false
                        ? () {
                       Utils.goto(context, AddEditEmployeeView(model: emp));
                    }
                        : null,
                    showActions: false,
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

  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      context.read<EmployeeBloc>().add(LoadEmployeeEvent());
    });
    super.initState();
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [

                  Expanded(
                    flex: 5,
                    child: Text(
                      tr.employees, style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: ZSearchField(
                      icon: FontAwesomeIcons.magnifyingGlass,
                      controller: searchController,
                      hint: tr.search,
                      onChanged: (e) {
                        setState(() {

                        });
                      },
                      title: "",
                    ),
                  ),
                  ZOutlineButton(
                      toolTip: 'F5',
                      width: 120,
                      icon: Icons.refresh,
                      onPressed: onRefresh,
                      label: Text(tr.refresh)),
                  if(login.hasPermission(106) ?? false)
                  ZOutlineButton(
                      toolTip: 'F1',
                      width: 120,
                      icon: Icons.add,
                      isActive: true,
                      onPressed: onAdd,
                      label: Text(tr.newKeyword)),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<EmployeeBloc, EmployeeState>(
                listener: (context, state) {
                  if(state is EmployeeErrorState){
                    Utils.showOverlayMessage(context, title: tr.accessDenied, message: state.message, isError: true);
                  }
                  if(state is EmployeeSuccessState){
                    Navigator.of(context).pop();
                  }
                },
                builder: (context, state) {
                  if(state is EmployeeLoadingState){
                    return Center(child: CircularProgressIndicator());
                  }
                  if(state is EmployeeErrorState){
                    return NoDataWidget(
                      imageName: "error.png",
                      title: tr.accessDenied,
                      message: state.message,
                      onRefresh: (){
                        context.read<EmployeeBloc>().add(LoadEmployeeEvent());
                      },
                    );
                  }
                  if(state is EmployeeLoadedState){
                    final query = searchController.text.toLowerCase().trim();
                    final filteredList = state.employees.where((item) {
                      final name = item.perName?.toLowerCase() ?? '';
                      return name.contains(query);
                    }).toList();

                    if(filteredList.isEmpty){
                      return NoDataWidget(
                        title: tr.noData,
                        message: tr.noDataFound,
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.80,
                      ),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final emp = filteredList[index];
                        return ZCard(
                          image: ImageHelper.stakeholderProfile(
                            imageName: emp.empImage,
                            size: 60,
                          ),

                          title: "${emp.perName} ${emp.perLastName}",
                          subtitle: emp.empPosition,
                          status: InfoStatus(
                            label: emp.empStatus == 1 ? tr.active : tr.inactive,
                            color: emp.empStatus == 1 ? Colors.green : Colors.red,
                          ),
                          infoItems: [
                            InfoItem(
                              icon: Icons.apartment,
                              text: emp.empDepartment ?? "-",
                            ),
                            InfoItem(
                              icon: Icons.date_range,
                              text: emp.empHireDate?.toFormattedDate() ?? "",
                            ),
                          ],
                          onTap: login.hasPermission (108) ?? false ? () {
                            showDialog(
                              context: context,
                              builder: (_) => AddEditEmployeeView(model: emp),
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
      return AddEditEmployeeView();
    });
  }
  void onRefresh(){
    context.read<EmployeeBloc>().add(LoadEmployeeEvent());
  }
}

