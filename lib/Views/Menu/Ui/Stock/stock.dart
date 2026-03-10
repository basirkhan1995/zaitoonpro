import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Features/Other/shortcut.dart';
import 'package:zaitoon_petroleum/Features/Other/utils.dart';
import 'package:zaitoon_petroleum/Features/Other/zForm_dialog.dart';
import 'package:zaitoon_petroleum/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoon_petroleum/Views/Auth/models/login_model.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Report/Ui/Stock/StockAvailability/product_report.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stock/Ui/Adjustment/add_adjustment.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stock/Ui/Estimate/View/add_estimate.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stock/Ui/Estimate/View/estimate.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stock/Ui/GoodsShift/add_shift.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stock/Ui/OrderScreen/NewPurchase/new_purchase.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stock/Ui/OrderScreen/NewSale/new_sale.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stock/Ui/Orders/Ui/orders.dart';
import '../../../../Features/Generic/tab_bar.dart';
import '../../../../Features/Widgets/outline_button.dart';
import '../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../Report/Ui/Stock/Cardx/Ui/cardx.dart';
import 'Ui/Adjustment/adjustment.dart';
import 'Ui/GoodsShift/goods_shift.dart';
import 'Ui/OrderScreen/GetOrderById/order_by_id.dart';
import 'bloc/stock_tab_bloc.dart';

