import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/section_title.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/bloc/employee_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/features/department_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/features/payment_method_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/features/salary_cal_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/Employees/model/emp_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/Ui/add_edit.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../Features/Other/toast.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';

class AddEditEmployeeView extends StatelessWidget {
  final EmployeeModel? model;
  final bool? isDriver;
  final String? employeeType;
  const AddEditEmployeeView({
    super.key,
    this.model,
    this.isDriver = false,
    this.employeeType,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(model: model, isDriver: isDriver,employeeType: employeeType),
      desktop: _Desktop(model: model, isDriver: isDriver, employeeType: employeeType),
      tablet: _Desktop(model: model, isDriver: isDriver, employeeType: employeeType),
    );
  }
}



class _Mobile extends StatefulWidget {
  final EmployeeModel? model;
  final bool? isDriver;
  final String? employeeType;

  const _Mobile({
    this.model,
    this.isDriver = false,
    this.employeeType,
  });

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final individualCtrl = TextEditingController();
  final indAccountCtrl = TextEditingController();
  final empSalary = TextEditingController();
  final empEmail = TextEditingController();
  final empTaxInfo = TextEditingController();
  final jobTitle = TextEditingController();

  int? perId;
  int? accNumber;
  String? salaryCalBase;
  String? paymentBase;
  EmpDepartment? department;
  EmpSalaryCalcBase? salaryCalculationBase;
  EmpPaymentMethod? employeePaymentMethod;
  DateTime? startDate;

  final formKey = GlobalKey<FormState>();

  bool get isDriverEmployee {
    return widget.isDriver == true ||
        widget.employeeType == 'driver' ||
        widget.model?.empPosition?.toLowerCase() == 'driver';
  }

  int? empStatus;

  @override
  void initState() {
    super.initState();

    if (widget.model != null) {
      // Convert string to EmpDepartment enum
      if (widget.model?.empDepartment != null) {
        department = EmpDepartment.fromDatabaseValue(widget.model!.empDepartment ?? "");
      }

      // Convert salary calculation base
      if (widget.model?.empSalCalcBase != null) {
        salaryCalculationBase = EmpSalaryCalcBase.fromDatabaseValue(widget.model!.empSalCalcBase ?? "");
      }

      // Convert payment method
      if (widget.model?.empPmntMethod != null) {
        employeePaymentMethod = EmpPaymentMethod.fromDatabaseValue(widget.model!.empPmntMethod ?? "");
      }

      indAccountCtrl.text = widget.model?.empSalAccount.toString() ?? "";
      paymentBase = widget.model?.empPmntMethod;
      salaryCalBase = widget.model?.empSalCalcBase;
      accNumber = widget.model?.empSalAccount;
      empSalary.text = widget.model?.empSalary?.toAmount() ?? "";
      empEmail.text = widget.model?.empEmail ?? "";
      empTaxInfo.text = widget.model?.empTaxInfo ?? "";
      perId = widget.model?.perId;
      empStatus = widget.model?.empStatus;
    }

    // 🔒 Force Driver job title
    if (isDriverEmployee) {
      jobTitle.text = "Driver";
    } else {
      jobTitle.text = widget.model?.empPosition ?? "";
    }
  }

