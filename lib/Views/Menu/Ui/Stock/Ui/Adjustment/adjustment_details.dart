// adjustment_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/alert_dialog.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import '../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'bloc/adjustment_bloc.dart';

class AdjustmentDetailView extends StatefulWidget {
  final int orderId;

  const AdjustmentDetailView({super.key, required this.orderId});

  @override
  State<AdjustmentDetailView> createState() => _AdjustmentDetailViewState();
}

class _AdjustmentDetailViewState extends State<AdjustmentDetailView> {
  late String? usrName;
  String? baseCurrency;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      usrName = authState.loginData.usrName;
    }

    final companyState = context.read<CompanyProfileBloc>().state;
    if (companyState is CompanyProfileLoadedState) {
      baseCurrency = companyState.company.comLocalCcy ?? "";
    }

    // Load adjustment details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdjustmentBloc>().add(LoadAdjustmentDetailsEvent(widget.orderId));
    });
  }

  void _onBackPressed() {
    // Trigger return to list before navigating back
    context.read<AdjustmentBloc>().add(ReturnToListEvent());
    Navigator.of(context).pop();
  }

  void _onDelete() {
    if (usrName == null) {
      Utils.showOverlayMessage(
        context,
        message: 'User not authenticated',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return ZAlertDialog(
          title: AppLocalizations.of(context)!.delete,
          content: AppLocalizations.of(context)!.deleteMessage,
          onYes: () {
            setState(() {
              _isDeleting = true;
            });
            context.read<AdjustmentBloc>().add(DeleteAdjustmentEvent(
              orderId: widget.orderId,
              usrName: usrName!,
            ));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    return BlocListener<AdjustmentBloc, AdjustmentState>(
      listener: (context, state) {
        if (state is AdjustmentDeletingState) {
          setState(() {
            _isDeleting = true;
          });
        }

        if (state is AdjustmentDeletedState) {
          Utils.showOverlayMessage(
            context,
            message: state.message,
            isError: false,
          );
          // Trigger return to list before popping
          context.read<AdjustmentBloc>().add(ReturnToListEvent());
          Navigator.of(context).pop();
        }

        if (state is AdjustmentErrorState) {
          setState(() {
            _isDeleting = false;
          });
          Utils.showOverlayMessage(
            context,
            message: state.error,
            isError: true,
          );
        }
      },
      child: Scaffold(
        backgroundColor: color.surface,
        appBar: AppBar(
          backgroundColor: color.surface,
          title: Text('${tr.adjustment} #${widget.orderId}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackPressed,
          ),
          titleSpacing: 0,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 15),
          actions: [
            ZOutlineButton(
              icon: Icons.print,
              width: 110,
              height: 38,
              label: Text(tr.print),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            if(login.hasPermission(109) ?? false)
            ZOutlineButton(
              isActive: true,
              backgroundHover: Theme.of(context).colorScheme.error,
              width: 110,
              height: 38,
              icon: Icons.delete,
              label: _isDeleting
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(color.surface),
                ),
              )
                  : Text(tr.delete),
              onPressed: _onDelete,
            ),
          ],
        ),
        body: BlocBuilder<AdjustmentBloc, AdjustmentState>(
          builder: (context, state) {
            if (state is AdjustmentDetailLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AdjustmentDetailLoadedState) {
              return _buildAdjustmentDetail(state, tr);
            }

            if (state is AdjustmentErrorState) {
              return Center(
                child: NoDataWidget(
                  imageName: 'error.png',
                  message: state.error,
                  onRefresh: () {
                    context.read<AdjustmentBloc>().add(
                      LoadAdjustmentDetailsEvent(widget.orderId),
                    );
                  },
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildAdjustmentDetail(
      AdjustmentDetailLoadedState state, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final adjustment = state.adjustment;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Adjustment Information Card
          ZCover(
            radius: 5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: color.primary),
                      const SizedBox(width: 8),
                      Text(
                        adjustment.ordName??"",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(tr.id, adjustment.ordId.toString()),
                      _buildInfoItem(tr.referenceNumber, adjustment.ordTrnRef.toString()),
                      _buildInfoItem(
                        tr.referenceNumber,
                        adjustment.ordxRef ?? '-',
                      ),
                      _buildInfoItem(
                        tr.date,
                        adjustment.ordEntryDate?.toFormattedDate() ?? '-',
                      ),
                      _buildInfoItem(
                        tr.status,
                        adjustment.trnStateText == "Authorized"
                            ? tr.authorizedTitle
                            : adjustment.trnStateText == "Pending"
                            ? tr.pendingTitle
                            : adjustment.trnStateText ?? '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(tr.expenseAccount, adjustment.account?.toString() ?? '-'),
                      _buildInfoItem(
                        tr.amount,
                        '${adjustment.amount?.toAmount()} $baseCurrency',
                        isAmount: true,
                      ),
                      if (adjustment.ordPersonalName != null)
                        _buildInfoItem(tr.maker, adjustment.ordPersonalName!),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Adjusted Items Table
          if (state.items.isNotEmpty) _buildItemsTable(state, tr),

          // Summary
          if (state.items.isNotEmpty) _buildSummaryCard(state, tr),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isAmount = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: isAmount
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          )
              : Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildItemsTable(AdjustmentDetailLoadedState state, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.items,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(40), // #
              1: FlexColumnWidth(4), // Product
              2: FlexColumnWidth(3), // Storage
              3: FlexColumnWidth(2), // Quantity
              4: FlexColumnWidth(2), // Unit Cost
              5: FlexColumnWidth(2), // Total
            },
            border: TableBorder.all(
              color: color.outline.withValues(alpha: .1),
              width: 1,
            ),
            children: [
              // Table header
              TableRow(
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .9),
                ),
                children: [
                  _buildTableCell('#', isHeader: true, center: true),
                  _buildTableCell(tr.productName, isHeader: true),
                  _buildTableCell(tr.storage, isHeader: true),
                  _buildTableCell(tr.qty, isHeader: true, center: true),
                  _buildTableCell(tr.unitPrice, isHeader: true, center: true),
                  _buildTableCell(tr.totalAmount, isHeader: true, center: true),
                ],
              ),
              // Table rows
              ...state.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return TableRow(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.transparent
                        : color.primary.withValues(alpha: .03),
                  ),
                  children: [
                    _buildTableCell((index + 1).toString(), center: true),
                    _buildTableCell(item.productName),
                    _buildTableCell(item.storageName),
                    _buildTableCell(item.quantity.toAmount(), center: true),
                    _buildTableCell((item.purPrice ?? 0).toAmount(), center: true),
                    _buildTableCell(item.totalCost.toAmount(), center: true),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(
      String text, {
        bool isHeader = false,
        bool center = false,
        Color? color,
        FontWeight? fontWeight,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontWeight: fontWeight ?? (isHeader ? FontWeight.bold : FontWeight.normal),
          color: color ??
              (isHeader
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AdjustmentDetailLoadedState state, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final totalItems = state.items.length;
    final totalValue = state.items.fold(0.0, (sum, item) => sum + item.totalCost);

    return ZCover(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.summary,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(tr.totalItems, totalItems.toString()),
            Divider(color: color.outline.withValues(alpha: .2)),
            _buildSummaryRow(
              tr.totalTitle,
              '${totalValue.toAmount()} $baseCurrency',
              isBold: true,
              color: color.primary,
            ),
            // Show expense account info if available
            if (state.adjustment.account != null) ...[
              Divider(color: color.outline.withValues(alpha: .2)),
              _buildSummaryRow(
                tr.expenseAmount,
                state.adjustment.account.toString(),
                color: Colors.orange,
              ),
              if (state.adjustment.amount != null)
                _buildSummaryRow(
                  tr.expenseAmount,
                  '${state.adjustment.amount?.toAmount()} $baseCurrency',
                  color: Colors.blue,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool isBold = false,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text(
        label,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Theme.of(context).colorScheme.onSurface,
          fontSize: isBold ? 16 : 14,
        ),
      ),
      ]
    ),
    );
  }
}


