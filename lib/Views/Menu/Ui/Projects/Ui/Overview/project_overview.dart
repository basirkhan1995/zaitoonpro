import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/section_title.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../Features/Other/utils.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';
import '../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../../../Stakeholders/Ui/Individuals/Ui/add_edit.dart';
import '../../../Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../AllProjects/bloc/projects_bloc.dart';
import '../AllProjects/model/pjr_model.dart';


class ProjectOverview extends StatelessWidget {
  final ProjectsModel? model;
  const ProjectOverview({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(model),
      tablet: _Tablet(model),
      desktop: _Desktop(model),
    );
  }
}

class _Mobile extends StatelessWidget {
  final ProjectsModel? model;
  const _Mobile(this.model);

  @override
  Widget build(BuildContext context) {
    return _MobileContent(model);
  }
}
class _MobileContent extends StatefulWidget {
  final ProjectsModel? model;
  const _MobileContent(this.model);

  @override
  State<_MobileContent> createState() => _MobileContentState();
}
class _MobileContentState extends State<_MobileContent> {
  final projectName = TextEditingController();
  final projectDetails = TextEditingController();
  final projectOwner = TextEditingController();
  final ownerAccount = TextEditingController();
  final projectLocation = TextEditingController();
  int? accNumber;
  int? ownerId;
  int? status;
  String deadline = DateTime.now().toFormattedDate();
  LoginData? loginData;
  final formKey = GlobalKey<FormState>();
  bool isPending = false;

