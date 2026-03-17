import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/cover.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/zForm_dialog.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Views/Auth/bloc/auth_bloc.dart';
import '../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../Features/PrintSettings/report_model.dart';
import '../bloc/transactions_bloc.dart';
import 'Print/txn_order_print.dart';
import 'bloc/order_txn_bloc.dart';
import 'model/get_order_model.dart';

class OrderTxnView extends StatelessWidget {
  final String reference;

  const OrderTxnView({
    super.key,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return const _OrderTxnDialog();
  }
}

class _OrderTxnDialog extends StatefulWidget {
  const _OrderTxnDialog();

  @override
  State<_OrderTxnDialog> createState() => _OrderTxnDialogState();
}

class _OrderTxnDialogState extends State<_OrderTxnDialog> {
  OrderTxnModel? orderTxn;
  bool isPrint = true;
  final company = ReportModel();
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = auth.loginData;

    return BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
      builder: (context, state) {

        // if (state is CompanyProfileLoadedState) {
        //   company.comName = state.company.comName ?? "";
        //   company.comAddress = state.company.addName ?? "";
        //   company.compPhone = state.company.comPhone ?? "";
        //   company.comEmail = state.company.comEmail ?? "";
        //   company.statementDate = DateTime.now().toFullDateTime;
        //
        //   final base64Logo = state.company.comLogo;
        //   if (base64Logo != null && base64Logo.isNotEmpty) {
        //     try {
        //       _companyLogo = base64Decode(base64Logo);
        //     } catch (e) {
        //       _companyLogo = Uint8List(0);
        //     }
        //   }
        // }

        return ZFormDialog(
          padding: EdgeInsets.all(15),
          onAction: null,
          title: tr.transactionDetails,
          isActionTrue: false,
          width: MediaQuery.of(context).size.width *.7,
          child: BlocBuilder<OrderTxnBloc, OrderTxnState>(
            builder: (context, state) {
              if (state is OrderTxnErrorState) {
                return NoDataWidget(
                  message: state.message,
                );
              }

              if (state is OrderTxnLoadingState) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is OrderTxnLoadedState) {
                orderTxn = state.data;
                final records = orderTxn?.records ?? [];
                final billItems = orderTxn?.bill ?? [];

                // Check permissions
                final showDeleteButton = orderTxn?.trnStatus == 0 && orderTxn?.maker == login.usrName;
                final showAuthorizeButton = orderTxn?.trnStatus == 0 && orderTxn?.maker != login.usrName;
                final showAnyButton = showDeleteButton || showAuthorizeButton;

                // Get loading states
                final isDeleteLoading = context.watch<TransactionsBloc>().state is TxnDeleteLoadingState;
                final isAuthorizeLoading = context.watch<TransactionsBloc>().state is TxnAuthorizeLoadingState;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Reference and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderTxn?.trnReference ?? "-",
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color.primary,
                                ),
                              ),
                              SizedBox(height: 8),
                              ZCover(
                                color: color.primary.withAlpha(30),
                                child: Text(
                                    orderTxn?.trntName ?? orderTxn?.trnType ?? "-",
                                    style: textTheme.titleMedium?.copyWith(color: color.primary)
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "${tr.branch}: ${orderTxn?.branch ?? "-"}",
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                spacing: 8,
                                children: [
                                   InkWell(
                                     onTap: ()=> getPrinted(data: orderTxn!,company: company),
                                     child: CircleAvatar(
                                         backgroundColor: color.primary.withValues(alpha: .06),
                                         child: Icon(Icons.print,color: color.outline.withValues(alpha: .9))),
                                   ),
                                  _buildStatusBadge(context, orderTxn?.trnStateText ?? ""),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "${orderTxn?.trnEntryDate?.toDateTime}",
                                style: textTheme.bodyMedium,
                              ),

                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Total Amount Card
                      ZCover(
                        color: color.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.totalAmount,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: color.onSurface.withAlpha(150),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        orderTxn?.totalBill?.toAmount() ?? "0.00",
                                        style: textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: color.primary,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        orderTxn?.ccy ?? "USD",
                                        style: textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: color.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),


                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Two Column Layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bill Items
                          Expanded(
                            flex: 3,
                            child: ZCover(
                              color: color.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.shopping_cart, size: 20, color: color.primary),
                                        SizedBox(width: 8),
                                        Text(
                                          tr.items,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),

                                    if (billItems.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        child: Center(
                                          child: Text(
                                            tr.noItems,
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: color.onSurface.withAlpha(150),
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      _buildBillItemsTable(billItems, context),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 16),

                          // Accounting Records
                          Expanded(
                            flex: 2,
                            child: ZCover(
                              color: color.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(FontAwesomeIcons.buildingColumns, size: 20, color: color.primary),
                                        SizedBox(width: 10),
                                        Text(
                                          tr.accountingEntries,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 8),
                                    if (records.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        child: Center(
                                          child: Text(
                                            tr.noRecords,
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: color.onSurface.withAlpha(150),
                                            ),
                                          ),
                                        ),
                                      )
                                    else ...records.map((record) => _buildRecordItem(record, context)),

                                    SizedBox(height: 16),

                                    // User Info
                                    Divider(height: 20, thickness: 1),
                                    _buildDetailRow(tr.maker, orderTxn?.maker ?? "-"),
                                    _buildDetailRow(tr.checker, orderTxn?.checker ?? "-"),
                                    _buildDetailRow(tr.currencyTitle, orderTxn?.ccy ?? "-"),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Action Buttons
                      if (showAnyButton) ...[
                        SizedBox(height: 20),
                        ZCover(
                          color: color.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.actions,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(thickness: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  spacing: 12,
                                  children: [
                                    if (showDeleteButton)
                                      ZOutlineButton(
                                        width: 150,
                                        height: 45,
                                        icon: isDeleteLoading
                                            ? null
                                            : Icons.delete_outline_rounded,
                                        isActive: true,
                                        backgroundHover: color.error,
                                        onPressed: () {
                                          context.read<TransactionsBloc>().add(
                                            DeletePendingTxnEvent(
                                              reference: orderTxn?.trnReference ?? "",
                                              usrName: login.usrName ?? "",
                                            ),
                                          );
                                        },
                                        label: isDeleteLoading
                                            ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: color.primary,
                                          ),
                                        )
                                            : Text(tr.delete),
                                      ),

                                    if (showAuthorizeButton)
                                      ZOutlineButton(
                                        width: 150,
                                        height: 45,
                                        onPressed: () {
                                          context.read<TransactionsBloc>().add(
                                            AuthorizeTxnEvent(
                                              reference: orderTxn?.trnReference ?? "",
                                              usrName: login.usrName ?? "",
                                            ),
                                          );
                                        },
                                        icon: isAuthorizeLoading
                                            ? null
                                            : Icons.check_circle_outline,
                                        isActive: true,
                                        backgroundColor: color.primary,
                                        textColor: color.onPrimary,
                                        label: isAuthorizeLoading
                                            ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: color.surface,
                                          ),
                                        )
                                            : Text(tr.authorize),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 20),
                    ],
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final isAuthorized = status.toLowerCase().contains("authorize");

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
          SizedBox(width: 6),
          Text(
            isAuthorized ? tr.authorizedTitle : tr.pendingTitle,
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

  Widget _buildBillItemsTable(List<Bill> billItems, BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;

    // Calculate total with safe parsing
    double total = 0;
    for (final item in billItems) {
      final parsed = double.tryParse(item.totalPrice ?? '');
      total += parsed ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            border: Border.all(color: color.outline.withAlpha(50)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  tr.productName,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tr.storage,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tr.qty,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tr.unitPrice,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tr.totalTitle,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Table Rows
        ...billItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: index.isEven ? color.primary.withValues(alpha: .05) : color.surface,
              border: Border(
                left: BorderSide(color: color.outline.withAlpha(50)),
                right: BorderSide(color: color.outline.withAlpha(50)),
                bottom: index == billItems.length - 1
                    ? BorderSide(color: color.outline.withAlpha(10))
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.productName ?? "-",
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    item.storageName ?? "-",
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "${item.quantity ?? "0"}T",
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    item.unitPrice?.toAmount() ?? "0.00",
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "${item.totalPrice?.toAmount()}",
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),

        // Total Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: color.primary.withAlpha(10),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            border: Border.all(color: color.outline.withAlpha(50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${tr.grandTotal} ",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.outline.withAlpha(180),
                ),
              ),
              SizedBox(width: 16),
              Text(
                "${total.toAmount()} ${orderTxn?.ccy ?? ""}",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
            ],
          ),
        ),

        // Remark (if any)
        if (orderTxn?.remark?.isNotEmpty == true) ...[
          SizedBox(height: 16),
          Divider(height: 1, thickness: 1),
          SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.remark,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                orderTxn?.remark ?? "",
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecordItem(Record record, BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isDebit = record.debitCredit?.toLowerCase() == "debit";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.outline.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.accountName ?? "-",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ZCover(
                color: isDebit
                    ? Colors.red.withAlpha(30)
                    : Colors.green.withAlpha(30),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  record.debitCredit ?? "-",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDebit ? Colors.red[700] : Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${record.accountNumber ?? "-"}",
                style: TextStyle(
                  fontSize: 11,
                  color: color.onSurface.withAlpha(150),
                ),
              ),
              Text(
                "${record.amount?.toAmount()} ${orderTxn?.ccy}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDebit ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this function in the _OrderTxnDialogState class
  void getPrinted({required OrderTxnModel data, required ReportModel company}) {
    if (isPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => PrintPreviewDialog<OrderTxnModel>(
            data: data,
            company: company,
            buildPreview: ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return OrderTxnPrintSettings().printPreview(
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
              return OrderTxnPrintSettings().printDocument(
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
              return OrderTxnPrintSettings().createDocument(
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