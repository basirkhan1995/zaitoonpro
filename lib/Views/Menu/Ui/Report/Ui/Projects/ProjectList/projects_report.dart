import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/ProjectsById/projects_by_id.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Projects/ProjectList/bloc/projects_report_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Projects/ProjectList/model/projects_report_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Transport/Shipments/features/status_drop.dart';
import '../../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../Stakeholders/Ui/Individuals/model/individual_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectsReportView extends StatelessWidget {
  const ProjectsReportView({super.key});
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Mobile(),
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
  String fromDate = DateTime.now()
      .subtract(const Duration(days: 7))
      .toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  final customerController = TextEditingController();
  int? customerId;
  int? status;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsReportBloc>().add(ResetProjectReportEvent());
    });
    super.initState();
  }

  void _clearFilters() {
    setState(() {
      fromDate = DateTime.now()
          .subtract(const Duration(days: 7))
          .toFormattedDate();
      toDate = DateTime.now().toFormattedDate();
      customerController.clear();
      customerId = null;
      status = null;
    });
    context.read<ProjectsReportBloc>().add(ResetProjectReportEvent());
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text("Projects Report"),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: BlocBuilder<ProjectsReportBloc, ProjectsReportState>(
              builder: (context, state) {
                if (state is ProjectsReportLoadedState) {
                  final totalAmount = state.prj.fold<double>(
                      0, (sum, item) => sum + (item.totalAmount.toDoubleAmount()));
                  final totalPayments = state.prj.fold<double>(
                      0, (sum, item) => sum + (item.totalPayments.toDoubleAmount()));

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            context,
                            tr.totalProjects,
                            state.prj.length.toString(),
                            Icons.folder,
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: color.outline.withValues(alpha: .3),
                          ),
                          _buildSummaryItem(
                            context,
                            tr.totalAmount,
                            totalAmount.toAmount(),
                            Icons.attach_money,
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: color.outline.withValues(alpha: .3),
                          ),
                          _buildSummaryItem(
                            context,
                            tr.totalPayment,
                            totalPayments.toAmount(),
                            Icons.payment,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),

          // Results List
          Expanded(
            child: BlocBuilder<ProjectsReportBloc, ProjectsReportState>(
              builder: (context, state) {
                if (state is ProjectsReportInitial) {
                  return NoDataWidget(
                    title: "Projects Report",
                    message: tr.applyFilter,
                    enableAction: false,
                  );
                }
                if (state is ProjectsReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProjectsReportErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    enableAction: false,
                  );
                }
                if (state is ProjectsReportLoadedState) {
                  if (state.prj.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.prj.length,
                    itemBuilder: (context, index) {
                      final pjr = state.prj[index];
                      return _buildMobileProjectCard(context, pjr, index);
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

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon) {
    final color = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: color.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMobileProjectCard(BuildContext context, ProjectsReportModel pjr, int index) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Utils.goto(context, ProjectsByIdView(projectId: pjr.prjId!));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${pjr.prjId}",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  _buildStatusChip(pjr.prjStatus),
                ],
              ),
              const SizedBox(height: 8),

              // Project Name
              Text(
                pjr.prjName?.toString() ?? "",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Location
              if (pjr.prjLocation != null)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: color.outline),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pjr.prjLocation.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Customer and Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.customer,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          pjr.customerName ?? "",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.deadline,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          pjr.prjDateLine?.daysLeftText ?? "",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Amount and Payments
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.totalProjects,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            "${pjr.totalAmount?.toAmount()} ${pjr.actCurrency}",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.totalPayment,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            "${pjr.totalPayments?.toAmount()} ${pjr.actCurrency}",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status ?? "",
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    final statusLower = status.toLowerCase();
    if (statusLower.contains('active') || statusLower.contains('progress')) {
      return Colors.green;
    } else if (statusLower.contains('complete')) {
      return Colors.blue;
    } else if (statusLower.contains('hold') || statusLower.contains('pause')) {
      return Colors.orange;
    } else if (statusLower.contains('cancel')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  void _showFilterSheet(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    // Create local state for the sheet
    String localFromDate = fromDate;
    String localToDate = toDate;
    int? localCustomerId = customerId;
    int? localStatus = status;
    final localCustomerController = TextEditingController(text: customerController.text);

    ZDraggableSheet.show(
      context: context,
      title: "Filter Project",
      showCloseButton: true,
      showDragHandle: true,
      adaptiveInitialSize: true,
      estimatedContentHeight: 360,
      bodyBuilder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Field
              GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                showAllOnFocus: true,
                controller: localCustomerController,
                title: tr.individuals,
                hintText: tr.userOwner,
                bloc: context.read<IndividualsBloc>(),
                fetchAllFunction: (bloc) =>
                    bloc.add(LoadIndividualsEvent()),
                searchFunction: (bloc, query) =>
                    bloc.add(SearchIndividualsEvent(query)),
                itemBuilder: (context, account) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${account.perName} ${account.perLastName}",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                itemToString: (ind) =>
                "${ind.perName} ${ind.perLastName}",
                stateToLoading: (state) =>
                state is IndividualLoadingState,
                loadingBuilder: (context) => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                stateToItems: (state) {
                  if (state is IndividualLoadedState) {
                    return state.individuals;
                  }
                  return [];
                },
                onSelected: (value) {
                  localCustomerId = value.perId!;
                },
                noResultsText: tr.noDataFound,
                showClearButton: true,
              ),
              const SizedBox(height: 16),

              // Date Range
              Row(
                children: [
                  Expanded(
                    child: ZDatePicker(
                      label: tr.fromDate,
                      value: localFromDate,
                      onDateChanged: (v) {
                        localFromDate = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZDatePicker(
                      label: tr.toDate,
                      value: localToDate,
                      onDateChanged: (v) {
                        localToDate = v;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              StatusDropdown(
                value: localStatus,
                onChanged: (e) {
                  localStatus = e;
                },
              ),
              const SizedBox(height: 15),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ZOutlineButton(
                      onPressed: () {
                        localFromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
                        localToDate = DateTime.now().toFormattedDate();
                        localCustomerController.clear();
                        localCustomerId = null;
                        localStatus = null;
                        (context as Element).markNeedsBuild();
                      },
                      backgroundHover: Theme.of(context).colorScheme.error,
                      icon: Icons.filter_alt_off_outlined,
                      label: Text(tr.clear),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZOutlineButton(
                      onPressed: () {
                        // Apply filters and close sheet
                        setState(() {
                          fromDate = localFromDate;
                          toDate = localToDate;
                          customerId = localCustomerId;
                          status = localStatus;
                          customerController.text = localCustomerController.text;
                        });
                        Navigator.pop(context);
                        context.read<ProjectsReportBloc>().add(
                          LoadProjectReportEvent(
                            fromDate: fromDate,
                            toDate: toDate,
                            customerId: customerId,
                            status: status,
                          ),
                        );
                      },
                      isActive: true,
                      label: Text(tr.applyFilter),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
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
  String fromDate = DateTime.now()
      .subtract(const Duration(days: 7))
      .toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  final customerController = TextEditingController();
  int? customerId;
  int? status;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      context.read<ProjectsReportBloc>().add(ResetProjectReportEvent());
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color.surface
    );
    TextStyle? subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color.outline.withValues(alpha: .8)
    );
    return Scaffold(
      appBar: AppBar(title: Text("Projects Report")),
      body: Column(
        children: [
          //Header
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child:
                      GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                        showAllOnFocus: true,
                        controller: customerController,
                        title: tr.individuals,
                        hintText: tr.userOwner,
                        bloc: context.read<IndividualsBloc>(),
                        fetchAllFunction: (bloc) =>
                            bloc.add(LoadIndividualsEvent()),
                        searchFunction: (bloc, query) =>
                            bloc.add(SearchIndividualsEvent(query)),
                        itemBuilder: (context, account) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${account.perName} ${account.perLastName}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        itemToString: (ind) =>
                            "${ind.perName} ${ind.perLastName}",
                        stateToLoading: (state) =>
                            state is IndividualLoadingState,
                        loadingBuilder: (context) => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        stateToItems: (state) {
                          if (state is IndividualLoadedState) {
                            return state.individuals;
                          }
                          return [];
                        },
                        onSelected: (value) {
                          setState(() {
                            customerId = value.perId!;
                          });
                        },
                        noResultsText: tr.noDataFound,
                        showClearButton: true,
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
                    child: StatusDropdown(
                    value: status,
                    onChanged: (e) {
                  setState(() {
                     status = e;
                  });
                })),
                const SizedBox(width: 8),
                ZOutlineButton(
                  icon: FontAwesomeIcons.solidFilePdf,
                  height: 47,
                  onPressed: () {},
                  label: Text("PDF"),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  icon: Icons.filter_alt_outlined,
                  height: 47,
                  isActive: true,
                  onPressed: () {
                    context.read<ProjectsReportBloc>().add(LoadProjectReportEvent(
                      fromDate: fromDate,
                      toDate: toDate,
                      customerId: customerId,
                      status: status
                    ));
                  },
                  label: Text(tr.applyFilter),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10.0),
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
            ),
            child: Row(
              children: [

                SizedBox(
                    width: 40,
                    child: Text(tr.id,style: titleStyle)),

                Expanded(
                    child: Text(tr.projectName,style: titleStyle)),

                SizedBox(
                    width: 180,
                    child: Text(tr.customer,style: titleStyle)),

                SizedBox(
                    width: 150,
                    child: Text(tr.totalProjects,style: titleStyle)),

                SizedBox(
                    width: 150,
                    child: Text(tr.totalPayment,style: titleStyle)),

                SizedBox(
                    width: 150,
                    child: Text(tr.deadline,style: titleStyle)),

                SizedBox(
                    width: 80,
                    child: Text(tr.status,style: titleStyle)),
              ],
            ),
          ),

          Expanded(
            child: BlocBuilder<ProjectsReportBloc, ProjectsReportState>(
              builder: (context, state) {
                if(state is ProjectsReportInitial){
                  return NoDataWidget(
                    title: "Projects Report",
                    message: "Apply filter to show project report",
                    enableAction: false,
                  );
                }
                if(state is ProjectsReportLoadingState){
                  return Center(child: CircularProgressIndicator());
                }if(state is ProjectsReportErrorState){
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    enableAction: false,
                  );
                }if(state is ProjectsReportLoadedState){
                  if(state.prj.isEmpty){
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      enableAction: false,
                    );
                  }
                  return ListView.builder(
                      itemCount: state.prj.length,
                      itemBuilder: (context,index){
                     final pjr = state.prj[index];
                     return InkWell(
                       onTap: (){
                         Utils.goto(context, ProjectsByIdView(projectId: pjr.prjId!));
                       },
                       child: Container(
                         padding: EdgeInsets.symmetric(horizontal: 20,vertical: 8),
                         decoration: BoxDecoration(
                           color: index.isOdd? Theme.of(context).colorScheme.primary.withValues(alpha: .05) : Colors.transparent
                         ),
                         child: Row(
                           children: [
                             SizedBox(
                                 width: 40,
                                 child: Text(pjr.prjId.toString())),
                             Expanded(
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.start,
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(pjr.prjName.toString(),style: titleStyle?.copyWith(color: color.onSurface),),
                                   Text(pjr.prjLocation.toString(),style: subtitleStyle),
                                 ],
                               ),
                             ),
                             SizedBox(
                                 width: 180,
                                 child: Text(pjr.customerName??"")),

                             SizedBox(
                                 width: 150,
                                 child: Text("${pjr.totalAmount.toAmount()} ${pjr.actCurrency}")),

                             SizedBox(
                                 width: 150,
                                 child: Text("${pjr.totalPayments.toAmount()} ${pjr.actCurrency}")),

                             SizedBox(
                                 width: 150,
                                 child: Text(pjr.prjDateLine?.daysLeftText??"")),
                             SizedBox(
                                 width: 80,
                                 child: Text(pjr.prjStatus.toString())),
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
    );
  }
}