  @override
  void initState() {
    super.initState();
    // Get the model from widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = (context as dynamic).widget.model;
      if (model != null) {
        _loadProjectData(model);
      }
    });
  }

  void _loadProjectData(ProjectsModel model) {
    setState(() {
      projectName.text = model.prjName ?? "";
      projectDetails.text = model.prjDetails ?? "";
      projectLocation.text = model.prjLocation ?? "";
      projectOwner.text = model.prjOwnerfullName ?? "";
      accNumber = model.prjOwnerAccount;
      ownerAccount.text = model.prjOwnerAccount?.toString() ?? "";
      ownerId = model.prjOwner;
      deadline = model.prjDateLine.toFormattedDate();
      status = model.prjStatus ?? 0;
      isPending = model.prjStatus == 0;
    });
  }

  @override
  void dispose() {
    projectName.dispose();
    projectDetails.dispose();
    projectOwner.dispose();
    ownerAccount.dispose();
    projectLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final prjState = context.watch<ProjectsBloc>().state;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = authState.loginData;

    return Scaffold(
      body: Form(
        key: formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Information Section
                    SectionTitle(title: tr.projectInformation),
                    const SizedBox(height: 12),

                    ZTextFieldEntitled(
                      isEnabled: isPending,
                      controller: projectName,
                      isRequired: true,
                      title: tr.projectName,
                      validator: (e) {
                        if (e.isEmpty) {
                          return tr.required(tr.projectName);
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    ZTextFieldEntitled(
                      isEnabled: isPending,
                      isRequired: true,
                      controller: projectDetails,
                      keyboardInputType: TextInputType.multiline,
                      title: tr.details,
                      validator: (e) {
                        if (e.isEmpty) {
                          return tr.required(tr.details);
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    ZTextFieldEntitled(
                      isEnabled: isPending,
                      controller: projectLocation,
                      title: tr.location,
                    ),

                    const SizedBox(height: 16),

                    ZDatePicker(
                      disablePastDate: true,
                      isActive: !isPending,
                      label: tr.deadline,
                      value: deadline,
                      onDateChanged: (v) {
                        setState(() {
                          deadline = v;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Owner Information Section
                    SectionTitle(title: tr.ownerInformation),
                    const SizedBox(height: 12),

                    GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                      isEnabled: isPending,
                      controller: projectOwner,
                      title: tr.individuals,
                      hintText: tr.individuals,
                      trailing: IconButton(
                        onPressed: isPending
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IndividualAddEditView(),
                            ),
                          );
                        }
                            : null,
                        icon: Icon(Icons.add, color: isPending ? null : color.outline),
                      ),
                      isRequired: true,
                      bloc: context.read<IndividualsBloc>(),
                      fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                      searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent(search: query)),
                      validator: (value) {
                        if (value.isEmpty) {
                          return tr.required(tr.individuals);
                        }
                        return null;
                      },
                      itemBuilder: (context, individual) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        child: Text(
                          "${individual.perName} ${individual.perLastName}",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      itemToString: (ind) => "${ind.perName} ${ind.perLastName}",
                      stateToLoading: (state) => state is IndividualLoadingState,
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
                          ownerId = value.perId!;
                          ownerAccount.clear();
                          accNumber = null;
                          context.read<AccountsBloc>().add(
                            LoadAccountsEvent(ownerId: ownerId),
                          );
                        });
                      },
                      noResultsText: tr.noDataFound,
                      showClearButton: true,
                    ),

                    const SizedBox(height: 16),

                    // Account Information
                    SectionTitle(title: tr.ownerAccount),
                    const SizedBox(height: 12),

                    GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                      isEnabled: isPending,
                      controller: ownerAccount,
                      title: tr.accounts,
                      hintText: tr.accNameOrNumber,
                      isRequired: true,
                      bloc: context.read<AccountsBloc>(),
                      fetchAllFunction: (bloc) =>
                          bloc.add(LoadAccountsEvent(ownerId: ownerId)),
                      searchFunction: (bloc, query) =>
                          bloc.add(LoadAccountsEvent(ownerId: ownerId)),
                      validator: (value) {
                        if (value.isEmpty) {
                          return tr.required(tr.accounts);
                        }
                        return null;
                      },
                      itemBuilder: (context, account) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${account.accNumber} | ${account.accName}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Utils.currencyColors(
                                  account.actCurrency ?? "",
                                ).withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                account.actCurrency ?? "",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Utils.currencyColors(
                                    account.actCurrency ?? "",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                      stateToLoading: (state) => state is AccountLoadingState,
                      loadingBuilder: (context) => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      stateToItems: (state) {
                        if (state is AccountLoadedState) {
                          return state.accounts;
                        }
                        return [];
                      },
                      onSelected: (value) {
                        setState(() {
                          accNumber = value.accNumber ?? 1;
                        });
                      },
                      noResultsText: tr.noDataFound,
                      showClearButton: true,
                    ),

                    const SizedBox(height: 16),

                    // Status Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.outline.withValues(alpha: .2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr.projectStatus,
                                style: textTheme.titleSmall,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: color.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    deadline,
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Switch(
                                value: status == 1,
                                onChanged: isPending
                                    ? (e) {
                                  setState(() {
                                    status = e ? 1 : 0;
                                  });
                                }
                                    : null,
                                activeTrackColor: Colors.green,
                                activeThumbColor: color.surface,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  status == 0 ? tr.inProgress : tr.completed,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: status == 1 ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.primary.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Read Only',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: color.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ZOutlineButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      label: Text(tr.cancel.toUpperCase()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZOutlineButton(
                      isActive: true,
                      onPressed: isPending ? onSubmit : null,
                      label: prjState is ProjectsLoadingState
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(isPending ? tr.update.toUpperCase() : tr.details.toUpperCase()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
    if (loginData == null) return;

    final bloc = context.read<ProjectsBloc>();
    final model = (context as dynamic).widget.model;

    final data = ProjectsModel(
      prjId: model?.prjId,
      usrName: loginData?.usrName,
      prjName: projectName.text,
      prjDetails: projectDetails.text,
      prjLocation: projectLocation.text,
      prjDateLine: DateTime.tryParse(deadline),
      prjOwner: ownerId,
      prjOwnerAccount: accNumber,
      prjStatus: status,
    );

    if (model == null) {
      bloc.add(AddProjectEvent(data));
    } else {
      bloc.add(UpdateProjectEvent(data));
    }

    // Close after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }
}

class _Tablet extends StatelessWidget {
  final ProjectsModel? model;
  const _Tablet(this.model);

  @override
  Widget build(BuildContext context) {
    return  _TabletContent(model);
  }
}
class _TabletContent extends StatefulWidget {
  final ProjectsModel? model;
  const _TabletContent(this.model);

  @override
  State<_TabletContent> createState() => _TabletContentState();
}
class _TabletContentState extends State<_TabletContent> {
  final projectName = TextEditingController();
  final projectDetails = TextEditingController();
  final projectOwner = TextEditingController();
  final ownerAccount = TextEditingController();
  final projectLocation = TextEditingController();
  int? accNumber;
  int? ownerId;
  int? status;
  String deadline = DateTime.now().toFormattedDate();
  LoginData? loginData;
  final formKey = GlobalKey<FormState>();
  bool isPending = false;

  @override
  void initState() {
    super.initState();
    // Get the model from widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = (context as dynamic).widget.model;
      if (model != null) {
        _loadProjectData(model);
      }
    });
  }

  void _loadProjectData(ProjectsModel model) {
    setState(() {
      projectName.text = model.prjName ?? "";
      projectDetails.text = model.prjDetails ?? "";
      projectLocation.text = model.prjLocation ?? "";
      projectOwner.text = model.prjOwnerfullName ?? "";
      accNumber = model.prjOwnerAccount;
      ownerAccount.text = model.prjOwnerAccount?.toString() ?? "";
      ownerId = model.prjOwner;
      deadline = model.prjDateLine.toFormattedDate();
      status = model.prjStatus ?? 0;
      isPending = model.prjStatus == 0;
    });
  }

  @override
  void dispose() {
    projectName.dispose();
    projectDetails.dispose();
    projectOwner.dispose();
    ownerAccount.dispose();
    projectLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final prjState = context.watch<ProjectsBloc>().state;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = authState.loginData;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(4),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Information Section
                    SectionTitle(title: tr.projectInformation),
                    const SizedBox(height: 16),

                    // Two column layout for tablet
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            isEnabled: isPending,
                            controller: projectName,
                            isRequired: true,
                            title: tr.projectName,
                            validator: (e) {
                              if (e.isEmpty) {
                                return tr.required(tr.projectName);
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ZDatePicker(
                            disablePastDate: true,
                            isActive: !isPending,
                            label: tr.deadline,
                            value: deadline,
                            onDateChanged: (v) {
                              setState(() {
                                deadline = v;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Details field (full width)
                    ZTextFieldEntitled(
                      isEnabled: isPending,
                      isRequired: true,
                      controller: projectDetails,
                      keyboardInputType: TextInputType.multiline,
                      title: tr.details,
                      validator: (e) {
                        if (e.isEmpty) {
                          return tr.required(tr.details);
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Location (full width)
                    ZTextFieldEntitled(
                      isEnabled: isPending,
                      controller: projectLocation,
                      title: tr.location,
                    ),

                    const SizedBox(height: 24),

                    // Owner Information Section
                    SectionTitle(title: tr.ownerInformation),
                    const SizedBox(height: 16),

                    // Owner field
                    GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                      isEnabled: isPending,
                      controller: projectOwner,
                      title: tr.individuals,
                      hintText: tr.individuals,
                      trailing: IconButton(
                        onPressed: isPending
                            ? () {
                          showDialog(
                            context: context,
                            builder: (context) => IndividualAddEditView(),
                          );
                        }
                            : null,
                        icon: Icon(Icons.add, color: isPending ? null : color.outline),
                      ),
                      isRequired: true,
                      bloc: context.read<IndividualsBloc>(),
                      fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                      searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent(search: query)),
                      validator: (value) {
                        if (value.isEmpty) {
                          return tr.required(tr.individuals);
                        }
                        return null;
                      },
                      itemBuilder: (context, individual) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        child: Text(
                          "${individual.perName} ${individual.perLastName}",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      itemToString: (ind) => "${ind.perName} ${ind.perLastName}",
                      stateToLoading: (state) => state is IndividualLoadingState,
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
                          ownerId = value.perId!;
                          ownerAccount.clear();
                          accNumber = null;
                          context.read<AccountsBloc>().add(
                            LoadAccountsEvent(ownerId: ownerId),
                          );
                        });
                      },
                      noResultsText: tr.noDataFound,
                      showClearButton: true,
                    ),

                    const SizedBox(height: 16),

                    // Account Information
                    SectionTitle(title: tr.ownerAccount),
                    const SizedBox(height: 12),

                    GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                      isEnabled: isPending,
                      controller: ownerAccount,
                      title: tr.accounts,
                      hintText: tr.accNameOrNumber,
                      isRequired: true,
                      bloc: context.read<AccountsBloc>(),
                      fetchAllFunction: (bloc) =>
                          bloc.add(LoadAccountsEvent(ownerId: ownerId)),
                      searchFunction: (bloc, query) =>
                          bloc.add(LoadAccountsEvent(ownerId: ownerId)),
                      validator: (value) {
                        if (value.isEmpty) {
                          return tr.required(tr.accounts);
                        }
                        return null;
                      },
                      itemBuilder: (context, account) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${account.accNumber} | ${account.accName}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Utils.currencyColors(
                                  account.actCurrency ?? "",
                                ).withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                account.actCurrency ?? "",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Utils.currencyColors(
                                    account.actCurrency ?? "",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                      stateToLoading: (state) => state is AccountLoadingState,
                      loadingBuilder: (context) => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      stateToItems: (state) {
                        if (state is AccountLoadedState) {
                          return state.accounts;
                        }
                        return [];
                      },
                      onSelected: (value) {
                        setState(() {
                          accNumber = value.accNumber ?? 1;
                        });
                      },
                      noResultsText: tr.noDataFound,
                      showClearButton: true,
                    ),

                    const SizedBox(height: 16),

                    // Status Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.outline.withValues(alpha: .2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr.projectStatus,
                                  style: textTheme.titleMedium,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: color.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Deadline: $deadline',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Switch(
                                value: status == 1,
                                onChanged: isPending
                                    ? (e) {
                                  setState(() {
                                    status = e ? 1 : 0;
                                  });
                                }
                                    : null,
                                activeTrackColor: Colors.green,
                                activeThumbColor: color.surface,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  status == 0 ? tr.inProgress : tr.completed,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: status == 1 ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.outline.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'View Only',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color.outline,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ZOutlineButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          label: Text(tr.cancel.toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        ZOutlineButton(
                          isActive: true,
                          onPressed: isPending ? onSubmit : () => Navigator.pop(context),
                          label: prjState is ProjectsLoadingState
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(isPending ? tr.update.toUpperCase() : tr.cancel.toUpperCase()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
    if (loginData == null) return;

    final bloc = context.read<ProjectsBloc>();
    final model = (context as dynamic).widget.model;

    final data = ProjectsModel(
      prjId: model?.prjId,
      usrName: loginData?.usrName,
      prjName: projectName.text,
      prjDetails: projectDetails.text,
      prjLocation: projectLocation.text,
      prjDateLine: DateTime.tryParse(deadline),
      prjOwner: ownerId,
      prjOwnerAccount: accNumber,
      prjStatus: status,
    );

    if (model == null) {
      bloc.add(AddProjectEvent(data));
    } else {
      bloc.add(UpdateProjectEvent(data));
    }

    // Close after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }
}

class _Desktop extends StatefulWidget {
  final ProjectsModel? model;
  const _Desktop(this.model);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final projectName = TextEditingController();
  final projectDetails = TextEditingController();
  final projectOwner = TextEditingController();
  final ownerAccount = TextEditingController();
  final projectLocation = TextEditingController();
  int? accNumber;
  int? ownerId;
  int? status;
  String deadline = DateTime.now().toFormattedDate();
  LoginData? loginData;
  final formKey = GlobalKey<FormState>();

  bool isPending = false;
  @override
  void initState() {
    final model = (context as dynamic).widget.model;
    if(model !=null){
      projectName.text = widget.model?.prjName ?? "";
      projectDetails.text = widget.model?.prjDetails ?? "";
      projectLocation.text = widget.model?.prjLocation ?? "";
      projectOwner.text = widget.model?.prjOwnerfullName ??"";
      accNumber = widget.model?.prjOwnerAccount;
      ownerAccount.text = widget.model?.prjOwnerAccount.toString() ?? "";
      ownerId = widget.model?.prjOwner;
      deadline = widget.model?.prjDateLine.toFormattedDate()??"";
      status = widget.model?.prjStatus ?? 0;
      isPending = widget.model?.prjStatus == 0;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final prjState = context.watch<ProjectsBloc>().state;
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = state.loginData;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SectionTitle(title: tr.projectInformation),
                      SizedBox(height: 5),
                      ZTextFieldEntitled(
                        isEnabled: isPending,
                        controller: projectName,
                        isRequired: true,
                        title: tr.projectName,
                        validator: (e) {
                          if (e.isEmpty) {
                            return tr.required(tr.projectName);
                          }
                          return null;
                        },
                      ),
                  
                      SizedBox(height: 8),
                      ZTextFieldEntitled(
                        isEnabled: isPending,
                        isRequired: true,
                        controller: projectDetails,
                        keyboardInputType: TextInputType.multiline,
                        title: tr.details,
                        validator: (e) {
                          if (e.isEmpty) {
                            return tr.required(tr.details);
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ZTextFieldEntitled(
                              isEnabled: isPending,
                              controller: projectLocation,
                              title: tr.location,
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: ZDatePicker(
                              initialDate: DateTime.tryParse(deadline),
                              isActive: !isPending,
                              label: tr.deadline,
                              value: deadline,
                              onDateChanged: (v) {
                                setState(() {
                                  deadline = v;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      SectionTitle(title: tr.ownerInformation),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                        child:
                        GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                          isEnabled: isPending,
                          controller: projectOwner,
                          title: tr.individuals,
                          hintText: tr.individuals,
                          trailing: IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return IndividualAddEditView();
                                },
                              );
                            },
                            icon: Icon(Icons.add),
                          ),
                          isRequired: true,
                          bloc: context.read<IndividualsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                          searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent(search: query)),
                          validator: (value) {
                            if (value.isEmpty) {
                              return tr.required(tr.individuals);
                            }
                            return null;
                          },
                          itemBuilder: (context, account) => Padding(
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
                                        "${account.perName} ${account.perLastName}",
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          itemToString: (acc) => "${acc.perName} ${acc.perLastName}",
                          stateToLoading: (state) => state is IndividualLoadingState,
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
                              ownerId = value.perId!;
                              ownerAccount.clear();
                              accNumber = null;
                              context.read<AccountsBloc>().add(
                                LoadAccountsEvent(ownerId: ownerId),
                              );
                            });
                          },
                          noResultsText: tr.noDataFound,
                          showClearButton: true,
                        ),
                      ),
                      SizedBox(height: 8),
                  
                      // Account Information Card
                      SectionTitle(title: tr.ownerAccount),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                        child:
                        GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                          isEnabled: isPending,
                          controller: ownerAccount,
                          title: tr.accounts,
                          hintText: tr.accNameOrNumber,
                          isRequired: true,
                          bloc: context.read<AccountsBloc>(),
                          fetchAllFunction: (bloc) =>
                              bloc.add(LoadAccountsEvent(ownerId: ownerId)),
                          searchFunction: (bloc, query) =>
                              bloc.add(LoadAccountsEvent(ownerId: ownerId)),
                          validator: (value) {
                            if (value.isEmpty) {
                              return tr.required(tr.accounts);
                            }
                            return null;
                          },
                          itemBuilder: (context, account) => Padding(
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
                                        "${account.accNumber} | ${account.accName}",
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Utils.currencyColors(
                                          account.actCurrency ?? "",
                                        ).withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${account.actCurrency}",
                                        style: Theme.of(context).textTheme.titleSmall
                                            ?.copyWith(
                                          color: Utils.currencyColors(
                                            account.actCurrency ?? "",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                          stateToLoading: (state) => state is AccountLoadingState,
                          loadingBuilder: (context) => const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          stateToItems: (state) {
                            if (state is AccountLoadedState) {
                              return state.accounts;
                            }
                            return [];
                          },
                          onSelected: (value) {
                            setState(() {
                              accNumber = value.accNumber ?? 1;
                            });
                          },
                          noResultsText: tr.noDataFound,
                          showClearButton: true,
                        ),
                      ),
                      const SizedBox(height: 5),
                  
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SectionTitle(title: tr.projectStatus),
                          Row(
                            children: [
                              SectionTitle(title: tr.deadline),
                              SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Text(
                                  widget.model?.prjDateLine?.daysLeftText ?? 'No deadline',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Switch(
                            value: status == 1,
                            onChanged: (e) {
                              setState(() {
                                status = e ? 1 : 0;
                              });
                            },
                            activeTrackColor: Colors.green,
                            activeThumbColor: Theme.of(context).colorScheme.surface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status == 0 ? tr.inProgress : tr.completed,
                            style: textTheme.bodyMedium?.copyWith(
                              color: status == 1 ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        ],
                      ),
                  
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ZOutlineButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                      label: Text(tr.cancel.toUpperCase())),
                  SizedBox(width: 5),
                  ZOutlineButton(
                      isActive: true,
                      onPressed: onSubmit,
                      label: prjState is ProjectsLoadingState? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator()) : Text(tr.update.toUpperCase())),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void onSubmit(){
    if (!formKey.currentState!.validate()) return;
    final bloc = context.read<ProjectsBloc>();

    final data = ProjectsModel(
      prjId: widget.model?.prjId,
      usrName: loginData?.usrName,
      prjName: projectName.text,
      prjDetails: projectDetails.text,
      prjLocation: projectLocation.text,
      prjDateLine: DateTime.tryParse(deadline),
      prjOwner: ownerId,
      prjOwnerAccount: accNumber,
      prjStatus: status
    );

    if(widget.model == null ){
      bloc.add(AddProjectEvent(data));
    }else{
      bloc.add(UpdateProjectEvent(data));
    }

  }
}
