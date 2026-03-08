import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/desktop_form_nav.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Other/zform_dialog.dart';
import 'package:zaitoon_petroleum/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/HR/Ui/Users/bloc/users_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/HR/Ui/Users/model/user_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Company/Branches/model/branch_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../Settings/Ui/General/Ui/UserRole/features/role_drop.dart';
import '../features/branch_dropdown.dart';

class AddUserView extends StatelessWidget {
  final int? indId; // Optional parameter for individual-specific users

  const AddUserView({super.key, this.indId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(indId: indId),
      tablet: _Desktop(indId: indId),
      desktop: _Desktop(indId: indId),
    );
  }
}

// Mobile Bottom Sheet Version
class _Mobile extends StatefulWidget {
  final int? indId;

  const _Mobile({this.indId});

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final TextEditingController usrName = TextEditingController();
  final TextEditingController usrEmail = TextEditingController();
  final TextEditingController usrPas = TextEditingController();
  final TextEditingController passConfirm = TextEditingController();
  final TextEditingController usrOwner = TextEditingController();

  int? _selectedRole;
  bool isPasswordSecure = true;
  bool fcpValue = true;
  bool fevValue = true;
  int? usrOwnerId;
  BranchModel? selectedBranch;
  IndividualsModel? selectedIndividual;

