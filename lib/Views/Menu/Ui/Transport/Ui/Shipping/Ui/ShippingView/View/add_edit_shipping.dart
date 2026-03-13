import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/cover.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Localizations/Bloc/localizations_bloc.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/Accounts/bloc/accounts_bloc.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../../../../../../../../../Features/Date/zdate_picker.dart';
import '../../../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../../../Features/Widgets/stepper.dart';
import '../../../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../../Settings/Ui/Stock/Ui/Products/bloc/products_bloc.dart';
import '../../../../../../Settings/Ui/Stock/Ui/Products/model/product_model.dart';
import '../../../../../../Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../../../Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../Vehicles/bloc/vehicle_bloc.dart';
import '../../../../Vehicles/model/vehicle_model.dart';
import '../../../feature/unit_drop.dart';
import '../PDF/single_shp_print.dart';
import '../bloc/shipping_bloc.dart';
import '../model/shipping_model.dart';
import '../model/shp_details_model.dart';

class ShippingByIdView extends StatelessWidget {
  final int? shippingId;
  final int? perId;
  const ShippingByIdView({super.key, this.shippingId, this.perId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(shippingId: shippingId, perId: perId),
      desktop: _Desktop(shippingId: shippingId, perId: perId),
      tablet: _Tablet(shippingId: shippingId, perId: perId),
    );
  }
}

class _Desktop extends StatefulWidget {
  final int? shippingId;
  final int? perId;
  const _Desktop({this.shippingId, this.perId});

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {

  final shpFrom = TextEditingController();
  final shpTo = TextEditingController();
  final shippingRent = TextEditingController();
  final loadingSize = TextEditingController();
  final unloadingSize = TextEditingController();
  final customerCtrl = TextEditingController();
  final vehicleCtrl = TextEditingController();
  final productCtrl = TextEditingController();
  final remark = TextEditingController();
  final advanceAmount = TextEditingController();
  final accountController = TextEditingController();
  final expenseAmount = TextEditingController();
  final expenseNarration = TextEditingController();
  final paymentAccountCtrl = TextEditingController();
  final cashCtrl = TextEditingController();

  int? expenseAccNumber;
  String? currentLocale;
  int? customerId;
  int? productId;
  int? vehicleId;
  String? unit;
  int? shpStatus;
  int? paymentAccNumber;

  // Date variables
  String shpFromGregorian = DateTime.now().toFormattedDate();
  String shpToGregorian = DateTime.now().toFormattedDate();

  String? usrName;
  // State variables
  bool _isCashPaymentEnabled = false;
  bool _isAccountPaymentEnabled = false;
  bool _isEditingExistingPayment = false;
  String? _existingPaymentReference;

  final GlobalKey<FormState> orderFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> shippingFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> advanceFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> expenseFormKey = GlobalKey<FormState>();

  Expense? _selectedExpenseForEdit;
  bool _paymentFormValid = false;
  String? _paymentError;
  int _currentStep = 0;
  String? baseCurrency;

  String? _accountCurrency;
  bool? isAccountCcyEqualBase;

  String? cusAddress;
  String? cusPhone;
  String? cusEmail;

  String? proCode;
  String? proDetails;

  bool _isReloadingDueToUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<CompanyProfileBloc>().state;
      if (state is CompanyProfileLoadedState) {
        baseCurrency = state.company.comLocalCcy;
      }
      currentLocale = context.read<LocalizationBloc>().state.languageCode;
      if (widget.shippingId != null) {
        _currentStep = 0;
        context.read<ShippingBloc>().add(LoadShippingDetailEvent(widget.shippingId!));
      }
    });
  }

  @override
  void didUpdateWidget(covariant _Desktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shippingId != oldWidget.shippingId) {
      _currentStep = 0;
    }
  }

  void _prefillForm(ShippingDetailsModel shipping) {
    if (!mounted) return;

    if (!_isReloadingDueToUpdate) {
      setState(() {
        _paymentError = null;
        _isEditingExistingPayment = false;
        _existingPaymentReference = null;
      });
    }
    _clearAllControllers();

    customerId = shipping.perId;
    productId = shipping.proId;
    vehicleId = shipping.vclId;

    customerCtrl.text = shipping.customer ?? '';
    productCtrl.text = shipping.proName ?? '';
    vehicleCtrl.text = shipping.vehicle ?? '';

    shpFrom.text = shipping.shpFrom ?? '';
    shpTo.text = shipping.shpTo ?? '';

    shpFromGregorian = shipping.shpMovingDate?.toFormattedDate() ?? "";
    shpToGregorian = shipping.shpArriveDate?.toFormattedDate() ?? "";

    loadingSize.text = shipping.shpLoadSize ?? '';
    unloadingSize.text = shipping.shpUnloadSize ?? '';

    unit = shipping.shpUnit;
    shippingRent.text = shipping.shpRent ?? '';
    remark.text = shipping.shpRemark ?? '';
    shpStatus = shipping.shpStatus ?? 0;

    _prefillPaymentData(shipping);
  }

  void _prefillPaymentData(ShippingDetailsModel shipping) {
    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      _existingPaymentReference = payment.trdReference;

      double cashAmount = _parseAmount(payment.cashAmount);
      if (cashAmount > 0) {
        cashCtrl.text = cashAmount.toAmount();
        _isCashPaymentEnabled = true;
      }

      double cardAmount = _parseAmount(payment.cardAmount);
      if (cardAmount > 0) {
        _isAccountPaymentEnabled = true;
        paymentAccNumber = payment.accountCustomer;
        paymentAccountCtrl.text = payment.accName ?? "";
        if (payment.accountCustomer != null) {
          _loadAccountDetails(payment.accountCustomer!);
        }
      }

      _calculatePaymentTotals(shipping);
    }
  }

  void _loadAccountDetails(int accountNumber) {
    paymentAccNumber = accountNumber;
  }

  void _clearAllControllers() {
    productCtrl.clear();
    shpFrom.clear();
    shpTo.clear();
    shippingRent.clear();
    loadingSize.clear();
    unloadingSize.clear();
    customerCtrl.clear();
    vehicleCtrl.clear();
    remark.clear();
    advanceAmount.clear();
    accountController.clear();
    expenseAmount.clear();
    expenseNarration.clear();
    cashCtrl.clear();
    paymentAccountCtrl.clear();

    customerId = null;
    vehicleId = null;
    productId = null;
    unit = null;
    expenseAccNumber = null;
    paymentAccNumber = null;
    _selectedExpenseForEdit = null;
    _isCashPaymentEnabled = false;
    _isAccountPaymentEnabled = false;
    _isEditingExistingPayment = false;
    _existingPaymentReference = null;

    _paymentFormValid = false;
    _paymentError = null;
  }

  @override
  void dispose() {
    productCtrl.dispose();
    shpFrom.dispose();
    shpTo.dispose();
    shippingRent.dispose();
    loadingSize.dispose();
    unloadingSize.dispose();
    customerCtrl.dispose();
    vehicleCtrl.dispose();
    remark.dispose();
    advanceAmount.dispose();
    accountController.dispose();
    expenseAmount.dispose();
    expenseNarration.dispose();
    cashCtrl.dispose();
    paymentAccountCtrl.dispose();
    super.dispose();
  }

  double _parseAmount(String? amountString) {
    if (amountString == null || amountString.isEmpty) return 0.0;
    try {
      String cleaned = amountString.cleanAmount;
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  double _getControllerAmount(TextEditingController controller) {
    return _parseAmount(controller.text);
  }

  double _safeMax(double value, double minValue) => value > minValue ? value.toDouble() : minValue;

  void _validatePaymentAmounts(ShippingDetailsModel shipping) {
    final shippingTotal = _parseAmount(shipping.total);

    double existingPaid = 0.0;
    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
    }

    final remainingBalance = _safeMax(shippingTotal - existingPaid, 0);

    if (_isEditingExistingPayment && shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final currentPayment = _calculateCurrentPayment();

      if (currentPayment == shippingTotal && currentPayment > 0) {
        setState(() {
          _paymentFormValid = true;
          _paymentError = null;
        });
      } else if (currentPayment > 0 && currentPayment != shippingTotal) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = "Edited payment (${currentPayment.toAmount()}) must exactly match shipping total (${shippingTotal.toAmount()})";
        });
      } else {
        setState(() {
          _paymentFormValid = false;
          _paymentError = null;
        });
      }
    } else {
      if (remainingBalance == 0) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = null;
        });
        return;
      }

      double currentPayment = _calculateCurrentPayment();

      if (currentPayment == remainingBalance && currentPayment > 0) {
        setState(() {
          _paymentFormValid = true;
          _paymentError = null;
        });
      } else if (currentPayment > 0 && currentPayment != remainingBalance) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = "Payment amount (${currentPayment.toAmount()}) must exactly match remaining balance (${remainingBalance.toAmount()})";
        });
      } else {
        setState(() {
          _paymentFormValid = false;
          _paymentError = null;
        });
      }
    }
  }

  double _calculateCurrentPayment() {
    final cashAmount = _getControllerAmount(cashCtrl);
    double currentPayment = 0;

    if (_isCashPaymentEnabled && cashAmount > 0) {
      currentPayment += cashAmount;
    }

    if (_isAccountPaymentEnabled && paymentAccNumber != null) {
      if (_isEditingExistingPayment) {
        final shippingState = context.read<ShippingBloc>().state;
        if (shippingState is ShippingDetailLoadedState) {
          final shippingTotal = _parseAmount(shippingState.currentShipping?.total);
          final remainingForAccount = shippingTotal - cashAmount;
          if (remainingForAccount > 0) {
            currentPayment += remainingForAccount;
          }
        }
      } else {
        final shippingState = context.read<ShippingBloc>().state;
        if (shippingState is ShippingDetailLoadedState) {
          final shipping = shippingState.currentShipping!;
          final totalAmount = _parseAmount(shipping.total);
          double existingPaid = 0.0;
          if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
            final payment = shipping.pyment!.first;
            existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
          }
          final remainingBalance = _safeMax(totalAmount - existingPaid, 0);
          final availableForAccount = _safeMax(remainingBalance - cashAmount, 0);
          currentPayment += availableForAccount;
        }
      }
    }

    return currentPayment;
  }

  void _calculatePaymentTotals(ShippingDetailsModel shipping) {
    _validatePaymentAmounts(shipping);
  }


