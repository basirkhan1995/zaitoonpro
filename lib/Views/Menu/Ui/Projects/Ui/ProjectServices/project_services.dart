import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/alert_dialog.dart';
import 'package:zaitoon_petroleum/Features/Other/cover.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/toast.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoon_petroleum/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/Ui/ProjectServices/bloc/project_services_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Projects/Ui/ProjectServices/model/project_services_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Services/Ui/add_edit_services.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Services/bloc/services_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Services/model/services_model.dart';

import '../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';

class ProjectServicesView extends StatelessWidget {
  final ProjectsModel? project;
  const ProjectServicesView({super.key, this.project});
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(project),
      tablet: _Tablet(project),
      desktop: _Desktop(project),
    );
  }
}

class _Mobile extends StatelessWidget {
  final ProjectsModel? projectId;
  const _Mobile(this.projectId);
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Tablet extends StatelessWidget {
  final ProjectsModel? projectId;
  const _Tablet(this.projectId);
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Desktop extends StatefulWidget {
  final ProjectsModel? projectId;
  const _Desktop(this.projectId);

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  final formKey = GlobalKey<FormState>();
  final servicesController = TextEditingController();
  final qty = TextEditingController(text: "1");
  final amount = TextEditingController();
  final remark = TextEditingController();
  int? serviceId;
  int? editingPjdId; // Track if we're editing an existing service
  String? myLocale;

  // Add this to control form visibility
  bool _isFormVisible = false;

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.projectId != null) {
        context.read<ProjectServicesBloc>().add(LoadProjectServiceEvent(widget.projectId!.prjId!));
      }
    });
    super.initState();
  }

  LoginData? loginData;

  @override
  void dispose() {
    remark.dispose();
    servicesController.dispose();
    amount.dispose();
    qty.dispose();
    super.dispose();
  }

  // Method to clear the form
  void clearForm() {
    servicesController.clear();
    qty.text = "1";
    amount.clear();
    remark.clear();
    setState(() {
      serviceId = null;
      editingPjdId = null;
      _isFormVisible = false; // Hide form after clear
    });
  }

  // Method to load a project service into the form for editing
  void loadServiceForEditing(ProjectServicesModel service) {
    setState(() {
      servicesController.text = service.srvName ?? '';
      qty.text = service.pjdQuantity?.toString() ?? '1';
      amount.text = service.pjdPricePerQty?.toString() ?? '';
      remark.text = service.pjdRemark ?? '';
      serviceId = service.srvId;
      editingPjdId = service.pjdId;
      _isFormVisible = true; // Show form when editing
    });
  }

  // Method to show form for adding new service
  void showAddForm() {
    clearForm(); // Clear any existing data
    setState(() {
      _isFormVisible = true; // Show form for adding
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color.surface
    );
    TextStyle? subtitleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color.secondary.withValues(alpha: .8),
    );

    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = state.loginData;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Add button to show form
          if (!_isFormVisible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical:  3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(tr.projectServices.toUpperCase(),style: titleStyle?.copyWith(color: color.outline,fontSize: 18)),
                  if(widget.projectId?.prjStatus == 0)
                  ZOutlineButton(
                    onPressed: showAddForm,
                    icon: Icons.add,
                    label: Text(tr.addNewServices.toUpperCase()),
                  ),
                ],
              ),
            ),

          // Form section - only visible when _isFormVisible is true
          if (_isFormVisible)
            ZCover(
              padding: const EdgeInsets.all(8.0),
              color: color.surface,
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          flex: 3,
                          child: GenericTextfield<ServicesModel, ServicesBloc, ServicesState>(
                            controller: servicesController,
                            title: tr.services,
                            hintText: tr.services,
                            trailing: IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AddEditServiceView();
                                  },
                                );
                              },
                              icon: const Icon(Icons.add),
                            ),
                            isRequired: true,
                            bloc: context.read<ServicesBloc>(),
                            fetchAllFunction: (bloc) => bloc.add(LoadServicesEvent()),
                            searchFunction: (bloc, query) => bloc.add(LoadServicesEvent(search: query)),
                            validator: (value) {
                              if (value.isEmpty) {
                                return tr.required(tr.services);
                              }
                              return null;
                            },
                            itemBuilder: (context, ser) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${ser.srvName}",
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            itemToString: (ser) => "${ser.srvName}",
                            stateToLoading: (state) => state is ServicesLoadingState,
                            loadingBuilder: (context) => const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            stateToItems: (state) {
                              if (state is ServicesLoadedState) {
                                return state.services;
                              }
                              return [];
                            },
                            onSelected: (value) {
                              setState(() {
                                serviceId = value.srvId;
                              });
                            },
                            noResultsText: tr.noDataFound,
                            showClearButton: true,
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            isRequired: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr.required(tr.qty);
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                            controller: qty,
                            title: tr.qty,
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            isRequired: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr.required(tr.amount);
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                            controller: amount,
                            title: tr.amount,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ZTextFieldEntitled(
                      keyboardInputType: TextInputType.multiline,
                      controller: remark,
                      title: tr.remark,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ZOutlineButton(
                          onPressed: () {
                            clearForm();
                            setState(() {
                              _isFormVisible = false; // Hide form on cancel
                            });
                          },
                          label: Text(tr.cancel.toUpperCase()),
                        ),
                        const SizedBox(width: 8),
                        ZOutlineButton(
                          onPressed: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState) ? null : (editingPjdId != null ? onUpdateSubmit : onAddSubmit),
                          isActive: true,
                          label: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState)
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(
                            editingPjdId != null
                                ? tr.update.toUpperCase()
                                : tr.create.toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (editingPjdId != null)
                          ZOutlineButton(
                            onPressed: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState) ? null : onDeleteSubmit,
                            isActive: true,
                            backgroundHover: color.error,
                            label: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState)
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text(tr.delete.toUpperCase()),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Rest of your UI remains the same...
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 7),
            ),
            child: Row(
              children: [
                Expanded(child: Text(tr.projectServices, style: titleStyle)),
                SizedBox(
                  width: 50,
                  child: Text(tr.qty, style: titleStyle),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                    tr.amount,
                    style: titleStyle,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                    tr.totalTitle,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
          ),
          // Add this after your Expanded child in the Column
          Expanded(
            child: BlocConsumer<ProjectServicesBloc, ProjectServicesState>(
              listener: (context, state) {
                if (state is ProjectServicesSuccessState) {
                  // Reset loading state and hide form on success
                  setState(() {
                    _isFormVisible = false; // Hide form after successful operation
                  });
                  clearForm();
                  ToastManager.show(context: context, message: tr.successMessage, type: ToastType.success);
                }
                if (state is ProjectServicesErrorState) {
                  ToastManager.show(context: context, message: state.message, type: ToastType.error);
                }
              },
              builder: (context, state) {
                // Don't show full screen loading indicator anymore
                // since we have button-specific loading indicator
                if (state is ProjectServicesErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    onRefresh: () {
                      if (widget.projectId != null) {
                        context.read<ProjectServicesBloc>().add(
                          LoadProjectServiceEvent(widget.projectId!.prjId!),
                        );
                      }
                    },
                  );
                }
                if (state is ProjectServicesLoadedState) {
                  if (state.projectServices.isEmpty) {
                    return NoDataWidget(
                      title: "No Services",
                      message: "Click Add Services to add a new",
                      enableAction: false,
                    );
                  }

                  // Calculate total sum of all services
                  double totalSum = 0;
                  for (var service in state.projectServices) {
                    totalSum += service.total ?? 0;
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.projectServices.length,
                          itemBuilder: (context, index) {
                            final prjServices = state.projectServices[index];
                            return InkWell(
                              onTap: () => (widget.projectId?.prjStatus == 0)? loadServiceForEditing(prjServices) : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: index.isOdd
                                      ? color.primary.withValues(alpha: .05)
                                      : Colors.transparent,
                                  border: editingPjdId == prjServices.pjdId
                                      ? Border.all(color: color.primary, width: 1)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(prjServices.srvName ?? "", style: titleStyle?.copyWith(color: color.onSurface)),
                                          Text(prjServices.prpTrnRef ?? "", style: subtitleStyle),
                                          if (prjServices.pjdRemark != null)
                                            Text(prjServices.pjdRemark ?? "", style: subtitleStyle),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: Text(prjServices.pjdQuantity?.toString() ?? '0'),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        "${(prjServices.pjdPricePerQty ?? 0).toAmount()} ${widget.projectId?.actCurrency}",
                                        textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        "${(prjServices.total ?? 0).toAmount()} ${widget.projectId?.actCurrency}",
                                        textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Total Footer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.03),
                          border: Border(
                            top: BorderSide(color: color.primary.withValues(alpha: 0.5), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr.summary.toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color.primary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                "${tr.services.toUpperCase()} | ${state.projectServices.length.toString()}",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),

                            Column(
                              children: [
                                Text(
                                  "${tr.totalTitle.toUpperCase()} | ${totalSum.toAmount()} ${widget.projectId?.actCurrency}",
                                  textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                // Show loading only for initial load
                if (state is ProjectServicesLoadingState && !_isFormVisible) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox();
              },
            ),
          ),

        ],
      ),
    );
  }

  void onAddSubmit() async {
    if (!formKey.currentState!.validate()) return;
    if (serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bloc = context.read<ProjectServicesBloc>();

    final data = ProjectServicesModel(
      prjId: widget.projectId!.prjId!,
      srvId: serviceId,
      pjdQuantity: double.tryParse(qty.text),
      pjdPricePerQty: double.tryParse(amount.text),
      usrName: loginData?.usrName,
    );

    bloc.add(AddProjectServiceEvent(data));
  }

  void onUpdateSubmit() async {
    if (!formKey.currentState!.validate()) return;
    if (serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bloc = context.read<ProjectServicesBloc>();

    final data = ProjectServicesModel(
      pjdId: editingPjdId,
      prjId: widget.projectId!.prjId!,
      srvId: serviceId,
      pjdRemark: remark.text,
      srvName: servicesController.text,
      pjdQuantity: double.tryParse(qty.text),
      pjdPricePerQty: double.tryParse(amount.text),
      usrName: loginData?.usrName,
    );

    bloc.add(UpdateProjectServiceEvent(data));
  }

  void onDeleteSubmit() {
    if (editingPjdId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final bloc = context.read<ProjectServicesBloc>();
              bloc.add(
                DeleteProjectServiceEvent(
                  editingPjdId!,
                  widget.projectId!.prjId!,
                  loginData?.usrName ?? '',
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showDeleteConfirmation(ProjectServicesModel service) {
    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: 'Confirm Delete',
        content: 'Are you sure you want to delete ${service.srvName}?',
        onYes: (){
          final bloc = context.read<ProjectServicesBloc>();
          bloc.add(
            DeleteProjectServiceEvent(
              service.pjdId!,
              widget.projectId!.prjId!,
              loginData?.usrName ?? '',
            ),
          );
        },
      ),
    );
  }
}
