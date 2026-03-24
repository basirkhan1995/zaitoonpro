import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../../Features/Other/utils.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import '../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../bloc/fx_bloc.dart';
import '../model/fx_model.dart';

class FxTransactionView extends StatelessWidget {
  const FxTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(), tablet: _Desktop(), desktop: _Desktop());
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}


class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final Map<int, List<TextEditingController>> _debitControllers = {};
  final Map<int, List<TextEditingController>> _creditControllers = {};
  final TextEditingController _narrationController = TextEditingController();
  final Map<int, FocusNode> _debitFocusNodes = {};
  final Map<int, FocusNode> _creditFocusNodes = {};

  String? userName;
  String? _baseCurrency;
  final Map<String, double> _exchangeRates = {};
  final Map<String, double> _originalExchangeRates = {};
  bool _isDisposed = false;

  // Track which rate requests are for which currencies
  final Map<String, Completer<double>> _pendingRateRequests = {};
  final Map<String, String> _rateCurrencyPairs = {};

  @override
  void initState() {
    super.initState();
    context.read<FxBloc>().add(InitializeFxEvent());

    // Set default base currency from company profile
    final comState = context.read<CompanyProfileBloc>().state;
    if (comState is CompanyProfileLoadedState) {
      _baseCurrency = comState.company.comLocalCcy;
      if (_baseCurrency != null) {
        context.read<FxBloc>().add(UpdateBaseCurrencyEvent(_baseCurrency));
      }
    }
  }
  @override
  void dispose() {
    _isDisposed = true;
    _clearAllControllers();
    _narrationController.dispose();
    super.dispose();
  }

  Future<double> _fetchExchangeRate(String fromCcy, String toCcy) async {
    if (_baseCurrency == null) return 1.0;

    final key = '$fromCcy:$toCcy';
    // Don't fetch rate if same currency
    if (fromCcy == toCcy) {
      _exchangeRates[key] = 1.0;
      _originalExchangeRates[key] = 1.0;
      return 1.0;
    }

    // Check if rate is already cached
    if (_exchangeRates.containsKey(key)) {
      return _exchangeRates[key]!;
    }

    // Check if request is already pending
    if (_pendingRateRequests.containsKey(key)) {
      return await _pendingRateRequests[key]!.future;
    }

    // Create new completer for this request
    final completer = Completer<double>();
    _pendingRateRequests[key] = completer;

    // Store currency pair for this request
    _rateCurrencyPairs[key] = '$fromCcy:$toCcy';

    final xBloc = context.read<ExchangeRateBloc>();
    xBloc.add(
      GetExchangeRateEvent(
        fromCcy: fromCcy,
        toCcy: toCcy,
      ),
    );

    // Wait for response (will be completed in listener)
    final rate = await completer.future;
    _pendingRateRequests.remove(key);
    _rateCurrencyPairs.remove(key);

    return rate;
  }

  void _handleExchangeRateResponse(String fromCcy, String toCcy, double rate) {
    final key = '$fromCcy:$toCcy';
    _exchangeRates[key] = rate;
    _originalExchangeRates[key] = rate; // Store as original rate

    // Also store the reverse rate
    final reverseKey = '$toCcy:$fromCcy';
    if (rate > 0) {
      _exchangeRates[reverseKey] = 1.0 / rate;
      _originalExchangeRates[reverseKey] = 1.0 / rate;
    }

    // Complete pending request if exists
    if (_pendingRateRequests.containsKey(key)) {
      _pendingRateRequests[key]!.complete(rate);
    }

    // Update UI
    if (mounted) {
      setState(() {});
    }
  }

  void _updateExchangeRate(String fromCcy, String toCcy, double newRate) {
    final key = '$fromCcy:$toCcy';
    _exchangeRates[key] = newRate;

    // Update UI
    if (mounted) {
      setState(() {});
    }
  }

  double _getExchangeRate(String fromCcy, String toCcy) {
    if (fromCcy == toCcy) return 1.0;
    final key = '$fromCcy:$toCcy';
    return _exchangeRates[key] ?? 1.0;
  }

  double _convertToBase(double amount, String currency) {
    if (_baseCurrency == null || currency == _baseCurrency) return amount;
    final rate = _getExchangeRate(currency, _baseCurrency!);
    return amount * rate;
  }

  void _clearAllControllers() {
    for (final controllers in _debitControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final controllers in _creditControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final node in _debitFocusNodes.values) {
      node.dispose();
    }
    for (final node in _creditFocusNodes.values) {
      node.dispose();
    }

    _debitControllers.clear();
    _creditControllers.clear();
    _debitFocusNodes.clear();
    _creditFocusNodes.clear();

    _narrationController.clear();
    _exchangeRates.clear();
    _originalExchangeRates.clear();
    _pendingRateRequests.clear();
    _rateCurrencyPairs.clear();
  }

  void _ensureControllerForEntry(TransferEntry entry, bool isDebit) {
    final map = isDebit ? _debitControllers : _creditControllers;
    final focusMap = isDebit ? _debitFocusNodes : _creditFocusNodes;

    if (!map.containsKey(entry.rowId)) {
      map[entry.rowId] = [
        TextEditingController(text: entry.accountName ?? ''),
        TextEditingController(text: entry.amount.toAmount()),
      ];

      if (!focusMap.containsKey(entry.rowId)) {
        focusMap[entry.rowId] = FocusNode();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocListener<ExchangeRateBloc, ExchangeRateState>(
      listener: (context, state) {
        if (state is ExchangeRateLoadedState && state.rate != null) {
          final rate = double.tryParse(state.rate ?? "1.0") ?? 1.0;

          // We need to know which currencies this rate is for
          // Since your state doesn't include from/to, we'll check pending requests
          // This is a workaround - ideally ExchangeRateLoadedState should have fromCcy/toCcy

          // Find which pending request this rate belongs to
          for (final key in _pendingRateRequests.keys.toList()) {
            if (_rateCurrencyPairs.containsKey(key)) {
              final currencies = _rateCurrencyPairs[key]!.split(':');
              if (currencies.length == 2) {
                final fromCcy = currencies[0];
                final toCcy = currencies[1];
                _handleExchangeRateResponse(fromCcy, toCcy, rate);
                break; // Assume first match is correct
              }
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(AppLocalizations.of(context)!.fxTransaction),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, auth) {
            if (auth is AuthenticatedState) {
              userName = auth.loginData.usrName;
            }

            return BlocConsumer<FxBloc, FxState>(
              listener: (context, state) {
                if (state is FxSavedState && state.success) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.reference,
                    isError: false,
                  );
                  _clearAllControllers();
                  context.read<FxBloc>().add(InitializeFxEvent());
                } else if (state is FxApiErrorState) {
                  Utils.showOverlayMessage(
                    context,
                    message: state.error,
                    isError: true,
                  );
                }
              },
              builder: (context, state) {
                if (_isDisposed) return const SizedBox.shrink();

                if (state is FxLoadedState || state is FxSavingState || state is FxApiErrorState) {
                  // These states all have the properties we need
                  final isSaving = state is FxSavingState;
                  final hasError = state is FxApiErrorState;

                  // Extract properties from state
                  String? baseCurrency;
                  String narration = '';
                  List<TransferEntry> debitEntries = [];
                  List<TransferEntry> creditEntries = [];
                  double totalDebitBase = 0.0;
                  double totalCreditBase = 0.0;

                  if (state is FxLoadedState) {
                    baseCurrency = state.baseCurrency;
                    narration = state.narration;
                    debitEntries = state.debitEntries;
                    creditEntries = state.creditEntries;
                    totalDebitBase = state.totalDebitBase;
                    totalCreditBase = state.totalCreditBase;
                  } else if (state is FxSavingState) {
                    baseCurrency = state.baseCurrency;
                    narration = state.narration;
                    debitEntries = state.debitEntries;
                    creditEntries = state.creditEntries;
                    totalDebitBase = state.totalDebitBase;
                    totalCreditBase = state.totalCreditBase;
                  } else if (state is FxApiErrorState) {
                    baseCurrency = state.baseCurrency;
                    narration = state.narration;
                    debitEntries = state.debitEntries;
                    creditEntries = state.creditEntries;
                    totalDebitBase = state.totalDebitBase;
                    totalCreditBase = state.totalCreditBase;
                  }

                  // Ensure controllers exist for all entries
                  for (final entry in debitEntries) {
                    _ensureControllerForEntry(entry, true);
                  }
                  for (final entry in creditEntries) {
                    _ensureControllerForEntry(entry, false);
                  }

                  // Update narration controller
                  if (_narrationController.text != narration) {
                    _narrationController.text = narration;
                  }

                  return _buildLoadedState(
                    context,
                    baseCurrency: baseCurrency,
                    narration: narration,
                    debitEntries: debitEntries,
                    creditEntries: creditEntries,
                    totalDebitBase: totalDebitBase,
                    totalCreditBase: totalCreditBase,
                    isSaving: isSaving,
                    hasError: hasError,
                    fxState: state,
                  );
                } else if (state is FxErrorState) {
                  return Center(
                    child: Text(
                      "${state.error}: (${state.accountNo})",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                } else if (state is FxSavedState) {
                  // After saving, show success message
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          tr.successTransactionMessage,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${tr.referenceNumber}: ${state.reference}',
                          style: TextStyle(color: color.outline),
                        ),
                        const SizedBox(height: 24),
                        ZOutlineButton(
                          width: 120,
                          onPressed: () {
                            context.read<FxBloc>().add(InitializeFxEvent());
                          },
                          label: Text(tr.newKeyword),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadedState(
      BuildContext context, {
        required String? baseCurrency,
        required String narration,
        required List<TransferEntry> debitEntries,
        required List<TransferEntry> creditEntries,
        required double totalDebitBase,
        required double totalCreditBase,
        required bool isSaving,
        required bool hasError,
        required FxState fxState,
      }) {
    final hasDebitEntries = debitEntries.isNotEmpty;
    final hasCreditEntries = creditEntries.isNotEmpty;
    final hasEntries = hasDebitEntries || hasCreditEntries;
    final tr = AppLocalizations.of(context)!;
    // Calculate totals in base currency - using current exchange rates
    double calculatedDebitBase = 0;
    for (final entry in debitEntries) {
      if (entry.currency != null && entry.amount > 0) {
        calculatedDebitBase += _convertToBase(entry.amount, entry.currency!);
      }
    }

    double calculatedCreditBase = 0;
    for (final entry in creditEntries) {
      if (entry.currency != null && entry.amount > 0) {
        calculatedCreditBase += _convertToBase(entry.amount, entry.currency!);
      }
    }

    final totalsMatch = (calculatedDebitBase - calculatedCreditBase).abs() < 0.01;
    final difference = (calculatedDebitBase - calculatedCreditBase).abs();

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (hasError && fxState is FxApiErrorState)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 15),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${fxState.error} ${fxState.accountNo}",
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: CurrencyDropdown(
                      height: 40,
                      title: tr.baseCurrency,
                      initiallySelectedSingle: CurrenciesModel(
                        ccyCode: baseCurrency,
                      ),
                      isMulti: false,
                      onMultiChanged: (_) {},
                      onSingleChanged: (e) {
                        final newCurrency = e?.ccyCode;
                        if (newCurrency != baseCurrency) {
                          _baseCurrency = newCurrency;
                          context.read<FxBloc>().add(UpdateBaseCurrencyEvent(newCurrency));

                          // Clear exchange rates when base currency changes
                          _exchangeRates.clear();
                          _originalExchangeRates.clear();
                          _pendingRateRequests.clear();
                          _rateCurrencyPairs.clear();

                          // Fetch new rates for all entries
                          for (final entry in debitEntries) {
                            if (entry.currency != null && entry.currency != newCurrency) {
                              _fetchExchangeRate(entry.currency!, newCurrency!);
                            }
                          }
                          for (final entry in creditEntries) {
                            if (entry.currency != null && entry.currency != newCurrency) {
                              _fetchExchangeRate(entry.currency!, newCurrency!);
                            }
                          }

                          // Update UI
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    flex: 6,
                    child: ZTextFieldEntitled(
                      title: AppLocalizations.of(context)!.narration,
                      controller: _narrationController,
                      onChanged: (value) {
                        context.read<FxBloc>().add(UpdateNarrationEvent(value));
                      },
                    ),
                  ),
                  const SizedBox(width: 5),
                  _buildSaveButton(
                    context,
                    baseCurrency: baseCurrency,
                    debitEntries: debitEntries,
                    creditEntries: creditEntries,
                    totalsMatch: totalsMatch,
                    isSaving: isSaving,
                  ),
                ],
              ),

              // Validation message
              if (!totalsMatch && hasEntries)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${tr.debitNotEqualBaseCurrency} '
                              '${tr.difference}: ${baseCurrency ?? ''} ${difference.toAmount()}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Debit and Credit Sections
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Debit Section
                Flexible(
                  child: _buildSideSection(
                    context,
                    title: AppLocalizations.of(context)!.debitSide,
                    entries: debitEntries,
                    isDebit: true,
                    totalAmount: debitEntries.fold(0.0, (sum, entry) => sum + entry.amount),
                    totalBase: calculatedDebitBase,
                    baseCurrency: baseCurrency,
                  ),
                ),

                const SizedBox(height: 10),

                // Credit Section
                Flexible(
                  child: _buildSideSection(
                    context,
                    title: AppLocalizations.of(context)!.creditSide,
                    entries: creditEntries,
                    isDebit: false,
                    totalAmount: creditEntries.fold(0.0, (sum, entry) => sum + entry.amount),
                    totalBase: calculatedCreditBase,
                    baseCurrency: baseCurrency,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Summary Section
        if (hasEntries)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildSummarySection(
              context,
              totalDebitBase: calculatedDebitBase,
              totalCreditBase: calculatedCreditBase,
              totalsMatch: totalsMatch,
              difference: difference,
              baseCurrency: baseCurrency,
            ),
          ),
      ],
    );
  }

  Widget _buildSideSection(
      BuildContext context, {
        required String title,
        required List<TransferEntry> entries,
        required bool isDebit,
        required double totalAmount,
        required double totalBase,
        required String? baseCurrency,
      }) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.outline.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDebit ? Theme.of(context).colorScheme.primary.withValues(alpha: .08) : Colors.green.shade50,
              border: Border(bottom: BorderSide(color: color.outline.withValues(alpha: .3))),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDebit ? color.primary.withValues(alpha: .8) : Colors.green.shade800,
                  ),
                ),
                const Spacer(),
                ZOutlineButton(
                  height: 33,
                  width: 130,
                  icon: Icons.add,
                  onPressed: () {
                    context.read<FxBloc>().add(AddFxEntryEvent(isDebit: isDebit));
                  },
                  label: Text(tr.addEntry),
                ),
              ],
            ),
          ),

          // Table Header
          _TableHeaderRow(isDebit: isDebit, baseCurrency: baseCurrency),

          // Entries
          Expanded(
            child: entries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: color.outline.withValues(alpha: .4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No entries',
                    style: TextStyle(color: color.outline.withValues(alpha: .7)),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final controllers = (isDebit ? _debitControllers : _creditControllers)[entry.rowId];
                final focusNode = (isDebit ? _debitFocusNodes : _creditFocusNodes)[entry.rowId];

                if (controllers == null || focusNode == null) {
                  return const SizedBox.shrink();
                }

                // Get exchange rate for this entry
                double exchangeRate = 1.0;
                if (entry.currency != null && baseCurrency != null && entry.currency != baseCurrency) {
                  final key = '${entry.currency}:$baseCurrency';
                  exchangeRate = _exchangeRates[key] ?? 1.0;
                }
                return _EntryRow(
                  entry: entry,
                  index: index,
                  isDebit: isDebit,
                  baseCurrency: baseCurrency,
                  accountController: controllers[0],
                  amountController: controllers[1],
                  focusNode: focusNode,
                  exchangeRates: _exchangeRates,
                  originalExchangeRates: _originalExchangeRates,
                  fetchExchangeRate: _fetchExchangeRate,
                  onAccountSelected: (account) {
                    context.read<FxBloc>().add(UpdateFxEntryEvent(
                      id: entry.rowId,
                      isDebit: isDebit,
                      accountNumber: account.accNumber,
                      accountName: account.accName,
                      currency: account.actCurrency,
                    ));

                    // Fetch exchange rate if needed
                    if (baseCurrency != null && account.actCurrency != null && account.actCurrency != baseCurrency) {
                      _fetchExchangeRate(account.actCurrency!, baseCurrency);
                    }
                  },
                  onAmountChanged: (amount) {
                    // Calculate converted amount
                    final convertedAmount = (amount * exchangeRate).toStringAsFixed(2);

                    context.read<FxBloc>().add(UpdateFxEntryEvent(
                      id: entry.rowId,
                      isDebit: isDebit,
                      amount: amount,
                      exchangeRate: exchangeRate.toStringAsFixed(4),
                      convertedAmount: convertedAmount, // Pass calculated converted amount
                    ));

                    // Fetch exchange rate if needed
                    if (baseCurrency != null && entry.currency != null && entry.currency != baseCurrency) {
                      _fetchExchangeRate(entry.currency!, baseCurrency);
                    }

                    // Force UI update for totals
                    setState(() {});
                  },
                  onExchangeRateChanged: (fromCcy, toCcy, newRate) {
                    _updateExchangeRate(fromCcy, toCcy, newRate);

                    // Calculate converted amount with new rate
                    final convertedAmount = (entry.amount * newRate).toStringAsFixed(2);

                    // Update the bloc with new exchange rate and converted amount
                    context.read<FxBloc>().add(UpdateFxEntryEvent(
                      id: entry.rowId,
                      isDebit: isDebit,
                      exchangeRate: newRate.toStringAsFixed(4),
                      convertedAmount: convertedAmount,
                    ));

                    // Update UI
                    setState(() {});
                  },
                  onRemove: () {
                    context.read<FxBloc>().add(RemoveFxEntryEvent(entry.rowId, isDebit: isDebit));
                  },
                );
              },
            ),
          ),

          // Footer with totals
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: color.outline.withValues(alpha: .04),
              border: Border(top: BorderSide(color: color.outline.withValues(alpha: .3))),
            ),
            child: Row(
              children: [
                Text(
                  '${tr.totalTitle}:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${totalAmount.toAmount()} (${tr.various})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${baseCurrency ?? ''} ${totalBase.toAmount()} (${tr.baseTitle})',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.outline.withValues(alpha: .8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
      BuildContext context, {
        required double totalDebitBase,
        required double totalCreditBase,
        required bool totalsMatch,
        required double difference,
        required String? baseCurrency,
      }) {
    final tr = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(10),
      margin: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
      decoration: BoxDecoration(
        color: totalsMatch ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: totalsMatch ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            '${tr.totalDebit} (${tr.baseTitle})',
            '${baseCurrency ?? ''} ${totalDebitBase.toAmount()}',
            totalsMatch ? Colors.green.shade800 : Colors.red.shade800,
          ),
          _buildSummaryItem(
            '${tr.totalCredit} (${tr.baseTitle})',
            '${baseCurrency ?? ''} ${totalCreditBase.toAmount()}',
            totalsMatch ? Colors.green.shade800 : Colors.red.shade800,
          ),
          _buildSummaryItem(
            tr.status,
            totalsMatch ? tr.balanced : tr.unbalanced,
            totalsMatch ? Colors.green : Colors.red,
            isBold: true,
          ),
          if (!totalsMatch)
            _buildSummaryItem(
              tr.difference,
              '${baseCurrency ?? ''} ${difference.toAmount()}',
              Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(
      BuildContext context, {
        required String? baseCurrency,
        required List<TransferEntry> debitEntries,
        required List<TransferEntry> creditEntries,
        required bool totalsMatch,
        required bool isSaving,
      }) {
    final hasDebitEntries = debitEntries.isNotEmpty;
    final hasCreditEntries = creditEntries.isNotEmpty;
    final allAccountsValid = [...debitEntries, ...creditEntries]
        .every((entry) => entry.accountNumber != null);
    final hasNonZeroAmounts = [...debitEntries, ...creditEntries]
        .any((entry) => entry.amount > 0);
    final baseCurrencySelected = baseCurrency != null && baseCurrency.isNotEmpty;

    final isValid = baseCurrencySelected &&
        hasDebitEntries &&
        hasCreditEntries &&
        allAccountsValid &&
        hasNonZeroAmounts &&
        totalsMatch;

    return ZOutlineButton(
      height: 40,
      isActive: true,
      icon: isSaving? null : Icons.refresh,
      onPressed: !isValid || userName == null || isSaving
          ? null
          : () async {
        final completer = Completer<String>();
        context.read<FxBloc>().add(
          SaveFxEvent(
            userName: userName!,
            completer: completer,
          ),
        );
        try {
          await completer.future;
        } catch (e) {
          // Error is handled in listener
        }
      },
      width: 140,
      label: isSaving
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.surface,
        ),
      )
          : Text(AppLocalizations.of(context)!.create),
    );
  }
}



class _TableHeaderRow extends StatelessWidget {
  final bool isDebit;
  final String? baseCurrency;

  const _TableHeaderRow({required this.isDebit, required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final TextStyle? titleStyle = textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold);
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        color: color.outline.withValues(alpha: .03),
        border: Border(bottom: BorderSide(color: color.outline.withValues(alpha: .2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: const Text('#')),
          Expanded(child: Text(tr.accounts,style: titleStyle)),
          SizedBox(width: 80, child: Text(tr.ccyCode,style: titleStyle)),
          SizedBox(width: 130, child: Text(tr.amount,style: titleStyle)),
          SizedBox(width: 140, child: Text(tr.exchangeRate,style: titleStyle)),
          SizedBox(width: 140, child: Text('${tr.amountIn} ${baseCurrency ?? tr.baseTitle}',style: titleStyle)),
          SizedBox(width: 25, child: Text('')),
        ],
      ),
    );
  }
}

class _EntryRow extends StatefulWidget {
  final TransferEntry entry;
  final int index;
  final bool isDebit;
  final String? baseCurrency;
  final TextEditingController accountController;
  final TextEditingController amountController;
  final FocusNode focusNode;
  final Map<String, double> exchangeRates;
  final Map<String, double> originalExchangeRates;
  final Future<double> Function(String, String) fetchExchangeRate;
  final Function(AccountsModel) onAccountSelected;
  final Function(double) onAmountChanged;
  final Function(String, String, double) onExchangeRateChanged;
  final Function() onRemove;

  const _EntryRow({
    required this.entry,
    required this.index,
    required this.isDebit,
    required this.baseCurrency,
    required this.accountController,
    required this.amountController,
    required this.focusNode,
    required this.exchangeRates,
    required this.originalExchangeRates,
    required this.fetchExchangeRate,
    required this.onAccountSelected,
    required this.onAmountChanged,
    required this.onExchangeRateChanged,
    required this.onRemove,
  });

  @override
  State<_EntryRow> createState() => __EntryRowState();
}

class __EntryRowState extends State<_EntryRow> {
  String? baseCurrency;
  String? currentLocale;
  double _amountInBase = 0.0;
  double _exchangeRate = 1.0;
  bool _isLoadingRate = false;
  bool _isEditingRate = false;
  late TextEditingController _rateController;
  late FocusNode _rateFocusNode;
  double _originalFetchedRate = 1.0;
  bool _isGLAccount = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController();
    _rateFocusNode = FocusNode();
    _calculateAmountInBase();
    _fetchRateIfNeeded();
    _setupRateController();
    _checkIfGLAccount();
  }

  void _saveExchangeRate() {
    final newRate = double.tryParse(_rateController.text) ?? _originalFetchedRate;

    // Validate the rate change (within ±5% of original fetched rate)
    final minRate = _originalFetchedRate * 0.95;
    final maxRate = _originalFetchedRate * 1.05;

    if (newRate < minRate || newRate > maxRate) {
      // Show error and revert to original
      Utils.showOverlayMessage(
        context,
        message: AppLocalizations.of(context)!.exchangeRatePercentage,
        isError: true,
      );
      _rateController.text = _exchangeRate.toStringAsFixed(6);
    } else {
      _exchangeRate = newRate;

      // Update the exchange rates map
      if (widget.entry.currency != null && widget.baseCurrency != null) {
        final key = '${widget.entry.currency}:${widget.baseCurrency}';
        widget.exchangeRates[key] = _exchangeRate;

        // Notify parent about rate change
        widget.onExchangeRateChanged(widget.entry.currency!, widget.baseCurrency!, _exchangeRate);
      }
      _calculateAmountInBase();
    }

    setState(() {
      _isEditingRate = false;
    });
  }

  void _checkIfGLAccount() {
    // Only show dropdown if account has no currency
    // When row is first added (no account selected yet), don't show dropdown
    _isGLAccount = widget.entry.accountNumber != null &&
        (widget.entry.currency == null || widget.entry.currency!.isEmpty);
  }

  void _setupRateController() {
    _rateController.text = _exchangeRate.toStringAsFixed(6);
    _rateFocusNode.addListener(() {
      if (!_rateFocusNode.hasFocus && _isEditingRate) {
        _saveExchangeRate();
      }
    });
  }

  void _startEditingRate() {
    // Only allow editing if currencies are different
    if (widget.entry.currency != null &&
        widget.baseCurrency != null &&
        widget.entry.currency != widget.baseCurrency) {
      setState(() {
        _isEditingRate = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rateFocusNode.requestFocus();
      });
    }
  }

  void _fetchRateIfNeeded() async {
    if (widget.baseCurrency != null &&
        widget.entry.currency != null &&
        widget.entry.currency != widget.baseCurrency) {

      final key = '${widget.entry.currency}:${widget.baseCurrency}';

      // Get original rate for validation
      _originalFetchedRate = widget.originalExchangeRates[key] ?? _exchangeRate;

      if (!widget.exchangeRates.containsKey(key)) {
        setState(() {
          _isLoadingRate = true;
        });

        try {
          final rate = await widget.fetchExchangeRate(widget.entry.currency!, widget.baseCurrency!);
          // Update the rate
          widget.exchangeRates[key] = rate;
          _exchangeRate = rate;
          _originalFetchedRate = rate; // Store as original for validation
          _rateController.text = rate.toStringAsFixed(6);
          _calculateAmountInBase();
        } catch (e) {
          // Handle error
        } finally {
          if (mounted) {
            setState(() {
              _isLoadingRate = false;
            });
          }
        }
      } else {
        // Use existing rate
        _exchangeRate = widget.exchangeRates[key]!;
        _rateController.text = _exchangeRate.toStringAsFixed(6);
        // Get original rate for validation
        _originalFetchedRate = widget.originalExchangeRates[key] ?? _exchangeRate;
      }
    }
  }

  void _calculateAmountInBase() {
    if (widget.baseCurrency != null && widget.entry.currency != null && widget.entry.amount > 0) {
      if (widget.entry.currency == widget.baseCurrency) {
        _exchangeRate = 1.0;
        _amountInBase = widget.entry.amount;
      } else {
        // Get exchange rate from the map
        final key = '${widget.entry.currency}:${widget.baseCurrency}';
        _exchangeRate = widget.exchangeRates[key] ?? 1.0;
        _amountInBase = widget.entry.amount * _exchangeRate;
      }
      // Update controller if not editing
      if (!_isEditingRate) {
        _rateController.text = _exchangeRate.toStringAsFixed(6);
      }
    } else {
      _amountInBase = 0.0;
      _exchangeRate = 1.0;
      if (!_isEditingRate) {
        _rateController.text = '1.00';
      }
    }
    // Trigger UI update
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant _EntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if GL account status changed
    _checkIfGLAccount();

    if (widget.entry.currency != oldWidget.entry.currency ||
        widget.entry.amount != oldWidget.entry.amount ||
        widget.baseCurrency != oldWidget.baseCurrency ||
        widget.exchangeRates != oldWidget.exchangeRates) {
      _calculateAmountInBase();

      // Fetch rate if needed when currencies change
      if ((widget.entry.currency != oldWidget.entry.currency ||
          widget.baseCurrency != oldWidget.baseCurrency) &&
          widget.baseCurrency != null &&
          widget.entry.currency != null &&
          widget.entry.currency != widget.baseCurrency) {
        _fetchRateIfNeeded();
      }
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _rateFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    currentLocale = context.watch<LocalizationBloc>().state.countryCode;
    final color = Theme.of(context).colorScheme;
    final comState = context.watch<CompanyProfileBloc>().state;
    if (comState is CompanyProfileLoadedState) {
      baseCurrency = comState.company.comLocalCcy;
    }

    // Recalculate when widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAmountInBase();
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color.outline.withValues(alpha: .1))),
      ),
      child: Row(
        spacing: 5,
        children: [
          // Index
          SizedBox(
            width: 15,
            child: Text('${widget.index + 1}'),
          ),

          // Account Selection
          Expanded(
            child: SizedBox(
              height: 40,
              child: GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                controller: widget.accountController,
                title: '',
                hintText: AppLocalizations.of(context)!.accounts,
                isRequired: true,
                bloc: context.read<AccountsBloc>(),
                fetchAllFunction: (bloc) => bloc.add(
                  LoadAccountsFilterEvent(
                    include: '1,2,3,4,5,6,7,8,9,10,11,12',
                    exclude: "10101011",
                  ),
                ),
                searchFunction: (bloc, query) => bloc.add(
                  LoadAccountsFilterEvent(
                    input: query,
                    include: '1,2,3,4,5,6,7,8,9,10,11,12',
                    exclude: "10101011",
                  ),
                ),
                itemBuilder: (context, account) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${account.accNumber} | ${account.accName}",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.outline.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          account.actCurrency ?? "",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                itemToString: (account) =>
                "${account.accNumber} | ${account.accName}",
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
                  widget.onAccountSelected(account);
                  // Check if this is a GL account (no currency)
                  _isGLAccount = account.actCurrency == null || account.actCurrency!.isEmpty;
                  setState(() {});
                },
                noResultsText: 'No account found',
                showClearButton: true,
              ),
            ),
          ),

          // Currency Display - Only show dropdown for GL accounts (no currency)
          Container(
            width: 80,
            height: 40,
            decoration: !_isGLAccount? BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3))
            ) : null,
            child: _isGLAccount
                ? CurrencyDropdown(
              height: 40,
              flag: false,
              initiallySelectedSingle: CurrenciesModel(
                ccyCode: widget.entry.currency ?? "",
              ),
              isMulti: false,
              onMultiChanged: (_) {},
              onSingleChanged: (selectedCurrency) {
                if (selectedCurrency != null) {
                  context.read<FxBloc>().add(UpdateFxEntryEvent(
                      id: widget.entry.rowId,
                      isDebit: widget.isDebit,
                      currency: selectedCurrency.ccyCode,
                      exchangeRate: _exchangeRate.toStringAsFixed(4),
                      convertedAmount: _amountInBase.toAmount()
                  ));

                  // Update local state
                  _isGLAccount = false;

                  // Fetch exchange rate if needed
                  if (widget.baseCurrency != null && selectedCurrency.ccyCode != widget.baseCurrency) {
                    widget.fetchExchangeRate(selectedCurrency.ccyCode!, widget.baseCurrency!);
                  }

                  // Trigger recalculation
                  _calculateAmountInBase();
                }
              },
            )
                : Center(
              child: Text(
                widget.entry.currency ?? '---',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.entry.currency == widget.baseCurrency
                      ? Colors.green
                      : color.primary,
                ),
              ),
            ),
          ),

          // Amount Field
          SizedBox(
            width: 120,
            height: 40,
            child: ZTextFieldEntitled(
              title: '',
              controller: widget.amountController,
              focusNode: widget.focusNode,
              inputFormat: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                SmartThousandsDecimalFormatter(),
              ],
              onChanged: (value) {
                final amount = value.cleanAmount.toDoubleAmount();
                // Call onAmountChanged with amount
                widget.onAmountChanged(amount);
                _calculateAmountInBase();
              },
            ),
          ),

          // Editable Exchange Rate Display
          Container(
            width: 140,
            height: 40,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3))
            ),
            child: Center(
              child: _buildExchangeRateWidget(),
            ),
          ),

          // Amount in Base Currency - This should update when rate changes
          Container(
            width: 120,
            height: 40,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3))
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _amountInBase.toAmount(),
                  style: TextStyle(
                    color: color.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Remove Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3))
            ),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: widget.onRemove,
              iconSize: 20,
            ),
          ),

        ],
      ),
    );
  }
  Widget _buildExchangeRateWidget() {
    if (_isLoadingRate) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 1),
      );
    }

    if (widget.entry.currency != null && widget.baseCurrency != null) {
      if (widget.entry.currency == widget.baseCurrency) {
        return Text(
          AppLocalizations.of(context)!.sameCurrency,
          style: TextStyle(
            fontSize: 11,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        );
      } else {
        final isAdjusted = (_exchangeRate - _originalFetchedRate).abs() > 0.000001;

        return GestureDetector(
          onTap: () => _startEditingRate(),
          child: _isEditingRate
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: _rateController,
              focusNode: _rateFocusNode,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: AppLocalizations.of(context)!.enterRate,
              ),
              onEditingComplete: _saveExchangeRate,
              onSubmitted: (_) => _saveExchangeRate(),
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '1 ${widget.entry.currency} = ${_exchangeRate.toStringAsFixed(6)} ${widget.baseCurrency}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (isAdjusted)
                Text(
                  AppLocalizations.of(context)!.adjusted,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        );
      }
    } else {
      return const Text(
        '---',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      );
    }
  }
}