// Add this method to your _DesktopState class
  Future<void> _printShippingDetails(ShippingDetailsModel shippingDetails) async {
    // Get company info from CompanyProfileBloc
    final companyState = context.read<CompanyProfileBloc>().state;
    ReportModel company = ReportModel();

    if (companyState is CompanyProfileLoadedState) {
      company = ReportModel(
        comName: companyState.company.comName ?? '',
        comAddress: companyState.company.addName ?? '',
        compPhone: companyState.company.comPhone ?? '',
        comEmail: companyState.company.comEmail ?? '',
        statementDate: DateTime.now().toFullDateTime,
        comLogo: companyState.company.comLogo != null
            ? base64Decode(companyState.company.comLogo!)
            : null,
      );
    }

    // Get base currency from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      baseCurrency = authState.loginData.company?.comLocalCcy;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => PrintPreviewDialog<ShippingDetailsModel>(
          data: shippingDetails,
          company: company,
          buildPreview: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return ShippingDetailsPdfServices().printPreview(
              shippingDetails: data,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
            );
          },
          onPrint: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
            required selectedPrinter,
            required copies,
            required pages,
          }) {
            return ShippingDetailsPdfServices().printDocument(
              shippingDetails: data,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
              selectedPrinter: selectedPrinter,
              copies: copies,
              pages: pages,
            );
          },
          onSave: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return ShippingDetailsPdfServices().createDocument(
              shippingDetails: data,
              language: language,
              orientation: orientation,
              company: company,
              pageFormat: pageFormat,
            );
          },
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    usrName = login.usrName ?? "";

    return BlocConsumer<ShippingBloc, ShippingState>(
      listener: (context, state) {
        if (state is ShippingSuccessState) {
          final message = state.message.toLowerCase();

          if (message.contains('shipping') && !message.contains('expense') && !message.contains('payment')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
            });
          }

          if (message.contains('expense')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _clearExpenseForm();
              setState(() {
                _selectedExpenseForEdit = null;
              });
            });
          }

          if (message.contains('payment')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _clearPaymentError();
              _isEditingExistingPayment = false;
            });
          }

          if ((message.contains('payment') || message.contains('expense')) && widget.shippingId != null) {
            context.read<ShippingBloc>().add(LoadShippingDetailEvent(widget.shippingId!));
          }
        }

        if (state is ShippingDetailLoadedState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isReloadingDueToUpdate) {
              _prefillForm(state.currentShipping!);
            }
          });
        }

        if (state is ShippingErrorState) {
          Utils.showOverlayMessage(context, message: state.error, isError: true);
        }
      },
      builder: (context, blocState) {
        if (blocState is ShippingDetailLoadingState) {
          return _buildLoadingContent();
        }

        ShippingDetailsModel? currentShipping;

        if (blocState is ShippingSuccessState && blocState.currentShipping != null) {
          currentShipping = blocState.currentShipping;
        } else if (blocState is ShippingDetailLoadedState) {
          currentShipping = blocState.currentShipping;
        } else if (blocState is ShippingListLoadedState && blocState.currentShipping != null) {
          currentShipping = blocState.currentShipping;
        }

        if (currentShipping != null) {
          return _buildStepperWithData(currentShipping, tr, context);
        }

        if (widget.shippingId == null && blocState is! ShippingSuccessState) {
          return _buildNewShippingStepper(tr, context);
        }

        return _buildLoadingContent();
      },
    );
  }

  void _clearPaymentError() {
    setState(() {
      _paymentError = null;
    });
  }

  bool _canMarkAsDelivered(ShippingDetailsModel shipping) {
    final totalAmount = _parseAmount(shipping.total);
    double existingPaid = 0.0;

    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
    }

    return existingPaid >= totalAmount && existingPaid == totalAmount;
  }

  bool _paymentNeedsUpdate(ShippingDetailsModel shipping) {
    final totalAmount = _parseAmount(shipping.total);
    double existingPaid = 0.0;

    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
    }

    return existingPaid > 0 && existingPaid != totalAmount;
  }

  Widget _buildPaymentView(ShippingDetailsModel shipping) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    final totalAmount = _parseAmount(shipping.total);
    double existingPaid = 0.0;
    Pyment? existingPayment;

    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      existingPayment = shipping.pyment!.first;
      existingPaid = _parseAmount(existingPayment.cashAmount) + _parseAmount(existingPayment.cardAmount);
    }

    final remainingBalance = _safeMax(totalAmount - existingPaid, 0);
    final isFullyPaid = existingPaid >= totalAmount && existingPaid == totalAmount;
    final paymentNeedsUpdate = _paymentNeedsUpdate(shipping);

    final canEditPayment = shipping.shpStatus != 1;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.shippingCharges,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isFullyPaid ? tr.fullyPaid : "${tr.balance}: ${remainingBalance.toAmount()} $baseCurrency",
                      style: textTheme.bodyMedium?.copyWith(
                        color: isFullyPaid ? Colors.green : color.error,
                      ),
                    ),
                    if (paymentNeedsUpdate && existingPayment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "${AppLocalizations.of(context)!.paymentNeedsUpdateTitle} ${existingPaid.toAmount()}, ${AppLocalizations.of(context)!.requiredTitle}: ${totalAmount.toAmount()}",
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            _buildAmountSummaryCard(totalAmount, existingPaid, remainingBalance, tr, paymentNeedsUpdate),

            const SizedBox(height: 10),

            if (existingPayment != null && !canEditPayment) _buildPaymentHistory(existingPayment, tr),

            if (canEditPayment) ...[
              const SizedBox(height: 10),
              _buildPaymentForm(shipping, existingPayment: existingPayment),
              if (_paymentError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.errorContainer,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: color.error),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_paymentError!)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ZOutlineButton(
                    width: 130,
                    isActive: _paymentFormValid,
                    onPressed: _paymentFormValid
                        ? () => _processPayment(shipping, existingPayment != null)
                        : null,
                    label: Text(existingPayment != null ? tr.updatePayment : tr.addPayment),
                  ),
                ],
              ),
            ],

            if (canEditPayment && existingPayment != null) ...[
              const SizedBox(height: 20),
              _buildPaymentHistory(existingPayment, tr),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSummaryCard(double totalAmount, double paidAmount, double remaining, AppLocalizations tr, bool paymentNeedsUpdate) {
    return ZCover(
      radius: 8,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .03),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildAmountRow(tr.totalCharge, totalAmount, true),
            const Divider(),
            _buildAmountRow(tr.totalPaid, paidAmount, false, isPaid: true, needsUpdate: paymentNeedsUpdate && remaining > 0),
            const Divider(),
            _buildAmountRow(
              tr.remainingBalance,
              remaining,
              false,
              isRemaining: true,
              isZero: remaining == 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, bool isTotal, {bool isPaid = false, bool isRemaining = false, bool isZero = false, bool needsUpdate = false}) {
    final color = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: needsUpdate ? Colors.orange : null,
          ),
        ),
        Text(
          "${amount.toAmount()} $baseCurrency",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18 : 16,
            color: isTotal
                ? color.primary
                : isPaid
                ? (needsUpdate ? Colors.orange : Colors.green)
                : isRemaining
                ? (isZero ? Colors.green : color.error)
                : color.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(Pyment payment, AppLocalizations tr) {
    final textTheme = Theme.of(context).textTheme;
    final cashAmount = _parseAmount(payment.cashAmount);
    final cardAmount = _parseAmount(payment.cardAmount);

    return ZCover(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.paymentDetails,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Divider(),
            const SizedBox(height: 5),

            _buildPaymentDetailRow(
              tr.totalPaid,
              "${(cashAmount + cardAmount).toAmount()} $baseCurrency",
              Icons.check_circle,
              Theme.of(context).colorScheme.primary,
              isBold: true,
            ),

            if (payment.trdReference != null)
              Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: _buildPaymentDetailRow(
                  tr.transactionRef,
                  payment.trdReference!,
                  Icons.receipt,
                  Theme.of(context).colorScheme.outline,
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: _buildPaymentDetailRow(
                tr.cashPaid,
                payment.cashAmount?.toAmount() ?? "0.00",
                Icons.money,
                Theme.of(context).colorScheme.outline,
              ),
            ),
            if (payment.cardAmount != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: _buildPaymentDetailRow(
                  tr.accountPayment,
                  payment.cardAmount?.toAmount() ?? "0.00",
                  Icons.credit_card,
                  Theme.of(context).colorScheme.outline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: _buildPaymentDetailRow(
                  tr.accountDetails,
                  "${payment.accName} (${payment.accountCustomer.toString()})",
                  FontAwesomeIcons.buildingColumns,
                  Theme.of(context).colorScheme.outline,
                  iconSize: 17,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value, IconData icon, Color color, {bool isBold = false, double iconSize = 20}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(ShippingDetailsModel shipping, {Pyment? existingPayment}) {
    final tr = AppLocalizations.of(context)!;
    final totalAmount = _parseAmount(shipping.total);

    double existingPaid = 0.0;
    if (existingPayment != null) {
      existingPaid = _parseAmount(existingPayment.cashAmount) + _parseAmount(existingPayment.cardAmount);
    }

    final remainingBalance = _safeMax(totalAmount - existingPaid, 0);
    final isEditing = existingPayment != null;
    final cashAmount = _getControllerAmount(cashCtrl);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZCover(
            radius: 5,
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .8),
            child: Row(
              spacing: 8,
              children: [
                Icon(Icons.add_card_rounded, color: Theme.of(context).colorScheme.surface),
                Text(
                  isEditing ? tr.editPayment : tr.addPayment,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.surface),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCashPaymentSection(isEditing ? totalAmount : remainingBalance, tr),

              const SizedBox(height: 10),

              _buildAccountPaymentSection(isEditing ? totalAmount : remainingBalance, cashAmount, tr, isEditing),
            ],
          ),

          const SizedBox(height: 10),

          if (cashAmount > 0 || (_isAccountPaymentEnabled && paymentAccNumber != null))
            _buildPaymentDialogSummary(
              isEditing ? totalAmount : remainingBalance,
              cashAmount,
              tr,
              isEditing: isEditing,
              existingPayment: existingPayment,
            ),
        ],
      ),
    );
  }

  Widget _buildCashPaymentSection(double targetAmount, AppLocalizations tr) {
    return ZCover(
      padding: const EdgeInsets.all(8.0),
      radius: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _isCashPaymentEnabled,
                onChanged: (value) {
                  setState(() {
                    _isCashPaymentEnabled = value ?? false;
                    if (!_isCashPaymentEnabled) {
                      cashCtrl.clear();
                    }
                    _validatePaymentForm();
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr.cashPayment, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),

          if (_isCashPaymentEnabled) ...[
            const SizedBox(height: 12),
            ZTextFieldEntitled(
              controller: cashCtrl,
              title: tr.cashAmount,
              hint: tr.enterAmount,
              keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
              inputFormat: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                SmartThousandsDecimalFormatter(),
              ],
              validator: (value) {
                if (_isCashPaymentEnabled) {
                  final amount = _parseAmount(value);
                  if (amount <= 0) return tr.amountGreaterZero;
                  if (amount > targetAmount) {
                    return "${tr.cashAmountCannotExceed} ${targetAmount.toAmount()} $baseCurrency";
                  }
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _validatePaymentForm();
                });
              },
            ),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountPaymentSection(double targetAmount, double cashAmount, AppLocalizations tr, bool isEditing) {
    final availableForAccount = isEditing ? _safeMax(targetAmount - cashAmount, 0) : targetAmount - cashAmount;

    return ZCover(
      radius: 5,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _isAccountPaymentEnabled,
                onChanged: (value) {
                  setState(() {
                    _isAccountPaymentEnabled = value ?? false;
                    if (!_isAccountPaymentEnabled) {
                      paymentAccountCtrl.clear();
                      paymentAccNumber = null;
                    }
                    _validatePaymentForm();
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr.accountPayment, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),

          if (_isAccountPaymentEnabled) ...[
            const SizedBox(height: 12),

            if (availableForAccount > 0)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.amountToChargeAccount),
                    Text(
                      "${availableForAccount.toAmount()} $baseCurrency",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
              showAllOnFocus: true,
              controller: paymentAccountCtrl,
              title: tr.selectAccount,
              hintText: tr.selectReceivableAccount,
              isRequired: _isAccountPaymentEnabled,
              bloc: context.read<AccountsBloc>(),
              fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: widget.perId)),
              searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: widget.perId)),
              validator: (value) {
                if (_isAccountPaymentEnabled && paymentAccNumber == null) {
                  return tr.selectValidAccount;
                }
                return null;
              },
              itemBuilder: (context, account) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.accName ?? "",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                account.accNumber?.toString() ?? "",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${account.accAvailBalance?.toAmount()} ${account.actCurrency}",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
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
                if (state is AccountLoadedState) return state.accounts;
                return [];
              },
              onSelected: (value) {
                setState(() {
                  paymentAccNumber = value.accNumber;
                  paymentAccountCtrl.text = "${value.accNumber} | ${value.accName}";
                  _accountCurrency = value.actCurrency;
                  isAccountCcyEqualBase = _accountCurrency == value.actCurrency;
                  _validatePaymentForm();
                });
              },
              noResultsText: tr.noAccountsFound,
              showClearButton: true,
            ),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDialogSummary(double targetAmount, double cashAmount, AppLocalizations tr, {bool isEditing = false, Pyment? existingPayment}) {
    double accountAmount = 0.0;

    if (_isAccountPaymentEnabled && paymentAccNumber != null) {
      if (isEditing) {
        accountAmount = _safeMax(targetAmount - cashAmount, 0);
      } else {
        final shippingState = context.read<ShippingBloc>().state;
        if (shippingState is ShippingDetailLoadedState) {
          final shipping = shippingState.currentShipping!;
          final totalAmount = _parseAmount(shipping.total);
          double existingPaid = 0.0;
          if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
            final payment = shipping.pyment!.first;
            existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
          }
          final remainingBalance = _safeMax(totalAmount - existingPaid, 0);
          accountAmount = _safeMax(remainingBalance - cashAmount, 0);
        }
      }
    }

    final totalPayment = cashAmount + accountAmount;
    final isValid = isEditing ? totalPayment == targetAmount : totalPayment == targetAmount;

    return ZCover(
      radius: 8,
      color: isValid ? Theme.of(context).colorScheme.primary.withValues(alpha: .03) : Theme.of(context).colorScheme.error.withValues(alpha: .07),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? tr.editPayment : tr.paymentSummary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),

            if (cashAmount > 0) _buildSummaryRow(tr.cashPayment, cashAmount, Icons.money),

            if (accountAmount > 0) _buildSummaryRow(tr.accountPayment, accountAmount, Icons.account_circle),

            Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.totalPayment, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  "${totalPayment.toAmount()} $baseCurrency",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? tr.totalShippingRent : "${tr.targetAmount}:",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  "${targetAmount.toAmount()} $baseCurrency",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isValid ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),

            if (isValid)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? tr.paymentMatchesShippingTotal : tr.paymentMatches,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text("${amount.toAmount()} $baseCurrency"),
        ],
      ),
    );
  }

  void _validatePaymentForm() {
    final shippingState = context.read<ShippingBloc>().state;
    ShippingDetailsModel? currentShipping;

    if (shippingState is ShippingDetailLoadedState) {
      currentShipping = shippingState.currentShipping;
    } else if (shippingState is ShippingSuccessState) {
      currentShipping = shippingState.currentShipping;
    }

    if (currentShipping != null) {
      final cashAmount = _getControllerAmount(cashCtrl);
      final hasExistingPayment = currentShipping.pyment != null && currentShipping.pyment!.isNotEmpty;

      final isEditing = hasExistingPayment && (_isCashPaymentEnabled || _isAccountPaymentEnabled || cashCtrl.text.isNotEmpty);

      if (isEditing) {
        _isEditingExistingPayment = true;
      }

      if (!_isCashPaymentEnabled && !_isAccountPaymentEnabled) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = AppLocalizations.of(context)!.selectPaymentMethod;
        });
        return;
      }

      if (_isCashPaymentEnabled && cashAmount <= 0) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = AppLocalizations.of(context)!.enterCashAmount;
        });
        return;
      }

      if (_isAccountPaymentEnabled && paymentAccNumber == null) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = AppLocalizations.of(context)!.selectAccountRequired;
        });
        return;
      }

      if (_isAccountPaymentEnabled && paymentAccNumber != null && _accountCurrency != baseCurrency) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = "${AppLocalizations.of(context)!.accountCcyNotMatchBaseCcy} ($baseCurrency)";
        });
        return;
      }

      _validatePaymentAmounts(currentShipping);
    }
  }

  void _processPayment(ShippingDetailsModel shipping, bool hasExistingPayment) {
    final tr = AppLocalizations.of(context)!;
    final bloc = context.read<ShippingBloc>();

    final cashAmount = _getControllerAmount(cashCtrl);
    final totalAmount = _parseAmount(shipping.total);

    double existingPaid = 0.0;
    if (hasExistingPayment && shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
    }

    final remainingBalance = _safeMax(totalAmount - existingPaid, 0);

    double accountAmount = 0.0;
    if (_isAccountPaymentEnabled && paymentAccNumber != null) {
      if (hasExistingPayment && _isEditingExistingPayment) {
        accountAmount = _safeMax(totalAmount - cashAmount, 0);
      } else {
        if (_isCashPaymentEnabled) {
          accountAmount = _safeMax(remainingBalance - cashAmount, 0);
        } else {
          accountAmount = remainingBalance;
        }
      }
    }

    final totalPayment = cashAmount + accountAmount;

    bool isValid = false;
    if (hasExistingPayment && _isEditingExistingPayment) {
      isValid = totalPayment == totalAmount;
      if (!isValid) {
        Utils.showOverlayMessage(
          context,
          message: "${tr.editPaymentValidation} ${totalAmount.toAmount()} $baseCurrency",
          isError: true,
        );
        return;
      }
    } else if (hasExistingPayment) {
      isValid = totalPayment == remainingBalance;
      if (!isValid) {
        Utils.showOverlayMessage(
          context,
          message: "${tr.paymentMustMatchRemaining} ${remainingBalance.toAmount()} $baseCurrency",
          isError: true,
        );
        return;
      }
    } else {
      isValid = totalPayment == totalAmount;
      if (!isValid) {
        Utils.showOverlayMessage(
          context,
          message: "${tr.paymentMustMatchTotalShipping} ${totalAmount.toAmount()} $baseCurrency",
          isError: true,
        );
        return;
      }
    }

    String paymentType;
    if (cashAmount > 0 && accountAmount > 0) {
      paymentType = "dual";
    } else if (cashAmount > 0) {
      paymentType = "cash";
    } else if (accountAmount > 0) {
      paymentType = "card";
    } else {
      Utils.showOverlayMessage(
        context,
        message: tr.selectPaymentMethod,
        isError: true,
      );
      return;
    }

    if ((paymentType == "card" || paymentType == "dual") && paymentAccNumber == null) {
      Utils.showOverlayMessage(
        context,
        message: tr.selectAccountRequired,
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(hasExistingPayment ? tr.editPayment : tr.addPayment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.confirmMethodPayment),
            const SizedBox(height: 16),
            if (hasExistingPayment && _isEditingExistingPayment)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  "${tr.paymentMustMatchTotalShipping} ${totalAmount.toAmount()} $baseCurrency",
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ),
            if (hasExistingPayment && !_isEditingExistingPayment)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  "${tr.paymentMustMatchRemaining} ${remainingBalance.toAmount()} $baseCurrency",
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ),
            const SizedBox(height: 16),
            if (cashAmount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.cashPayment),
                  Text("${cashAmount.toAmount()} $baseCurrency"),
                ],
              ),
            if (accountAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.accountPayment),
                    Text("${accountAmount.toAmount()} $baseCurrency"),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  _getPaymentTypeDisplayName(paymentType),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.totalPayment, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${totalPayment.toAmount()} $baseCurrency",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.totalCharge, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${totalAmount.toAmount()} $baseCurrency",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (hasExistingPayment) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.existingPayment, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "${existingPaid.toAmount()} $baseCurrency",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
            if (hasExistingPayment && !_isEditingExistingPayment) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.remainingBalance, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "${remainingBalance.toAmount()} $baseCurrency",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr.cancel),
          ),
          ZOutlineButton(
            onPressed: !isValid
                ? null
                : () {
              Navigator.of(context).pop();
              setState(() {
                _isReloadingDueToUpdate = true;
              });
              if (hasExistingPayment && _isEditingExistingPayment && _existingPaymentReference != null) {
                bloc.add(EditShippingPaymentEvent(
                  reference: _existingPaymentReference,
                  shpId: shipping.shpId!,
                  cashAmount: cashAmount,
                  accNumber: paymentAccNumber,
                  accountAmount: accountAmount,
                  paymentType: paymentType,
                  usrName: usrName ?? "",
                ));
              } else if (hasExistingPayment && !_isEditingExistingPayment) {
                bloc.add(EditShippingPaymentEvent(
                  reference: shipping.pyment?.first.trdReference,
                  shpId: shipping.shpId!,
                  cashAmount: cashAmount,
                  accNumber: paymentAccNumber,
                  accountAmount: accountAmount,
                  paymentType: paymentType,
                  usrName: usrName ?? "",
                ));
              } else {
                bloc.add(AddShippingPaymentEvent(
                  shpId: shipping.shpId!,
                  cashAmount: cashAmount,
                  accNumber: paymentAccNumber,
                  accountAmount: accountAmount,
                  paymentType: paymentType,
                  usrName: usrName ?? "",
                ));
              }
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _isReloadingDueToUpdate = false;
                  });
                }
              });
            },
            label: Text(hasExistingPayment ? tr.updatePayment : tr.confirmPayment),
          ),
        ],
      ),
    );
  }

  String _getPaymentTypeDisplayName(String paymentType) {
    final tr = AppLocalizations.of(context)!;
    switch (paymentType) {
      case "dual":
        return tr.paymentTypeDisplayDual;
      case "cash":
        return tr.paymentTypeDisplayCash;
      case "card":
        return tr.paymentTypeDisplayCard;
      default:
        return paymentType;
    }
  }

  Widget _advancePayment() {
    final tr = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: advanceFormKey,
          child: Column(
            children: [
              ZTextFieldEntitled(
                keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                inputFormat: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                  SmartThousandsDecimalFormatter(),
                ],
                controller: advanceAmount,
                title: tr.advanceAmount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperWithData(ShippingDetailsModel shipping, AppLocalizations tr, BuildContext context) {
    final blocState = context.watch<ShippingBloc>().state;
    final isLoading = blocState is ShippingListLoadingState && blocState.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    visualDensity: const VisualDensity(vertical: -4),
                    minVerticalPadding: 0,
                    title: Text(tr.updateShipping,
                        style: textTheme.titleMedium?.copyWith(
                          color: color.primary,
                        )),
                    subtitle: Text(tr.updateShippingHint,
                        style: textTheme.bodySmall?.copyWith(color: color.outline)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(onPressed: popUp, icon: const Icon(Icons.clear)),
                )
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(5.0),
                child: CustomStepper(
                  key: ValueKey('existing-shipping-${shipping.shpId}'),
                  currentStep: _currentStep,
                  onStepTapped: (step) {
                    if (!isLoading) {
                      setState(() {
                        _currentStep = step;
                      });
                    }
                  },
                  onStepChanged: (currentStep, requestedStep) {
                    if (isLoading) return false;
                    return _validateStepChange(currentStep, requestedStep);
                  },
                  steps: [
                    StepItem(
                      title: tr.order,
                      content: _order(shipping: shipping),
                      icon: Icons.shopping_cart,
                    ),
                    StepItem(
                      title: tr.shipping,
                      content: _shipping(shipping: shipping),
                      icon: Icons.local_shipping,
                    ),
                    StepItem(
                      title: tr.expense,
                      content: _buildExpensesView(shipping),
                      icon: Icons.data_exploration,
                    ),
                    StepItem(
                      title: tr.shippingCharges,
                      content: _buildPaymentView(shipping),
                      icon: Icons.payment_rounded,
                    ),
                    StepItem(
                      title: tr.summary,
                      content: _buildSummaryView(shipping),
                      icon: Icons.summarize,
                    ),
                  ],
                  onFinish: () => onFinish(shipping),
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewShippingStepper(AppLocalizations tr, BuildContext context) {
    final blocState = context.watch<ShippingBloc>().state;
    final isLoading = blocState is ShippingListLoadingState && blocState.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.zero,
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    visualDensity: const VisualDensity(vertical: -4),
                    minVerticalPadding: 0,
                    title: Text(tr.createNewShipping,
                        style: textTheme.titleMedium?.copyWith(
                          color: color.primary,
                        )),
                    subtitle: Text(tr.newShippingHint,
                        style: textTheme.bodySmall?.copyWith(color: color.outline)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(onPressed: popUp, icon: const Icon(Icons.clear)),
                )
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10.0),
                child: CustomStepper(
                  key: const ValueKey('new-shipping'),
                  currentStep: _currentStep,
                  onStepTapped: (step) {
                    if (!isLoading) {
                      setState(() {
                        _currentStep = step;
                      });
                    }
                  },
                  onStepChanged: (currentStep, requestedStep) {
                    if (isLoading) return false;
                    return _validateStepChange(currentStep, requestedStep);
                  },
                  steps: [
                    StepItem(
                      title: tr.order,
                      content: _order(),
                      icon: Icons.shopping_cart,
                    ),
                    StepItem(
                      title: tr.shipping,
                      content: _shipping(),
                      icon: Icons.local_shipping,
                    ),
                    StepItem(
                      title: tr.advancePayment,
                      content: _advancePayment(),
                      icon: Icons.attach_money_outlined,
                    ),
                    StepItem(
                      title: tr.summary,
                      content: _buildSummaryView(null),
                      icon: Icons.summarize,
                    ),
                  ],
                  onFinish: () => onFinish(null),
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateStepChange(int currentStep, int requestedStep) {
    final tr = AppLocalizations.of(context)!;
    if (requestedStep > currentStep) {
      if (requestedStep == 1) {
        if (customerCtrl.text.isEmpty || productCtrl.text.isEmpty) {
          Utils.showOverlayMessage(
            context,
            message: tr.requiredField(tr.orderStep),
            isError: true,
          );
          return false;
        }
      }

      if (requestedStep == 2) {
        if (vehicleCtrl.text.isEmpty ||
            shpFrom.text.isEmpty ||
            shpTo.text.isEmpty ||
            shippingRent.text.isEmpty) {
          Utils.showOverlayMessage(
            context,
            message: tr.requiredField(tr.shippingStep),
            isError: true,
          );
          return false;
        }
      }
    }
    return true;
  }

  Widget _order({ShippingDetailsModel? shipping}) {
    final tr = AppLocalizations.of(context)!;
    bool isDelivered = shipping?.shpStatus == 1;
    TextStyle? title = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.outline);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: orderFormKey,
          child: Column(
            children: [
              GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                readOnly: isDelivered,
                showAllOnFocus: true,
                controller: customerCtrl,
                title: tr.customer,
                hintText: tr.customer,
                isRequired: true,
                bloc: context.read<IndividualsBloc>(),
                fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
                searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr.required(tr.customer);
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
                    customerId = value.perId!;
                    customerCtrl.text = "${value.perName} ${value.perLastName}";
                    cusAddress = value.addName ?? "";
                    cusPhone = value.perPhone ?? "";
                    cusEmail = value.perEmail ?? "";
                  });

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    orderFormKey.currentState?.validate();
                  });
                },
                noResultsText: tr.noDataFound,
                showClearButton: true,
              ),
              const SizedBox(height: 13),
              GenericTextfield<ProductsModel, ProductsBloc, ProductsState>(
                readOnly: isDelivered,
                showAllOnFocus: true,
                controller: productCtrl,
                title: tr.products,
                hintText: tr.products,
                isRequired: true,
                bloc: context.read<ProductsBloc>(),
                fetchAllFunction: (bloc) => bloc.add(LoadProductsEvent()),
                searchFunction: (bloc, query) => bloc.add(LoadProductsEvent()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr.required(tr.products);
                  }
                  return null;
                },
                itemBuilder: (context, product) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.proName ?? "",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                itemToString: (product) => product.proName ?? "",
                stateToLoading: (state) => state is ProductsLoadingState,
                loadingBuilder: (context) => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                stateToItems: (state) {
                  if (state is ProductsLoadedState) {
                    return state.products;
                  }
                  return [];
                },
                onSelected: (value) {
                  setState(() {
                    productId = value.proId!;
                    productCtrl.text = value.proName ?? "";
                    proCode = value.proCode ?? "";
                    proDetails = value.proDetails ?? "";
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    orderFormKey.currentState?.validate();
                  });
                },
                noResultsText: tr.noDataFound,
                showClearButton: true,
              ),

              if (customerCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 13),
                ZCover(
                  padding: const EdgeInsets.all(15),
                  radius: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.customerInformation, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: [
                                Text(tr.customer, style: title),
                                Text(tr.mobile1, style: title),
                                Text(tr.email, style: title),
                                Text(tr.address, style: title),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 5,
                            children: [
                              Text(customerCtrl.text),
                              Text(cusPhone ?? ""),
                              Text(cusEmail ?? ""),
                              Text(cusAddress ?? ""),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              if (productCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 13),
                ZCover(
                  padding: const EdgeInsets.all(15),
                  radius: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.productDetails, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: [
                                Text(tr.productCode, style: title),
                                Text(tr.productName, style: title),
                                Text(tr.details, style: title),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 5,
                            children: [
                              Text(proCode ?? ""),
                              Text(productCtrl.text),
                              Text(proDetails ?? ""),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _shipping({ShippingDetailsModel? shipping}) {
    final tr = AppLocalizations.of(context)!;
    bool isDelivered = shipping?.shpStatus == 1;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: shippingFormKey,
          child: Column(
            children: [
              GenericTextfield<VehicleModel, VehicleBloc, VehicleState>(
                showAllOnFocus: true,
                readOnly: isDelivered,
                controller: vehicleCtrl,
                title: tr.vehicles,
                hintText: tr.vehicles,
                isRequired: true,
                bloc: context.read<VehicleBloc>(),
                fetchAllFunction: (bloc) => bloc.add(LoadVehicleEvent()),
                searchFunction: (bloc, query) => bloc.add(LoadVehicleEvent()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr.required(tr.vehicle);
                  }
                  return null;
                },
                itemBuilder: (context, veh) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${veh.vclModel} | ${veh.vclPlateNo}",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                itemToString: (veh) => "${veh.vclModel} | ${veh.vclPlateNo}",
                stateToLoading: (state) => state is VehicleLoadingState,
                loadingBuilder: (context) => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                stateToItems: (state) {
                  if (state is VehicleLoadedState) {
                    return state.vehicles;
                  }
                  return [];
                },
                onSelected: (value) {
                  setState(() {
                    vehicleId = value.vclId!;
                    vehicleCtrl.text = "${value.vclModel} | ${value.vclPlateNo}";
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    shippingFormKey.currentState?.validate();
                  });
                },
                noResultsText: tr.noDataFound,
                showClearButton: true,
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      readOnly: isDelivered,
                      isRequired: true,
                      controller: shpFrom,
                      title: tr.shpFrom,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required(tr.shpFrom);
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ZTextFieldEntitled(
                      isRequired: true,
                      readOnly: isDelivered,
                      controller: shpTo,
                      title: tr.shpTo,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required(tr.shpTo);
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _datePicker(
                      isActive: isDelivered,
                      date: shpFromGregorian,
                      title: tr.loadingDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _datePicker(
                      isActive: isDelivered,
                      date: shpToGregorian,
                      title: tr.unloadingDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      readOnly: isDelivered,
                      isRequired: true,
                      controller: loadingSize,
                      title: tr.loadingSize,
                      inputFormat: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                        SmartThousandsDecimalFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required(tr.loadingSize);
                        }
                        final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                        final amount = double.tryParse(clean);
                        if (amount == null || amount <= 0) {
                          return tr.amountGreaterZero;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: ZTextFieldEntitled(
                      readOnly: isDelivered,
                      isRequired: true,
                      controller: unloadingSize,
                      title: tr.unloadingSize,
                      inputFormat: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                        SmartThousandsDecimalFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required(tr.unloadingSize);
                        }
                        final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                        final amount = double.tryParse(clean);
                        if (amount == null || amount <= 0) {
                          return tr.amountGreaterZero;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: UnitDropdown(
                      isActive: isDelivered,
                      selectedUnit: UnitType.fromDatabaseValue(shipping?.shpUnit ?? ""),
                      onUnitSelected: (e) {
                        setState(() {
                          unit = e.name;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      readOnly: isDelivered,
                      isRequired: true,
                      keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormat: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                        SmartThousandsDecimalFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required(tr.shippingRent);
                        }
                        final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                        final amount = double.tryParse(clean);
                        if (amount == null || amount <= 0.0) {
                          return tr.amountGreaterZero;
                        }
                        return null;
                      },
                      controller: shippingRent,
                      title: tr.shippingRent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ZTextFieldEntitled(
                readOnly: isDelivered,
                controller: remark,
                title: tr.remark,
                keyboardInputType: TextInputType.multiline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesView(ShippingDetailsModel shipping) {
    final tr = AppLocalizations.of(context)!;
    final expenses = shipping.expenses ?? [];
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocSelector<ShippingBloc, ShippingState, int?>(
      selector: (state) => state.loadingShpId,
      builder: (context, loadingShpId) {
        final isLoading = loadingShpId == widget.shippingId;

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    if (shipping.shpStatus != 1)
                      Form(
                        key: expenseFormKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                                    showAllOnFocus: true,
                                    controller: accountController,
                                    title: tr.accounts,
                                    hintText: tr.accNameOrNumber,
                                    isRequired: true,
                                    bloc: context.read<AccountsBloc>(),
                                    fetchAllFunction: (bloc) => bloc.add(
                                      LoadAccountsFilterEvent(
                                        include: '11,12',
                                        ccy: "$baseCurrency",
                                        exclude: "",
                                      ),
                                    ),
                                    searchFunction: (bloc, query) => bloc.add(
                                      LoadAccountsFilterEvent(
                                        include: '11,12',
                                        ccy: "$baseCurrency",
                                        exclude: "",
                                        input: query,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return tr.required(tr.accounts);
                                      }
                                      if (expenseAccNumber == null) {
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
                                    onSelected: (value) {
                                      setState(() {
                                        expenseAccNumber = value.accNumber;
                                        accountController.text = "${value.accNumber} | ${value.accName}";
                                      });
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        expenseFormKey.currentState?.validate();
                                      });
                                    },
                                    noResultsText: tr.noDataFound,
                                    showClearButton: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ZTextFieldEntitled(
                                    isRequired: true,
                                    keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormat: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                                      SmartThousandsDecimalFormatter(decimalDigits: 4),
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
                                    controller: expenseAmount,
                                    title: tr.amount,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ZTextFieldEntitled(
                              keyboardInputType: TextInputType.multiline,
                              controller: expenseNarration,
                              title: tr.narration,
                            ),
                          ],
                        ),
                      ),
                    if (shipping.shpStatus != 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (_selectedExpenseForEdit != null)
                              ZOutlineButton(
                                width: 100,
                                height: 35,
                                label: Text(tr.cancel),
                                onPressed: () {
                                  setState(() {
                                    _selectedExpenseForEdit = null;
                                    _clearExpenseForm();
                                  });
                                },
                              ),
                            if (_selectedExpenseForEdit != null) const SizedBox(width: 10),
                            ZOutlineButton(
                              width: 100,
                              height: 35,
                              isActive: true,
                              label: isLoading
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              )
                                  : Text(_selectedExpenseForEdit != null ? tr.update : tr.create),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                _handleExpenseAction();
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${tr.expense} (${expenses.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                if (expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context)!.noExpenseRecorded,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 300,
                              child: Text(
                                tr.referenceNumber,
                                style: textTheme.titleSmall,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tr.narration,
                                style: textTheme.titleSmall,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                tr.amount,
                                style: textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: color.outline.withValues(alpha: .1)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];

                            return Material(
                              child: InkWell(
                                hoverColor: color.primary.withValues(alpha: .06),
                                highlightColor: color.primary.withValues(alpha: .06),
                                onTap: isLoading ? null : () => _loadExpenseForEdit(expense),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _selectedExpenseForEdit?.trdReference == expense.trdReference
                                        ? color.primary.withValues(alpha: .1)
                                        : index.isEven
                                        ? color.outline.withValues(alpha: .05)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 300,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              expense.trdReference ?? "",
                                              style: textTheme.bodyMedium?.copyWith(color: color.outline),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 70,
                                                  child: Text(
                                                    expense.accNumber?.toString() ?? "",
                                                    style: TextStyle(color: color.primary),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 150,
                                                  child: Text(expense.accName ?? ""),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(child: Text(expense.narration ?? "")),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          "${expense.amount?.toAmount()} ${expense.currency}",
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryView(ShippingDetailsModel? shipping) {
    final summaryData = _getSummaryData(shipping);
    final hasShippingDetails = shipping != null;
    final tr = AppLocalizations.of(context)!;

    bool paymentNeedsUpdate = false;
    bool canBeDelivered = true;
    String paymentStatusMessage = "";

    if (hasShippingDetails) {
      paymentNeedsUpdate = _paymentNeedsUpdate(shipping);
      canBeDelivered = _canMarkAsDelivered(shipping);

      if (paymentNeedsUpdate) {
        final totalAmount = _parseAmount(shipping.total);
        double existingPaid = 0.0;
        if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
          final payment = shipping.pyment!.first;
          existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
        }
        paymentStatusMessage = "Payment needs update! Current payment (${existingPaid.toAmount()}) doesn't match shipping total (${totalAmount.toAmount()})";
      } else if (!canBeDelivered && shipping.shpStatus != 1) {
        final totalAmount = _parseAmount(shipping.total);
        double existingPaid = 0.0;
        if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
          final payment = shipping.pyment!.first;
          existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
        }
        paymentStatusMessage = "${tr.cannotMarkDeliveredMsg}: ${existingPaid.toAmount()}, ${tr.requiredTitle}: ${totalAmount.toAmount()}";
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Print Button at the top
            if (hasShippingDetails)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ZOutlineButton(
                    onPressed: () => _printShippingDetails(shipping),
                    label: Text(tr.print),
                    icon: Icons.print,
                    isActive: true,
                  ),
                ],
              ),

            const SizedBox(height: 16),

            if (shipping != null)
              if (summaryData['status'] != null && summaryData['status']!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: summaryData['status'] == "1" ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: summaryData['status'] == "1" ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        summaryData['status'] == "1" ? Icons.check_circle : Icons.schedule,
                        color: summaryData['status'] == "1" ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          summaryData['status'] == "1" ? tr.delivered : tr.pendingTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: summaryData['status'] == "1" ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      Switch(
                        value: shpStatus == 1,
                        onChanged: (e) {
                          if (e && !canBeDelivered) {
                            Utils.showOverlayMessage(
                              context,
                              message: tr.paymentIsNotComplete,
                              isError: true,
                            );
                            return;
                          }
                          if (e && paymentNeedsUpdate) {
                            Utils.showOverlayMessage(
                              context,
                              message: tr.paymentNeedsUpdate,
                              isError: true,
                            );
                            return;
                          }
                          setState(() {
                            shpStatus = e ? 1 : 0;
                          });
                        },
                      )
                    ],
                  ),
                ),

            if (paymentStatusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: paymentNeedsUpdate ? Colors.orange.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: paymentNeedsUpdate ? Colors.orange : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      paymentNeedsUpdate ? Icons.warning : Icons.error,
                      color: paymentNeedsUpdate ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        paymentStatusMessage,
                        style: TextStyle(
                          color: paymentNeedsUpdate ? Colors.orange : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            Text(
              tr.shippingSummary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),

            _buildSummaryItem(tr.customer, summaryData['customer'] ?? ''),
            _buildSummaryItem(tr.productName, summaryData['product'] ?? ''),

            const SizedBox(height: 5),
            Text(
              tr.shippingDetails,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            _buildSummaryItem(tr.vehicle, summaryData['vehicle'] ?? ''),
            _buildSummaryItem(tr.fromTo, "${summaryData['from']} - ${summaryData['to']}"),
            _buildSummaryItem(tr.loadingDate, shpFromGregorian),
            _buildSummaryItem(tr.unloadingDate, shpToGregorian),
            _buildSummaryItem(tr.loadingSize, summaryData['loadingSize'] ?? ''),
            _buildSummaryItem(tr.unloadingSize, summaryData['unloadingSize'] ?? ''),
            _buildSummaryItem(tr.shippingRent, summaryData['rent']?.toAmount() ?? ''),

            if (summaryData['total'] != null && summaryData['total']!.isNotEmpty)
              _buildSummaryItem(tr.totalTitle, "${summaryData['total']?.toAmount()}", isHighlighted: true),

            if (hasShippingDetails && shipping.expenses != null && shipping.expenses!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    tr.expense,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...shipping.expenses!.map(
                        (expense) => _buildSummaryItem(
                      "${expense.accName} (${expense.accNumber})",
                      "${expense.amount?.toAmount()} ${expense.currency}",
                      isSubItem: true,
                    ),
                  ),
                ],
              ),

            if (hasShippingDetails && shipping.pyment != null && shipping.pyment!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    tr.shippingCharges,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...shipping.pyment!.map(
                        (payment) => _buildSummaryItem(
                      tr.referenceNumber,
                      "${payment.trdReference}",
                      isSubItem: false,
                    ),
                  ),
                  ...shipping.pyment!.map(
                        (payment) => _buildSummaryItem(
                      tr.cashAmount,
                      "${payment.cashAmount?.toAmount()}",
                      isSubItem: false,
                    ),
                  ),
                  if (shipping.pyment?.first.cardAmount != null) ...[
                    ...shipping.pyment!.map(
                          (payment) => _buildSummaryItem(
                        tr.accountPayment,
                        "${payment.cardAmount?.toAmount()}",
                        isSubItem: false,
                      ),
                    ),
                    ...shipping.pyment!.map(
                          (payment) => _buildSummaryItem(
                        tr.accountNumber,
                        "${payment.accountCustomer}",
                        isSubItem: false,
                      ),
                    ),
                  ]
                ],
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, {bool isHighlighted = false, bool isSubItem = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSubItem ? 4.0 : 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              title,
              style: isSubItem
                  ? Theme.of(context).textTheme.bodyMedium
                  : Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: isSubItem
                  ? Theme.of(context).textTheme.bodyMedium
                  : Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loadingTitle, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  ShippingModel _getFormDataAsShippingModel() {
    return ShippingModel(
      shpLoadSize: loadingSize.text,
      shpUnloadSize: unloadingSize.text,
      shpTo: shpTo.text,
      shpFrom: shpFrom.text,
      shpRent: shippingRent.text.cleanAmount,
      productId: productId,
      vehicleId: vehicleId,
      customerId: customerId,
      shpArriveDate: DateTime.tryParse(shpToGregorian),
      shpMovingDate: DateTime.tryParse(shpFromGregorian),
      usrName: usrName ?? "",
      advanceAmount: advanceAmount.text.cleanAmount,
      remark: remark.text,
      shpId: widget.shippingId,
      shpUnit: unit ?? "TN",
      shpStatus: shpStatus ?? 0,
    );
  }

  void _clearExpenseForm() {
    expenseAmount.clear();
    expenseNarration.clear();
    accountController.clear();
    expenseAccNumber = null;
    _selectedExpenseForEdit = null;
    if (expenseFormKey.currentState != null) {
      expenseFormKey.currentState!.reset();
    }
  }

  void popUp() {
    Navigator.of(context).pop();
  }

  void onFinish(ShippingDetailsModel? existingShipping) async {
    final tr = AppLocalizations.of(context)!;
    final bloc = context.read<ShippingBloc>();

    if (customerId == null) {
      Utils.showOverlayMessage(
        context,
        message: tr.selectCustomer,
        isError: true,
      );
      setState(() => _currentStep = 0);
      return;
    }

    if (productId == null) {
      Utils.showOverlayMessage(
        context,
        message: tr.selectProduct,
        isError: true,
      );
      setState(() => _currentStep = 0);
      return;
    }

    if (vehicleId == null) {
      Utils.showOverlayMessage(
        context,
        message: tr.selectVehicle,
        isError: true,
      );
      setState(() => _currentStep = 1);
      return;
    }

    if (shpFrom.text.isEmpty || shpTo.text.isEmpty) {
      Utils.showOverlayMessage(
        context,
        message: tr.fillShippingLocations,
        isError: true,
      );
      setState(() => _currentStep = 1);
      return;
    }

    if (shpStatus == 1 && existingShipping != null) {
      if (!_canMarkAsDelivered(existingShipping)) {
        Utils.showOverlayMessage(
          context,
          message: tr.paymentIsNotComplete,
          isError: true,
        );
        setState(() => _currentStep = 3);
        return;
      }

      if (_paymentNeedsUpdate(existingShipping)) {
        Utils.showOverlayMessage(
          context,
          message: tr.paymentNeedsUpdate,
          isError: true,
        );
        setState(() => _currentStep = 3);
        return;
      }
    }

    final data = ShippingModel(
      shpId: widget.shippingId,
      shpLoadSize: loadingSize.text.cleanAmount,
      shpUnloadSize: unloadingSize.text.cleanAmount,
      shpTo: shpTo.text,
      shpFrom: shpFrom.text,
      shpRent: shippingRent.text.cleanAmount,
      productId: productId!,
      vehicleId: vehicleId!,
      customerId: customerId!,
      shpArriveDate: DateTime.tryParse(shpToGregorian),
      shpMovingDate: DateTime.tryParse(shpFromGregorian),
      usrName: usrName ?? "",
      advanceAmount: advanceAmount.text.cleanAmount,
      remark: remark.text,
      shpStatus: shpStatus ?? 0,
      shpUnit: unit ?? "TN",
    );

    if (widget.shippingId != null) {
      bloc.add(UpdateShippingEvent(data));
    } else {
      bloc.add(AddShippingEvent(data));
    }
  }

  Map<String, String> _getSummaryData(ShippingDetailsModel? shipping) {
    if (shipping != null) {
      return {
        'customer': shipping.customer ?? customerCtrl.text,
        'product': shipping.proName ?? productCtrl.text,
        'vehicle': shipping.vehicle ?? vehicleCtrl.text,
        'from': shipping.shpFrom ?? shpFrom.text,
        'to': shipping.shpTo ?? shpTo.text,
        'loadingSize': "${shipping.shpLoadSize ?? loadingSize.text} ${shipping.shpUnit ?? unit ?? ''}",
        'unloadingSize': "${shipping.shpUnloadSize ?? unloadingSize.text} ${shipping.shpUnit ?? unit ?? ''}",
        'rent': shipping.shpRent ?? shippingRent.text,
        'total': shipping.total ?? "",
        'status': shipping.shpStatus?.toString() ?? "",
      };
    } else {
      final formData = _getFormDataAsShippingModel();
      return {
        'customer': formData.customer ?? customerCtrl.text,
        'product': formData.proName ?? productCtrl.text,
        'vehicle': formData.vehicle ?? vehicleCtrl.text,
        'from': formData.shpFrom ?? shpFrom.text,
        'to': formData.shpTo ?? shpTo.text,
        'loadingSize': "${formData.shpLoadSize ?? loadingSize.text} ${formData.shpUnit ?? unit ?? 'TN'}",
        'unloadingSize': "${formData.shpUnloadSize ?? unloadingSize.text} ${formData.shpUnit ?? unit ?? 'TN'}",
        'rent': formData.shpRent ?? shippingRent.text,
        'total': formData.total ?? "",
        'status': formData.shpStatus?.toString() ?? "",
      };
    }
  }

  void _loadExpenseForEdit(Expense expense) {
    setState(() {
      _selectedExpenseForEdit = expense;
      expenseAmount.text = expense.amount ?? '';
      expenseNarration.text = expense.narration ?? '';

      if (expense.accNumber != null && expense.accName != null) {
        accountController.text = '${expense.accNumber} | ${expense.accName}';
        expenseAccNumber = expense.accNumber;
      }
    });
  }

  void _handleExpenseAction() {
    if (expenseFormKey.currentState == null || !expenseFormKey.currentState!.validate()) {
      Utils.showOverlayMessage(context, message: AppLocalizations.of(context)!.requiredField(''), isError: true);
      return;
    }

    setState(() {
      _isReloadingDueToUpdate = true;
    });
    if (_selectedExpenseForEdit != null) {
      context.read<ShippingBloc>().add(
        UpdateShippingExpenseEvent(
          shpId: widget.shippingId!,
          trnReference: _selectedExpenseForEdit!.trdReference!,
          amount: expenseAmount.text.cleanAmount,
          narration: expenseNarration.text,
          usrName: usrName ?? "",
        ),
      );
    } else {
      context.read<ShippingBloc>().add(
        AddShippingExpenseEvent(
          shpId: widget.shippingId!,
          accNumber: expenseAccNumber!,
          amount: expenseAmount.text.cleanAmount,
          narration: expenseNarration.text,
          usrName: usrName ?? "",
        ),
      );
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isReloadingDueToUpdate = false;
        });
      }
    });
  }

  Widget _datePicker({required String date, required String title, bool? isActive}) {
    return GenericDatePicker(
      isActive: isActive ?? false,
      label: title,
      initialGregorianDate: date,
      onDateChanged: (newDate) {
        setState(() {
          if (title == 'Loading Date') {
            shpFromGregorian = newDate;
          } else {
            shpToGregorian = newDate;
          }
        });
      },
    );
  }
}

// Mobile View Implementation
class _Mobile extends StatefulWidget {
  final int? shippingId;
  final int? perId;
  const _Mobile({this.shippingId, this.perId});

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final shpFrom = TextEditingController();
  final shpTo = TextEditingController();
  final shippingRent = TextEditingController();
  final loadingSize = TextEditingController();
  final unloadingSize = TextEditingController();
  final customerCtrl = TextEditingController();
  final vehicleCtrl = TextEditingController();
  final productCtrl = TextEditingController();
  final remark = TextEditingController();
  final advanceAmount = TextEditingController();
  final accountController = TextEditingController();
  final expenseAmount = TextEditingController();
  final expenseNarration = TextEditingController();
  final paymentAccountCtrl = TextEditingController();
  final cashCtrl = TextEditingController();

  int? expenseAccNumber;
  String? currentLocale;
  int? customerId;
  int? productId;
  int? vehicleId;
  String? unit;
  int? shpStatus;
  int? paymentAccNumber;

  // Date variables
  String shpFromGregorian = DateTime.now().toFormattedDate();
  String shpToGregorian = DateTime.now().toFormattedDate();

  String? usrName;
  // State variables
  bool _isCashPaymentEnabled = false;
  bool _isAccountPaymentEnabled = false;
  bool _isEditingExistingPayment = false;
  String? _existingPaymentReference;

  final GlobalKey<FormState> orderFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> shippingFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> advanceFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> expenseFormKey = GlobalKey<FormState>();

  Expense? _selectedExpenseForEdit;
  bool _paymentFormValid = false;
  String? _paymentError;
  int _currentStep = 0;
  String? baseCurrency;

  String? _accountCurrency;
  bool? isAccountCcyEqualBase;

  String? cusAddress;
  String? cusPhone;
  String? cusEmail;

  String? proCode;
  String? proDetails;

  bool _isReloadingDueToUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<CompanyProfileBloc>().state;
      if (state is CompanyProfileLoadedState) {
        baseCurrency = state.company.comLocalCcy;
      }
      currentLocale = context.read<LocalizationBloc>().state.languageCode;
      if (widget.shippingId != null) {
        _currentStep = 0;
        context.read<ShippingBloc>().add(LoadShippingDetailEvent(widget.shippingId!));
      }
    });
  }

  @override
  void didUpdateWidget(covariant _Mobile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shippingId != oldWidget.shippingId) {
      _currentStep = 0;
    }
  }

  void _prefillForm(ShippingDetailsModel shipping) {
    if (!mounted) return;

    if (!_isReloadingDueToUpdate) {
      setState(() {
        _paymentError = null;
        _isEditingExistingPayment = false;
        _existingPaymentReference = null;
      });
    }
    _clearAllControllers();

    customerId = shipping.perId;
    productId = shipping.proId;
    vehicleId = shipping.vclId;

    customerCtrl.text = shipping.customer ?? '';
    productCtrl.text = shipping.proName ?? '';
    vehicleCtrl.text = shipping.vehicle ?? '';

    shpFrom.text = shipping.shpFrom ?? '';
    shpTo.text = shipping.shpTo ?? '';

    shpFromGregorian = shipping.shpMovingDate?.toFormattedDate() ?? "";
    shpToGregorian = shipping.shpArriveDate?.toFormattedDate() ?? "";

    loadingSize.text = shipping.shpLoadSize ?? '';
    unloadingSize.text = shipping.shpUnloadSize ?? '';

    unit = shipping.shpUnit;
    shippingRent.text = shipping.shpRent ?? '';
    remark.text = shipping.shpRemark ?? '';
    shpStatus = shipping.shpStatus ?? 0;

    _prefillPaymentData(shipping);
  }

  void _prefillPaymentData(ShippingDetailsModel shipping) {
    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      _existingPaymentReference = payment.trdReference;

      double cashAmount = _parseAmount(payment.cashAmount);
      if (cashAmount > 0) {
        cashCtrl.text = cashAmount.toAmount();
        _isCashPaymentEnabled = true;
      }

      double cardAmount = _parseAmount(payment.cardAmount);
      if (cardAmount > 0) {
        _isAccountPaymentEnabled = true;
        paymentAccNumber = payment.accountCustomer;
        paymentAccountCtrl.text = payment.accName ?? "";
        if (payment.accountCustomer != null) {
          _loadAccountDetails(payment.accountCustomer!);
        }
      }

      _calculatePaymentTotals(shipping);
    }
  }

  void _loadAccountDetails(int accountNumber) {
    paymentAccNumber = accountNumber;
  }

  void _clearAllControllers() {
    productCtrl.clear();
    shpFrom.clear();
    shpTo.clear();
    shippingRent.clear();
    loadingSize.clear();
    unloadingSize.clear();
    customerCtrl.clear();
    vehicleCtrl.clear();
    remark.clear();
    advanceAmount.clear();
    accountController.clear();
    expenseAmount.clear();
    expenseNarration.clear();
    cashCtrl.clear();
    paymentAccountCtrl.clear();

    customerId = null;
    vehicleId = null;
    productId = null;
    unit = null;
    expenseAccNumber = null;
    paymentAccNumber = null;
    _selectedExpenseForEdit = null;
    _isCashPaymentEnabled = false;
    _isAccountPaymentEnabled = false;
    _isEditingExistingPayment = false;
    _existingPaymentReference = null;

    _paymentFormValid = false;
    _paymentError = null;
  }

  @override
  void dispose() {
    productCtrl.dispose();
    shpFrom.dispose();
    shpTo.dispose();
    shippingRent.dispose();
    loadingSize.dispose();
    unloadingSize.dispose();
    customerCtrl.dispose();
    vehicleCtrl.dispose();
    remark.dispose();
    advanceAmount.dispose();
    accountController.dispose();
    expenseAmount.dispose();
    expenseNarration.dispose();
    cashCtrl.dispose();
    paymentAccountCtrl.dispose();
    super.dispose();
  }

  double _parseAmount(String? amountString) {
    if (amountString == null || amountString.isEmpty) return 0.0;
    try {
      String cleaned = amountString.cleanAmount;
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  double _getControllerAmount(TextEditingController controller) {
    return _parseAmount(controller.text);
  }

  double _safeMax(double value, double minValue) => value > minValue ? value.toDouble() : minValue;

  void _validatePaymentAmounts(ShippingDetailsModel shipping) {
    final shippingTotal = _parseAmount(shipping.total);

    double existingPaid = 0.0;
    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
    }

    final remainingBalance = _safeMax(shippingTotal - existingPaid, 0);

    if (_isEditingExistingPayment && shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final currentPayment = _calculateCurrentPayment();

      if (currentPayment == shippingTotal && currentPayment > 0) {
        setState(() {
          _paymentFormValid = true;
          _paymentError = null;
        });
      } else if (currentPayment > 0 && currentPayment != shippingTotal) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = "Edited payment (${currentPayment.toAmount()}) must exactly match shipping total (${shippingTotal.toAmount()})";
        });
      } else {
        setState(() {
          _paymentFormValid = false;
          _paymentError = null;
        });
      }
    } else {
      if (remainingBalance == 0) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = null;
        });
        return;
      }

      double currentPayment = _calculateCurrentPayment();

      if (currentPayment == remainingBalance && currentPayment > 0) {
        setState(() {
          _paymentFormValid = true;
          _paymentError = null;
        });
      } else if (currentPayment > 0 && currentPayment != remainingBalance) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = "Payment amount (${currentPayment.toAmount()}) must exactly match remaining balance (${remainingBalance.toAmount()})";
        });
      } else {
        setState(() {
          _paymentFormValid = false;
          _paymentError = null;
        });
      }
    }
  }

  double _calculateCurrentPayment() {
    final cashAmount = _getControllerAmount(cashCtrl);
    double currentPayment = 0;

    if (_isCashPaymentEnabled && cashAmount > 0) {
      currentPayment += cashAmount;
    }

    if (_isAccountPaymentEnabled && paymentAccNumber != null) {
      if (_isEditingExistingPayment) {
        final shippingState = context.read<ShippingBloc>().state;
        if (shippingState is ShippingDetailLoadedState) {
          final shippingTotal = _parseAmount(shippingState.currentShipping?.total);
          final remainingForAccount = shippingTotal - cashAmount;
          if (remainingForAccount > 0) {
            currentPayment += remainingForAccount;
          }
        }
      } else {
        final shippingState = context.read<ShippingBloc>().state;
        if (shippingState is ShippingDetailLoadedState) {
          final shipping = shippingState.currentShipping!;
          final totalAmount = _parseAmount(shipping.total);
          double existingPaid = 0.0;
          if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
            final payment = shipping.pyment!.first;
            existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
          }
          final remainingBalance = _safeMax(totalAmount - existingPaid, 0);
          final availableForAccount = _safeMax(remainingBalance - cashAmount, 0);
          currentPayment += availableForAccount;
        }
      }
    }

    return currentPayment;
  }

  void _calculatePaymentTotals(ShippingDetailsModel shipping) {
    _validatePaymentAmounts(shipping);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    usrName = login.usrName ?? "";

    return BlocConsumer<ShippingBloc, ShippingState>(
      listener: (context, state) {
        if (state is ShippingSuccessState) {
          final message = state.message.toLowerCase();

          if (message.contains('shipping') && !message.contains('expense') && !message.contains('payment')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
            });
          }

          if (message.contains('expense')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _clearExpenseForm();
              setState(() {
                _selectedExpenseForEdit = null;
              });
            });
          }

          if (message.contains('payment')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _clearPaymentError();
              _isEditingExistingPayment = false;
            });
          }

          if ((message.contains('payment') || message.contains('expense')) && widget.shippingId != null) {
            context.read<ShippingBloc>().add(LoadShippingDetailEvent(widget.shippingId!));
          }
        }

        if (state is ShippingDetailLoadedState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isReloadingDueToUpdate) {
              _prefillForm(state.currentShipping!);
            }
          });
        }

        if (state is ShippingErrorState) {
          Utils.showOverlayMessage(context, message: state.error, isError: true);
        }
      },
      builder: (context, blocState) {
        if (blocState is ShippingDetailLoadingState) {
          return _buildLoadingContent();
        }

        ShippingDetailsModel? currentShipping;

        if (blocState is ShippingSuccessState && blocState.currentShipping != null) {
          currentShipping = blocState.currentShipping;
        } else if (blocState is ShippingDetailLoadedState) {
          currentShipping = blocState.currentShipping;
        } else if (blocState is ShippingListLoadedState && blocState.currentShipping != null) {
          currentShipping = blocState.currentShipping;
        }

        if (currentShipping != null) {
          return _buildStepperWithData(currentShipping, tr);
        }

        if (widget.shippingId == null && blocState is! ShippingSuccessState) {
          return _buildNewShippingStepper(tr);
        }

        return _buildLoadingContent();
      },
    );
  }

  void _clearPaymentError() {
    setState(() {
      _paymentError = null;
    });
  }

  bool _canMarkAsDelivered(ShippingDetailsModel shipping) {
    final totalAmount = _parseAmount(shipping.total);
    double existingPaid = 0.0;

    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
    }

    return existingPaid >= totalAmount && existingPaid == totalAmount;
  }

  bool _paymentNeedsUpdate(ShippingDetailsModel shipping) {
    final totalAmount = _parseAmount(shipping.total);
    double existingPaid = 0.0;

    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
    }

    return existingPaid > 0 && existingPaid != totalAmount;
  }

  Widget _buildPaymentView(ShippingDetailsModel shipping) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    final totalAmount = _parseAmount(shipping.total);
    double existingPaid = 0.0;
    Pyment? existingPayment;

    if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      existingPayment = shipping.pyment!.first;
      existingPaid = _parseAmount(existingPayment.cashAmount) + _parseAmount(existingPayment.cardAmount);
    }

    final remainingBalance = _safeMax(totalAmount - existingPaid, 0);
    final isFullyPaid = existingPaid >= totalAmount && existingPaid == totalAmount;
    final paymentNeedsUpdate = _paymentNeedsUpdate(shipping);

    final canEditPayment = shipping.shpStatus != 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.primary.withValues(alpha: .1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.shippingCharges,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.totalCharge, style: textTheme.titleMedium),
                    Text(
                      "${totalAmount.toAmount()} $baseCurrency",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.totalPaid, style: textTheme.bodyMedium),
                    Text(
                      "${existingPaid.toAmount()} $baseCurrency",
                      style: textTheme.bodyMedium?.copyWith(
                        color: existingPaid > 0 ? Colors.green : color.outline,
                        fontWeight: existingPaid > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr.remainingBalance, style: textTheme.bodyMedium),
                    // Text(
                    //   "${remainingBalance.toAmount()} $baseCurrency",
                    //   style: textTheme.bodyMedium?.copyWith(
                    //     color: remainingBalance > 0 ? color.error : Colors.green,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    Text(
                      isFullyPaid ? tr.fullyPaid : "${tr.balance}: ${remainingBalance.toAmount()} $baseCurrency",
                      style: textTheme.bodyMedium?.copyWith(
                        color: isFullyPaid ? Colors.green : color.error,
                      ),
                    ),
                  ],
                ),
                if (paymentNeedsUpdate && existingPayment != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${tr.paymentNeedsUpdateTitle}: ${existingPaid.toAmount()} ${tr.requiredTitle}: ${totalAmount.toAmount()}",
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (existingPayment != null && !canEditPayment) ...[
            _buildPaymentHistory(existingPayment, tr),
            const SizedBox(height: 16),
          ],

          if (canEditPayment) ...[
            _buildPaymentForm(shipping, existingPayment: existingPayment),
            const SizedBox(height: 16),
            if (_paymentError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: color.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_paymentError!, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ZOutlineButton(
                onPressed: _paymentFormValid
                    ? () => _processPayment(shipping, existingPayment != null)
                    : null,
                isActive: true,
                label: Text(
                  existingPayment != null ? tr.updatePayment : tr.addPayment,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (existingPayment != null) _buildPaymentHistory(existingPayment, tr),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(Pyment payment, AppLocalizations tr) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final cashAmount = _parseAmount(payment.cashAmount);
    final cardAmount = _parseAmount(payment.cardAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outline.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: color.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                tr.payment,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPaymentDetailRow(
            tr.totalPaid,
            "${(cashAmount + cardAmount).toAmount()} $baseCurrency",
            Icons.check_circle,
            color.primary,
            isBold: true,
          ),
          const Divider(height: 16),
          if (payment.trdReference != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildPaymentDetailRow(
                tr.referenceNumber,
                payment.trdReference!,
                Icons.receipt,
                color.outline,
              ),
            ),
          _buildPaymentDetailRow(
            tr.cashPaid,
            payment.cashAmount?.toAmount() ?? "0.00",
            Icons.money,
            color.outline,
          ),
          if (payment.cardAmount != null) ...[
            const SizedBox(height: 8),
            _buildPaymentDetailRow(
              tr.accountPayment,
              payment.cardAmount?.toAmount() ?? "0.00",
              Icons.credit_card,
              color.outline,
            ),
            _buildPaymentDetailRow(
              tr.accountDetails,
              "${payment.accName} (${payment.accountCustomer.toString()})",
              FontAwesomeIcons.buildingColumns,
              color.outline,
              iconSize: 16,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value, IconData icon, Color color, {bool isBold = false, double iconSize = 18}) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(ShippingDetailsModel shipping, {Pyment? existingPayment}) {
    final tr = AppLocalizations.of(context)!;
    final totalAmount = _parseAmount(shipping.total);

    double existingPaid = 0.0;
    if (existingPayment != null) {
      existingPaid = _parseAmount(existingPayment.cashAmount) + _parseAmount(existingPayment.cardAmount);
    }

    final remainingBalance = _safeMax(totalAmount - existingPaid, 0);
    final isEditing = existingPayment != null;
    final cashAmount = _getControllerAmount(cashCtrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? tr.editPayment : tr.addPayment,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cash Payment Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isCashPaymentEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isCashPaymentEnabled = value ?? false;
                          if (!_isCashPaymentEnabled) {
                            cashCtrl.clear();
                          }
                          _validatePaymentForm();
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr.cashPayment,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isCashPaymentEnabled) ...[
                  const SizedBox(height: 12),
                  ZTextFieldEntitled(
                    controller: cashCtrl,
                    title: tr.cashAmount,
                    hint: tr.enterAmount,
                    keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormat: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                      SmartThousandsDecimalFormatter(),
                    ],
                    validator: (value) {
                      if (_isCashPaymentEnabled) {
                        final amount = _parseAmount(value);
                        if (amount <= 0) return tr.amountGreaterZero;
                        if (amount > (isEditing ? totalAmount : remainingBalance)) {
                          return "${tr.cashAmountCannotExceed} ${(isEditing ? totalAmount : remainingBalance).toAmount()} $baseCurrency";
                        }
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _validatePaymentForm();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Account Payment Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isAccountPaymentEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isAccountPaymentEnabled = value ?? false;
                          if (!_isAccountPaymentEnabled) {
                            paymentAccountCtrl.clear();
                            paymentAccNumber = null;
                          }
                          _validatePaymentForm();
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr.accountPayment,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isAccountPaymentEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr.amountToChargeAccount, style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          "${(isEditing ? _safeMax(totalAmount - cashAmount, 0) : remainingBalance - cashAmount).toAmount()} $baseCurrency",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                    showAllOnFocus: true,
                    controller: paymentAccountCtrl,
                    title: tr.selectAccount,
                    hintText: tr.selectReceivableAccount,
                    isRequired: _isAccountPaymentEnabled,
                    bloc: context.read<AccountsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadAccountsEvent(ownerId: widget.perId)),
                    searchFunction: (bloc, query) => bloc.add(LoadAccountsEvent(ownerId: widget.perId)),
                    validator: (value) {
                      if (_isAccountPaymentEnabled && paymentAccNumber == null) {
                        return tr.selectValidAccount;
                      }
                      return null;
                    },
                    itemBuilder: (context, account) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.accName ?? "",
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Text(
                                      account.accNumber?.toString() ?? "",
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${account.accAvailBalance?.toAmount()} ${account.actCurrency}",
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
                      if (state is AccountLoadedState) return state.accounts;
                      return [];
                    },
                    onSelected: (value) {
                      setState(() {
                        paymentAccNumber = value.accNumber;
                        paymentAccountCtrl.text = "${value.accNumber} | ${value.accName}";
                        _accountCurrency = value.actCurrency;
                        isAccountCcyEqualBase = _accountCurrency == value.actCurrency;
                        _validatePaymentForm();
                      });
                    },
                    noResultsText: tr.noAccountsFound,
                    showClearButton: true,
                  ),
                ],
              ],
            ),
          ),

          if (cashAmount > 0 || (_isAccountPaymentEnabled && paymentAccNumber != null)) ...[
            const SizedBox(height: 16),
            _buildPaymentSummary(isEditing ? totalAmount : remainingBalance, cashAmount, tr, isEditing: isEditing),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(double targetAmount, double cashAmount, AppLocalizations tr, {bool isEditing = false}) {
    double accountAmount = 0.0;

    if (_isAccountPaymentEnabled && paymentAccNumber != null) {
      if (isEditing) {
        accountAmount = _safeMax(targetAmount - cashAmount, 0);
      } else {
        final shippingState = context.read<ShippingBloc>().state;
        if (shippingState is ShippingDetailLoadedState) {
          final shipping = shippingState.currentShipping!;
          final totalAmount = _parseAmount(shipping.total);
          double existingPaid = 0.0;
          if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
            final payment = shipping.pyment!.first;
            existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
          }
          final remainingBalance = _safeMax(totalAmount - existingPaid, 0);
          accountAmount = _safeMax(remainingBalance - cashAmount, 0);
        }
      }
    }

    final totalPayment = cashAmount + accountAmount;
    final isValid = isEditing ? totalPayment == targetAmount : totalPayment == targetAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid
            ? Theme.of(context).colorScheme.primary.withValues(alpha: .05)
            : Theme.of(context).colorScheme.error.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .3)
              : Theme.of(context).colorScheme.error.withValues(alpha: .3),
        ),
      ),
      child: Column(
        children: [
          Text(
            tr.paymentSummary,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (cashAmount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.cashPayment),
                  Text("${cashAmount.toAmount()} $baseCurrency"),
                ],
              ),
            ),
          if (accountAmount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr.accountPayment),
                  Text("${accountAmount.toAmount()} $baseCurrency"),
                ],
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.totalPayment, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${totalPayment.toAmount()} $baseCurrency",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isValid ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          if (isValid)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  isEditing ? tr.paymentMatchesShippingTotal : tr.paymentMatches,
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _validatePaymentForm() {
    final shippingState = context.read<ShippingBloc>().state;
    ShippingDetailsModel? currentShipping;

    if (shippingState is ShippingDetailLoadedState) {
      currentShipping = shippingState.currentShipping;
    } else if (shippingState is ShippingSuccessState) {
      currentShipping = shippingState.currentShipping;
    }

    if (currentShipping != null) {
      final cashAmount = _getControllerAmount(cashCtrl);
      final hasExistingPayment = currentShipping.pyment != null && currentShipping.pyment!.isNotEmpty;

      final isEditing = hasExistingPayment && (_isCashPaymentEnabled || _isAccountPaymentEnabled || cashCtrl.text.isNotEmpty);

      if (isEditing) {
        _isEditingExistingPayment = true;
      }

      if (!_isCashPaymentEnabled && !_isAccountPaymentEnabled) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = AppLocalizations.of(context)!.selectPaymentMethod;
        });
        return;
      }

      if (_isCashPaymentEnabled && cashAmount <= 0) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = AppLocalizations.of(context)!.enterCashAmount;
        });
        return;
      }

      if (_isAccountPaymentEnabled && paymentAccNumber == null) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = AppLocalizations.of(context)!.selectAccountRequired;
        });
        return;
      }

      if (_isAccountPaymentEnabled && paymentAccNumber != null && _accountCurrency != baseCurrency) {
        setState(() {
          _paymentFormValid = false;
          _paymentError = "${AppLocalizations.of(context)!.accountCcyNotMatchBaseCcy} ($baseCurrency)";
        });
        return;
      }

      _validatePaymentAmounts(currentShipping);
    }
  }

  void _processPayment(ShippingDetailsModel shipping, bool hasExistingPayment) {
    final tr = AppLocalizations.of(context)!;
    final bloc = context.read<ShippingBloc>();

    final cashAmount = _getControllerAmount(cashCtrl);
    final totalAmount = _parseAmount(shipping.total);

    double existingPaid = 0.0;
    if (hasExistingPayment && shipping.pyment != null && shipping.pyment!.isNotEmpty) {
      final payment = shipping.pyment!.first;
      existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
    }

    final remainingBalance = _safeMax(totalAmount - existingPaid, 0);

    double accountAmount = 0.0;
    if (_isAccountPaymentEnabled && paymentAccNumber != null) {
      if (hasExistingPayment && _isEditingExistingPayment) {
        accountAmount = _safeMax(totalAmount - cashAmount, 0);
      } else {
        if (_isCashPaymentEnabled) {
          accountAmount = _safeMax(remainingBalance - cashAmount, 0);
        } else {
          accountAmount = remainingBalance;
        }
      }
    }

    final totalPayment = cashAmount + accountAmount;

    bool isValid = false;
    if (hasExistingPayment && _isEditingExistingPayment) {
      isValid = totalPayment == totalAmount;
      if (!isValid) {
        Utils.showOverlayMessage(
          context,
          message: "${tr.editPaymentValidation} ${totalAmount.toAmount()} $baseCurrency",
          isError: true,
        );
        return;
      }
    } else if (hasExistingPayment) {
      isValid = totalPayment == remainingBalance;
      if (!isValid) {
        Utils.showOverlayMessage(
          context,
          message: "${tr.paymentMustMatchRemaining} ${remainingBalance.toAmount()} $baseCurrency",
          isError: true,
        );
        return;
      }
    } else {
      isValid = totalPayment == totalAmount;
      if (!isValid) {
        Utils.showOverlayMessage(
          context,
          message: "${tr.paymentMustMatchTotalShipping} ${totalAmount.toAmount()} $baseCurrency",
          isError: true,
        );
        return;
      }
    }

    String paymentType;
    if (cashAmount > 0 && accountAmount > 0) {
      paymentType = "dual";
    } else if (cashAmount > 0) {
      paymentType = "cash";
    } else if (accountAmount > 0) {
      paymentType = "card";
    } else {
      Utils.showOverlayMessage(
        context,
        message: tr.selectPaymentMethod,
        isError: true,
      );
      return;
    }

    if ((paymentType == "card" || paymentType == "dual") && paymentAccNumber == null) {
      Utils.showOverlayMessage(
        context,
        message: tr.selectAccountRequired,
        isError: true,
      );
      return;
    }

    // Mobile confirmation bottom sheet instead of dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasExistingPayment ? tr.editPayment : tr.addPayment,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(tr.confirmMethodPayment),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
              ),
              child: Column(
                children: [
                  if (cashAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.cashPayment),
                          Text("${cashAmount.toAmount()} $baseCurrency"),
                        ],
                      ),
                    ),
                  if (accountAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.accountPayment),
                          Text("${accountAmount.toAmount()} $baseCurrency"),
                        ],
                      ),
                    ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr.totalPayment, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          "${totalPayment.toAmount()} $baseCurrency",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(tr.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZOutlineButton(
                    onPressed: !isValid
                        ? null
                        : () {
                      Navigator.of(context).pop();
                      setState(() {
                        _isReloadingDueToUpdate = true;
                      });
                      if (hasExistingPayment && _isEditingExistingPayment && _existingPaymentReference != null) {
                        bloc.add(EditShippingPaymentEvent(
                          reference: _existingPaymentReference,
                          shpId: shipping.shpId!,
                          cashAmount: cashAmount,
                          accNumber: paymentAccNumber,
                          accountAmount: accountAmount,
                          paymentType: paymentType,
                          usrName: usrName ?? "",
                        ));
                      } else if (hasExistingPayment && !_isEditingExistingPayment) {
                        bloc.add(EditShippingPaymentEvent(
                          reference: shipping.pyment?.first.trdReference,
                          shpId: shipping.shpId!,
                          cashAmount: cashAmount,
                          accNumber: paymentAccNumber,
                          accountAmount: accountAmount,
                          paymentType: paymentType,
                          usrName: usrName ?? "",
                        ));
                      } else {
                        bloc.add(AddShippingPaymentEvent(
                          shpId: shipping.shpId!,
                          cashAmount: cashAmount,
                          accNumber: paymentAccNumber,
                          accountAmount: accountAmount,
                          paymentType: paymentType,
                          usrName: usrName ?? "",
                        ));
                      }
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            _isReloadingDueToUpdate = false;
                          });
                        }
                      });
                    },
                    isActive: true,
                    label: Text(hasExistingPayment ? tr.updatePayment : tr.confirmPayment),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _advancePayment() {
    final tr = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: advanceFormKey,
        child: ZTextFieldEntitled(
          keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
          inputFormat: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
            SmartThousandsDecimalFormatter(),
          ],
          controller: advanceAmount,
          title: tr.advanceAmount,
        ),
      ),
    );
  }

  Widget _buildStepperWithData(ShippingDetailsModel shipping, AppLocalizations tr) {
    final blocState = context.watch<ShippingBloc>().state;
    final isLoading = blocState is ShippingListLoadingState && blocState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          tr.updateShipping,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Mobile Stepper Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStepIndicator(0, tr.order, _currentStep == 0),
                        _buildStepConnector(_currentStep > 0),
                        _buildStepIndicator(1, tr.shipping, _currentStep == 1),
                        _buildStepConnector(_currentStep > 1),
                        _buildStepIndicator(2, tr.expense, _currentStep == 2),
                        _buildStepConnector(_currentStep > 2),
                        _buildStepIndicator(3, tr.shippingCharges, _currentStep == 3),
                        _buildStepConnector(_currentStep > 3),
                        _buildStepIndicator(4, tr.summary, _currentStep == 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Step Content
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildOrderStep(shipping),
                _buildShippingStep(shipping),
                _buildExpensesStep(shipping),
                _buildPaymentStep(shipping),
                _buildSummaryStep(shipping),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: ZOutlineButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      label: Text(tr.back),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ZOutlineButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      if (_currentStep < 4) {
                        if (_validateStepChange(_currentStep, _currentStep + 1)) {
                          setState(() {
                            _currentStep++;
                          });
                        }
                      } else {
                        onFinish(shipping);
                      }
                    },
                    isActive: true,
                    label: Text(_currentStep < 4 ? tr.next : tr.finish),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewShippingStepper(AppLocalizations tr) {
    final blocState = context.watch<ShippingBloc>().state;
    final isLoading = blocState is ShippingListLoadingState && blocState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          tr.createNewShipping,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Mobile Stepper Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStepIndicator(0, tr.order, _currentStep == 0),
                        _buildStepConnector(_currentStep > 0),
                        _buildStepIndicator(1, tr.shipping, _currentStep == 1),
                        _buildStepConnector(_currentStep > 1),
                        _buildStepIndicator(2, tr.advancePayment, _currentStep == 2),
                        _buildStepConnector(_currentStep > 2),
                        _buildStepIndicator(3, tr.summary, _currentStep == 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Step Content
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildOrderStep(null),
                _buildShippingStep(null),
                _buildAdvancePaymentStep(),
                _buildSummaryStep(null),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(tr.back),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ZOutlineButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      if (_currentStep < 3) {
                        if (_validateStepChange(_currentStep, _currentStep + 1)) {
                          setState(() {
                            _currentStep++;
                          });
                        }
                      } else {
                        onFinish(null);
                      }
                    },
                    label: Text(_currentStep < 3 ? tr.next : tr.finish),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: .3),
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 10,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline.withValues(alpha: .3),
      ),
    );
  }

  Widget _buildOrderStep(ShippingDetailsModel? shipping) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _order(shipping: shipping),
    );
  }

  Widget _buildShippingStep(ShippingDetailsModel? shipping) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _shipping(shipping: shipping),
    );
  }

  Widget _buildExpensesStep(ShippingDetailsModel shipping) {
    return _buildExpensesView(shipping);
  }

  Widget _buildAdvancePaymentStep() {
    return _advancePayment();
  }

  Widget _buildPaymentStep(ShippingDetailsModel shipping) {
    return _buildPaymentView(shipping);
  }

  Widget _buildSummaryStep(ShippingDetailsModel? shipping) {
    return _buildSummaryView(shipping);
  }

  bool _validateStepChange(int currentStep, int requestedStep) {
    final tr = AppLocalizations.of(context)!;
    if (requestedStep > currentStep) {
      if (requestedStep == 1) {
        if (customerCtrl.text.isEmpty || productCtrl.text.isEmpty) {
          Utils.showOverlayMessage(
            context,
            message: tr.requiredField(tr.orderStep),
            isError: true,
          );
          return false;
        }
      }

      if (requestedStep == 2) {
        if (vehicleCtrl.text.isEmpty ||
            shpFrom.text.isEmpty ||
            shpTo.text.isEmpty ||
            shippingRent.text.isEmpty) {
          Utils.showOverlayMessage(
            context,
            message: tr.requiredField(tr.shippingStep),
            isError: true,
          );
          return false;
        }
      }
    }
    return true;
  }

  Widget _order({ShippingDetailsModel? shipping}) {
    final tr = AppLocalizations.of(context)!;
    bool isDelivered = shipping?.shpStatus == 1;
    TextStyle? title = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.outline);

    return Form(
      key: orderFormKey,
      child: Column(
        children: [
          GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
            readOnly: isDelivered,
            showAllOnFocus: true,
            controller: customerCtrl,
            title: tr.customer,
            hintText: tr.customer,
            isRequired: true,
            bloc: context.read<IndividualsBloc>(),
            fetchAllFunction: (bloc) => bloc.add(LoadIndividualsEvent()),
            searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent()),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr.required(tr.customer);
              }
              return null;
            },
            itemBuilder: (context, account) => Padding(
              padding: const EdgeInsets.all(12),
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
                customerId = value.perId!;
                customerCtrl.text = "${value.perName} ${value.perLastName}";
                cusAddress = value.addName ?? "";
                cusPhone = value.perPhone ?? "";
                cusEmail = value.perEmail ?? "";
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                orderFormKey.currentState?.validate();
              });
            },
            noResultsText: tr.noDataFound,
            showClearButton: true,
          ),
          const SizedBox(height: 16),

          GenericTextfield<ProductsModel, ProductsBloc, ProductsState>(
            readOnly: isDelivered,
            showAllOnFocus: true,
            controller: productCtrl,
            title: tr.products,
            hintText: tr.products,
            isRequired: true,
            bloc: context.read<ProductsBloc>(),
            fetchAllFunction: (bloc) => bloc.add(LoadProductsEvent()),
            searchFunction: (bloc, query) => bloc.add(LoadProductsEvent()),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr.required(tr.products);
              }
              return null;
            },
            itemBuilder: (context, product) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                product.proName ?? "",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            itemToString: (product) => product.proName ?? "",
            stateToLoading: (state) => state is ProductsLoadingState,
            loadingBuilder: (context) => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            stateToItems: (state) {
              if (state is ProductsLoadedState) {
                return state.products;
              }
              return [];
            },
            onSelected: (value) {
              setState(() {
                productId = value.proId!;
                productCtrl.text = value.proName ?? "";
                proCode = value.proCode ?? "";
                proDetails = value.proDetails ?? "";
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                orderFormKey.currentState?.validate();
              });
            },
            noResultsText: tr.noDataFound,
            showClearButton: true,
          ),

          if (customerCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.customerInformation, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr.customer, style: title),
                            const SizedBox(height: 8),
                            Text(tr.mobile1, style: title),
                            const SizedBox(height: 8),
                            Text(tr.email, style: title),
                            const SizedBox(height: 8),
                            Text(tr.address, style: title),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customerCtrl.text),
                            const SizedBox(height: 8),
                            Text(cusPhone ?? ""),
                            const SizedBox(height: 8),
                            Text(cusEmail ?? ""),
                            const SizedBox(height: 8),
                            Text(cusAddress ?? ""),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (productCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.productDetails, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr.productCode, style: title),
                            const SizedBox(height: 8),
                            Text(tr.productName, style: title),
                            const SizedBox(height: 8),
                            Text(tr.details, style: title),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(proCode ?? ""),
                            const SizedBox(height: 8),
                            Text(productCtrl.text),
                            const SizedBox(height: 8),
                            Text(proDetails ?? ""),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _shipping({ShippingDetailsModel? shipping}) {
    final tr = AppLocalizations.of(context)!;
    bool isDelivered = shipping?.shpStatus == 1;

    return Form(
      key: shippingFormKey,
      child: Column(
        children: [
          GenericTextfield<VehicleModel, VehicleBloc, VehicleState>(
            showAllOnFocus: true,
            readOnly: isDelivered,
            controller: vehicleCtrl,
            title: tr.vehicles,
            hintText: tr.vehicles,
            isRequired: true,
            bloc: context.read<VehicleBloc>(),
            fetchAllFunction: (bloc) => bloc.add(LoadVehicleEvent()),
            searchFunction: (bloc, query) => bloc.add(LoadVehicleEvent()),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr.required(tr.vehicle);
              }
              return null;
            },
            itemBuilder: (context, veh) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "${veh.vclModel} | ${veh.vclPlateNo}",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            itemToString: (veh) => "${veh.vclModel} | ${veh.vclPlateNo}",
            stateToLoading: (state) => state is VehicleLoadingState,
            loadingBuilder: (context) => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            stateToItems: (state) {
              if (state is VehicleLoadedState) {
                return state.vehicles;
              }
              return [];
            },
            onSelected: (value) {
              setState(() {
                vehicleId = value.vclId!;
                vehicleCtrl.text = "${value.vclModel} | ${value.vclPlateNo}";
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                shippingFormKey.currentState?.validate();
              });
            },
            noResultsText: tr.noDataFound,
            showClearButton: true,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ZTextFieldEntitled(
                  readOnly: isDelivered,
                  isRequired: true,
                  controller: shpFrom,
                  title: tr.shpFrom,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr.required(tr.shpFrom);
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: ZTextFieldEntitled(
                  isRequired: true,
                  readOnly: isDelivered,
                  controller: shpTo,
                  title: tr.shpTo,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr.required(tr.shpTo);
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _datePicker(
                  isActive: isDelivered,
                  date: shpFromGregorian,
                  title: tr.loadingDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _datePicker(
                  isActive: isDelivered,
                  date: shpToGregorian,
                  title: tr.unloadingDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ZTextFieldEntitled(
                  readOnly: isDelivered,
                  isRequired: true,
                  controller: loadingSize,
                  title: tr.loadingSize,
                  inputFormat: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                    SmartThousandsDecimalFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr.required(tr.loadingSize);
                    }
                    final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                    final amount = double.tryParse(clean);
                    if (amount == null || amount <= 0) {
                      return tr.amountGreaterZero;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: ZTextFieldEntitled(
                  readOnly: isDelivered,
                  isRequired: true,
                  controller: unloadingSize,
                  title: tr.unloadingSize,
                  inputFormat: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                    SmartThousandsDecimalFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr.required(tr.unloadingSize);
                    }
                    final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
                    final amount = double.tryParse(clean);
                    if (amount == null || amount <= 0) {
                      return tr.amountGreaterZero;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: UnitDropdown(
                  isActive: isDelivered,
                  selectedUnit: UnitType.fromDatabaseValue(shipping?.shpUnit ?? ""),
                  onUnitSelected: (e) {
                    setState(() {
                      unit = e.name;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ZTextFieldEntitled(
            readOnly: isDelivered,
            isRequired: true,
            keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
            inputFormat: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
              SmartThousandsDecimalFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr.required(tr.shippingRent);
              }
              final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
              final amount = double.tryParse(clean);
              if (amount == null || amount <= 0.0) {
                return tr.amountGreaterZero;
              }
              return null;
            },
            controller: shippingRent,
            title: tr.shippingRent,
          ),
          const SizedBox(height: 16),

          ZTextFieldEntitled(
            readOnly: isDelivered,
            controller: remark,
            title: tr.remark,
            keyboardInputType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesView(ShippingDetailsModel shipping) {
    final tr = AppLocalizations.of(context)!;
    final expenses = shipping.expenses ?? [];
    final color = Theme.of(context).colorScheme;

    return BlocSelector<ShippingBloc, ShippingState, int?>(
      selector: (state) => state.loadingShpId,
      builder: (context, loadingShpId) {
        final isLoading = loadingShpId == widget.shippingId;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shipping.shpStatus != 1) ...[
                Form(
                  key: expenseFormKey,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.outline.withValues(alpha: .2)),
                    ),
                    child: Column(
                      children: [
                        GenericTextfield<AccountsModel, AccountsBloc, AccountsState>(
                          showAllOnFocus: true,
                          controller: accountController,
                          title: tr.accounts,
                          hintText: tr.accNameOrNumber,
                          isRequired: true,
                          bloc: context.read<AccountsBloc>(),
                          fetchAllFunction: (bloc) => bloc.add(
                            LoadAccountsFilterEvent(
                              include: '11,12',
                              ccy: "$baseCurrency",
                              exclude: "",
                            ),
                          ),
                          searchFunction: (bloc, query) => bloc.add(
                            LoadAccountsFilterEvent(
                              include: '11,12',
                              ccy: "$baseCurrency",
                              exclude: "",
                              input: query,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr.required(tr.accounts);
                            }
                            if (expenseAccNumber == null) {
                              return tr.required(tr.accounts);
                            }
                            return null;
                          },
                          itemBuilder: (context, account) => Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${account.accNumber} | ${account.accName}",
                                  style: Theme.of(context).textTheme.bodyLarge,
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
                          onSelected: (value) {
                            setState(() {
                              expenseAccNumber = value.accNumber;
                              accountController.text = "${value.accNumber} | ${value.accName}";
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              expenseFormKey.currentState?.validate();
                            });
                          },
                          noResultsText: tr.noDataFound,
                          showClearButton: true,
                        ),
                        const SizedBox(height: 16),

                        ZTextFieldEntitled(
                          isRequired: true,
                          keyboardInputType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormat: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                            SmartThousandsDecimalFormatter(decimalDigits: 4),
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
                          controller: expenseAmount,
                          title: tr.amount,
                        ),
                        const SizedBox(height: 16),

                        ZTextFieldEntitled(
                          keyboardInputType: TextInputType.multiline,
                          controller: expenseNarration,
                          title: tr.narration,
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            if (_selectedExpenseForEdit != null)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedExpenseForEdit = null;
                                      _clearExpenseForm();
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(tr.cancel),
                                ),
                              ),
                            if (_selectedExpenseForEdit != null) const SizedBox(width: 12),
                            Expanded(
                              child: ZOutlineButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                  _handleExpenseAction();
                                },
                                isActive: true,
                                label: isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                )
                                    : Text(_selectedExpenseForEdit != null ? tr.update : tr.create),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                '${tr.expense} (${expenses.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (expenses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.outline.withValues(alpha: .2)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_outlined, size: 48, color: color.outline),
                        const SizedBox(height: 16),
                        Text(
                          tr.noExpenseRecorded,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: color.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final isSelected = _selectedExpenseForEdit?.trdReference == expense.trdReference;

                    return GestureDetector(
                      onTap: isLoading ? null : () => _loadExpenseForEdit(expense),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? color.primary.withValues(alpha: .05) : color.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color.primary
                                : color.outline.withValues(alpha: .2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    expense.trdReference ?? "",
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: color.primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${expense.amount?.toAmount()} ${expense.currency}",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${expense.accNumber} | ${expense.accName}",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (expense.narration != null && expense.narration!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                expense.narration!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: color.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryView(ShippingDetailsModel? shipping) {
    final summaryData = _getSummaryData(shipping);
    final hasShippingDetails = shipping != null;
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    bool paymentNeedsUpdate = false;
    bool canBeDelivered = true;
    String paymentStatusMessage = "";

    if (hasShippingDetails) {
      paymentNeedsUpdate = _paymentNeedsUpdate(shipping);
      canBeDelivered = _canMarkAsDelivered(shipping);

      if (paymentNeedsUpdate) {
        final totalAmount = _parseAmount(shipping.total);
        double existingPaid = 0.0;
        if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
          final payment = shipping.pyment!.first;
          existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
        }
        paymentStatusMessage = "${tr.paymentNeedsUpdateTitle}: ${existingPaid.toAmount()}, ${tr.requiredTitle}: ${totalAmount.toAmount()}";
      } else if (!canBeDelivered && shipping.shpStatus != 1) {
        final totalAmount = _parseAmount(shipping.total);
        double existingPaid = 0.0;
        if (shipping.pyment != null && shipping.pyment!.isNotEmpty) {
          final payment = shipping.pyment!.first;
          existingPaid = _parseAmount(payment.cashAmount) + _parseAmount(payment.cardAmount);
        }
        paymentStatusMessage = "${tr.cannotMarkDeliveredMsg}: ${existingPaid.toAmount()}, ${tr.requiredTitle}: ${totalAmount.toAmount()}";
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shipping != null)
            if (summaryData['status'] != null && summaryData['status']!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: summaryData['status'] == "1" ? Colors.green.withValues(alpha: .1) : Colors.orange.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: summaryData['status'] == "1" ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      summaryData['status'] == "1" ? Icons.check_circle : Icons.schedule,
                      color: summaryData['status'] == "1" ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        summaryData['status'] == "1" ? tr.delivered : tr.pendingTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: summaryData['status'] == "1" ? Colors.green : Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Switch(
                      value: shpStatus == 1,
                      onChanged: (e) {
                        if (e && !canBeDelivered) {
                          Utils.showOverlayMessage(
                            context,
                            message: tr.paymentIsNotComplete,
                            isError: true,
                          );
                          return;
                        }
                        if (e && paymentNeedsUpdate) {
                          Utils.showOverlayMessage(
                            context,
                            message: tr.paymentNeedsUpdate,
                            isError: true,
                          );
                          return;
                        }
                        setState(() {
                          shpStatus = e ? 1 : 0;
                        });
                      },
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

          if (paymentStatusMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: paymentNeedsUpdate ? Colors.orange.withValues(alpha: .1) : Colors.red.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: paymentNeedsUpdate ? Colors.orange : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    paymentNeedsUpdate ? Icons.warning : Icons.error,
                    color: paymentNeedsUpdate ? Colors.orange : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      paymentStatusMessage,
                      style: TextStyle(
                        color: paymentNeedsUpdate ? Colors.orange : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Summary Cards
          _buildSummaryCard(
            title: tr.order,
            icon: Icons.shopping_cart,
            color: color.primary,
            children: [
              _buildSummaryRow(tr.customer, summaryData['customer'] ?? ''),
              _buildSummaryRow(tr.productName, summaryData['product'] ?? ''),
            ],
          ),

          const SizedBox(height: 12),

          _buildSummaryCard(
            title: tr.shipping,
            icon: Icons.local_shipping,
            color: color.secondary,
            children: [
              _buildSummaryRow(tr.vehicle, summaryData['vehicle'] ?? ''),
              _buildSummaryRow(tr.fromTo, "${summaryData['from']} - ${summaryData['to']}"),
              _buildSummaryRow(tr.loadingDate, shpFromGregorian),
              _buildSummaryRow(tr.unloadingDate, shpToGregorian),
              _buildSummaryRow(tr.loadingSize, summaryData['loadingSize'] ?? ''),
              _buildSummaryRow(tr.unloadingSize, summaryData['unloadingSize'] ?? ''),
              _buildSummaryRow(tr.shippingRent, summaryData['rent']?.toAmount() ?? ''),
              if (summaryData['total'] != null && summaryData['total']!.isNotEmpty)
                _buildSummaryRow(tr.totalTitle, "${summaryData['total']?.toAmount()}", isHighlighted: true),
            ],
          ),

          if (hasShippingDetails && shipping.expenses != null && shipping.expenses!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSummaryCard(
              title: tr.expense,
              icon: Icons.receipt,
              color: Colors.orange,
              children: shipping.expenses!.map(
                    (expense) => _buildSummaryRow(
                  "${expense.accName}",
                  "${expense.amount?.toAmount()} ${expense.currency}",
                  subtitle: expense.accNumber?.toString(),
                ),
              ).toList(),
            ),
          ],

          if (hasShippingDetails && shipping.pyment != null && shipping.pyment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSummaryCard(
              title: tr.shippingCharges,
              icon: Icons.payment,
              color: Colors.green,
              children: [
                ...shipping.pyment!.map(
                      (payment) => _buildSummaryRow(
                    tr.referenceNumber,
                    payment.trdReference ?? "",
                  ),
                ),
                ...shipping.pyment!.map(
                      (payment) => _buildSummaryRow(
                    tr.cashAmount,
                    "${payment.cashAmount?.toAmount()}",
                  ),
                ),
                if (shipping.pyment?.first.cardAmount != null) ...[
                  ...shipping.pyment!.map(
                        (payment) => _buildSummaryRow(
                      tr.accountPayment,
                      "${payment.cardAmount?.toAmount()}",
                    ),
                  ),
                  ...shipping.pyment!.map(
                        (payment) => _buildSummaryRow(
                      tr.accountNumber,
                      "${payment.accountCustomer}",
                    ),
                  ),
                ]
              ],
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loadingTitle),
          ],
        ),
      ),
    );
  }

  ShippingModel _getFormDataAsShippingModel() {
    return ShippingModel(
      shpLoadSize: loadingSize.text,
      shpUnloadSize: unloadingSize.text,
      shpTo: shpTo.text,
      shpFrom: shpFrom.text,
      shpRent: shippingRent.text.cleanAmount,
      productId: productId,
      vehicleId: vehicleId,
      customerId: customerId,
      shpArriveDate: DateTime.tryParse(shpToGregorian),
      shpMovingDate: DateTime.tryParse(shpFromGregorian),
      usrName: usrName ?? "",
      advanceAmount: advanceAmount.text.cleanAmount,
      remark: remark.text,
      shpId: widget.shippingId,
      shpUnit: unit ?? "TN",
      shpStatus: shpStatus ?? 0,
    );
  }

  void _clearExpenseForm() {
    expenseAmount.clear();
    expenseNarration.clear();
    accountController.clear();
    expenseAccNumber = null;
    _selectedExpenseForEdit = null;
    if (expenseFormKey.currentState != null) {
      expenseFormKey.currentState!.reset();
    }
  }

  void onFinish(ShippingDetailsModel? existingShipping) async {
    final tr = AppLocalizations.of(context)!;
    final bloc = context.read<ShippingBloc>();

    if (customerId == null) {
      Utils.showOverlayMessage(
        context,
        message: tr.selectCustomer,
        isError: true,
      );
      setState(() => _currentStep = 0);
      return;
    }

    if (productId == null) {
      Utils.showOverlayMessage(
        context,
        message: tr.selectProduct,
        isError: true,
      );
      setState(() => _currentStep = 0);
      return;
    }

    if (vehicleId == null) {
      Utils.showOverlayMessage(
        context,
        message: tr.selectVehicle,
        isError: true,
      );
      setState(() => _currentStep = 1);
      return;
    }

    if (shpFrom.text.isEmpty || shpTo.text.isEmpty) {
      Utils.showOverlayMessage(
        context,
        message: tr.fillShippingLocations,
        isError: true,
      );
      setState(() => _currentStep = 1);
      return;
    }

    if (shpStatus == 1 && existingShipping != null) {
      if (!_canMarkAsDelivered(existingShipping)) {
        Utils.showOverlayMessage(
          context,
          message: tr.paymentIsNotComplete,
          isError: true,
        );
        setState(() => _currentStep = 3);
        return;
      }

      if (_paymentNeedsUpdate(existingShipping)) {
        Utils.showOverlayMessage(
          context,
          message: tr.paymentNeedsUpdate,
          isError: true,
        );
        setState(() => _currentStep = 3);
        return;
      }
    }

    final data = ShippingModel(
      shpId: widget.shippingId,
      shpLoadSize: loadingSize.text.cleanAmount,
      shpUnloadSize: unloadingSize.text.cleanAmount,
      shpTo: shpTo.text,
      shpFrom: shpFrom.text,
      shpRent: shippingRent.text.cleanAmount,
      productId: productId!,
      vehicleId: vehicleId!,
      customerId: customerId!,
      shpArriveDate: DateTime.tryParse(shpToGregorian),
      shpMovingDate: DateTime.tryParse(shpFromGregorian),
      usrName: usrName ?? "",
      advanceAmount: advanceAmount.text.cleanAmount,
      remark: remark.text,
      shpStatus: shpStatus ?? 0,
      shpUnit: unit ?? "TN",
    );

    if (widget.shippingId != null) {
      bloc.add(UpdateShippingEvent(data));
    } else {
      bloc.add(AddShippingEvent(data));
    }
  }

  Map<String, String> _getSummaryData(ShippingDetailsModel? shipping) {
    if (shipping != null) {
      return {
        'customer': shipping.customer ?? customerCtrl.text,
        'product': shipping.proName ?? productCtrl.text,
        'vehicle': shipping.vehicle ?? vehicleCtrl.text,
        'from': shipping.shpFrom ?? shpFrom.text,
        'to': shipping.shpTo ?? shpTo.text,
        'loadingSize': "${shipping.shpLoadSize ?? loadingSize.text} ${shipping.shpUnit ?? unit ?? ''}",
        'unloadingSize': "${shipping.shpUnloadSize ?? unloadingSize.text} ${shipping.shpUnit ?? unit ?? ''}",
        'rent': shipping.shpRent ?? shippingRent.text,
        'total': shipping.total ?? "",
        'status': shipping.shpStatus?.toString() ?? "",
      };
    } else {
      final formData = _getFormDataAsShippingModel();
      return {
        'customer': formData.customer ?? customerCtrl.text,
        'product': formData.proName ?? productCtrl.text,
        'vehicle': formData.vehicle ?? vehicleCtrl.text,
        'from': formData.shpFrom ?? shpFrom.text,
        'to': formData.shpTo ?? shpTo.text,
        'loadingSize': "${formData.shpLoadSize ?? loadingSize.text} ${formData.shpUnit ?? unit ?? 'TN'}",
        'unloadingSize': "${formData.shpUnloadSize ?? unloadingSize.text} ${formData.shpUnit ?? unit ?? 'TN'}",
        'rent': formData.shpRent ?? shippingRent.text,
        'total': formData.total ?? "",
        'status': formData.shpStatus?.toString() ?? "",
      };
    }
  }

  void _loadExpenseForEdit(Expense expense) {
    setState(() {
      _selectedExpenseForEdit = expense;
      expenseAmount.text = expense.amount ?? '';
      expenseNarration.text = expense.narration ?? '';

      if (expense.accNumber != null && expense.accName != null) {
        accountController.text = '${expense.accNumber} | ${expense.accName}';
        expenseAccNumber = expense.accNumber;
      }
    });
  }

  void _handleExpenseAction() {
    if (expenseFormKey.currentState == null || !expenseFormKey.currentState!.validate()) {
      Utils.showOverlayMessage(context, message: AppLocalizations.of(context)!.requiredField(''), isError: true);
      return;
    }

    setState(() {
      _isReloadingDueToUpdate = true;
    });
    if (_selectedExpenseForEdit != null) {
      context.read<ShippingBloc>().add(
        UpdateShippingExpenseEvent(
          shpId: widget.shippingId!,
          trnReference: _selectedExpenseForEdit!.trdReference!,
          amount: expenseAmount.text.cleanAmount,
          narration: expenseNarration.text,
          usrName: usrName ?? "",
        ),
      );
    } else {
      context.read<ShippingBloc>().add(
        AddShippingExpenseEvent(
          shpId: widget.shippingId!,
          accNumber: expenseAccNumber!,
          amount: expenseAmount.text.cleanAmount,
          narration: expenseNarration.text,
          usrName: usrName ?? "",
        ),
      );
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isReloadingDueToUpdate = false;
        });
      }
    });
  }

  Widget _datePicker({required String date, required String title, bool? isActive}) {
    return GenericDatePicker(
      isActive: isActive ?? false,
      label: title,
      initialGregorianDate: date,
      onDateChanged: (newDate) {
        setState(() {
          if (title == 'Loading Date') {
            shpFromGregorian = newDate;
          } else {
            shpToGregorian = newDate;
          }
        });
      },
    );
  }
}

// Tablet View Implementation (could be similar to mobile with adjustments)
class _Tablet extends StatefulWidget {
  final int? shippingId;
  final int? perId;
  const _Tablet({this.shippingId, this.perId});

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  // For tablets, we can use a combination of desktop and mobile approaches
  // For simplicity, we'll use the mobile implementation with some adjustments
  // You can customize this further based on your needs

  @override
  Widget build(BuildContext context) {
    // Reuse mobile implementation with maybe a different layout
    return _Mobile(shippingId: widget.shippingId, perId: widget.perId);
  }
}