  final formKey = GlobalKey<FormState>();
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize with widget.indId in initState
    if (widget.indId != null) {
      usrOwnerId = widget.indId!;
    }
  }

  // Safe method to get current user with fallback
  String? currentUser() {
    try {
      final companyState = context.read<AuthBloc>().state;
      if (companyState is AuthenticatedState) {
        return companyState.loginData.usrName;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  @override
  void dispose() {
    usrName.dispose();
    usrEmail.dispose();
    usrPas.dispose();
    passConfirm.dispose();
    usrOwner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final isLoading = context.watch<UsersBloc>().state is UsersLoadingState;

    return Scaffold(
      body: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.outline.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
      
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        color: color.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        locale.addUserTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
      
                // Form
                Expanded(
                  child: BlocListener<UsersBloc, UsersState>(
                    listener: (context, state) {
                      if (state is UsersErrorState) {
                        setState(() {
                          errorMessage = state.message;
                        });
                      }
                      if (state is UserSuccessState) {
                        Navigator.of(context).pop();
                        Utils.showOverlayMessage(
                          context,
                          message: locale.successMessage,
                          isError: false,
                        );
                      }
                    },
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Username and Role
                            ZTextFieldEntitled(
                              isRequired: true,
                              controller: usrName,
                              hint: "e.g zaitoon",
                              onSubmit: (_) => onSubmit(),
                              validator: (e) {
                                if (e.isEmpty) {
                                  return locale.required(locale.username);
                                }
                                if (e.isNotEmpty) {
                                  return Utils.validateUsername(
                                    value: e,
                                    context: context,
                                  );
                                }
                                return null;
                              },
                              title: locale.username,
                            ),
      
                            const SizedBox(height: 12),
      
                            UserRoleDropdown(
                              onRoleSelected: (e) {
                                setState(() {
                                  _selectedRole = e?.rolId;
                                });
                              },
                            ),
      
                            const SizedBox(height: 12),
      
                            // Individual/Owner Field (conditionally shown)
                            if (widget.indId == null) ...[
                              GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                                showAllOnFocus: true,
                                controller: usrOwner,
                                title: locale.individuals,
                                hintText: locale.userOwner,
                                isRequired: true,
                                bloc: context.read<IndividualsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                                searchFunction: (bloc, query) => bloc.add(SearchIndividualsEvent(query)),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return locale.required(locale.individuals);
                                  }
                                  return null;
                                },
                                itemBuilder: (context, account) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 5,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${account.perName} ${account.perLastName}",
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
                                    selectedIndividual = value;
                                    usrOwnerId = value.perId!;
                                  });
                                },
                                noResultsText: locale.noDataFound,
                                showClearButton: true,
                              ),
      
                              const SizedBox(height: 12),
                            ],
      
                            // Branch Dropdown
                            BranchDropdown(
                              title: locale.branch,
                              onBranchSelected: (branch) {
                                selectedBranch = branch;
                              },
                            ),
      
                            const SizedBox(height: 12),
      
                            // Email
                            ZTextFieldEntitled(
                              isRequired: true,
                              controller: usrEmail,
                              hint: 'example@zaitoonsoft.com',
                              onSubmit: (_) => onSubmit(),
                              validator: (e) {
                                if (e.isEmpty) {
                                  return locale.required(locale.email);
                                }
                                if (e.isNotEmpty) {
                                  return Utils.validateEmail(email: e, context: context);
                                }
                                return null;
                              },
                              title: locale.email,
                            ),
      
                            const SizedBox(height: 12),
      
                            // Password and Confirm Password
                            ZTextFieldEntitled(
                              isRequired: true,
                              securePassword: isPasswordSecure,
                              controller: usrPas,
                              onSubmit: (_) => onSubmit(),
                              validator: (e) {
                                if (e.isEmpty) {
                                  return locale.required(locale.password);
                                }
                                return null;
                              },
                              title: locale.password,
                              trailing: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPasswordSecure = !isPasswordSecure;
                                  });
                                },
                                icon: Icon(
                                  isPasswordSecure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
      
                            const SizedBox(height: 12),
      
                            ZTextFieldEntitled(
                              isRequired: true,
                              securePassword: isPasswordSecure,
                              controller: passConfirm,
                              onSubmit: (_) => onSubmit(),
                              validator: (e) {
                                if (e.isEmpty) {
                                  return locale.required(locale.confirmPassword);
                                }
                                if (usrPas.text != passConfirm.text) {
                                  return locale.passwordNotMatch;
                                }
                                return null;
                              },
                              title: locale.confirmPassword,
                              trailing: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPasswordSecure = !isPasswordSecure;
                                  });
                                },
                                icon: Icon(
                                  isPasswordSecure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
      
                            const SizedBox(height: 12),
      
                            // Switches
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.surfaceContainerHighest.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        locale.forceChangePasswordTitle,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Switch.adaptive(
                                        value: fcpValue,
                                        onChanged: (value) {
                                          setState(() {
                                            fcpValue = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        locale.forceEmailVerificationTitle,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Switch.adaptive(
                                        value: fevValue,
                                        onChanged: (value) {
                                          setState(() {
                                            fevValue = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
      
                            const SizedBox(height: 16),
      
                            // Error Message
                            if (errorMessage != null && errorMessage!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.error.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: color.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: TextStyle(
                                          color: color.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
      
                            const SizedBox(height: 24),
      
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(color: color.outline.withValues(alpha: .2)),
                                    ),
                                    child: Text(locale.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: isLoading ? null : onSubmit,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: color.primary,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Text(locale.create),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void onSubmit() {
    if (formKey.currentState!.validate()) {
      context.read<UsersBloc>().add(
        AddUserEvent(
          UsersModel(
            usrName: usrName.text.trim(),
            usrPass: usrPas.text,
            usrBranch: selectedBranch?.brcId ?? 1000,
            rolID: _selectedRole,
            usrEmail: usrEmail.text,
            usrFcp: fcpValue ? 1 : 0,
            usrFev: fevValue,
            usrOwner: widget.indId ?? usrOwnerId, // This is fine here because it's inside a method
            loggedInUser: currentUser(),
          ),
        ),
      );
    }
  }
}


// Desktop Dialog Version (with indId support)
class _Desktop extends StatefulWidget {
  final int? indId;

  const _Desktop({this.indId});

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final TextEditingController usrName = TextEditingController();
  final TextEditingController usrEmail = TextEditingController();
  final TextEditingController usrPas = TextEditingController();
  final TextEditingController passConfirm = TextEditingController();
  final TextEditingController usrOwner = TextEditingController();

  int? _selectedRole;
  bool isPasswordSecure = true;
  bool fcpValue = true;
  bool fevValue = true;
  int? usrOwnerId;
  BranchModel? selectedBranch;
  IndividualsModel? selectedIndividual;

  final formKey = GlobalKey<FormState>();
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize with widget.indId in initState
    if (widget.indId != null) {
      usrOwnerId = widget.indId!;
    }
  }

  // Safe method to get base currency with fallback
  String? currentUser() {
    try {
      final companyState = context.read<AuthBloc>().state;
      if (companyState is AuthenticatedState) {
        return companyState.loginData.usrName;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isLoading = context.watch<UsersBloc>().state is UsersLoadingState;

    return ZFormDialog(
      width: 650,
      icon: Icons.person_add_rounded,
      onAction: onSubmit,
      actionLabel: isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          color: Theme.of(context).colorScheme.surface,
        ),
      )
          : Text(locale.create),
      title: locale.addUserTitle,
      child: BlocListener<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UsersErrorState) {
            setState(() {
              errorMessage = state.message;
            });
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FormNavigation(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 5,
                      children: [
                        Expanded(
                          flex: 4,
                          child: ZTextFieldEntitled(
                            isRequired: true,
                            controller: usrName,
                            hint: "e.g zaitoon",
                            onSubmit: (_) => onSubmit(),
                            validator: (e) {
                              if (e.isEmpty) {
                                return locale.required(locale.username);
                              }
                              if (e.isNotEmpty) {
                                return Utils.validateUsername(
                                  value: e,
                                  context: context,
                                );
                              }
                              return null;
                            },
                            title: locale.username,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: UserRoleDropdown(
                            onRoleSelected: (e) {
                              setState(() {
                                _selectedRole = e?.rolId;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Conditional rendering based on indId
                    if (widget.indId == null) ...[
                      // Show individual selector only when indId is not provided
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 8,
                        children: [
                          Expanded(
                            flex: 3,
                            child: GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                              showAllOnFocus: true,
                              controller: usrOwner,
                              title: locale.individuals,
                              hintText: locale.userOwner,
                              isRequired: true,
                              bloc: context.read<IndividualsBloc>(),
                              fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                              searchFunction: (bloc, query) => bloc.add(SearchIndividualsEvent(query)),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return locale.required(locale.individuals);
                                }
                                return null;
                              },
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
                                  selectedIndividual = value;
                                  usrOwnerId = value.perId!;
                                });
                              },
                              noResultsText: locale.noDataFound,
                              showClearButton: true,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: BranchDropdown(
                              title: locale.branch,
                              onBranchSelected: (branch) {
                                selectedBranch = branch;
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Show only branch dropdown when indId is provided
                      Row(
                        children: [
                          Expanded(
                            child: BranchDropdown(
                              title: locale.branch,
                              onBranchSelected: (branch) {
                                selectedBranch = branch;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    ZTextFieldEntitled(
                      isRequired: true,
                      controller: usrEmail,
                      hint: 'example@zaitoonsoft.com',
                      onSubmit: (_) => onSubmit(),
                      validator: (e) {
                        if (e.isEmpty) {
                          return locale.required(locale.email);
                        }
                        if (e.isNotEmpty) {
                          return Utils.validateEmail(email: e, context: context);
                        }
                        return null;
                      },
                      title: locale.email,
                    ),

                    Row(
                      spacing: 3,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            isRequired: true,
                            securePassword: isPasswordSecure,
                            controller: usrPas,
                            onSubmit: (_) => onSubmit(),
                            validator: (e) {
                              if (e.isEmpty) {
                                return locale.required(locale.password);
                              }
                              return null;
                            },
                            title: locale.password,
                            trailing: IconButton(
                              onPressed: () {
                                setState(() {
                                  isPasswordSecure = !isPasswordSecure;
                                });
                              },
                              icon: Icon(
                                isPasswordSecure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            isRequired: true,
                            securePassword: isPasswordSecure,
                            controller: passConfirm,
                            onSubmit: (_) => onSubmit(),
                            validator: (e) {
                              if (e.isEmpty) {
                                return locale.required(locale.confirmPassword);
                              }
                              if (usrPas.text != passConfirm.text) {
                                return locale.passwordNotMatch;
                              }
                              return null;
                            },
                            title: locale.confirmPassword,
                            trailing: IconButton(
                              onPressed: () {
                                setState(() {
                                  isPasswordSecure = !isPasswordSecure;
                                });
                              },
                              icon: Icon(
                                isPasswordSecure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      spacing: 5,
                      children: [
                        Switch.adaptive(
                          value: fcpValue,
                          onChanged: (value) {
                            setState(() {
                              fcpValue = value;
                            });
                          },
                        ),
                        Text(
                          locale.forceChangePasswordTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),

                    Row(
                      spacing: 5,
                      children: [
                        Switch.adaptive(
                          value: fevValue,
                          onChanged: (value) {
                            setState(() {
                              fevValue = value;
                            });
                          },
                        ),
                        Text(
                          locale.forceEmailVerificationTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (errorMessage != null && errorMessage!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          spacing: 5,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            Expanded(
                              child: Text(
                                errorMessage ?? "",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
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
    if (formKey.currentState!.validate()) {
      context.read<UsersBloc>().add(
        AddUserEvent(
          UsersModel(
            usrName: usrName.text.trim(),
            usrPass: usrPas.text,
            usrBranch: selectedBranch?.brcId ?? 1000,
            rolID: _selectedRole,
            usrEmail: usrEmail.text,
            usrFcp: fcpValue ? 1 : 0,
            usrFev: fevValue,
            usrOwner: widget.indId ?? usrOwnerId, // Use indId if provided
            loggedInUser: currentUser(),
          ),
        ),
      );
    }
  }
}