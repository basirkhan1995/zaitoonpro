import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/IncomeExpense/bloc/project_inc_exp_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/IncomeExpense/model/prj_inc_exp_model.dart';
import '../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../Features/Other/alert_dialog.dart';
import '../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../Features/Other/utils.dart';
import '../../../../../../Features/Other/zForm_dialog.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/models/login_model.dart';
import '../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../Stakeholders/Ui/Accounts/model/acc_model.dart';

class AddEditIncomeExpenseDialog extends StatelessWidget {
  final ProjectsModel project;
  final Payment? existingData;

  const AddEditIncomeExpenseDialog({
    super.key,
    required this.project,
    this.existingData,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _AddEditIncomeExpenseMobile(
        project: project,
        existingData: existingData,
      ),
      tablet: _AddEditIncomeExpenseTablet(
        project: project,
        existingData: existingData,
      ),
      desktop: _AddEditIncomeExpenseDesktop(
        project: project,
        existingData: existingData,
      ),
    );
  }
}

// Mobile View
class _AddEditIncomeExpenseMobile extends StatefulWidget {
  final ProjectsModel project;
  final Payment? existingData;

  const _AddEditIncomeExpenseMobile({
    required this.project,
    this.existingData,
  });

  @override
  State<_AddEditIncomeExpenseMobile> createState() => _AddEditIncomeExpenseMobileState();
}

