import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/bloc/employee_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Other/image_helper.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../Features/Other/utils.dart';
import '../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../../HR/Ui/Employees/Ui/add_edit_employee.dart';
import '../../../HR/Ui/Employees/features/emp_card.dart';

class DriversView extends StatelessWidget {
  const DriversView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Mobile(), tablet: _Desktop(), desktop: _Desktop());
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const _MobileDriversView();
  }
}

class _MobileDriversView extends StatefulWidget {
  const _MobileDriversView();

  @override
  State<_MobileDriversView> createState() => _MobileDriversViewState();
}

class _MobileDriversViewState extends State<_MobileDriversView> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeBloc>().add(LoadEmployeeEvent(cat: "driver"));
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: color.outline.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search drivers',
                  prefixIcon: Icon(Icons.search, color: color.primary),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: color.outline),
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),

          // Drivers List
          Expanded(
            child: BlocBuilder<EmployeeBloc, EmployeeState>(
              builder: (context, state) {
                if (state is EmployeeLoadingState) {
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
                          size: 64,
                          color: color.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (state is EmployeeLoadedState) {
                  final query = searchController.text.toLowerCase().trim();
                  final filteredList = state.employees.where((item) {
                    final fullName = '${item.perName ?? ""} ${item.perLastName ?? ""}'.toLowerCase();
                    final position = item.empPosition?.toLowerCase() ?? '';
                    return fullName.contains(query) || position.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 64,
                            color: color.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Drivers Found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchController.text.isEmpty
                                ? 'No drivers registered yet'
                                : 'No results for "${searchController.text}"',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final driver = filteredList[index];
                      final fullName = '${driver.perName ?? ""} ${driver.perLastName ?? ""}'.trim();
                      return MobileInfoCard(
                        imageUrl: driver.empImage,
                        title: fullName.isNotEmpty ? fullName : 'Unnamed Driver',
                        subtitle: driver.empPosition ?? 'No Position',
                        status: MobileStatus(
                          label: driver.empStatus == 1 ? 'Active' : 'Inactive',
                          color: driver.empStatus == 1 ? Colors.green : Colors.red,
                          backgroundColor: driver.empStatus == 1
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                        ),
                        infoItems: [
                          if (driver.empDepartment != null)
                            MobileInfoItem(
                              icon: Icons.business_center,
                              text: driver.empDepartment!,
                              iconColor: color.primary,
                            ),
                          if (driver.empSalary != null)
                            MobileInfoItem(
                              icon: Icons.payments,
                              text: driver.empSalary!.toAmount(),
                              iconColor: Colors.green,
                            ),
                          if (driver.empHireDate != null)
                            MobileInfoItem(
                              icon: Icons.calendar_today,
                              text: driver.empHireDate!.toFormattedDate(),
                              iconColor: color.secondary,
                            ),
                        ],
                        onTap: () {
                          Utils.goto(context, AddEditEmployeeView(model: driver));
                        },
                        accentColor: color.primary,
                        showActions: true,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Utils.goto(context, const AddEditEmployeeView(
            isDriver: true,
            employeeType: 'driver',
          ),);
        },
        backgroundColor: color.primary,
        foregroundColor: color.surface,
        child: const Icon(Icons.add),
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
      context.read<EmployeeBloc>().add(LoadEmployeeEvent(cat: "driver"));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: ZSearchField(
                    icon: FontAwesomeIcons.magnifyingGlass,
                    controller: searchController,
                    hint: tr.search,
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
                    label: Text(tr.refresh)),

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
                  ToastManager.show(context: context,
                      title: tr.operationFailedTitle,
                      message: state.message, type: ToastType.error);
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
                    title: tr.accessDenied,
                    message: state.message,
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
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final emp = filteredList[index];
                      return ZCard(
                        image: ImageHelper.stakeholderProfile(
                          imageName: emp.empImage,
                          size: 46,
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
                            icon: Icons.payments,
                            text: emp.empSalary?.toAmount() ?? "-",
                          ),
                          InfoItem(
                            icon: Icons.date_range,
                            text: emp.empHireDate?.toFormattedDate() ?? "",
                          ),
                        ],
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddEditEmployeeView(model: emp),
                          );
                        },
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

  void onAdd() {
    showDialog(
      context: context,
      builder: (context) {
        return AddEditEmployeeView(
          isDriver: true,
          employeeType: 'driver',
        );
      },
    );
  }

  void onRefresh() {
    context.read<EmployeeBloc>().add(LoadEmployeeEvent(cat: "driver"));
  }
}