class StockView extends StatefulWidget {
  const StockView({super.key});

  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView> {
  bool _isExpanded = true;

  // Helper methods to detect screen size
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    double opacity = .05;

    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): () => gotoPurchase(context),
      const SingleActivator(LogicalKeyboardKey.f2): () => gotoSale(context),
      const SingleActivator(LogicalKeyboardKey.f3): () => getInvoiceById(context),
      const SingleActivator(LogicalKeyboardKey.f4): () => getInvoiceById(context),
      const SingleActivator(LogicalKeyboardKey.f5): () => getInvoiceById(context),
      const SingleActivator(LogicalKeyboardKey.f6): () => getInvoiceById(context),
      const SingleActivator(LogicalKeyboardKey.f7): () => getInvoiceById(context),
      const SingleActivator(LogicalKeyboardKey.f8): () => getInvoiceById(context),
    };

    return Scaffold(
      body: GlobalShortcuts(
        shortcuts: shortcuts,
        child: isMobile
            ? _buildMobileLayout(context, login, color, locale, opacity)
            : _buildDesktopTabletLayout(context, login, color, locale, opacity, isTablet: isTablet),
      ),
    );
  }

  // Mobile Layout - Using Underline Tabs
  Widget _buildMobileLayout(
      BuildContext context,
      LoginData login,
      ColorScheme color,
      AppLocalizations locale,
      double opacity,
      ) {
    return Column(
      children: [
        // Mobile Header with Scrollable Action Buttons
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // New Purchase Button
                if (login.hasPermission(56) ?? false)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ZOutlineButton(
                      backgroundColor: color.primary.withValues(alpha: opacity),
                      toolTip: "F1 - ${locale.newPurchase}",
                      label: Text(locale.newPurchase),
                      icon: Icons.shopping_bag_outlined,
                      onPressed: () => Utils.goto(context, NewPurchaseOrderView()),
                    ),
                  ),

                // New Sale Button
                if (login.hasPermission(57) ?? false)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ZOutlineButton(
                      backgroundColor: color.primary.withValues(alpha: opacity),
                      toolTip: "F2 - ${locale.newSale}",
                      label: Text(locale.newSale),
                      icon: Icons.shopping_bag_outlined,
                      onPressed: () => Utils.goto(context, NewSaleView()),
                    ),
                  ),

                // New Estimate Button
                if (login.hasPermission(58) ?? false)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ZOutlineButton(
                      backgroundColor: color.primary.withValues(alpha: opacity),
                      toolTip: "F3 - ${locale.newEstimate}",
                      label: Text(locale.newEstimate),
                      icon: Icons.file_open_outlined,
                      onPressed: () => Utils.goto(context, AddEstimateView()),
                    ),
                  ),

                // Find Invoice Button
                if (login.hasPermission(61) ?? false)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ZOutlineButton(
                      backgroundColor: color.primary.withValues(alpha: opacity),
                      toolTip: "F4 - ${locale.findInvoice}",
                      label: Text(locale.findInvoice),
                      icon: Icons.filter_alt_outlined,
                      onPressed: () => getInvoiceById(context),
                    ),
                  ),

                // Shift Button
                if (login.hasPermission(59) ?? false)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ZOutlineButton(
                      backgroundColor: color.primary.withValues(alpha: opacity),
                      toolTip: "F7 - ${locale.shift}",
                      label: Text(locale.shift),
                      icon: Icons.edit_location_outlined,
                      onPressed: () => Utils.goto(context, AddGoodsShiftView()),
                    ),
                  ),

                // Adjustment Button
                if (login.hasPermission(60) ?? false)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ZOutlineButton(
                      backgroundColor: color.primary.withValues(alpha: opacity),
                      toolTip: "F8 - ${locale.adjustment}",
                      label: Text(locale.adjustment),
                      icon: Icons.settings_backup_restore_rounded,
                      onPressed: () => Utils.goto(context, AddAdjustmentView()),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ZTabContainer with Underline style for mobile
        Expanded(
          child: BlocBuilder<StockTabBloc, StockTabState>(
            builder: (context, state) {
              final tabs = <ZTabItem<StockTabsName>>[
                if (login.hasPermission(52) ?? false)
                  ZTabItem(
                    value: StockTabsName.orders,
                    label: locale.orderTitle,
                    screen: const OrdersView(),
                    icon: Icons.shopping_cart,
                  ),
                if (login.hasPermission(53) ?? false)
                  ZTabItem(
                    value: StockTabsName.estimates,
                    label: locale.estimateTitle,
                    screen: const EstimateView(),
                    icon: Icons.request_quote,
                  ),
                if (login.hasPermission(54) ?? false)
                  ZTabItem(
                    value: StockTabsName.shift,
                    label: locale.shift,
                    screen: const GoodsShiftView(),
                    icon: Icons.compare_arrows,
                  ),
                if (login.hasPermission(55) ?? false)
                  ZTabItem(
                    value: StockTabsName.adjustment,
                    label: locale.adjustment,
                    screen: const AdjustmentView(),
                    icon: Icons.tune,
                  ),
              ];

              final available = tabs.map((t) => t.value).toList();
              final selected = available.contains(state.tabs) ? state.tabs : available.first;

              return ZTabContainer<StockTabsName>(
                // Remove title and description since we removed the header
                title: null,
                description: null,
                tabs: tabs,
                selectedValue: selected,
                onChanged: (val) => context.read<StockTabBloc>().add(StockOnChangeEvent(val)),

                // Use underline style for mobile
                style: ZTabStyle.underline,

                // Colors
                selectedColor: color.primary,
                unselectedColor: Colors.transparent,
                selectedTextColor: color.primary,
                unselectedTextColor: color.secondary,

                // Padding and alignment
                tabBarPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                tabAlignment: MainAxisAlignment.start,
                tabContainerColor: color.surface,
              );
            },
          ),
        ),
      ],
    );
  }

  // Desktop/Tablet Layout - Using Rounded Tabs with Shortcut Panel
  Widget _buildDesktopTabletLayout(
      BuildContext context,
      LoginData login,
      ColorScheme color,
      AppLocalizations locale,
      double opacity, {
        required bool isTablet,
      }) {
    return Row(
      children: [
        // Left side - Tab Content with Rounded tabs
        Expanded(
          child: BlocBuilder<StockTabBloc, StockTabState>(
            builder: (context, state) {
              final tabs = <ZTabItem<StockTabsName>>[
                if (login.hasPermission(52) ?? false)
                  ZTabItem(
                    value: StockTabsName.orders,
                    label: locale.orderTitle,
                    screen: const OrdersView(),
                    icon: Icons.shopping_cart,
                  ),
                if (login.hasPermission(53) ?? false)
                  ZTabItem(
                    value: StockTabsName.estimates,
                    label: locale.estimateTitle,
                    screen: const EstimateView(),
                    icon: Icons.request_quote,
                  ),
                if (login.hasPermission(54) ?? false)
                  ZTabItem(
                    value: StockTabsName.shift,
                    label: locale.shift,
                    screen: const GoodsShiftView(),
                    icon: Icons.compare_arrows,
                  ),
                if (login.hasPermission(55) ?? false)
                  ZTabItem(
                    value: StockTabsName.adjustment,
                    label: locale.adjustment,
                    screen: const AdjustmentView(),
                    icon: Icons.tune,
                  ),
              ];

              final available = tabs.map((t) => t.value).toList();
              final selected = available.contains(state.tabs) ? state.tabs : available.first;

              return ZTabContainer<StockTabsName>(
                title: locale.inventory,
                description: locale.inventorySubtitle,
                tabs: tabs,
                selectedValue: selected,
                onChanged: (val) => context.read<StockTabBloc>().add(StockOnChangeEvent(val)),
                style: ZTabStyle.rounded,
                selectedColor: color.primary,
                unselectedColor: Colors.transparent,
                selectedTextColor: color.surface,
                unselectedTextColor: color.secondary,
                borderRadius: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 0),
                tabBarPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                tabAlignment: MainAxisAlignment.start,
                tabContainerColor: color.surface,
              );
            },
          ),
        ),

        const SizedBox(width: 3),

        // Right side - Shortcut Buttons Panel
        _buildShortcutPanel(context, login, color, locale, opacity, isTablet: isTablet),
      ],
    );
  }

  // Shortcut Panel
  Widget _buildShortcutPanel(
      BuildContext context,
      LoginData login,
      ColorScheme color,
      AppLocalizations locale,
      double opacity, {
        bool isTablet = false,
      }) {
    return AnimatedContainer(
      clipBehavior: Clip.hardEdge,
      duration: const Duration(milliseconds: 300),
      width: isTablet
          ? (_isExpanded ? 140 : 60)
          : (_isExpanded ? 170 : 70),
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: color.primary.withValues(alpha: .1),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 3,
            spreadRadius: 2,
            color: color.surfaceContainerHighest.withValues(alpha: .03),
          ),
        ],
        borderRadius: BorderRadius.circular(5),
        color: color.surface,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            // Toggle arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: _isExpanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                children: [
                  if (_isExpanded)
                    Flexible(
                      child: Text(
                        locale.shortcuts,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: IconButton(
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(_isExpanded
                          ? Icons.chevron_right
                          : Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            if (_isExpanded) ...[
              Wrap(
                spacing: 5,
                children: [
                  Icon(Icons.shopify_rounded, size: 20, color: color.outline),
                  Text(
                    locale.invoiceTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ],

            if (login.hasPermission(56) ?? false)
              ZOutlineButton(
                backgroundColor: color.primary.withValues(alpha: opacity),
                toolTip: "F1 - ${locale.newPurchase}",
                label: Text(locale.newPurchase),
                icon: Icons.shopping_bag_outlined,
                width: double.infinity,
                onPressed: () => Utils.goto(context, NewPurchaseOrderView()),
              ),

            if (login.hasPermission(57) ?? false)
              ZOutlineButton(
                backgroundColor: color.primary.withValues(alpha: opacity),
                toolTip: "F2 - ${locale.newSale}",
                label: Text(locale.newSale),
                icon: Icons.shopping_bag_outlined,
                width: double.infinity,
                onPressed: () => Utils.goto(context, NewSaleView()),
              ),

            if (login.hasPermission(58) ?? false)
              ZOutlineButton(
                backgroundColor: color.primary.withValues(alpha: opacity),
                toolTip: "F3 - ${locale.newEstimate}",
                label: Text(locale.newEstimate),
                icon: Icons.file_open_outlined,
                width: double.infinity,
                onPressed: () => Utils.goto(context, AddEstimateView()),
              ),
            if (login.hasPermission(61) ?? false)
              ZOutlineButton(
                backgroundColor: color.primary.withValues(alpha: opacity),
                toolTip: "F4 - ${locale.findInvoice}",
                label: Text(locale.findInvoice),
                icon: Icons.filter_alt_outlined,
                width: double.infinity,
                onPressed: () => getInvoiceById(context),
              ),

            if (_isExpanded) ...[
              const SizedBox(height: 3),
              Wrap(
                spacing: 5,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18, color: color.outline),
                  Text(
                    locale.stock,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ],

            if (login.hasPermission(59) ?? false)
              ZOutlineButton(
                backgroundColor: color.primary.withValues(alpha: opacity),
                toolTip: "F7 - ${locale.shift}",
                label: Text(locale.shift),
                icon: Icons.edit_location_outlined,
                width: double.infinity,
                onPressed: () => Utils.goto(context, AddGoodsShiftView()),
              ),

            if (login.hasPermission(60) ?? false)
              ZOutlineButton(
                backgroundColor: color.primary.withValues(alpha: opacity),
                toolTip: "F8 - ${locale.adjustment}",
                label: Text(locale.adjustment),
                icon: Icons.settings_backup_restore_rounded,
                width: double.infinity,
                onPressed: () => Utils.goto(context, AddAdjustmentView()),
              ),

            if (_isExpanded) ...[
              const SizedBox(height: 3),
              Wrap(
                spacing: 5,
                children: [
                  Icon(Icons.report_gmailerrorred, size: 18, color: color.outline),
                  Text(
                    locale.report,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ],

            ZOutlineButton(
              backgroundColor: color.primary.withValues(alpha: opacity),
              toolTip: "F9 - ${locale.stock}",
              label: Text(locale.stock),
              icon: Icons.inventory_2_outlined,
              width: double.infinity,
              onPressed: () => Utils.goto(context, ProductReportView()),
            ),

            ZOutlineButton(
              backgroundColor: color.primary.withValues(alpha: opacity),
              toolTip: "F10 - ${"Movement"}",
              label: Text("Movement"),
              icon: Icons.crop,
              width: double.infinity,
              onPressed: () => Utils.goto(context, StockRecordReportView()),
            ),
          ],
        ),
      ),
    );
  }

  void getInvoiceById(BuildContext context) {
    final invController = TextEditingController();
    final tr = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return ZFormDialog(
          padding: const EdgeInsets.all(14),
          width: 500,
          onAction: () {
            if (invController.text.isNotEmpty) {
              Utils.goto(
                context,
                OrderByIdView(orderId: int.parse(invController.text)),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
          actionLabel: Text(tr.submit),
          title: tr.findInvoice,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ZTextFieldEntitled(
                inputFormat: [FilteringTextInputFormatter.digitsOnly],
                icon: Icons.numbers,
                onSubmit: (e) {
                  if (e.isNotEmpty) {
                    Utils.goto(
                      context,
                      OrderByIdView(orderId: int.parse(e)),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                controller: invController,
                hint: tr.enterInvoiceNumber,
                title: tr.orderId,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void gotoPurchase(BuildContext context) {
    Utils.goto(context, NewPurchaseOrderView());
  }

  void gotoSale(BuildContext context) {
    Utils.goto(context, NewSaleView());
  }
}