class _AddEditIncomeExpenseMobileState extends State<_AddEditIncomeExpenseMobile> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _remarkController = TextEditingController();

  String _selectedType = 'Income';
  bool _isLoading = false;
  LoginData? loginData;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingData != null) {
      _selectedType = widget.existingData!.prpType == 'Payment' ? 'Income' : 'Expense';

      if (_selectedType == 'Income') {
        _amountController.text = widget.existingData!.payments.toAmount();
      } else {
        _amountController.text = widget.existingData!.expenses.toAmount();
      }

      _accountController.text = widget.project.prjOwnerAccount.toString();
      _remarkController.text = '';
    } else if (widget.project.prjOwnerAccount != null) {
      _accountController.text = widget.project.prjOwnerAccount!.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (loginData == null) return;

    setState(() => _isLoading = true);

    final data = ProjectInOutModel(
      reference: widget.existingData?.prpTrnRef,
      prpType: _selectedType == 'Income' ? 'Payment' : 'Expense',
      prjId: widget.project.prjId,
      account: _accountController.text,
      amount: _amountController.text.cleanAmount,
      currency: widget.project.actCurrency,
      ppRemark: _remarkController.text,
      usrName: loginData?.usrName ?? "",
    );

    if (widget.existingData != null) {
      context.read<ProjectIncExpBloc>().add(UpdateProjectIncExpEvent(data));
    } else {
      context.read<ProjectIncExpBloc>().add(AddProjectIncExpEvent(data));
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _deleteTransaction() {
    if (widget.existingData == null || loginData == null) return;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: 'Confirm Delete',
        content: 'Are you sure you want to delete this transaction?',
        onYes: () {
          Navigator.of(context).pop();
          setState(() => _isLoading = true);

          context.read<ProjectIncExpBloc>().add(
            DeleteProjectIncExpEvent(
              usrName: loginData!.usrName!,
              reference: widget.existingData!.prpTrnRef!,
              projectId: widget.project.prjId,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      loginData = authState.loginData;
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.existingData == null ? Icons.add_circle_outline : Icons.edit,
                    color: color.surface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingData == null ? tr.newKeyword : '${tr.edit} Transaction',
                      style: TextStyle(
                        color: color.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: color.surface),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Type
                      Text(
                        'Transaction Type',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMobileTypeCard(
                              title: tr.payment,
                              isSelected: _selectedType == 'Income',
                              selectedColor: Colors.green,
                              icon: Icons.arrow_downward,
                              onTap: widget.existingData == null
                                  ? () {
                                setState(() {
                                  _selectedType = 'Income';
                                  if (widget.project.prjOwnerAccount != null) {
                                    _accountController.text = widget.project.prjOwnerAccount.toString();
                                  }
                                  _amountController.clear();
                                });
                              }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMobileTypeCard(
                              title: tr.expense,
                              isSelected: _selectedType == 'Expense',
                              selectedColor: color.error,
                              icon: Icons.arrow_upward,
                              onTap: widget.existingData == null
                                  ? () {
                                setState(() {
                                  _selectedType = 'Expense';
                                  _accountController.clear();
                                  _amountController.clear();
                                });
                              }
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Amount
                      ZTextFieldEntitled(
                        controller: _amountController,
                        title: '${tr.amount} (${widget.project.actCurrency})',
                        isRequired: true,
                        icon: Icons.money,
                        inputFormat: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                          SmartThousandsDecimalFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.amount);
                          }
                          final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                          final amount = double.tryParse(clean);
                          if (amount == null || amount <= 0.0) {
                            return tr.amountGreaterZero;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Account
                      if (_selectedType == "Income")
                        ZTextFieldEntitled(
                          controller: _accountController,
                          title: 'Account Number',
                          isRequired: true,
                          isEnabled: false,
                          icon: Icons.account_balance,
                          hint: 'Using project owner account',
                        ),

                      if (_selectedType == "Expense" && widget.existingData == null)
                        GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                          showAllOnFocus: true,
                          controller: _accountController,
                          title: tr.accounts,
                          hintText: tr.accNameOrNumber,
                          isRequired: true,
                          bloc: context.read<AccountsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(
                            LoadAccountsFilterEvent(
                              include: "11,12",
                              ccy: widget.project.actCurrency,
                              exclude: "",
                            ),
                          ),
                          searchFunction: (bloc, query) => bloc.add(
                            LoadAccountsFilterEvent(
                              include: "11,12",
                              ccy: widget.project.actCurrency,
                              input: query,
                              exclude: "",
                            ),
                          ),
                          itemBuilder: (context, account) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                            child: Text(
                              "${account.accNumber} | ${account.accName}",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                          stateToLoading: (state) => state is AccountLoadingState,
                          loadingBuilder: (context) => const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          stateToItems: (state) {
                            if (state is AccountLoadedState) {
                              return state.accounts;
                            }
                            return [];
                          },
                          onSelected: (value) {},
                          noResultsText: tr.noDataFound,
                          showClearButton: true,
                        ),

                      const SizedBox(height: 16),

                      // Remark
                      ZTextFieldEntitled(
                        controller: _remarkController,
                        title: tr.remark,
                        keyboardInputType: TextInputType.multiline,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surface,
                border: Border(
                  top: BorderSide(color: color.outline.withValues(alpha: .1)),
                ),
              ),
              child: Row(
                children: [
                  if (widget.existingData != null)
                    Expanded(
                      child: ZOutlineButton(
                        height: 45,
                        onPressed: _isLoading ? null : _deleteTransaction,
                        isActive: true,
                        backgroundHover: color.error,
                        label: Text(tr.delete),
                      ),
                    ),
                  if (widget.existingData != null) const SizedBox(width: 8),
                  Expanded(
                    child: ZOutlineButton(
                      height: 45,
                      isActive: true,
                      onPressed: _isLoading ? null : _submitForm,
                      label: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(widget.existingData == null ? tr.create : tr.update),
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

  Widget _buildMobileTypeCard({
    required String title,
    required bool isSelected,
    required Color selectedColor,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? selectedColor.withValues(alpha: .1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tablet View
class _AddEditIncomeExpenseTablet extends StatefulWidget {
  final ProjectsModel project;
  final Payment? existingData;

  const _AddEditIncomeExpenseTablet({
    required this.project,
    this.existingData,
  });

  @override
  State<_AddEditIncomeExpenseTablet> createState() => _AddEditIncomeExpenseTabletState();
}

class _AddEditIncomeExpenseTabletState extends State<_AddEditIncomeExpenseTablet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _remarkController = TextEditingController();

  String _selectedType = 'Income';
  bool _isLoading = false;
  LoginData? loginData;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingData != null) {
      _selectedType = widget.existingData!.prpType == 'Payment' ? 'Income' : 'Expense';

      if (_selectedType == 'Income') {
        _amountController.text = widget.existingData!.payments.toAmount();
      } else {
        _amountController.text = widget.existingData!.expenses.toAmount();
      }

      _accountController.text = widget.project.prjOwnerAccount.toString();
      _remarkController.text = '';
    } else if (widget.project.prjOwnerAccount != null) {
      _accountController.text = widget.project.prjOwnerAccount!.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (loginData == null) return;

    setState(() => _isLoading = true);

    final data = ProjectInOutModel(
      reference: widget.existingData?.prpTrnRef,
      prpType: _selectedType == 'Income' ? 'Payment' : 'Expense',
      prjId: widget.project.prjId,
      account: _accountController.text,
      amount: _amountController.text.cleanAmount,
      currency: widget.project.actCurrency,
      ppRemark: _remarkController.text,
      usrName: loginData?.usrName ?? "",
    );

    if (widget.existingData != null) {
      context.read<ProjectIncExpBloc>().add(UpdateProjectIncExpEvent(data));
    } else {
      context.read<ProjectIncExpBloc>().add(AddProjectIncExpEvent(data));
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _deleteTransaction() {
    if (widget.existingData == null || loginData == null) return;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: 'Confirm Delete',
        content: 'Are you sure you want to delete this transaction?',
        onYes: () {
          Navigator.of(context).pop();
          setState(() => _isLoading = true);

          context.read<ProjectIncExpBloc>().add(
            DeleteProjectIncExpEvent(
              usrName: loginData!.usrName!,
              reference: widget.existingData!.prpTrnRef!,
              projectId: widget.project.prjId,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      loginData = authState.loginData;
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.existingData == null ? Icons.add_circle_outline : Icons.edit,
                    color: color.surface,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingData == null ? tr.newKeyword : '${tr.edit} Transaction',
                      style: TextStyle(
                        color: color.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: color.surface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Type
                      Text(
                        'Transaction Type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTabletTypeCard(
                              title: tr.payment,
                              isSelected: _selectedType == 'Income',
                              selectedColor: Colors.green,
                              icon: Icons.arrow_downward,
                              onTap: widget.existingData == null
                                  ? () {
                                setState(() {
                                  _selectedType = 'Income';
                                  if (widget.project.prjOwnerAccount != null) {
                                    _accountController.text = widget.project.prjOwnerAccount.toString();
                                  }
                                  _amountController.clear();
                                });
                              }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTabletTypeCard(
                              title: tr.expense,
                              isSelected: _selectedType == 'Expense',
                              selectedColor: color.error,
                              icon: Icons.arrow_upward,
                              onTap: widget.existingData == null
                                  ? () {
                                setState(() {
                                  _selectedType = 'Expense';
                                  _accountController.clear();
                                  _amountController.clear();
                                });
                              }
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Amount
                      ZTextFieldEntitled(
                        controller: _amountController,
                        title: '${tr.amount} (${widget.project.actCurrency})',
                        isRequired: true,
                        icon: Icons.money,
                        inputFormat: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                          SmartThousandsDecimalFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.amount);
                          }
                          final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                          final amount = double.tryParse(clean);
                          if (amount == null || amount <= 0.0) {
                            return tr.amountGreaterZero;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Account
                      if (_selectedType == "Income")
                        ZTextFieldEntitled(
                          controller: _accountController,
                          title: 'Account Number',
                          isRequired: true,
                          isEnabled: false,
                          icon: Icons.account_balance,
                          hint: 'Using project owner account',
                        ),

                      if (_selectedType == "Expense" && widget.existingData == null)
                        GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                          showAllOnFocus: true,
                          controller: _accountController,
                          title: tr.accounts,
                          hintText: tr.accNameOrNumber,
                          isRequired: true,
                          bloc: context.read<AccountsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(
                            LoadAccountsFilterEvent(
                              include: "11,12",
                              ccy: widget.project.actCurrency,
                              exclude: "",
                            ),
                          ),
                          searchFunction: (bloc, query) => bloc.add(
                            LoadAccountsFilterEvent(
                              include: "11,12",
                              ccy: widget.project.actCurrency,
                              input: query,
                              exclude: "",
                            ),
                          ),
                          itemBuilder: (context, account) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: Row(
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
                                    color: Utils.currencyColors(account.actCurrency ?? "").withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    account.actCurrency ?? "",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Utils.currencyColors(account.actCurrency ?? ""),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                          stateToLoading: (state) => state is AccountLoadingState,
                          loadingBuilder: (context) => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          stateToItems: (state) {
                            if (state is AccountLoadedState) {
                              return state.accounts;
                            }
                            return [];
                          },
                          onSelected: (value) {},
                          noResultsText: tr.noDataFound,
                          showClearButton: true,
                        ),

                      const SizedBox(height: 20),

                      // Remark
                      ZTextFieldEntitled(
                        controller: _remarkController,
                        title: tr.remark,
                        keyboardInputType: TextInputType.multiline,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.surface,
                border: Border(
                  top: BorderSide(color: color.outline.withValues(alpha: .1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.existingData != null)
                    ZOutlineButton(
                      height: 48,
                      onPressed: _isLoading ? null : _deleteTransaction,
                      isActive: true,
                      backgroundHover: color.error,
                      label: Text(
                        tr.delete,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  if (widget.existingData != null) const SizedBox(width: 12),
                  ZOutlineButton(
                    height: 48,
                    isActive: true,
                    onPressed: _isLoading ? null : _submitForm,
                    label: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(
                      widget.existingData == null ? tr.create : tr.update,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ZOutlineButton(
                    height: 48,
                    onPressed: () => Navigator.pop(context),
                    label: Text(
                      tr.cancel,
                      style: const TextStyle(fontSize: 16),
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

  Widget _buildTabletTypeCard({
    required String title,
    required bool isSelected,
    required Color selectedColor,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? selectedColor.withValues(alpha: .1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Desktop View (Your existing implementation wrapped in Responsive)
class _AddEditIncomeExpenseDesktop extends StatefulWidget {
  final ProjectsModel project;
  final Payment? existingData;

  const _AddEditIncomeExpenseDesktop({
    required this.project,
    this.existingData,
  });

  @override
  State<_AddEditIncomeExpenseDesktop> createState() => _AddEditIncomeExpenseDesktopState();
}

class _AddEditIncomeExpenseDesktopState extends State<_AddEditIncomeExpenseDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _remarkController = TextEditingController();

  String _selectedType = 'Income';
  bool _isLoading = false;
  LoginData? loginData;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingData != null) {
      _selectedType = widget.existingData!.prpType == 'Payment' ? 'Income' : 'Expense';

      if (_selectedType == 'Income') {
        _amountController.text = widget.existingData!.payments.toAmount();
      } else {
        _amountController.text = widget.existingData!.expenses.toAmount();
      }

      _accountController.text = widget.project.prjOwnerAccount.toString();
      _remarkController.text = '';
    } else if (widget.project.prjOwnerAccount != null) {
      _accountController.text = widget.project.prjOwnerAccount!.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (loginData == null) return;

    setState(() => _isLoading = true);

    final data = ProjectInOutModel(
      reference: widget.existingData?.prpTrnRef,
      prpType: _selectedType == 'Income' ? 'Payment' : 'Expense',
      prjId: widget.project.prjId,
      account: _accountController.text,
      amount: _amountController.text.cleanAmount,
      currency: widget.project.actCurrency,
      ppRemark: _remarkController.text,
      usrName: loginData?.usrName ?? "",
    );

    if (widget.existingData != null) {
      context.read<ProjectIncExpBloc>().add(UpdateProjectIncExpEvent(data));
    } else {
      context.read<ProjectIncExpBloc>().add(AddProjectIncExpEvent(data));
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _deleteTransaction() {
    if (widget.existingData == null || loginData == null) return;

    showDialog(
      context: context,
      builder: (context) => ZAlertDialog(
        title: 'Confirm Delete',
        content: 'Are you sure you want to delete this transaction?',
        onYes: () {
          Navigator.of(context).pop();
          setState(() => _isLoading = true);

          context.read<ProjectIncExpBloc>().add(
            DeleteProjectIncExpEvent(
              usrName: loginData!.usrName!,
              reference: widget.existingData!.prpTrnRef!,
              projectId: widget.project.prjId,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      loginData = authState.loginData;
    }

    return ZFormDialog(
      title: widget.existingData == null ? tr.newKeyword : '${tr.edit} | ${widget.existingData!.prpTrnRef}',
      icon: widget.existingData == null ? Icons.add_circle_outline : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      onAction: _submitForm,
      isButtonEnabled: !_isLoading,
      actionLabel: _isLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Text(widget.existingData == null ? tr.create : tr.update),
      expandedAction: widget.existingData != null
          ? ZOutlineButton(
        height: 43,
        onPressed: _isLoading ? null : _deleteTransaction,
        isActive: true,
        backgroundHover: color.error,
        label: Text(tr.delete),
      )
          : null,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Selection
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Transaction Type',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDesktopTypeCard(
                          title: tr.payment,
                          isSelected: _selectedType == 'Income',
                          selectedColor: Colors.green,
                          icon: Icons.arrow_downward,
                          onTap: widget.existingData == null
                              ? () {
                            setState(() {
                              _selectedType = 'Income';
                              if (widget.existingData == null && widget.project.prjOwnerAccount != null) {
                                _accountController.text = widget.project.prjOwnerAccount.toString();
                              }
                              _amountController.clear();
                            });
                          }
                              : null, // This null is outside the function
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDesktopTypeCard(
                          title: tr.expense,
                          isSelected: _selectedType == 'Expense',
                          selectedColor: color.error,
                          icon: Icons.arrow_upward,
                          onTap: widget.existingData == null
                              ? () {
                            setState(() {
                              _selectedType = 'Expense';
                              if (widget.existingData == null) {
                                _accountController.clear();
                              }
                              _amountController.clear();
                            });
                          }
                              : null, // This null is outside the function
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amount Field
            ZTextFieldEntitled(
              controller: _amountController,
              title: '${tr.amount} (${widget.project.actCurrency})',
              isRequired: true,
              icon: Icons.money,
              inputFormat: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                SmartThousandsDecimalFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr.required(tr.amount);
                }
                final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                final amount = double.tryParse(clean);
                if (amount == null || amount <= 0.0) {
                  return tr.amountGreaterZero;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Account Field
            if (_selectedType == "Income") ...[
              ZTextFieldEntitled(
                controller: _accountController,
                title: 'Account Number',
                isRequired: true,
                isEnabled: false,
                icon: Icons.account_balance,
                hint: 'Using project owner account',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  return null;
                },
              ),
            ],
            if (widget.existingData == null)
              if (_selectedType == "Expense") ...[
                GenericTextField<AccountsModel, AccountsBloc, AccountsState>(
                  showAllOnFocus: true,
                  controller: _accountController,
                  title: tr.accounts,
                  hintText: tr.accNameOrNumber,
                  isRequired: true,
                  bloc: context.read<AccountsBloc>(),
                  fetchAllFunction: (bloc) => bloc.add(
                    LoadAccountsFilterEvent(
                      include: "11,12",
                      ccy: widget.project.actCurrency,
                      exclude: "",
                    ),
                  ),
                  searchFunction: (bloc, query) => bloc.add(
                    LoadAccountsFilterEvent(
                      include: "11,12",
                      ccy: widget.project.actCurrency,
                      input: query,
                      exclude: "",
                    ),
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return tr.required(tr.accounts);
                    }
                    return null;
                  },
                  itemBuilder: (context, account) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${account.accNumber} | ${account.accName}",
                              style: Theme.of(context).textTheme.bodyLarge,
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
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  stateToItems: (state) {
                    if (state is AccountLoadedState) {
                      return state.accounts;
                    }
                    return [];
                  },
                  onSelected: (value) {},
                  noResultsText: tr.noDataFound,
                  showClearButton: true,
                ),
              ],

            const SizedBox(height: 16),

            // Remark Field
            ZTextFieldEntitled(
              controller: _remarkController,
              title: tr.remark,
              keyboardInputType: TextInputType.multiline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTypeCard({
    required String title,
    required bool isSelected,
    required Color selectedColor,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? selectedColor : Theme.of(context).colorScheme.outline.withValues(alpha: .5),
            width: isSelected ? 1 : 0.5,
          ),
          color: isSelected ? selectedColor.withValues(alpha: .1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? selectedColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}