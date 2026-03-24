import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchGLAT/Print/glat_print.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchGLAT/bloc/glat_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchGLAT/model/glat_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../../../../Features/Other/responsive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../bloc/transactions_bloc.dart';

class GlatView extends StatelessWidget {
  const GlatView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  GlatModel? loadedGlat;
  final company = ReportModel();
  bool isPrint = true;
  Uint8List _companyLogo = Uint8List(0);

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
    final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = auth.loginData;

    return BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
      builder: (context, state) {
        if (state is CompanyProfileLoadedState) {
          company.comName = state.company.comName ?? "";
          company.comAddress = state.company.addName ?? "";
          company.compPhone = state.company.comPhone ?? "";
          company.comEmail = state.company.comEmail ?? "";
          company.statementDate = DateTime.now().toFullDateTime;
          final base64Logo = state.company.comLogo;
          if (base64Logo != null && base64Logo.isNotEmpty) {
            try {
              _companyLogo = base64Decode(base64Logo);
              company.comLogo = _companyLogo;
            } catch (e) {
              _companyLogo = Uint8List(0);
            }
          }
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: color.surface,
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 8,
                    right: 8,
                    bottom: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: color.onSurface.withValues(alpha: .1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr.transactionDetails,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: BlocConsumer<GlatBloc, GlatState>(
                    listener: (context, state) {},
                    builder: (context, state) {
                      if (state is GlatErrorState) {
                        return Center(
                          child: NoDataWidget(
                            message: state.message,
                          ),
                        );
                      }

                      if (state is GlatLoadingState) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (state is GlatLoadedState) {
                        loadedGlat = state.data;
                        final glat = state.data;
                        final transaction = glat.transaction;

                        // Check if any buttons should be shown
                        final bool showAuthorizeButton = glat.transaction?.trnStatus == 0 && login.usrName != transaction?.maker;
                        final bool showDeleteButton = glat.transaction?.trnStatus == 0 && transaction?.maker == login.usrName;
                        final bool showAnyButton = showAuthorizeButton || showDeleteButton;

                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Amount Card
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color.primary.withValues(alpha: .1),
                                            color.primary.withValues(alpha: .05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: color.primary.withValues(alpha: .2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tr.amount,
                                                style: textTheme.titleSmall?.copyWith(
                                                  color: color.onSurface.withValues(alpha: .7),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${glat.vclPurchaseAmount?.toAmount() ?? "0.00"} ${transaction?.purchaseCurrency ?? ""}",
                                                style: textTheme.headlineSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: color.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              _buildStatusBadge(context, glat.transaction?.trnStateText ?? ""),
                                              const SizedBox(width: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: color.outline.withValues(alpha: .06),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                child: IconButton(
                                                  onPressed: () => getPrinted(data: loadedGlat!, company: company),
                                                  icon: Icon(Icons.print, size: 20),
                                                  constraints: const BoxConstraints(
                                                    minWidth: 40,
                                                    minHeight: 40,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Vehicle Details Card
                                    ZCover(
                                      color: color.surface,
                                      radius: 8,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.directions_car, size: 20, color: color.primary),
                                                const SizedBox(width: 8),
                                                Text(
                                                  tr.vehicleDetails,
                                                  style: textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 20, thickness: 1),
                                            _buildMobileDetailRow(tr.vehicleModel, glat.vclModel ?? "-"),
                                            _buildMobileDetailRow(tr.manufacturedYear, glat.vclYear ?? "-"),
                                            _buildMobileDetailRow(tr.vinNumber, glat.vclVinNo ?? "-"),
                                            _buildMobileDetailRow(tr.vehiclePlate, glat.vclPlateNo ?? "-"),
                                            _buildMobileDetailRow(tr.fuelType, glat.vclFuelType ?? "-"),
                                            _buildMobileDetailRow(tr.enginePower, glat.vclEnginPower ?? "-"),
                                            _buildMobileDetailRow(tr.categoryTitle, glat.vclBodyType ?? "-"),
                                            _buildMobileDetailRow(tr.meter, "${glat.vclOdoMeter ?? 0} km"),
                                            _buildMobileDetailRow(tr.driver, glat.driver ?? "-"),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Transaction Details Card
                                    ZCover(
                                      color: color.surface,
                                      radius: 8,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.receipt_long, size: 20, color: color.primary),
                                                const SizedBox(width: 8),
                                                Text(
                                                  tr.transactionDetails,
                                                  style: textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 20, thickness: 1),
                                            _buildMobileDetailRow(tr.referenceNumber, transaction?.trnReference ?? "-"),
                                            _buildMobileDetailRow(tr.debitAccount, "${transaction?.debitAccount ?? "-"}"),
                                            _buildMobileDetailRow(tr.creditAccount, "${transaction?.creditAccount ?? "-"}"),
                                            _buildMobileDetailRow(tr.maker, transaction?.maker ?? "-"),
                                            _buildMobileDetailRow(
                                              tr.checker,
                                              transaction?.checker ?? "-",
                                              isHighlighted: transaction?.checker == null,
                                            ),
                                            _buildMobileDetailRow(
                                              tr.status,
                                              glat.transaction?.trnStatus == 1 ? tr.authorizedTitle : tr.pendingTitle,
                                              isHighlighted: glat.transaction?.trnStatus == 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Narration Card
                                    if (transaction?.narration?.isNotEmpty == true)
                                      ZCover(
                                        color: color.surface,
                                        radius: 8,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.description, size: 20, color: color.primary),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    tr.narration,
                                                    style: textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 20, thickness: 1),
                                              Text(
                                                transaction!.narration!,
                                                style: textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Action Buttons
                            if (showAnyButton) ...[
                              Container(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: MediaQuery.of(context).padding.bottom + 16,
                                  top: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: color.surface,
                                  border: Border(
                                    top: BorderSide(
                                      color: color.onSurface.withValues(alpha: .1),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr.actions,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: color.primary,
                                      ),
                                    ),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (showDeleteButton)
                                          Expanded(
                                            child: ZOutlineButton(
                                              height: 48,
                                              icon: isDeleteLoading ? null : Icons.delete_outline_rounded,
                                              isActive: true,
                                              backgroundHover: color.error,
                                              onPressed: () {
                                                context.read<TransactionsBloc>().add(
                                                  DeletePendingTxnEvent(
                                                    reference: loadedGlat?.transaction?.trnReference ?? "",
                                                    usrName: login.usrName ?? "",
                                                  ),
                                                );
                                              },
                                              label: isDeleteLoading
                                                  ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                ),
                                              )
                                                  : Text(tr.delete),
                                            ),
                                          ),
                                        if (showDeleteButton && showAuthorizeButton)
                                          const SizedBox(width: 12),
                                        if (showAuthorizeButton)
                                          Expanded(
                                            child: ZOutlineButton(
                                              height: 48,
                                              onPressed: () {
                                                context.read<TransactionsBloc>().add(
                                                  AuthorizeTxnEvent(
                                                    reference: loadedGlat?.transaction?.trnReference ?? "",
                                                    usrName: login.usrName ?? "",
                                                  ),
                                                );
                                              },
                                              icon: isAuthorizeLoading ? null : Icons.check_circle_outline,
                                              isActive: true,
                                              backgroundColor: color.primary,
                                              textColor: color.onPrimary,
                                              label: isAuthorizeLoading
                                                  ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                  color: Colors.white,
                                                ),
                                              )
                                                  : Text(tr.authorize),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final color = Theme.of(context).colorScheme;
    final isAuthorized = status.toLowerCase().contains("authorize");
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAuthorized ? color.primary.withAlpha(30) : Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isAuthorized ? color.primary.withAlpha(100) : Colors.orange.withAlpha(100),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAuthorized ? Icons.verified : Icons.pending,
            size: 12,
            color: isAuthorized ? color.primary : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            status == "Pending" ? tr.pendingTitle : tr.authorizedTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAuthorized ? color.primary : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailRow(String label, String value, {bool isHighlighted = false}) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color.onSurface.withValues(alpha: .7),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                color: isHighlighted ? Colors.green[700] : color.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void getPrinted({required GlatModel data, required ReportModel company}) {
    if (isPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<GlatModel>(
            data: data,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return GlatPrintSettings().printPreview(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                data: data,
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
              return GlatPrintSettings().printDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                data: data,
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
              return GlatPrintSettings().createDocument(
                data: data,
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      });
    }
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  GlatModel? loadedGlat;
  final company = ReportModel();
  bool isPrint = true;
  Uint8List _companyLogo = Uint8List(0);

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
    final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = auth.loginData;

    return BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
      builder: (context, state) {
        if (state is CompanyProfileLoadedState) {
          company.comName = state.company.comName ?? "";
          company.comAddress = state.company.addName ?? "";
          company.compPhone = state.company.comPhone ?? "";
          company.comEmail = state.company.comEmail ?? "";
          company.statementDate = DateTime.now().toFullDateTime;
          final base64Logo = state.company.comLogo;
          if (base64Logo != null && base64Logo.isNotEmpty) {
            try {
              _companyLogo = base64Decode(base64Logo);
              company.comLogo = _companyLogo;
            } catch (e) {
              _companyLogo = Uint8List(0);
            }
          }
        }

        return ZFormDialog(
          onAction: null,
          title: tr.transactionDetails,
          isActionTrue: false,
          width: 800,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BlocConsumer<GlatBloc, GlatState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (state is GlatErrorState) {
                  return NoDataWidget(
                    message: state.message,
                  );
                }

                if (state is GlatLoadingState) {
                  return const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is GlatLoadedState) {
                  loadedGlat = state.data;
                  final glat = state.data;
                  final transaction = glat.transaction;

                  // Check if any buttons should be shown
                  final bool showAuthorizeButton = glat.transaction?.trnStatus == 0 && login.usrName != transaction?.maker;
                  final bool showDeleteButton = glat.transaction?.trnStatus == 0 && transaction?.maker == login.usrName;
                  final bool showAnyButton = showAuthorizeButton || showDeleteButton;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Amount and Actions
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Amount Card
                            ZCover(
                              color: color.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr.amount,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: color.onSurface.withValues(alpha: .7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${glat.vclPurchaseAmount?.toAmount() ?? "0.00"} ${transaction?.purchaseCurrency ?? ""}",
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: color.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _buildStatusBadge(context, glat.transaction?.trnStateText ?? ""),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: color.outline.withValues(alpha: .06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: () => getPrinted(data: loadedGlat!, company: company),
                                    icon: const Icon(Icons.print),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Two Column Layout for Vehicle and Transaction Details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle Details Card
                          Expanded(
                            child: ZCover(
                              color: color.surface,
                              radius: 8,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.directions_car, size: 20, color: color.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          tr.vehicleDetails,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20, thickness: 1),
                                    _buildTabletDetailRow(tr.vehicleModel, glat.vclModel ?? "-"),
                                    _buildTabletDetailRow(tr.manufacturedYear, glat.vclYear ?? "-"),
                                    _buildTabletDetailRow(tr.vinNumber, glat.vclVinNo ?? "-"),
                                    _buildTabletDetailRow(tr.vehiclePlate, glat.vclPlateNo ?? "-"),
                                    _buildTabletDetailRow(tr.fuelType, glat.vclFuelType ?? "-"),
                                    _buildTabletDetailRow(tr.enginePower, glat.vclEnginPower ?? "-"),
                                    _buildTabletDetailRow(tr.categoryTitle, glat.vclBodyType ?? "-"),
                                    _buildTabletDetailRow(tr.meter, "${glat.vclOdoMeter ?? 0} km"),
                                    _buildTabletDetailRow(tr.driver, glat.driver ?? "-"),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Transaction Details Card
                          Expanded(
                            child: ZCover(
                              color: color.surface,
                              radius: 8,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.receipt_long, size: 20, color: color.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          tr.transactionDetails,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20, thickness: 1),
                                    _buildTabletDetailRow(tr.referenceNumber, transaction?.trnReference ?? "-"),
                                    _buildTabletDetailRow(tr.debitAccount, "${transaction?.debitAccount ?? "-"}"),
                                    _buildTabletDetailRow(tr.creditAccount, "${transaction?.creditAccount ?? "-"}"),
                                    _buildTabletDetailRow(tr.maker, transaction?.maker ?? "-"),
                                    _buildTabletDetailRow(
                                      tr.checker,
                                      transaction?.checker ?? "-",
                                      isHighlighted: transaction?.checker == null,
                                    ),
                                    _buildTabletDetailRow(
                                      tr.status,
                                      glat.transaction?.trnStatus == 1 ? tr.authorizedTitle : tr.pendingTitle,
                                      isHighlighted: glat.transaction?.trnStatus == 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Narration Card
                      if (transaction?.narration?.isNotEmpty == true)
                        ZCover(
                          color: color.surface,
                          radius: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description, size: 20, color: color.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      tr.narration,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, thickness: 1),
                                Text(
                                  transaction!.narration!,
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Action Buttons
                      if (showAnyButton) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (showDeleteButton)
                                ZOutlineButton(
                                  width: 140,
                                  height: 45,
                                  icon: isDeleteLoading ? null : Icons.delete_outline_rounded,
                                  isActive: true,
                                  backgroundHover: color.error,
                                  onPressed: () {
                                    context.read<TransactionsBloc>().add(
                                      DeletePendingTxnEvent(
                                        reference: loadedGlat?.transaction?.trnReference ?? "",
                                        usrName: login.usrName ?? "",
                                      ),
                                    );
                                  },
                                  label: isDeleteLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  )
                                      : Text(tr.delete),
                                ),
                              if (showDeleteButton && showAuthorizeButton)
                                const SizedBox(width: 12),
                              if (showAuthorizeButton)
                                ZOutlineButton(
                                  width: 140,
                                  height: 45,
                                  onPressed: () {
                                    context.read<TransactionsBloc>().add(
                                      AuthorizeTxnEvent(
                                        reference: loadedGlat?.transaction?.trnReference ?? "",
                                        usrName: login.usrName ?? "",
                                      ),
                                    );
                                  },
                                  icon: isAuthorizeLoading ? null : Icons.check_circle_outline,
                                  isActive: true,
                                  backgroundColor: color.primary,
                                  textColor: color.onPrimary,
                                  label: isAuthorizeLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                      : Text(tr.authorize),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final color = Theme.of(context).colorScheme;
    final isAuthorized = status.toLowerCase().contains("authorize");
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAuthorized ? color.primary.withAlpha(30) : Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isAuthorized ? color.primary.withAlpha(100) : Colors.orange.withAlpha(100),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAuthorized ? Icons.verified : Icons.pending,
            size: 14,
            color: isAuthorized ? color.primary : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            status == "Pending" ? tr.pendingTitle : tr.authorizedTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAuthorized ? color.primary : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletDetailRow(String label, String value, {bool isHighlighted = false}) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color.onSurface.withValues(alpha: .7),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                color: isHighlighted ? Colors.green[700] : color.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void getPrinted({required GlatModel data, required ReportModel company}) {
    if (isPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<GlatModel>(
            data: data,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return GlatPrintSettings().printPreview(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                data: data,
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
              return GlatPrintSettings().printDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                data: data,
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
              return GlatPrintSettings().createDocument(
                data: data,
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      });
    }
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  GlatModel? loadedGlat;
  final company = ReportModel();
  bool isPrint = true;
  Uint8List _companyLogo = Uint8List(0);

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
    final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = auth.loginData;

    return BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
      builder: (context, state) {
        if (state is CompanyProfileLoadedState) {
          company.comName = state.company.comName ?? "";
          company.comAddress = state.company.addName ?? "";
          company.compPhone = state.company.comPhone ?? "";
          company.comEmail = state.company.comEmail ?? "";
          company.statementDate = DateTime.now().toFullDateTime;
          final base64Logo = state.company.comLogo;
          if (base64Logo != null && base64Logo.isNotEmpty) {
            try {
              _companyLogo = base64Decode(base64Logo);
              company.comLogo = _companyLogo;
            } catch (e) {
              _companyLogo = Uint8List(0);
            }
          }
        }

        return ZFormDialog(
          onAction: null,
          title: tr.transactionDetails,
          isActionTrue: false,
          width: 750,
          child: SingleChildScrollView(
            child: BlocBuilder<GlatBloc, GlatState>(
              builder: (context, state) {
                if (state is GlatErrorState) {
                  return NoDataWidget(
                    message: state.message,
                  );
                }

                if (state is GlatLoadingState) {
                  return const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is GlatLoadedState) {
                  loadedGlat = state.data;
                  final glat = state.data;
                  final transaction = glat.transaction;

                  // Check if any buttons should be shown
                  final bool showAuthorizeButton = glat.transaction?.trnStatus == 0 && login.usrName != transaction?.maker;
                  final bool showDeleteButton = glat.transaction?.trnStatus == 0 && transaction?.maker == login.usrName;
                  final bool showAnyButton = showAuthorizeButton || showDeleteButton;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Main Amount Card
                            ZCover(
                              color: color.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr.amount,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: color.onSurface.withValues(alpha: .7),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${glat.vclPurchaseAmount?.toAmount() ?? "0.00"} ${transaction?.purchaseCurrency ?? ""}",
                                      style: textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: color.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Two Column Layout for Vehicle and Transaction Details
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vehicle Details Card
                            Expanded(
                              child: ZCover(
                                color: color.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.directions_car, size: 20, color: color.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            tr.vehicleDetails,
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20, thickness: 1),
                                      _buildDetailRow(tr.vehicleModel, glat.vclModel ?? "-"),
                                      _buildDetailRow(tr.manufacturedYear, glat.vclYear ?? "-"),
                                      _buildDetailRow(tr.vinNumber, glat.vclVinNo ?? "-"),
                                      _buildDetailRow(tr.vehiclePlate, glat.vclPlateNo ?? "-"),
                                      _buildDetailRow(tr.fuelType, glat.vclFuelType ?? "-"),
                                      _buildDetailRow(tr.enginePower, glat.vclEnginPower ?? "-"),
                                      _buildDetailRow(tr.categoryTitle, glat.vclBodyType ?? "-"),
                                      _buildDetailRow(tr.meter, "${glat.vclOdoMeter ?? 0} km"),
                                      _buildDetailRow(tr.driver, glat.driver ?? "-"),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Transaction Details Card
                            Expanded(
                              child: ZCover(
                                color: color.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.receipt_long, size: 20, color: color.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            tr.transactionDetails,
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20, thickness: 1),
                                      _buildDetailRow(tr.referenceNumber, transaction?.trnReference ?? "-"),
                                      _buildDetailRow(tr.debitAccount, "${transaction?.debitAccount ?? "-"}"),
                                      _buildDetailRow(tr.creditAccount, "${transaction?.creditAccount ?? "-"}"),
                                      _buildDetailRow(tr.maker, transaction?.maker ?? "-"),
                                      _buildDetailRow(
                                        tr.checker,
                                        transaction?.checker ?? "-",
                                        isHighlighted: transaction?.checker == null,
                                      ),
                                      _buildDetailRow(
                                        tr.status,
                                        glat.transaction?.trnStatus == 1 ? tr.authorizedTitle : tr.pendingTitle,
                                        isHighlighted: glat.transaction?.trnStatus == 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Narration Card
                      if (transaction?.narration?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: ZCover(
                            color: color.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.description, size: 20, color: color.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        tr.narration,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20, thickness: 1),
                                  Text(
                                    transaction!.narration!,
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 5),
                      const Divider(indent: 5, endIndent: 5),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Row(
                          children: [
                            // Action Buttons
                            if (showAnyButton) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                spacing: 12,
                                children: [
                                  if (showDeleteButton)
                                    ZOutlineButton(
                                      icon: isDeleteLoading ? null : Icons.delete_outline_rounded,
                                      isActive: true,
                                      backgroundHover: color.error,
                                      onPressed: () {
                                        context.read<TransactionsBloc>().add(
                                          DeletePendingTxnEvent(
                                            reference: loadedGlat?.transaction?.trnReference ?? "",
                                            usrName: login.usrName ?? "",
                                          ),
                                        );
                                      },
                                      label: isDeleteLoading
                                          ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      )
                                          : Text(tr.delete),
                                    ),

                                  if (showAuthorizeButton)
                                    ZOutlineButton(
                                      onPressed: () {
                                        context.read<TransactionsBloc>().add(
                                          AuthorizeTxnEvent(
                                            reference: loadedGlat?.transaction?.trnReference ?? "",
                                            usrName: login.usrName ?? "",
                                          ),
                                        );
                                      },
                                      icon: isAuthorizeLoading ? null : Icons.check_circle_outline,
                                      isActive: true,
                                      backgroundColor: color.primary,
                                      textColor: color.onPrimary,
                                      label: isAuthorizeLoading
                                          ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                          : Text(tr.authorize),
                                    ),
                                ],
                              ),
                              SizedBox(width: 5),
                            ],

                            ZOutlineButton(
                                isActive: true,
                                onPressed: () => getPrinted(data: loadedGlat!, company: company),
                                icon: Icons.print,
                                label: Text(tr.print)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                color: isHighlighted ? Colors.green[700] : color.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void getPrinted({required GlatModel data, required ReportModel company}) {
    if (isPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<GlatModel>(
            data: data,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return GlatPrintSettings().printPreview(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                data: data,
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
              return GlatPrintSettings().printDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                data: data,
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
              return GlatPrintSettings().createDocument(
                data: data,
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
              );
            },
          ),
        );
      });
    }
  }
}