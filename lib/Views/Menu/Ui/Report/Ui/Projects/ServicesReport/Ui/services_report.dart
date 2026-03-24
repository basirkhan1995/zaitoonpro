import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/AllProjects/bloc/projects_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Projects/ServicesReport/model/services_report_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/bloc/services_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/model/services_model.dart';
import '../../../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../../../../../Features/Widgets/zcard_mobile.dart';
import '../../../../../Finance/Ui/Currency/features/currency_drop.dart';
import '../bloc/services_report_bloc.dart';

class ServicesReportView extends StatelessWidget {
  const ServicesReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Mobile(), tablet: _Tablet(), desktop: _Desktop());
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const _MobileTabletLayout();
  }
}

class _Tablet extends StatelessWidget {
  const _Tablet();

  @override
  Widget build(BuildContext context) {
    return const _MobileTabletLayout();
  }
}

class _MobileTabletLayout extends StatefulWidget {
  const _MobileTabletLayout();

  @override
  State<_MobileTabletLayout> createState() => _MobileTabletLayoutState();
}

class _MobileTabletLayoutState extends State<_MobileTabletLayout> {
  String fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();

  final servicesController = TextEditingController();
  final projectsController = TextEditingController();

  int? projectId;
  int? serviceId;

  // Summary values
  int totalServices = 0;
  double totalAmount = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesReportBloc>().add(ResetServicesReportEvent());
    });
    super.initState();
  }

  void _updateSummary(List<ServicesReportModel> services) {
    totalServices = services.length;
    totalAmount = services.fold(0, (sum, service) => sum + (service.totalAmount.toDoubleAmount()));
  }

  void _showFilterSheet(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    ZDraggableSheet.show(
      context: context,
      title: tr.applyFilter,
      showCloseButton: true,
      showDragHandle: true,
      adaptiveInitialSize: true,
      estimatedContentHeight: 530,
      bodyBuilder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            // Services Dropdown
            GenericTextfield<ServicesModel, ServicesBloc, ServicesState>(
              title: tr.services,
              controller: servicesController,
              hintText: "Select Service",
              bloc: context.read<ServicesBloc>(),
              fetchAllFunction: (bloc) => bloc.add(LoadServicesEvent()),
              searchFunction: (bloc, query) =>
                  bloc.add(LoadServicesEvent(search: query)),
              showAllOption: true,
              allOption: ServicesModel(srvName: "All"),
              itemBuilder: (context, services) {
                if (services.srvId == null) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "All",
                      style: TextStyle(
                        color: color.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(services.srvName ?? ''),
                );
              },
              itemToString: (ser) =>
              ser.srvName ?? (ser.srvId == null ? "All" : ''),
              stateToLoading: (state) => state is ServicesLoadingState,
              stateToItems: (state) {
                if (state is ServicesLoadedState) {
                  return state.services;
                }
                return [];
              },
              onSelected: (ser) {
                setState(() {
                  serviceId = ser.srvId;
                  if (ser.srvId == null) {
                    servicesController.clear();
                  } else {
                    servicesController.text = ser.srvName ?? '';
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // Projects Dropdown
            GenericTextfield<ProjectsModel, ProjectsBloc, ProjectsState>(
              title: "Projects",
              controller: projectsController,
              hintText: "Select Project",
              bloc: context.read<ProjectsBloc>(),
              fetchAllFunction: (bloc) => bloc.add(LoadProjectsEvent()),
              searchFunction: (bloc, query) =>
                  bloc.add(LoadProjectsEvent()),
              showAllOption: true,
              allOption: ProjectsModel(prjName: "All"),
              itemBuilder: (context, prj) {
                if (prj.prjId == null) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "All",
                      style: TextStyle(
                        color: color.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(prj.prjName ?? ''),
                );
              },
              itemToString: (prj) =>
              prj.prjName ?? (prj.prjId == null ? "All" : ''),
              stateToLoading: (state) => state is ProjectsLoadingState,
              stateToItems: (state) {
                if (state is ProjectsLoadedState) {
                  return state.pjr;
                }
                return [];
              },
              onSelected: (prj) {
                setState(() {
                  projectId = prj.prjId;
                  if (prj.prjId == null) {
                    projectsController.clear();
                  } else {
                    projectsController.text = prj.prjName ?? '';
                  }
                });
              },
            ),
            const SizedBox(height: 15),
            Expanded(
              child: CurrencyDropdown(
                title: tr.currencyTitle,
                isMulti: false,
                onMultiChanged: (e){},
                onSingleChanged: (e){
                  context.read<ServicesReportBloc>().add(
                    LoadServicesReportEvent(
                        fromDate: fromDate,
                        toDate: toDate,
                        serviceId: serviceId,
                        projectId: projectId,
                        currency: e?.ccyCode??""
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Date Pickers
            ZDatePicker(
              label: "From Date",
              value: fromDate,
              onDateChanged: (v) {
                setState(() {
                  fromDate = v;
                });
              },
            ),

            const SizedBox(height: 12),

            ZDatePicker(
              label: "To Date",
              value: toDate,
              onDateChanged: (v) {
                setState(() {
                  toDate = v;
                });
              },
            ),

            const SizedBox(height: 24),
            // Apply Filter Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ZOutlineButton(
                isActive: true,
                onPressed: () {
                  Navigator.pop(context);
                  _applyFilters();
                },
                icon: Icons.filter_alt,
                label: Text(tr.applyFilter),
              ),
            ),

            // Reset Button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    serviceId = null;
                    projectId = null;
                    servicesController.clear();
                    projectsController.clear();
                    fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
                    toDate = DateTime.now().toFormattedDate();
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
                child: const Text("Reset Filters"),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Services Report"),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Summary Chips
          if (_hasActiveFilters())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (serviceId != null)
                      _FilterChip(
                        label: "Service: ${servicesController.text}",
                        onDeleted: () {
                          setState(() {
                            serviceId = null;
                            servicesController.clear();
                            _applyFilters();
                          });
                        },
                      ),
                    if (projectId != null)
                      _FilterChip(
                        label: "Project: ${projectsController.text}",
                        onDeleted: () {
                          setState(() {
                            projectId = null;
                            projectsController.clear();
                            _applyFilters();
                          });
                        },
                      ),
                    if (fromDate != DateTime.now().subtract(const Duration(days: 7)).toFormattedDate())
                      _FilterChip(
                        label: "From: $fromDate",
                        onDeleted: () {
                          setState(() {
                            fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
                            _applyFilters();
                          });
                        },
                      ),
                    if (toDate != DateTime.now().toFormattedDate())
                      _FilterChip(
                        label: "To: $toDate",
                        onDeleted: () {
                          setState(() {
                            toDate = DateTime.now().toFormattedDate();
                            _applyFilters();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

          // Summary Card
          BlocBuilder<ServicesReportBloc, ServicesReportState>(
            builder: (context, state) {
              if (state is ServicesReportLoadedState) {
                _updateSummary(state.services);
                return Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.primary.withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Services",
                              style: TextStyle(
                                fontSize: 12,
                                color: color.onPrimaryContainer.withValues(alpha: .7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalServices.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: color.primary.withValues(alpha: .3),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 12,
                                color: color.onPrimaryContainer.withValues(alpha: .7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalAmount.toAmount(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Content
          Expanded(
            child: BlocBuilder<ServicesReportBloc, ServicesReportState>(
              builder: (context, state) {
                if (state is ServicesReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ServicesReportErrorState) {
                  return _buildNoDataWidget(
                    title: "Error",
                    message: state.message,
                  );
                }if(state is ServicesReportInitial){
                  return Center(
                    child: NoDataWidget(
                      title: "Service Report",
                      message: "Select filter to report",
                      enableAction: false,
                    ),
                  );
                }
                if (state is ServicesReportLoadedState) {
                  if (state.services.isEmpty) {
                    return _buildNoDataWidget(
                      title: "No Data",
                      message: "No services found",
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: state.services.length,
                    itemBuilder: (context, index) {
                      final service = state.services[index];

                      // Create info items for the card
                      final infoItems = [
                        MobileInfoItem(
                          icon: Icons.money,
                          text: "${service.pjdPricePerQty.toAmount()} ${service.currency}",
                        ),
                        MobileInfoItem(
                          icon: Icons.format_list_numbered,
                          text: "QTY: ${service.pjdQuantity}",
                        ),
                        MobileInfoItem(
                          icon: Icons.calculate,
                          text: "Total: ${service.totalAmount.toAmount()} ${service.currency}",
                          iconColor: Colors.green,
                        ),
                      ];

                      return MobileInfoCard(
                        title: service.serviceName ?? "Unknown Service",
                        subtitle: service.projectName ?? "No Project",
                        infoItems: infoItems,
                        showActions: false, // Disable the view details button
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

  bool _hasActiveFilters() {
    return serviceId != null ||
        projectId != null ||
        fromDate != DateTime.now().subtract(const Duration(days: 7)).toFormattedDate() ||
        toDate != DateTime.now().toFormattedDate();
  }

  void _applyFilters() {
    context.read<ServicesReportBloc>().add(
      LoadServicesReportEvent(
        fromDate: fromDate,
        toDate: toDate,
        serviceId: serviceId,
        projectId: projectId,
      ),
    );
  }

  Widget _buildNoDataWidget({required String title, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    servicesController.dispose();
    projectsController.dispose();
    super.dispose();
  }
}

// Helper widget for filter chips
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _FilterChip({
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
  String fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      context.read<ServicesReportBloc>().add(ResetServicesReportEvent());
    });
    super.initState();
  }

  final servicesController = TextEditingController();
  final projectsController = TextEditingController();

  int? projectId;
  int? serviceId;

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: color.surface);
    TextStyle? subtitleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: color.outline);
    return Scaffold(
      appBar: AppBar(
        title: Text("Services Report"),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: GenericTextfield<ServicesModel, ServicesBloc, ServicesState>(
                    title: tr.services,
                    controller: servicesController,
                    hintText: tr.services,
                    bloc: context.read<ServicesBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadServicesEvent()),
                    searchFunction: (bloc, query) => bloc.add(LoadServicesEvent(search: query)),
                    showAllOption: true,
                    allOption: ServicesModel(
                      srvName: tr.all,
                    ),
                    itemBuilder: (context, services) {
                      if (services.srvId == null) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            tr.all,
                            style: TextStyle(
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(services.srvName ?? ''),
                      );
                    },
                    itemToString: (ser) =>
                    ser.srvName ?? (ser.srvId == null ? tr.all : ''),
                    stateToLoading: (state) =>
                    state is ServicesLoadingState,
                    stateToItems: (state) {
                      if (state is ServicesLoadedState) {
                        return state.services;
                      }
                      return [];
                    },
                    onSelected: (ser) {
                      setState(() {
                        serviceId = ser.srvId;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GenericTextfield<ProjectsModel, ProjectsBloc, ProjectsState>(
                    title: tr.projects,
                    controller: projectsController,
                    hintText: tr.projects,
                    bloc: context.read<ProjectsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadProjectsEvent()),
                    searchFunction: (bloc, query) => bloc.add(LoadProjectsEvent()),
                    showAllOption: true,
                    allOption: ProjectsModel(
                      prjName: tr.all,
                    ),
                    itemBuilder: (context, prj) {
                      if (prj.prjId == null) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            tr.all,
                            style: TextStyle(
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(prj.prjName ?? ''),
                      );
                    },
                    itemToString: (prj) =>
                    prj.prjName ?? (prj.prjId == null ? tr.all : ''),
                    stateToLoading: (state) =>
                    state is ProjectsLoadingState,
                    stateToItems: (state) {
                      if (state is ProjectsLoadedState) {
                        return state.pjr;
                      }
                      return [];
                    },
                    onSelected: (prj) {
                      setState(() {
                        projectId = prj.prjId;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZDatePicker(
                    label: tr.fromDate,
                    value: fromDate,
                    onDateChanged: (v) {
                      setState(() {
                        fromDate = v;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZDatePicker(
                    label: tr.toDate,
                    value: toDate,
                    onDateChanged: (v) {
                      setState(() {
                        toDate = v;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CurrencyDropdown(
                    title: tr.currencyTitle,
                    isMulti: false,
                    onMultiChanged: (e){},
                    onSingleChanged: (e){
                      context.read<ServicesReportBloc>().add(LoadServicesReportEvent(
                          fromDate: fromDate,
                          toDate: toDate,
                          serviceId: serviceId,
                          projectId: projectId,
                          currency: e?.ccyCode??""
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                    isActive: true,
                    height: 47,
                    icon: Icons.filter_alt_outlined,
                    onPressed: (){
                      context.read<ServicesReportBloc>().add(LoadServicesReportEvent(
                        fromDate: fromDate,
                        toDate: toDate,
                        serviceId: serviceId,
                        projectId: projectId
                      ));
                    },
                    label: Text(tr.applyFilter)),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: color.primary,

            ),
            child: Row(
              children: [
                SizedBox(
                    width: 100,
                    child: Text(tr.date,style: titleStyle)),

                Expanded(
                    child: Text("Service & Project name",style: titleStyle)),

                SizedBox(
                    width: 100,
                    child: Text("Charges",style: titleStyle)),

                SizedBox(
                    width: 100,
                    child: Text(tr.qty,style: titleStyle)),

                SizedBox(
                    width: 100,
                    child: Text("Total Value",style: titleStyle)),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ServicesReportBloc, ServicesReportState>(
              builder: (context, state) {
                if(state is ServicesReportLoadingState){
                  return Center(child: CircularProgressIndicator());
                }if(state is ServicesReportErrorState){
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                  );
                }if(state is ServicesReportLoadedState){
                 return ListView.builder(
                     itemCount: state.services.length,
                     itemBuilder: (context,index){
                       final service = state.services[index];
                     return Container(
                       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       decoration: BoxDecoration(
                        color: index.isOdd? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent
                       ),
                       child: Row(
                         children: [
                           SizedBox(
                               width: 100,
                               child: Text(service.entryDate.toFormattedDate())),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service.serviceName??"",style: titleStyle?.copyWith(color: color.onSurface),),
                                Text(service.projectName??"",style: subtitleStyle),
                              ],
                            ),
                          ),
                           SizedBox(
                               width: 100,
                               child: Text("${service.pjdPricePerQty.toAmount()} ${service.currency}")),
                           SizedBox(
                               width: 100,
                               child: Text(service.pjdQuantity.toString())),
                           SizedBox(
                               width: 100,
                               child: Text("${service.totalAmount.toAmount()} ${service.currency}")),

                         ],
                       ),
                     );
                 });
                }
                return const SizedBox();
              },
            ),
          )

        ],
      ),
    );
  }
}
