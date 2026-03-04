import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/zForm_dialog.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Features/Widgets/section_title.dart';
import 'package:zaitoon_petroleum/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
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
import 'bloc/projects_bloc.dart';
import 'model/pjr_model.dart';

class AddNewProjectView extends StatelessWidget {
  final ProjectsModel? model;
  const AddNewProjectView({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(model: model),
      tablet: _Tablet(model: model),
      desktop: _Desktop(model),
    );
  }
}

class _Mobile extends StatelessWidget {
  final ProjectsModel? model;

  const _Mobile({this.model});

  @override
  Widget build(BuildContext context) {
    return _MobileContent(model: model);
  }
}
class _MobileContent extends StatefulWidget {
  final ProjectsModel? model;

  const _MobileContent({this.model});

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
  String deadline = DateTime.now().toFormattedDate();
  LoginData? loginData;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use widget.model instead of ModalRoute
    if (widget.model != null) {
      _loadProjectData(widget.model!);
    }
  }

  void _loadProjectData(ProjectsModel model) {
    projectName.text = model.prjName ?? "";
    projectDetails.text = model.prjDetails ?? "";
    projectLocation.text = model.prjLocation ?? "";
    projectOwner.text = model.prjOwnerfullName ?? "";
    accNumber = model.prjOwnerAccount;
    ownerAccount.text = model.prjOwnerAccount?.toString() ?? "";
    ownerId = model.prjOwner;
    deadline = model.prjDateLine.toFormattedDate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final isEdit = widget.model != null; // Use widget.model instead of ModalRoute
    final prjState = context.watch<ProjectsBloc>().state;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      loginData = authState.loginData;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? tr.update : tr.newProject),
        actions: [
          if (prjState is ProjectsLoadingState)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Project Information Section
            SectionTitle(title: tr.projectInformation),
            const SizedBox(height: 12),

            ZTextFieldEntitled(
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
              controller: projectLocation,
              title: tr.location,
            ),

            const SizedBox(height: 16),

            ZDatePicker(
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

            GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
              showAllOnFocus: true,
              controller: projectOwner,
              title: tr.individuals,
              hintText: tr.individuals,
              trailing: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IndividualAddEditView(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${individual.perName} ${individual.perLastName}",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
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

            GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
              showAllOnFocus: true,
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

            const SizedBox(height: 32),

            // Submit Button
            ZOutlineButton(
              onPressed: prjState is ProjectsLoadingState ? null : onSubmit,
              isActive: true,
              label: prjState is ProjectsLoadingState
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(isEdit ? tr.update : tr.create),
            ),

            const SizedBox(height: 10),

            // Cancel Button
            ZOutlineButton(
              onPressed: () => Navigator.pop(context),
              label: Text(tr.cancel),
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
    final isEdit = widget.model != null;

    final data = ProjectsModel(
      prjId: isEdit ? widget.model!.prjId : null,
      usrName: loginData?.usrName,
      prjName: projectName.text,
      prjDetails: projectDetails.text,
      prjLocation: projectLocation.text,
      prjDateLine: DateTime.tryParse(deadline),
      prjOwner: ownerId,
      prjOwnerAccount: accNumber,
    );

    if (!isEdit) {
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
  final ProjectsModel? model; // Add this parameter

  const _Tablet({this.model}); // Add this

  @override
  Widget build(BuildContext context) {
    return _TabletContent(model: model); // Pass the model
  }
}

class _TabletContent extends StatefulWidget {
  final ProjectsModel? model; // Add this parameter

  const _TabletContent({this.model});

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
  String deadline = DateTime.now().toFormattedDate();
  LoginData? loginData;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Use widget.model instead of ModalRoute
    if (widget.model != null) {
      _loadProjectData(widget.model!);
    }
  }

  void _loadProjectData(ProjectsModel model) {
    projectName.text = model.prjName ?? "";
    projectDetails.text = model.prjDetails ?? "";
    projectLocation.text = model.prjLocation ?? "";
    projectOwner.text = model.prjOwnerfullName ?? "";
    accNumber = model.prjOwnerAccount;
    ownerAccount.text = model.prjOwnerAccount?.toString() ?? "";
    ownerId = model.prjOwner;
    deadline = model.prjDateLine.toFormattedDate();
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
    final isEdit = widget.model != null; // Use widget.model instead of ModalRoute
    final prjState = context.watch<ProjectsBloc>().state;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      loginData = authState.loginData;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? tr.update : tr.newProject),
        centerTitle: false,
        actions: [
          if (prjState is ProjectsLoadingState)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SectionTitle(title: tr.projectInformation),
                    const SizedBox(height: 16),

                    // Two column layout for tablet
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
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
                      controller: projectLocation,
                      title: tr.location,
                    ),

                    const SizedBox(height: 24),

                    // Owner Information Section
                    SectionTitle(title: tr.ownerInformation),
                    const SizedBox(height: 16),

                    // Owner field
                    GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                      showAllOnFocus: true,
                      controller: projectOwner,
                      title: tr.individuals,
                      hintText: tr.individuals,
                      trailing: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => IndividualAddEditView(),
                          );
                        },
                        icon: const Icon(Icons.add),
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

                    GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                      showAllOnFocus: true,
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

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ZOutlineButton(
                          onPressed: () => Navigator.pop(context),
                          label: Text(tr.cancel),
                        ),
                        const SizedBox(width: 16),
                        ZOutlineButton(
                          onPressed: prjState is ProjectsLoadingState ? null : onSubmit,
                          isActive: true,
                          label: prjState is ProjectsLoadingState
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(isEdit ? tr.update : tr.create),
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
    final isEdit = widget.model != null;

    final data = ProjectsModel(
      prjId: isEdit ? widget.model!.prjId : null,
      usrName: loginData?.usrName,
      prjName: projectName.text,
      prjDetails: projectDetails.text,
      prjLocation: projectLocation.text,
      prjDateLine: DateTime.tryParse(deadline),
      prjOwner: ownerId,
      prjOwnerAccount: accNumber,
    );

    if (!isEdit) {
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
  String deadline = DateTime.now().toFormattedDate();
  LoginData? loginData;
  final formKey = GlobalKey<FormState>();

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
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isEdit = (context as dynamic).widget.model != null;
    final prjState = context.watch<ProjectsBloc>().state;
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = state.loginData;

    return ZFormDialog(
      onAction: onSubmit,
      actionLabel: prjState is ProjectsLoadingState? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator()) : Text(isEdit? tr.update.toUpperCase() : tr.create),

      padding: EdgeInsets.all(12),
      title: isEdit? tr.update.toUpperCase() : tr.newProject,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionTitle(title: tr.projectInformation),
            SizedBox(height: 5),
            ZTextFieldEntitled(
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
                    controller: projectLocation,
                    title: tr.location,
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: ZDatePicker(
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
                  GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                    showAllOnFocus: true,
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
                  GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                    showAllOnFocus: true,
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
          ],
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
    );

    if(widget.model == null ){
      bloc.add(AddProjectEvent(data));
    }else{
      bloc.add(UpdateProjectEvent(data));
    }

  }
}
