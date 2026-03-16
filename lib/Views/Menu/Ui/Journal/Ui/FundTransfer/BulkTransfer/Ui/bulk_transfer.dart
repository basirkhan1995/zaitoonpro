import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/zForm_dialog.dart';
import 'package:zaitoon_petroleum/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../../Features/Other/utils.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../bloc/transfer_bloc.dart';
import '../model/transfer_model.dart';

class BulkTransferScreen extends StatefulWidget {
  const BulkTransferScreen({super.key});

  @override
  State<BulkTransferScreen> createState() => _BulkTransferScreenState();
}

class _BulkTransferScreenState extends State<BulkTransferScreen> {
  final Map<int, List<TextEditingController>> _rowControllers = {};
  final Map<int, FocusNode> _rowFocusNodes = {};
  final TextEditingController _currencyController = TextEditingController(text: 'USD');
  String? userName;
  String? _selectedCurrency;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    context.read<TransferBloc>().add(InitializeTransferEvent());
    _selectedCurrency = 'USD';
  }

  void _clearAllControllersAndFocus() {
    for (final controllers in _rowControllers.values) {
      for (final controller in controllers) {
        controller.clear();
      }
    }
    for (final node in _rowFocusNodes.values) {
      node.unfocus();
    }
    _selectedCurrency = 'USD';
    _currencyController.text = 'USD';
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final controllers in _rowControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    _rowControllers.clear();

    for (final node in _rowFocusNodes.values) {
      node.dispose();
    }
    _rowFocusNodes.clear();
    _currencyController.dispose();
    super.dispose();
  }

  void _ensureControllerForEntry(TransferEntry entry) {
    if (!_rowControllers.containsKey(entry.rowId)) {
      _rowControllers[entry.rowId] = [
        TextEditingController(text: entry.accountName ?? ''),
        TextEditingController(text: entry.debit > 0 ? entry.debit.toAmount() : ''),
        TextEditingController(text: entry.credit > 0 ? entry.credit.toAmount() : ''),
        TextEditingController(text: entry.narration),
      ];
      if (!_rowFocusNodes.containsKey(entry.rowId)) {
        _rowFocusNodes[entry.rowId] = FocusNode();
      }
    }
  }

  String? baseCurrency;
  @override
  Widget build(BuildContext context) {
    final comState = context.watch<CompanyProfileBloc>().state;
    if(comState is CompanyProfileLoadedState){
      baseCurrency = comState.company.comLocalCcy;
    }
    return ZFormDialog(
      width: MediaQuery.of(context).size.width * .7,
      icon: Icons.bubble_chart_outlined,
      isActionTrue: false,
      onAction: null,
      title: AppLocalizations.of(context)!.bulkTransfer,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, auth) {
          if (auth is AuthenticatedState) {
            userName = auth.loginData.usrName;
          }

          return BlocConsumer<TransferBloc, TransferState>(
            listener: (context, state) {
              if (state is TransferSavedState && state.success) {
                Utils.showOverlayMessage(context, message: state.reference, isError: false);
                _clearAllControllersAndFocus();
              } else if (state is TransferApiErrorState) {
                Utils.showOverlayMessage(context, message: state.error, isError: true);
              }
            },
            builder: (context, state) {
              if (_isDisposed) return const SizedBox.shrink();

              if (state is TransferLoadedState || state is TransferSavingState) {
                final entries = (state is TransferLoadedState ? state.entries : (state as TransferSavingState).entries);
                for (final entry in entries) {
                  _ensureControllerForEntry(entry);
                }

                return _buildLoadedState(context, state is TransferLoadedState ? state : TransferLoadedState(
                  entries: (state as TransferSavingState).entries,
                  totalDebit: state.entries.fold(0.0, (sum, e) => sum + e.debit),
                  totalCredit: state.entries.fold(0.0, (sum, e) => sum + e.credit),
                ));
              } else if (state is TransferApiErrorState) {
                return _buildErrorState(context, state);
              } else if (state is TransferErrorState) {
                return Center(child: Text(state.error, style: TextStyle(color: Theme.of(context).colorScheme.error)));
              }

              return const Center(child: CircularProgressIndicator());
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, TransferLoadedState state) {
    final isEmpty = state.entries.isEmpty;
    bool hasCurrencyMismatch = false;
    if (!isEmpty && _selectedCurrency != null) {
      for (final entry in state.entries) {
        if (entry.currency != null && entry.currency!.isNotEmpty && entry.currency != _selectedCurrency) {
          hasCurrencyMismatch = true;
          break;
        }
      }
    }

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CurrencyDropdown(
                      height: 40,
                      title: '',
                      initiallySelectedSingle: CurrenciesModel(ccyCode: _selectedCurrency),
                      isMulti: false,
                      onMultiChanged: (_) {},
                      onSingleChanged: (e) {
                        setState(() {
                          _selectedCurrency = e?.ccyCode ?? baseCurrency;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    height: 40,
                    icon: Icons.add,
                    onPressed: () {
                      context.read<TransferBloc>().add(AddTransferEntryEvent());
                    },
                    width: 120,
                    label: Text(AppLocalizations.of(context)!.addEntry),
                  ),
                  const SizedBox(width: 8),
                  _buildSaveButton(context, state, hasCurrencyMismatch),
                ],
              ),
              if (isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Add entries to begin transaction',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (!isEmpty && hasCurrencyMismatch)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.transactionMismatchCcyAlert,
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (!isEmpty && (state.totalDebit - state.totalCredit).abs() > 0.01)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.debitNoEqualCredit,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!isEmpty) ...[
          const SizedBox(height: 8),
          _TransferHeaderRow(currencySymbol: _selectedCurrency ?? baseCurrency??""),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                final controllers = _rowControllers[entry.rowId];
                final focusNode = _rowFocusNodes[entry.rowId];
                if (controllers == null || focusNode == null) return const SizedBox.shrink();

                return _TransferEntryRow(
                  key: ValueKey(entry.rowId),
                  entry: entry,
                  index: index,
                  focusNode: focusNode,
                  accountController: controllers[0],
                  debitController: controllers[1],
                  creditController: controllers[2],
                  narrationController: controllers[3],
                  selectedCurrency: _selectedCurrency,
                  onChanged: (updatedEntry) {
                    if (_isDisposed) return;
                    context.read<TransferBloc>().add(
                      UpdateTransferEntryEvent(
                        id: updatedEntry.rowId,
                        accountNumber: updatedEntry.accountNumber,
                        accountName: updatedEntry.accountName,
                        currency: updatedEntry.currency,
                        debit: updatedEntry.debit,
                        credit: updatedEntry.credit,
                        narration: updatedEntry.narration,
                      ),
                    );
                  },
                  onRemove: (id) {
                    if (_isDisposed) return;
                    context.read<TransferBloc>().add(RemoveTransferEntryEvent(id));
                  },
                );
              },
            ),
          ),
          _TransferSummary(
            totalDebit: state.totalDebit,
            totalCredit: state.totalCredit,
            currencySymbol: _selectedCurrency ?? baseCurrency ?? "",
          ),
        ] else ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.outline.withValues(alpha: .5)),
                  const SizedBox(height: 16),
                  Text('No entries added', style: TextStyle(color: Theme.of(context).colorScheme.outline.withValues(alpha: .7), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Click "+ Add Entry" to start', style: TextStyle(color: Theme.of(context).colorScheme.outline.withValues(alpha: .5), fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, TransferApiErrorState state) {
    // Show error but keep entries for editing
    return Column(
      children: [
        // Error Banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.transactionFailedTitle,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.error,
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  context.read<TransferBloc>().add(ClearApiErrorEvent());
                },
              ),
            ],
          ),
        ),

        // Show the entries (reuse the loaded state builder with error state entries)
        Expanded(
          child: _buildLoadedState(
            context,
            TransferLoadedState(
              entries: state.entries,
              totalDebit: state.entries.fold(0.0, (sum, entry) => sum + entry.debit),
              totalCredit: state.entries.fold(0.0, (sum, entry) => sum + entry.credit),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, TransferLoadedState state, bool hasCurrencyMismatch) {
    final isBalanced = (state.totalDebit - state.totalCredit).abs() < 0.01;
    final hasEntries = state.entries.isNotEmpty;
    final allAccountsValid = state.entries.every((entry) => entry.accountNumber != null);

    // Check that at least one entry has non-zero amount (debit or credit > 0)
    final hasNonZeroAmount = state.entries.any((entry) =>
    entry.debit > 0 || entry.credit > 0
    );

    // Also check that debits and credits are not mixed in the same entry
    final hasValidAmounts = state.entries.every((entry) =>
    (entry.debit > 0 && entry.credit == 0) || // Either debit only
        (entry.credit > 0 && entry.debit == 0) || // Or credit only
        (entry.debit == 0 && entry.credit == 0)   // Or both zero (if you allow zero amounts)
    );

    // Check that there are no entries with both debit and credit > 0
    final hasNoMixedEntries = state.entries.every((entry) =>
    !(entry.debit > 0 && entry.credit > 0)
    );

    final isValid = isBalanced &&
        hasEntries &&
        allAccountsValid &&
        hasNonZeroAmount &&
        hasValidAmounts &&
        hasNoMixedEntries &&
        !hasCurrencyMismatch;

    return BlocBuilder<TransferBloc, TransferState>(
      builder: (context, blocState) {
        final isSaving = blocState is TransferSavingState;

        return ZOutlineButton(
          height: 40,
          icon: isSaving ? null : Icons.cached_rounded,
          onPressed: !isValid || userName == null || isSaving
              ? null
              : () async {
            final completer = Completer<String>();
            context.read<TransferBloc>().add(
              SaveTransferEvent(
                userName: userName!,
                completer: completer,
              ),
            );
            try {
              await completer.future;
            } catch (e) {
              // Error is handled in listener via TransferApiErrorState
            }
          },
          width: 120,
          label: isSaving
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
              : Text(AppLocalizations.of(context)!.create),
        );
      },
    );
  }
}

class _TransferHeaderRow extends StatelessWidget {
  final String currencySymbol;

  const _TransferHeaderRow({
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 25,
            child: Text(
              '#',
              style: TextStyle(
                color: color.surface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppLocalizations.of(context)!.accounts,
              style: TextStyle(
                color: color.surface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              AppLocalizations.of(context)!.ccyCode,
              style: TextStyle(
                color: color.surface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              '${AppLocalizations.of(context)!.debitTitle} ($currencySymbol)',
              style: TextStyle(
                color: color.surface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              '${AppLocalizations.of(context)!.creditTitle} ($currencySymbol)',
              style: TextStyle(
                color: color.surface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppLocalizations.of(context)!.narration,
              style: TextStyle(
                color: color.surface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            child: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.surface,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferEntryRow extends StatefulWidget {
  final TransferEntry entry;
  final int index;
  final FocusNode focusNode;
  final TextEditingController accountController;
  final TextEditingController debitController;
  final TextEditingController creditController;
  final TextEditingController narrationController;
  final String? selectedCurrency;
  final Function(TransferEntry) onChanged;
  final Function(int) onRemove;

  const _TransferEntryRow({
    super.key,
    required this.entry,
    required this.index,
    required this.focusNode,
    required this.accountController,
    required this.debitController,
    required this.creditController,
    required this.narrationController,
    this.selectedCurrency,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_TransferEntryRow> createState() => __TransferEntryRowState();
}

class __TransferEntryRowState extends State<_TransferEntryRow> {
  String? baseCurrency;
  String? currentLocale;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final entryCurrency = widget.entry.currency ?? widget.selectedCurrency ?? baseCurrency;
    final hasCurrencyMismatch = widget.selectedCurrency != null && entryCurrency != widget.selectedCurrency;
    currentLocale = context.watch<LocalizationBloc>().state.countryCode;
    final comState = context.watch<CompanyProfileBloc>().state;
    if(comState is CompanyProfileLoadedState){
      baseCurrency = comState.company.comLocalCcy;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: color.outline.withValues(alpha: .1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        spacing: 8,
        children: [
          // Improved Index with Circle Design
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  color: color.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Account Selection
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                key: ValueKey('account_${widget.entry.rowId}'),
                showAllOnFocus: true,
                controller: widget.accountController,
                title: '',
                hintText: AppLocalizations.of(context)!.accounts,
                isRequired: true,
                bloc: context.read<AccountsBloc>(),
                fetchAllFunction: (bloc) => bloc.add(LoadAccountsFilterEvent(include: '1,2,3,4,5,6,7,8,9,10,11,12', exclude: "10101010,10101011",ccy: widget.selectedCurrency ?? baseCurrency,)),
                searchFunction: (bloc, query) => bloc.add(LoadAccountsFilterEvent(input: query, include: '1,2,3,4,5,6,7,8,9,10,11,12', exclude: "10101010,10101011",ccy: widget.selectedCurrency ?? baseCurrency)),
                itemBuilder: (context, account) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.accName ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              account.accNumber.toString(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: account.actCurrency == widget.selectedCurrency
                              ? color.primary.withValues(alpha: .1)
                              : color.error.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          account.actCurrency ?? baseCurrency ?? "",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: account.actCurrency == widget.selectedCurrency
                                ? color.primary
                                : color.error,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                itemToString: (account) => "${account.accNumber} | ${account.accName}",
                stateToLoading: (state) => state is AccountLoadingState,
                loadingBuilder: (context) => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1),
                ),
                stateToItems: (state) {
                  if (state is AccountLoadedState) return state.accounts;
                  return [];
                },
                onSelected: (account) {
                  widget.accountController.text = account.accName ?? '';
                  widget.onChanged(widget.entry.copyWith(
                    accountNumber: account.accNumber,
                    accountName: account.accName,
                    currency: account.actCurrency,
                  ));
                },
                noResultsText: 'No account found',
                showClearButton: true,
              ),
            ),
          ),

          Container(
            width: 55,
            height: 38,
            decoration: BoxDecoration(
              color: hasCurrencyMismatch
                  ? color.error.withValues(alpha: .05)
                  : color.primary.withValues(alpha: .05),
              border: Border.all(
                color: hasCurrencyMismatch
                    ? color.error.withValues(alpha: .3)
                    : color.outline.withValues(alpha: .3),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                entryCurrency ?? baseCurrency ?? "",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasCurrencyMismatch ? color.error : color.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Debit
          SizedBox(
            width: 150,
            height: 40,
            child: TextField(
              key: ValueKey('debit_${widget.entry.rowId}'),
              controller: widget.debitController,
              style: const TextStyle(fontSize: 14),
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                SmartThousandsDecimalFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: color.outline.withValues(alpha: .4)),
                prefixIconConstraints: const BoxConstraints(minWidth: 30),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.outline.withValues(alpha: .3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.outline.withValues(alpha: .3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.primary, width: 1.5),
                ),
              ),
              onChanged: (value) {
                final debit = value.cleanAmount.toDoubleAmount();
                if (debit > 0) {
                  widget.creditController.clear();
                }
                widget.onChanged(widget.entry.copyWith(debit: debit, credit: 0.0));
              },
              onEditingComplete: () {
                final debit = widget.debitController.text.cleanAmount.toDoubleAmount();
                if (debit > 0) {
                  widget.debitController.text = debit.toAmount();
                  widget.creditController.clear();
                }
                widget.onChanged(widget.entry.copyWith(debit: debit, credit: 0.0));
              },
            ),
          ),

          // Credit
          SizedBox(
            width: 150,
            height: 40,
            child: TextFormField(
              key: ValueKey('credit_${widget.entry.rowId}'),
              controller: widget.creditController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                SmartThousandsDecimalFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: color.outline.withValues(alpha: .4)),
                prefixIconConstraints: const BoxConstraints(minWidth: 30),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.outline.withValues(alpha: .3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.outline.withValues(alpha: .3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.primary, width: 1.5),
                ),
              ),
              onChanged: (value) {
                final credit = value.cleanAmount.toDoubleAmount();
                if (credit > 0) {
                  widget.debitController.clear();
                }
                widget.onChanged(widget.entry.copyWith(credit: credit, debit: 0.0));
              },
              onEditingComplete: () {
                final credit = widget.creditController.text.cleanAmount.toDoubleAmount();
                if (credit > 0) {
                  widget.creditController.text = credit.toAmount();
                  widget.debitController.clear();
                }
                widget.onChanged(widget.entry.copyWith(credit: credit, debit: 0.0));
              },
            ),
          ),

          // Narration
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: TextField(
                key: ValueKey('narration_${widget.entry.rowId}'),
                controller: widget.narrationController,
                textInputAction: TextInputAction.done,
                maxLines: 1,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.narration,
                  hintStyle: TextStyle(color: color.outline.withValues(alpha: .4)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: color.outline.withValues(alpha: .3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: color.outline.withValues(alpha: .3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: color.primary, width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  widget.onChanged(widget.entry.copyWith(narration: value));
                },
              ),
            ),
          ),

          // Improved Delete Button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.error.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: color.error,
              ),
              onPressed: () => widget.onRemove(widget.entry.rowId),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              tooltip: 'Remove entry',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TransferSummary extends StatelessWidget {
  final double totalDebit;
  final double totalCredit;
  final String currencySymbol;

  const _TransferSummary({
    required this.totalDebit,
    required this.totalCredit,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final difference = totalDebit - totalCredit;
    final isBalanced = difference.abs() < 0.01;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isBalanced ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalDebit,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: .6),
                    ),
                  ),
                  Text(
                    '$currencySymbol ${totalDebit.toAmount()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalCredit,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: .6),
                    ),
                  ),
                  Text(
                    '$currencySymbol ${totalCredit.toAmount()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.difference,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: .6),
                    ),
                  ),
                  Text(
                    '$currencySymbol ${difference.abs().toAmount()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isBalanced ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isBalanced) const SizedBox(height: 8),
          if (!isBalanced)
            Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.debitNoEqualCredit,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}