import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/alert_dialog.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/ProjectServices/bloc/project_services_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/ProjectServices/model/project_services_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/Ui/add_edit_services.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/bloc/services_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Services/model/services_model.dart';

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
  int? editingPjdId;
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



class _Mobile extends StatefulWidget {
  final ProjectsModel? project;
  const _Mobile(this.project);

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final formKey = GlobalKey<FormState>();
  final servicesController = TextEditingController();
  final qty = TextEditingController(text: "1");
  final amount = TextEditingController();
  final remark = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? serviceId;
  int? editingPjdId;
  String? myLocale;
  LoginData? loginData;
  bool _isFormVisible = false;
  bool _isFabVisible = true;

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;

    // Add scroll listener to hide/show FAB
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) {
          setState(() {
            _isFabVisible = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) {
          setState(() {
            _isFabVisible = true;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.project != null) {
        context.read<ProjectServicesBloc>().add(LoadProjectServiceEvent(widget.project!.prjId!));
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    remark.dispose();
    servicesController.dispose();
    amount.dispose();
    qty.dispose();
    super.dispose();
  }

  void clearForm() {
    servicesController.clear();
    qty.text = "1";
    amount.clear();
    remark.clear();
    setState(() {
      serviceId = null;
      editingPjdId = null;
      _isFormVisible = false;
    });
  }

  void loadServiceForEditing(ProjectServicesModel service) {
    setState(() {
      servicesController.text = service.srvName ?? '';
      qty.text = service.pjdQuantity?.toString() ?? '1';
      amount.text = service.pjdPricePerQty?.toString() ?? '';
      remark.text = service.pjdRemark ?? '';
      serviceId = service.srvId;
      editingPjdId = service.pjdId;
      _isFormVisible = true;
    });
  }

  void showAddForm() {
    clearForm();
    setState(() {
      _isFormVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = state.loginData;

    return Scaffold(
      body: Column(
        children: [
          // Form Section (when visible)
          if (_isFormVisible)
            _buildFormSection(context),

          // Services List with Summary
          Expanded(
            child: BlocConsumer<ProjectServicesBloc, ProjectServicesState>(
              listener: (context, state) {
                if (state is ProjectServicesSuccessState) {
                  setState(() {
                    _isFormVisible = false;
                  });
                  clearForm();
                  ToastManager.show(context: context, message: tr.successMessage, type: ToastType.success);
                }
                if (state is ProjectServicesErrorState) {
                  ToastManager.show(context: context, message: state.message, type: ToastType.error);
                }
              },
              builder: (context, state) {
                if (state is ProjectServicesErrorState) {
                  return NoDataWidget(
                    title: tr.errorTitle,
                    message: state.message,
                    onRefresh: () {
                      if (widget.project != null) {
                        context.read<ProjectServicesBloc>().add(
                          LoadProjectServiceEvent(widget.project!.prjId!),
                        );
                      }
                    },
                  );
                }
                if (state is ProjectServicesLoadedState) {
                  if (state.projectServices.isEmpty) {
                    return NoDataWidget(
                      title: "No Services",
                      message: "Click + to add services",
                      enableAction: false,
                    );
                  }

                  // Calculate totals
                  double totalSum = 0;
                  for (var service in state.projectServices) {
                    totalSum += service.total ?? 0;
                  }

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Summary Header (Sticky)
                      SliverToBoxAdapter(
                        child: _buildTotalHeader(
                          context,
                          totalSum,
                          state.projectServices.length,
                          color,
                          tr,
                        ),
                      ),

                      // Services List
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final prjServices = state.projectServices[index];
                            return _buildMobileServiceCard(
                              context,
                              prjServices,
                              index,
                              color,
                              tr,
                            );
                          },
                          childCount: state.projectServices.length,
                        ),
                      ),

                      // Bottom Padding for FAB
                      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                    ],
                  );
                }
                if (state is ProjectServicesLoadingState && !_isFormVisible) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      // Floating Action Button
      floatingActionButton: widget.project?.prjStatus == 0 && !_isFormVisible && _isFabVisible
          ? FloatingActionButton(
        onPressed: showAddForm,
        child: const Icon(Icons.add),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFormSection(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return ZCover(
      padding: const EdgeInsets.all(12),
      color: color.surface,
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // Service Selection
            GenericTextfield<ServicesModel, ServicesBloc, ServicesState>(
              controller: servicesController,
              title: tr.services,
              hintText: tr.services,
              trailing: IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddEditServiceView(),
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
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                child: Text(
                  ser.srvName ?? "",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              itemToString: (ser) => ser.srvName ?? "",
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
            const SizedBox(height: 12),

            // Quantity and Amount Row
            Row(
              children: [
                Expanded(
                  child: ZTextFieldEntitled(
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr.required(tr.qty);
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter Valid Number";
                      }
                      return null;
                    },
                    controller: qty,
                    title: tr.qty,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZTextFieldEntitled(
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr.required(tr.amount);
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter Valid Amount";
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

            // Remark
            ZTextFieldEntitled(
                keyboardInputType: TextInputType.multiline,
                controller: remark,
                title: tr.remark
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    onPressed: () {
                      clearForm();
                    },
                    label: Text(tr.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZOutlineButton(
                    isActive: true,
                    backgroundHover: color.primary,
                    onPressed: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState)
                        ? null
                        : (editingPjdId != null ? onUpdateSubmit : onAddSubmit),
                    label: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState)
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(editingPjdId != null ? tr.update : tr.create),
                  ),
                ),
              ],
            ),
            if (editingPjdId != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ZOutlineButton(
                  isActive: true,
                  backgroundHover: color.error,
                  onPressed: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState)
                      ? null
                      : onDeleteSubmit,
                  label: Text(tr.delete),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileServiceCard(
      BuildContext context,
      ProjectServicesModel service,
      int index,
      ColorScheme color,
      AppLocalizations tr,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => (widget.project?.prjStatus == 0) ? loadServiceForEditing(service) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Name and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      service.srvName ?? "",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.project?.prjStatus == 0)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () => loadServiceForEditing(service),
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16, color: color.primary),
                              const SizedBox(width: 8),
                              Text(tr.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => showDeleteConfirmation(service),
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: color.error),
                              const SizedBox(width: 8),
                              Text(tr.delete),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Remark if exists
              if (service.pjdRemark?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(
                  service.pjdRemark!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.onSurface.withValues(alpha: .6),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Quantity, Amount, Total Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.qty,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          service.pjdQuantity?.toString() ?? '0',
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
                          tr.amount,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          "${(service.pjdPricePerQty ?? 0).toAmount()} ${widget.project?.actCurrency}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tr.totalTitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          "${(service.total ?? 0).toAmount()} ${widget.project?.actCurrency}",
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalHeader(
      BuildContext context,
      double totalSum,
      int itemCount,
      ColorScheme color,
      AppLocalizations tr,
      ) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.primaryContainer,
            color.primary.withValues(alpha: .1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.primary.withValues(alpha: .1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total Services
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.services,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.onPrimaryContainer.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.list_alt_rounded,
                    size: 16,
                    color: color.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$itemCount ${tr.items}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Divider
          Container(
            height: 40,
            width: 1,
            color: color.primary.withValues(alpha: .3),
          ),

          // Total Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tr.totalTitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.onPrimaryContainer.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: color.primary,
                  ),
                  Text(
                    "${totalSum.toAmount()} ${widget.project?.actCurrency ?? ''}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void onAddSubmit() async {
    if (!formKey.currentState!.validate()) return;
    if (serviceId == null) {
      ToastManager.show(
        context: context,
        message: "Select Service",
        type: ToastType.warning,
      );
      return;
    }

    final bloc = context.read<ProjectServicesBloc>();

    final data = ProjectServicesModel(
      prjId: widget.project!.prjId!,
      srvId: serviceId,
      pjdRemark: remark.text,
      pjdQuantity: double.tryParse(qty.text),
      pjdPricePerQty: double.tryParse(amount.text),
      usrName: loginData?.usrName,
    );

    bloc.add(AddProjectServiceEvent(data));
  }

  void onUpdateSubmit() async {
    if (!formKey.currentState!.validate()) return;
    if (serviceId == null) {
      ToastManager.show(
        context: context,
        message: "Select Service",
        type: ToastType.warning,
      );
      return;
    }

    final bloc = context.read<ProjectServicesBloc>();

    final data = ProjectServicesModel(
      pjdId: editingPjdId,
      prjId: widget.project!.prjId!,
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
      builder: (context) => ZAlertDialog(
        title: "Confirm Delete",
        content: "Delete this service?",
        onYes: () {
          final bloc = context.read<ProjectServicesBloc>();
          bloc.add(
            DeleteProjectServiceEvent(
              editingPjdId!,
              widget.project!.prjId!,
              loginData?.usrName ?? '',
            ),
          );
        },
      ),
    );
  }

  void showDeleteConfirmation(ProjectServicesModel service) {
    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: "Confirm Delete",
        content: '${AppLocalizations.of(context)!.delete} ${service.srvName}?',
        onYes: () {
          final bloc = context.read<ProjectServicesBloc>();
          bloc.add(
            DeleteProjectServiceEvent(
              service.pjdId!,
              widget.project!.prjId!,
              loginData?.usrName ?? '',
            ),
          );
        },
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  final ProjectsModel? project;
  const _Tablet(this.project);

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  final formKey = GlobalKey<FormState>();
  final servicesController = TextEditingController();
  final qty = TextEditingController(text: "1");
  final amount = TextEditingController();
  final remark = TextEditingController();
  int? serviceId;
  int? editingPjdId;
  String? myLocale;
  LoginData? loginData;
  bool _isFormVisible = false;

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.project != null) {
        context.read<ProjectServicesBloc>().add(LoadProjectServiceEvent(widget.project!.prjId!));
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    remark.dispose();
    servicesController.dispose();
    amount.dispose();
    qty.dispose();
    super.dispose();
  }

  void clearForm() {
    servicesController.clear();
    qty.text = "1";
    amount.clear();
    remark.clear();
    setState(() {
      serviceId = null;
      editingPjdId = null;
      _isFormVisible = false;
    });
  }

  void loadServiceForEditing(ProjectServicesModel service) {
    setState(() {
      servicesController.text = service.srvName ?? '';
      qty.text = service.pjdQuantity?.toString() ?? '1';
      amount.text = service.pjdPricePerQty?.toString() ?? '';
      remark.text = service.pjdRemark ?? '';
      serviceId = service.srvId;
      editingPjdId = service.pjdId;
      _isFormVisible = true;
    });
  }

  void showAddForm() {
    clearForm();
    setState(() {
      _isFormVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = state.loginData;

    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(),
        actions: [
          if (widget.project?.prjStatus == 0 && !_isFormVisible)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ZOutlineButton(
                onPressed: showAddForm,
                icon: Icons.add,
                label: Text(tr.addNewServices),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Form Section
            if (_isFormVisible)
              _buildFormSection(context),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(tr.projectServices, style: _getHeaderStyle(context)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(tr.qty, style: _getHeaderStyle(context)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      tr.amount,
                      textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                      style: _getHeaderStyle(context),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      tr.totalTitle,
                      textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                      style: _getHeaderStyle(context),
                    ),
                  ),
                  const SizedBox(width: 40), // For actions
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Services List
            Expanded(
              child: BlocConsumer<ProjectServicesBloc, ProjectServicesState>(
                listener: (context, state) {
                  if (state is ProjectServicesSuccessState) {
                    setState(() {
                      _isFormVisible = false;
                    });
                    clearForm();
                    ToastManager.show(context: context, message: tr.successMessage, type: ToastType.success);
                  }
                  if (state is ProjectServicesErrorState) {
                    ToastManager.show(context: context, message: state.message, type: ToastType.error);
                  }
                },
                builder: (context, state) {
                  if (state is ProjectServicesErrorState) {
                    return NoDataWidget(
                      title: tr.errorTitle,
                      message: state.message,
                      onRefresh: () {
                        if (widget.project != null) {
                          context.read<ProjectServicesBloc>().add(
                            LoadProjectServiceEvent(widget.project!.prjId!),
                          );
                        }
                      },
                    );
                  }
                  if (state is ProjectServicesLoadedState) {
                    if (state.projectServices.isEmpty) {
                      return NoDataWidget(
                        title: "No Services",
                        message: "Click Add Services",
                        enableAction: false,
                      );
                    }

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
                              return _buildTabletServiceTile(
                                context,
                                prjServices,
                                index,
                                color,
                                tr,
                              );
                            },
                          ),
                        ),
                        _buildTotalFooter(context, totalSum, state.projectServices.length, color, tr),
                      ],
                    );
                  }
                  if (state is ProjectServicesLoadingState && !_isFormVisible) {
                    return const Center(child: CircularProgressIndicator());
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

  TextStyle? _getHeaderStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.surface,
      fontWeight: FontWeight.bold,
    );
  }

  Widget _buildFormSection(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return ZCover(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: GenericTextfield<ServicesModel, ServicesBloc, ServicesState>(
                      controller: servicesController,
                      title: tr.services,
                      hintText: tr.services,
                      trailing: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddEditServiceView(),
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
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        child: Text(
                          ser.srvName ?? "",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      itemToString: (ser) => ser.srvName ?? "",
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZTextFieldEntitled(
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required(tr.qty);
                        }
                        if (double.tryParse(value) == null) {
                          return "enterValidNumber";
                        }
                        return null;
                      },
                      controller: qty,
                      title: tr.qty,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZTextFieldEntitled(
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required(tr.amount);
                        }
                        if (double.tryParse(value) == null) {
                          return "enterValidAmount";
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
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ZOutlineButton(
                            onPressed: clearForm,
                            label: Text(tr.cancel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ZOutlineButton(
                            isActive: true,
                            onPressed: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState)
                                ? null
                                : (editingPjdId != null ? onUpdateSubmit : onAddSubmit),
                              label: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState)
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text(editingPjdId != null ? tr.update : tr.create),
                          ),
                        ),

                        if (editingPjdId != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ZOutlineButton(
                              isActive: true,
                              backgroundHover: Theme.of(context).colorScheme.error,
                              onPressed: (context.watch<ProjectServicesBloc>().state is ProjectServicesLoadingState)
                                  ? null
                                  : onDeleteSubmit,
                              label: Text(tr.delete),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletServiceTile(
      BuildContext context,
      ProjectServicesModel service,
      int index,
      ColorScheme color,
      AppLocalizations tr,
      ) {
    return InkWell(
      onTap: () => (widget.project?.prjStatus == 0) ? loadServiceForEditing(service) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: index.isOdd ? color.primary.withValues(alpha: .05) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: color.outline.withValues(alpha: .2)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.srvName ?? "",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (service.pjdRemark?.isNotEmpty ?? false)
                    Text(
                      service.pjdRemark!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(service.pjdQuantity?.toString() ?? '0'),
            ),
            SizedBox(
              width: 120,
              child: Text(
                "${(service.pjdPricePerQty ?? 0).toAmount()} ${widget.project?.actCurrency}",
                textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                "${(service.total ?? 0).toAmount()} ${widget.project?.actCurrency}",
                textAlign: myLocale == "en" ? TextAlign.right : TextAlign.left,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: widget.project?.prjStatus == 0
                  ? PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 18),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => loadServiceForEditing(service),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: color.primary),
                        const SizedBox(width: 8),
                        Text(tr.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => showDeleteConfirmation(service),
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: color.error),
                        const SizedBox(width: 8),
                        Text(tr.delete),
                      ],
                    ),
                  ),
                ],
              )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalFooter(
      BuildContext context,
      double totalSum,
      int itemCount,
      ColorScheme color,
      AppLocalizations tr,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: 0.03),
        border: Border(
          top: BorderSide(color: color.primary.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                "${tr.services}: ",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                itemCount.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                "${tr.totalTitle}: ",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                "${totalSum.toAmount()} ${widget.project?.actCurrency}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void onAddSubmit() async {
    if (!formKey.currentState!.validate()) return;
    if (serviceId == null) {
      ToastManager.show(
        context: context,
        message: "selectService",
        type: ToastType.warning,
      );
      return;
    }

    final bloc = context.read<ProjectServicesBloc>();

    final data = ProjectServicesModel(
      prjId: widget.project!.prjId!,
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
      ToastManager.show(
        context: context,
        message: "Select Service",
        type: ToastType.warning,
      );
      return;
    }

    final bloc = context.read<ProjectServicesBloc>();

    final data = ProjectServicesModel(
      pjdId: editingPjdId,
      prjId: widget.project!.prjId!,
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
      builder: (context) => ZAlertDialog(
        title: "confirmDelete",
        content: "deleteServiceConfirmation",
        onYes: () {
          final bloc = context.read<ProjectServicesBloc>();
          bloc.add(
            DeleteProjectServiceEvent(
              editingPjdId!,
              widget.project!.prjId!,
              loginData?.usrName ?? '',
            ),
          );
        },
      ),
    );
  }

  void showDeleteConfirmation(ProjectServicesModel service) {
    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: "Confirm Delete",
        content: '${AppLocalizations.of(context)!.delete} ${service.srvName}?',
        onYes: () {
          final bloc = context.read<ProjectServicesBloc>();
          bloc.add(
            DeleteProjectServiceEvent(
              service.pjdId!,
              widget.project!.prjId!,
              loginData?.usrName ?? '',
            ),
          );
        },
      ),
    );
  }
}