  @override
  void dispose() {
    jobTitle.dispose();
    indAccountCtrl.dispose();
    individualCtrl.dispose();
    empSalary.dispose();
    empEmail.dispose();
    empTaxInfo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isLoading = context.watch<EmployeeBloc>().state is EmployeeLoadingState;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.model == null
              ? (isDriverEmployee
              ? locale.driverRegistration
              : locale.employeeRegistration)
              : "${locale.update} ${widget.model?.perName ?? ''}",
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocListener<EmployeeBloc, EmployeeState>(
        listener: (context, state) {
          if (state is EmployeeSuccessState) {
            ToastManager.show(
              context: context,
              message: locale.successMessage,
              type: ToastType.success,
            );
          }
          if (state is EmployeeErrorState) {
            ToastManager.show(
              context: context,
              message: state.message,
              type: ToastType.error,
            );
          }
        },
        child: Stack(
          children: [
            Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Card
                    if (widget.model == null) ...[
                      SectionTitle(title:  locale.personalInfo),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                          showAllOnFocus: true,
                          controller: individualCtrl,
                          title: locale.individuals,
                          hintText: locale.individuals,
                          trailing: IconButton(
                              onPressed: (){
                                showDialog(context: context, builder: (context){
                                  return IndividualAddEditView();
                                });
                              },
                              icon: Icon(Icons.add)),
                          isRequired: true,
                          bloc: context.read<IndividualsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                          searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
                          validator: (value) {
                            if (value.isEmpty) {
                              return locale.required(locale.individuals);
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
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                          itemToString: (acc) =>
                          "${acc.perName} ${acc.perLastName}",
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
                              perId = value.perId!;
                              indAccountCtrl.clear();
                              context.read<AccountsBloc>().add(LoadAccountsEvent(ownerId: perId));
                            });
                          },
                          noResultsText: locale.noDataFound,
                          showClearButton: true,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],

                    // Account Information Card
                    SectionTitle(title: locale.accountInfo),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: GenericTextField<AccountsModel, AccountsBloc,
                          AccountsState>(
                        showAllOnFocus: true,
                        controller: indAccountCtrl,
                        title: locale.accounts,
                        hintText: locale.accNameOrNumber,
                        isRequired: true,
                        bloc: context.read<AccountsBloc>(),
                        fetchAllFunction: (bloc) =>
                            bloc.add(LoadAccountsEvent(ownerId: perId)),
                        searchFunction: (bloc, query) =>
                            bloc.add(LoadAccountsEvent(ownerId: perId)),
                        validator: (value) {
                          if (value.isEmpty) {
                            return locale.required(locale.accounts);
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
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${account.accNumber} | ${account.accName}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Utils.currencyColors(
                                          account.actCurrency ?? "")
                                          .withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${account.actCurrency}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                        color: Utils.currencyColors(
                                            account.actCurrency ?? ""),
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
                        noResultsText: locale.noDataFound,
                        showClearButton: true,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Employment Details Card
                    SectionTitle(title: 'Employment Details'),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Department Dropdown
                          DepartmentDropdown(
                            selectedDepartment: department,
                            onDepartmentSelected: (e) {
                              setState(() {
                                department = e;
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Salary Calculation and Payment Method
                          Row(
                            children: [
                              Expanded(
                                child: SalaryCalcBaseDropdown(
                                  selectedBase: salaryCalculationBase,
                                  onSelected: (e) {
                                    setState(() {
                                      salaryCalculationBase = e;
                                      salaryCalBase = e.name;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PaymentMethodDropdown(
                                  selectedMethod: employeePaymentMethod,
                                  onSelected: (e) {
                                    setState(() {
                                      employeePaymentMethod = e;
                                      paymentBase = e.name;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Job & Salary Card
                    SectionTitle(title: locale.jobAndSalary),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Job Title
                          ZTextFieldEntitled(
                            isEnabled: !isDriverEmployee,
                            controller: jobTitle,
                            title: locale.jobTitle,
                            isRequired: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return locale.required(locale.jobTitle);
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Salary
                          ZTextFieldEntitled(
                            isRequired: true,
                            keyboardInputType:
                            TextInputType.numberWithOptions(decimal: true),
                            inputFormat: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]*')),
                              SmartThousandsDecimalFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return locale.required(locale.salary);
                              }

                              // Remove formatting (e.g. commas)
                              final clean =
                              value.replaceAll(RegExp(r'[^\d.]'), '');
                              final amount = double.tryParse(clean);

                              if (amount == null || amount <= 0.0) {
                                return locale.amountGreaterZero;
                              }

                              return null;
                            },
                            controller: empSalary,
                            title: locale.salary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Additional Information Card
                    SectionTitle(title: 'Additional Info'),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ZTextFieldEntitled(
                            controller: empTaxInfo,
                            title: locale.taxInfo,
                          ),
                          const SizedBox(height: 12),
                          ZTextFieldEntitled(
                            controller: empEmail,
                            validator: (value) => Utils.validateEmail(
                                email: value, context: context),
                            title: locale.email,
                            keyboardInputType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),

                    // Status Toggle for Edit
                    if (widget.model != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Switch(
                              value: empStatus == 1,
                              onChanged: (e) {
                                setState(() {
                                  empStatus = e == true ? 1 : 0;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                empStatus == 1
                                    ? locale.active
                                    : locale.blocked,
                                style: TextStyle(
                                  color: empStatus == 1
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Submit Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 5),
                      child: ZOutlineButton(
                        isActive: true,
                        width: double.infinity,
                        onPressed: isLoading ? null : onSubmit,
                        label: isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          widget.model == null
                              ? locale.create.toUpperCase()
                              : locale.update.toUpperCase(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Loading Overlay
            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: .3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }


  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = EmployeeModel(
      empId: widget.model?.empId,
      empPersonal: perId,
      empSalAccount: accNumber,
      empEmail: empEmail.text,
      empHireDate: DateTime.now(),
      empDepartment: department?.toDatabaseValue(),
      empPosition: isDriverEmployee ? "Driver" : jobTitle.text,
      empSalCalcBase: salaryCalculationBase?.name,
      empPmntMethod: employeePaymentMethod?.name,
      empStatus: empStatus ?? 1,
      empFingerprint: "FP-${DateTime.now().millisecondsSinceEpoch}",
      empEndDate: DateTime.now().toFormattedDate(),
      empSalary: empSalary.text.cleanAmount,
      empTaxInfo: empTaxInfo.text,
    );

    final bloc = context.read<EmployeeBloc>();

    if (widget.model == null) {
      bloc.add(AddEmployeeEvent(data));
    } else {
      bloc.add(UpdateEmployeeEvent(data));
    }
  }
}

class _Desktop extends StatefulWidget {
  final EmployeeModel? model;
  final bool? isDriver;
  final String? employeeType;
  const _Desktop({
    this.model,
    this.isDriver = false,
    this.employeeType,
  });

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final individualCtrl = TextEditingController();
  final indAccountCtrl = TextEditingController();
  final empSalary = TextEditingController();
  final empEmail = TextEditingController();
  final empTaxInfo = TextEditingController();
  final jobTitle = TextEditingController();

  int? perId;
  int? accNumber;
  String? salaryCalBase;
  String? paymentBase;
  EmpDepartment? department;
  EmpSalaryCalcBase? salaryCalculationBase;
  EmpPaymentMethod? employeePaymentMethod;
  DateTime? startDate;

  final formKey = GlobalKey<FormState>();
  bool get isDriverEmployee {
    return widget.isDriver == true ||
        widget.employeeType == 'driver' ||
        widget.model?.empPosition?.toLowerCase() == 'driver';
  }
  int? empStatus;
  @override
  void initState() {
    super.initState();

    if (widget.model != null) {
      // Convert string to EmpDepartment enum
      if (widget.model?.empDepartment != null) {
        department = EmpDepartment.fromDatabaseValue(widget.model!.empDepartment??"");
      }

      // FIXED: Use the correct enum methods
      if (widget.model?.empSalCalcBase != null) {
        salaryCalculationBase = EmpSalaryCalcBase.fromDatabaseValue(widget.model!.empSalCalcBase??"");
      }

      // FIXED: Use the correct enum methods
      if (widget.model?.empPmntMethod != null) {
        employeePaymentMethod = EmpPaymentMethod.fromDatabaseValue(widget.model!.empPmntMethod??"");
      }

      indAccountCtrl.text = widget.model?.empSalAccount.toString() ?? "";
      paymentBase = widget.model?.empPmntMethod;
      salaryCalBase = widget.model?.empSalCalcBase;
      accNumber = widget.model?.empSalAccount;
      empSalary.text = widget.model?.empSalary?.toAmount() ?? "";
      empEmail.text = widget.model?.empEmail ?? "";
      empTaxInfo.text = widget.model?.empTaxInfo ?? "";
      perId = widget.model?.perId;
      empStatus = widget.model?.empStatus;
    }

    // 🔒 Force Driver job title
    if (isDriverEmployee) {
      jobTitle.text = "Driver";
    } else {
      jobTitle.text = widget.model?.empPosition ?? "";
    }
  }

  @override
  void dispose() {
    jobTitle.dispose();
    indAccountCtrl.dispose();
    individualCtrl.dispose();
    empSalary.dispose();
    empEmail.dispose();
    empTaxInfo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isLoading = context.watch<EmployeeBloc>().state is EmployeeLoadingState;

    return ZFormDialog(
      width: 550,
      actionLabel: isLoading
          ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.surface,
            strokeWidth: 2,
          ))
          : widget.model == null
          ? Text(locale.create)
          : Text(locale.update),
      icon: Icons.perm_contact_calendar_rounded,
      onAction: onSubmit,
      title: widget.model == null
          ? (widget.isDriver == true || widget.employeeType == 'driver'
          ? locale.driverRegistration
          : locale.employeeRegistration)
          : "${locale.update} ${widget.model?.perName} ${widget.model?.perLastName}",
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.model == null)
                  GenericTextField<IndividualsModel, IndividualsBloc, IndividualsState>(
                    showAllOnFocus: true,
                    controller: individualCtrl,
                    title: locale.individuals,
                    hintText: locale.individuals,
                    trailing: IconButton(
                        onPressed: (){
                          showDialog(context: context, builder: (context){
                            return IndividualAddEditView();
                          });
                        },
                        icon: Icon(Icons.add)),
                    isRequired: true,
                    bloc: context.read<IndividualsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                    searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent(search: query)),
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
                        perId = value.perId!;
                        indAccountCtrl.clear();
                        context
                            .read<AccountsBloc>()
                            .add(LoadAccountsEvent(ownerId: perId));
                      });
                    },
                    noResultsText: locale.noDataFound,
                    showClearButton: true,
                  ),
                if (widget.model == null) SizedBox(height: 10),
                  GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                    showAllOnFocus: true,
                    controller: indAccountCtrl,
                    title: locale.accounts,
                    hintText: locale.accNameOrNumber,
                    isRequired: true,
                    bloc: context.read<AccountsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: perId)),
                    searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: perId)),
                    validator: (value) {
                      if (value.isEmpty) {
                        return locale.required(locale.accounts);
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${account.accNumber} | ${account.accName}",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                ZCover(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: .01),
                                  child: Text(
                                    "${account.actCurrency}",
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Utils.currencyColors(account.actCurrency??"")
                                    ),
                                  ),
                                ),
                              ],
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
                    noResultsText: locale.noDataFound,
                    showClearButton: true,
                  ),
                SizedBox(height: 10),
                DepartmentDropdown(
                  selectedDepartment: department,
                  onDepartmentSelected: (e) {
                    setState(() {
                      department = e;
                    });
                  },
                ),
                SizedBox(height: 10),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: SalaryCalcBaseDropdown(
                       selectedBase: salaryCalculationBase,
                        onSelected: (e) {
                          salaryCalBase = e.name;
                        },
                      ),
                    ),
                    Expanded(
                      child: PaymentMethodDropdown(
                        selectedMethod: employeePaymentMethod,
                        onSelected: (e) {
                          paymentBase = e.name;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  spacing: 5,
                  children: [
                    Expanded(
                      child: ZTextFieldEntitled(
                        isEnabled: !isDriverEmployee,
                        controller: jobTitle,
                        title: locale.jobTitle,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return locale.required(locale.jobTitle);
                          }
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      child: ZTextFieldEntitled(
                        isRequired: true,
                        keyboardInputType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormat: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]*')),
                          SmartThousandsDecimalFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return locale.required(locale.salary);
                          }

                          // Remove formatting (e.g. commas)
                          final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                          final amount = double.tryParse(clean);

                          if (amount == null || amount <= 0.0) {
                            return locale.amountGreaterZero;
                          }

                          return null;
                        },
                        controller: empSalary,
                        title: locale.salary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ZTextFieldEntitled(
                    controller: empTaxInfo, title: locale.taxInfo),
                SizedBox(height: 10),
                ZTextFieldEntitled(
                  controller: empEmail,
                  validator: (value) =>
                      Utils.validateEmail(email: value, context: context),
                  title: locale.email,
                ),
                if(widget.model !=null)...[
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Switch(
                        value: empStatus == 1,
                        onChanged: (e) {
                          setState(() {
                            empStatus = e == true ? 1 : 0;
                          });
                        },
                      ),
                      SizedBox(width: 8),
                      Text(empStatus == 1 ? locale.active : locale.blocked),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = EmployeeModel(
      empId: widget.model?.empId,
      empPersonal: perId,
      empSalAccount: accNumber,
      empEmail: empEmail.text,
      empHireDate: DateTime.now(),
      empDepartment: department?.toDatabaseValue(),
      empPosition: isDriverEmployee ? "Driver" : jobTitle.text,
      empSalCalcBase: salaryCalBase,
      empPmntMethod: paymentBase,
      empStatus: empStatus,
      empFingerprint: "FP-23452",
      empEndDate: DateTime.now().toFormattedDate(),
      empSalary: empSalary.text.cleanAmount,
      empTaxInfo: empTaxInfo.text,
    );

    final bloc = context.read<EmployeeBloc>();

    if (widget.model == null) {
      bloc.add(AddEmployeeEvent(data));
    } else {
      bloc.add(UpdateEmployeeEvent(data));
    }
  }
}