import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:flutter/services.dart';
import 'package:zaitoonpro/Features/Other/shortcut.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Shipping/Ui/ShippingView/View/add_edit_shipping.dart';
import '../../../../../../../../../Features/Other/utils.dart';
import '../../../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../../../Localizations/Bloc/localizations_bloc.dart';
import '../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../PDF/pdf.dart';
import '../bloc/shipping_bloc.dart';
import '../model/shipping_model.dart';
import '../model/shp_details_model.dart';

class ShippingView extends StatelessWidget {
  const ShippingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileView(),
      desktop: _DesktopView(),
      tablet: _MobileView(),
    );
  }
}

// New Mobile View with Card Widgets
class _MobileView extends StatefulWidget {
  const _MobileView();

  @override
  State<_MobileView> createState() => _MobileViewState();
}

class _MobileViewState extends State<_MobileView> {
  final TextEditingController searchController = TextEditingController();
  String _baseCurrency = "";
  int? _perId;
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShippingBloc>().add(LoadShippingEvent());
      final comState = context.read<CompanyProfileBloc>().state;
      if (comState is CompanyProfileLoadedState) {
        _baseCurrency = comState.company.comLocalCcy ?? "";
        company.comName = comState.company.comName ?? "";
        company.statementDate = DateTime.now().toDateTime;
        company.comEmail = comState.company.comEmail ?? "";
        company.comAddress = comState.company.addName ?? "";
        company.compPhone = comState.company.comPhone ?? "";
        company.comLogo = _companyLogo;
        final base64Logo = comState.company.comLogo;
        if (base64Logo != null && base64Logo.isNotEmpty) {
          try {
            _companyLogo = base64Decode(base64Logo);
            company.comLogo = _companyLogo;
          } catch (e) {
            _companyLogo = Uint8List(0);
          }
        }
      }
    });
  }

  void _handleShippingTap(ShippingModel shp) {
    if (shp.shpId == null) return;

    // Store the perId for passing to the details screen
    setState(() {
      _perId = shp.perId;
    });

    // Navigate to the shipping details screen
    Utils.goto(
      context,
      ShippingByIdView(
        shippingId: shp.shpId,
        perId: _perId, // This is why we keep _perId
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<ShippingBloc, ShippingState>(
          listener: (context, state) {
            if (state is ShippingSuccessState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ShippingBloc>().add(ClearShippingSuccessEvent());
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.allShipping,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                tr.lastMonthShipments,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _onRefresh,
              tooltip: tr.refresh,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _onAdd,
              tooltip: tr.newKeyword,
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.solidFilePdf),
              onPressed: _onPDF,
              tooltip: "PDF",
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ZSearchField(
                icon: FontAwesomeIcons.magnifyingGlass,
                controller: searchController,
                hint: tr.search,
                onChanged: (e) => setState(() {}),
                title: "",
              ),
            ),
          ),
        ),
        body: BlocBuilder<ShippingBloc, ShippingState>(
          builder: (context, state) {
            return _buildShippingList(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildShippingList(BuildContext context, ShippingState state) {
    final tr = AppLocalizations.of(context)!;

    List<ShippingModel> shippingList = [];
    int? loadingShpId;
    bool isLoading = false;

    if (state is ShippingInitial) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ShippingListLoadingState) {
      shippingList = state.shippingList;
      loadingShpId = state.loadingShpId;
      isLoading = state.isLoading;
    } else if (state is ShippingDetailLoadingState ||
        state is ShippingDetailLoadedState ||
        state is ShippingListLoadedState ||
        state is ShippingSuccessState) {
      shippingList = state.shippingList;
      loadingShpId = state.loadingShpId;
    } else if (state is ShippingErrorState) {
      shippingList = state.shippingList;
      loadingShpId = state.loadingShpId;
    }

    if (shippingList.isEmpty && !isLoading) {
      return NoDataWidget(message: tr.noDataFound, onRefresh: _onRefresh);
    }

    final query = searchController.text.toLowerCase().trim();
    final filteredList = shippingList.where((shp) {
      final id = shp.shpId?.toString() ?? '';
      final vehicle = shp.vehicle?.toLowerCase() ?? '';
      final product = shp.proName?.toLowerCase() ?? '';
      final customer = shp.customer?.toLowerCase() ?? '';
      final status = (shp.shpStatus == 1 ? tr.completedTitle : tr.pendingTitle)
          .toLowerCase();
      return id.contains(query) ||
          vehicle.contains(query) ||
          product.contains(query) ||
          customer.contains(query) ||
          status.contains(query);
    }).toList();

    if (isLoading && shippingList.isNotEmpty) {
      return Stack(
        children: [
          _buildShippingCardListView(filteredList, loadingShpId),
          Positioned.fill(
            child: Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      );
    }

    if (isLoading && shippingList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildShippingCardListView(filteredList, loadingShpId);
  }

  Widget _buildShippingCardListView(
    List<ShippingModel> shippingList,
    int? loadingShpId,
  ) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (shippingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 80,
              color: theme.colorScheme.outline.withValues(alpha: .3),
            ),
            const SizedBox(height: 16),
            Text(
              tr.noDataFound,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: shippingList.length,
      itemBuilder: (context, index) {
        final shp = shippingList[index];
        final isLoadingThisItem = loadingShpId == shp.shpId;

        return _buildShippingCard(
          shp: shp,
          isLoading: isLoadingThisItem,
          onTap: isLoadingThisItem ? null : () => _handleShippingTap(shp),
        );
      },
    );
  }

  Widget _buildShippingCard({
    required ShippingModel shp,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ZCover(
      radius: 5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with ID and Status
              Row(
                children: [
                  // ID with loading indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        if (!isLoading)
                          Text(
                            '#${shp.shpId}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Status Badge
                  ShippingStatusBadge(status: shp.shpStatus ?? 0, tr: tr),
                ],
              ),

              const SizedBox(height: 12),

              // Main Content
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: tr.date,
                value: shp.shpMovingDate.toFormattedDate(),
              ),

              const SizedBox(height: 8),

              _buildInfoRow(
                icon: Icons.directions_car,
                label: tr.vehicles,
                value: shp.vehicle ?? '-',
              ),

              const SizedBox(height: 8),

              _buildInfoRow(
                icon: Icons.category,
                label: tr.products,
                value: shp.proName ?? '-',
              ),

              const SizedBox(height: 8),

              _buildInfoRow(
                icon: Icons.person,
                label: tr.customer,
                value: shp.customer ?? '-',
              ),

              const Divider(height: 20),

              // Financial Information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAmountChip(
                    label: tr.shippingRent,
                    amount: shp.shpRent.toDoubleAmount(),
                    currency: _baseCurrency,
                    icon: Icons.price_change,
                  ),
                  _buildAmountChip(
                    label: tr.loadingSize,
                    amount: shp.shpLoadSize.toDoubleAmount(),
                    unit: shp.shpUnit,
                    icon: Icons.arrow_upward,
                  ),
                  _buildAmountChip(
                    label: tr.unloadingSize,
                    amount: shp.shpUnloadSize.toDoubleAmount(),
                    unit: shp.shpUnit,
                    icon: Icons.arrow_downward,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Total Amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: .2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.totalTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${shp.total?.toAmount()} $_baseCurrency',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountChip({
    required String label,
    required double? amount,
    String? unit,
    String? currency,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount != null
                ? currency != null
                      ? '${amount.toAmount()} $currency'
                      : unit != null
                      ? '${amount.toAmount()} $unit'
                      : amount.toAmount()
                : '-',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _onPDF() {
    final locale = AppLocalizations.of(context)!;
    final state = context.read<ShippingBloc>().state;

    List<ShippingModel> shippingList = [];

    if (state is ShippingListLoadedState) {
      shippingList = state.shippingList;
    } else if (state is ShippingDetailLoadedState) {
      shippingList = state.shippingList;
    } else if (state is ShippingListLoadingState) {
      shippingList = state.shippingList;
    } else if (state is ShippingSuccessState) {
      shippingList = state.shippingList;
    }

    if (shippingList.isEmpty) {
      Utils.showOverlayMessage(context, message: locale.noData, isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<List<ShippingModel>>(
        data: shippingList,
        company: company,
        buildPreview:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return AllShippingPdfServices().printPreview(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                shippingList: data,
              );
            },
        onPrint:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return AllShippingPdfServices().printDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                shippingList: data,
                copies: copies,
                pages: pages,
              );
            },
        onSave:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return AllShippingPdfServices().createDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                shippingList: data,
              );
            },
      ),
    );
  }

  void _onAdd() {
    Utils.goto(context, const ShippingByIdView());
  }

  void _onRefresh() {
    context.read<ShippingBloc>().add(LoadShippingEvent());
  }
}

class _DesktopView extends StatefulWidget {
  const _DesktopView();

  @override
  State<_DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<_DesktopView> {
  final TextEditingController searchController = TextEditingController();
  String _baseCurrency = "";
  String? myLocale;
  bool _isDialogOpen = false;
  int? _loadingShpId;
  int? _perId;
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShippingBloc>().add(LoadShippingEvent());
      myLocale = context.read<LocalizationBloc>().state.languageCode;
      final comState = context.read<CompanyProfileBloc>().state;
      if (comState is CompanyProfileLoadedState) {
        _baseCurrency = comState.company.comLocalCcy ?? "";
        company.comName = comState.company.comName ?? "";
        company.statementDate = DateTime.now().toDateTime;
        company.comEmail = comState.company.comEmail ?? "";
        company.comAddress = comState.company.addName ?? "";
        company.compPhone = comState.company.comPhone ?? "";
        company.comLogo = _companyLogo;
        final base64Logo = comState.company.comLogo;
        if (base64Logo != null && base64Logo.isNotEmpty) {
          try {
            _companyLogo = base64Decode(base64Logo);
            company.comLogo = _companyLogo;
          } catch (e) {
            _companyLogo = Uint8List(0);
          }
        }
      }
    });
  }

  void _handleShippingTap(ShippingModel shp) {
    if (shp.shpId == null) return;

    if (_isDialogOpen && _loadingShpId == shp.shpId) {
      return;
    }

    if (_loadingShpId != null && _loadingShpId != shp.shpId) {
      _loadingShpId = null;
    }

    _loadingShpId = shp.shpId;
    context.read<ShippingBloc>().add(ClearShippingDetailEvent());
    context.read<ShippingBloc>().add(LoadShippingDetailEvent(shp.shpId!));
    setState(() {
      _perId = shp.perId;
    });
  }

  void _showShippingDetailDialog(
    BuildContext context,
    ShippingDetailsModel shipping,
  ) {
    if (_isDialogOpen) return;

    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          ShippingByIdView(shippingId: shipping.shpId, perId: _perId),
    ).then((value) {
      _isDialogOpen = false;
      _loadingShpId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ShippingBloc>().add(ClearShippingDetailEvent());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): _onAdd,
      const SingleActivator(LogicalKeyboardKey.f6): _onPDF,
      const SingleActivator(LogicalKeyboardKey.f5): _onRefresh,
    };

    return MultiBlocListener(
      listeners: [
        BlocListener<ShippingBloc, ShippingState>(
          listener: (context, state) {
            if (state is ShippingDetailLoadedState &&
                state.currentShipping != null &&
                state.shouldOpenDialog) {
              if (!_isDialogOpen &&
                  _loadingShpId == state.currentShipping!.shpId) {
                _showShippingDetailDialog(context, state.currentShipping!);
              }
            }
            if (state is ShippingDetailLoadingState) {
              _loadingShpId = state.loadingShpId;
            }
            if (state is ShippingErrorState ||
                (state is ShippingListLoadedState &&
                    state.currentShipping == null)) {
              _loadingShpId = null;
            }
            if (state is ShippingSuccessState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ShippingBloc>().add(ClearShippingSuccessEvent());
              });
            }
            if (state is ShippingListLoadedState &&
                state.currentShipping == null) {
              _isDialogOpen = false;
              _loadingShpId = null;
            }
          },
        ),
      ],
      child: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8,
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.allShipping,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            tr.lastMonthShipments,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: ZSearchField(
                        icon: FontAwesomeIcons.magnifyingGlass,
                        controller: searchController,
                        hint: tr.search,
                        onChanged: (e) => setState(() {}),
                        title: "",
                      ),
                    ),
                    ZOutlineButton(
                      toolTip: "F6",
                      width: 120,
                      icon: FontAwesomeIcons.solidFilePdf,
                      onPressed: _onPDF,
                      label: Text("PDF"),
                    ),
                    ZOutlineButton(
                      toolTip: "F5",
                      width: 120,
                      icon: Icons.refresh,
                      onPressed: _onRefresh,
                      label: Text(tr.refresh),
                    ),
                    ZOutlineButton(
                      toolTip: "F1",
                      width: 120,
                      icon: Icons.add,
                      isActive: true,
                      onPressed: _onAdd,
                      label: Text(tr.newKeyword),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              _buildColumnHeaders(context),
              const SizedBox(height: 5),
              const Divider(),
              const SizedBox(height: 0),
              Expanded(
                child: BlocBuilder<ShippingBloc, ShippingState>(
                  builder: (context, state) {
                    return _buildShippingList(context, state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeaders(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(context).textTheme.titleSmall;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(tr.id, style: titleStyle)),
          SizedBox(width: 100, child: Text(tr.date, style: titleStyle)),
          Expanded(child: Text(tr.vehicles, style: titleStyle)),
          SizedBox(width: 200, child: Text(tr.products, style: titleStyle)),
          SizedBox(width: 130, child: Text(tr.customer, style: titleStyle)),
          SizedBox(width: 110, child: Text(tr.shippingRent, style: titleStyle)),
          SizedBox(width: 110, child: Text(tr.loadingSize, style: titleStyle)),
          SizedBox(
            width: 110,
            child: Text(tr.unloadingSize, style: titleStyle),
          ),
          SizedBox(width: 120, child: Text(tr.totalTitle, style: titleStyle)),
          SizedBox(width: 100, child: Text(tr.status, style: titleStyle)),
        ],
      ),
    );
  }

  Widget _buildShippingListView(
    List<ShippingModel> shippingList,
    int? loadingShpId,
  ) {
    return ListView.builder(
      itemCount: shippingList.length,
      itemBuilder: (context, index) {
        final shp = shippingList[index];
        final isLoadingThisItem = loadingShpId == shp.shpId;
        final isCurrentlyViewing = _loadingShpId == shp.shpId && _isDialogOpen;

        return InkWell(
          onTap: (isLoadingThisItem || isCurrentlyViewing)
              ? null
              : () => _handleShippingTap(shp),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: isCurrentlyViewing
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .1)
                  : index.isEven
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .05)
                  : Colors.transparent,
              border: isCurrentlyViewing
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoadingThisItem)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      if (!isLoadingThisItem)
                        Flexible(
                          child: Text(
                            shp.shpId.toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(shp.shpMovingDate.toFormattedDate()),
                ),
                Expanded(child: Text(shp.vehicle ?? "")),
                SizedBox(width: 200, child: Text(shp.proName ?? "")),
                SizedBox(width: 130, child: Text(shp.customer ?? "")),
                SizedBox(
                  width: 110,
                  child: Text("${shp.shpRent?.toAmount()} $_baseCurrency"),
                ),
                SizedBox(
                  width: 110,
                  child: Text("${shp.shpLoadSize?.toAmount()} ${shp.shpUnit}"),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    "${shp.shpUnloadSize?.toAmount()} ${shp.shpUnit}",
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text("${shp.total?.toAmount()} $_baseCurrency"),
                ),
                SizedBox(
                  width: 100,
                  child: ShippingStatusBadge(
                    status: shp.shpStatus ?? 0,
                    tr: AppLocalizations.of(context)!,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShippingList(BuildContext context, ShippingState state) {
    final tr = AppLocalizations.of(context)!;

    List<ShippingModel> shippingList = [];
    int? loadingShpId;
    bool isLoading = false;

    if (state is ShippingInitial) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ShippingListLoadingState) {
      shippingList = state.shippingList;
      loadingShpId = state.loadingShpId;
      isLoading = state.isLoading;
    } else if (state is ShippingDetailLoadingState ||
        state is ShippingDetailLoadedState ||
        state is ShippingListLoadedState ||
        state is ShippingSuccessState) {
      shippingList = state.shippingList;
      loadingShpId = state.loadingShpId;
    } else if (state is ShippingErrorState) {
      shippingList = state.shippingList;
      loadingShpId = state.loadingShpId;
    }

    if (shippingList.isEmpty && !isLoading) {
      return NoDataWidget(message: tr.noDataFound, onRefresh: _onRefresh);
    }

    final query = searchController.text.toLowerCase().trim();
    final filteredList = shippingList.where((shp) {
      final id = shp.shpId?.toString() ?? '';
      final vehicle = shp.vehicle?.toLowerCase() ?? '';
      final product = shp.proName?.toLowerCase() ?? '';
      final customer = shp.customer?.toLowerCase() ?? '';
      final status = (shp.shpStatus == 1 ? tr.completedTitle : tr.pendingTitle)
          .toLowerCase();
      return id.contains(query) ||
          vehicle.contains(query) ||
          product.contains(query) ||
          customer.contains(query) ||
          status.contains(query);
    }).toList();

    if (isLoading && shippingList.isNotEmpty) {
      return Stack(
        children: [
          _buildShippingListView(filteredList, loadingShpId),
          Positioned.fill(
            child: SizedBox(
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      );
    }

    if (isLoading && shippingList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildShippingListView(filteredList, loadingShpId);
  }

  void _onPDF() {
    final locale = AppLocalizations.of(context)!;
    final state = context.read<ShippingBloc>().state;

    List<ShippingModel> shippingList = [];

    if (state is ShippingListLoadedState) {
      shippingList = state.shippingList;
    } else if (state is ShippingDetailLoadedState) {
      shippingList = state.shippingList;
    } else if (state is ShippingListLoadingState) {
      shippingList = state.shippingList;
    } else if (state is ShippingSuccessState) {
      shippingList = state.shippingList;
    }

    if (shippingList.isEmpty) {
      Utils.showOverlayMessage(context, message: locale.noData, isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<List<ShippingModel>>(
        data: shippingList,
        company: company,
        buildPreview:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return AllShippingPdfServices().printPreview(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                shippingList: data,
              );
            },
        onPrint:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
              required selectedPrinter,
              required copies,
              required pages,
            }) {
              return AllShippingPdfServices().printDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                shippingList: data,
                copies: copies,
                pages: pages,
              );
            },
        onSave:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return AllShippingPdfServices().createDocument(
                company: company,
                language: language,
                orientation: orientation,
                pageFormat: pageFormat,
                shippingList: data,
              );
            },
      ),
    );
  }

  void _onAdd() {
    context.read<ShippingBloc>().add(ClearShippingDetailEvent());
    _isDialogOpen = false;
    _loadingShpId = null;

    showDialog(
      context: context,
      builder: (context) => const ShippingByIdView(),
    ).then((value) {
      _isDialogOpen = false;
      _loadingShpId = null;
    });
  }

  void _onRefresh() {
    context.read<ShippingBloc>().add(LoadShippingEvent());
  }
}

class ShippingStatusBadge extends StatelessWidget {
  final int status;
  final AppLocalizations tr;

  const ShippingStatusBadge({
    super.key,
    required this.status,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = status == 1;

    final Color bgColor = isCompleted
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);

    final Color textColor = isCompleted
        ? const Color(0xFF2E7D32)
        : const Color(0xFFEF6C00);

    final IconData icon = isCompleted
        ? Icons.check_circle_rounded
        : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: textColor.withValues(alpha: .4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            isCompleted ? tr.completedTitle : tr.pendingTitle,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
