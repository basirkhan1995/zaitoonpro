import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:flutter/services.dart';
import 'package:zaitoon_petroleum/Features/Other/toast.dart';
import 'package:zaitoon_petroleum/Features/Widgets/no_data_widget.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Stakeholders/Ui/Individuals/features/individuals_dropdown.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Transport/Ui/Drivers/driver_drop.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Transport/Ui/Vehicles/features/vehicle_drop.dart';
import '../../../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../../../Localizations/Bloc/localizations_bloc.dart';
import '../../../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../Features/Date/z_range_picker.dart';
import '../../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/Widgets/z_dragable_sheet.dart';
import '../../../../Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../../Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../../../../Transport/Ui/Shipping/Ui/ShippingView/View/add_edit_shipping.dart';
import '../../../../Transport/Ui/Shipping/Ui/ShippingView/View/all_shipping.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'PDF/shp_excel.dart';
import 'PDF/shp_report_print.dart';
import 'bloc/shipping_report_bloc.dart';
import 'features/status_drop.dart';
import 'model/shp_report_model.dart';

class ShippingReportView extends StatelessWidget {
  const ShippingReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      desktop: _Desktop(),
      tablet: _Mobile(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  String fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().subtract(const Duration(days: 7)).toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;

  int? perId;
  int? vehicleId;
  int? status;
  int? driverId;
  String _baseCurrency = "";
  String? myLocale;

  final _filterCustomerController = TextEditingController();
  final _filterVehicleController = TextEditingController();
  final _filterDriverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShippingReportBloc>().add(ResetShippingReportEvent());
      myLocale = context.read<LocalizationBloc>().state.languageCode;
      final comState = context.read<CompanyProfileBloc>().state;
      if (comState is CompanyProfileLoadedState) {
        _baseCurrency = comState.company.comLocalCcy ?? "";
      }
    });
  }

  @override
  void dispose() {
    _filterCustomerController.dispose();
    _filterVehicleController.dispose();
    _filterDriverController.dispose();
    super.dispose();
  }

  bool get hasFilter =>
      perId != null || vehicleId != null || driverId != null || status != null;

  void _clearFilters() {
    setState(() {
      perId = null;
      vehicleId = null;
      driverId = null;
      status = null;
      fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
      toDate = DateTime.now().toFormattedDate();
      _filterCustomerController.clear();
      _filterVehicleController.clear();
      _filterDriverController.clear();
    });
    context.read<ShippingReportBloc>().add(ResetShippingReportEvent());
  }

  void _loadData() {
    context.read<ShippingReportBloc>().add(
      LoadShippingReportEvent(
        status: status,
        customerId: perId,
        fromDate: fromDate,
        toDate: toDate,
        vehicleId: vehicleId,
        driverId: driverId,
      ),
    );
  }

  void _showFilterBottomSheet() {
    final tr = AppLocalizations.of(context)!;

    int? localStatus = status;
    int? localPerId = perId;
    int? localVehicleId = vehicleId;
    int? localDriverId = driverId;
    String localFromDate = fromDate;
    String localToDate = toDate;

    ZDraggableSheet.show(
      context: context,
      title: tr.filterReports,
      estimatedContentHeight: 550,
      bodyBuilder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 8),
              children: [
                /// 🔹 Driver Dropdown
                DriversDropdown(
                  onSingleChanged: (driver) {
                    setSheetState(() {
                      localDriverId = driver?.empId;
                    });
                  },
                ),
                const SizedBox(height: 12),

                /// 🔹 Vehicle Dropdown
                VehicleDropdown(
                  onSingleChanged: (vehicle) {
                    setSheetState(() {
                      localVehicleId = vehicle?.vclId;
                    });
                  },
                ),
                const SizedBox(height: 12),

                /// 🔹 Customer Dropdown
                StakeholdersDropdown(
                  title: tr.customer,
                  height: 40,
                  isMulti: false,
                  onMultiChanged: (_) {},
                  onSingleChanged: (e) {
                    setSheetState(() {
                      localPerId = e!.perId;
                    });
                  },
                ),
                const SizedBox(height: 12),

                /// 🔹 Status Dropdown
                StatusDropdown(
                  value: localStatus,
                  onChanged: (v) => setSheetState(() => localStatus = v),
                ),
                const SizedBox(height: 12),

                /// 🔹 Date Range
                Row(
                  children: [
                    Expanded(
                      child: ZDatePicker(
                        label: tr.fromDate,
                        value: localFromDate,
                        onDateChanged: (v) => setSheetState(() => localFromDate = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ZDatePicker(
                        label: tr.toDate,
                        value: localToDate,
                        onDateChanged: (v) => setSheetState(() => localToDate = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// 🔹 Apply / Clear Buttons
                Row(
                  children: [
                    if (hasFilter)
                      Expanded(
                        child: ZOutlineButton(
                          onPressed: () {
                            setSheetState(() {
                              localPerId = null;
                              localVehicleId = null;
                              localDriverId = null;
                              localStatus = null;
                              localFromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
                              localToDate = DateTime.now().toFormattedDate();
                            });
                            setState(() {
                              perId = null;
                              vehicleId = null;
                              driverId = null;
                              status = null;
                              fromDate = DateTime.now().subtract(const Duration(days: 7)).toFormattedDate();
                              toDate = DateTime.now().toFormattedDate();
                            });
                          },
                          label: Text(tr.clear),
                        ),
                      ),
                    if (hasFilter) const SizedBox(width: 8),
                    Expanded(
                      child: ZOutlineButton(
                        isActive: true,
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            perId = localPerId;
                            vehicleId = localVehicleId;
                            driverId = localDriverId;
                            status = localStatus;
                            fromDate = localFromDate;
                            toDate = localToDate;
                          });
                          _loadData();
                        },
                        label: Text(tr.apply),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  String _getStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Delivered';
      case 0:
        return 'Pending';
      default:
        return 'All';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 0:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.allShipping),
        actions: [
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.filePdf),
            onPressed: () {
              // PDF functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Summary
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.allShipping,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$fromDate - $toDate",
                        style: TextStyle(color: color.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selected Filters Chips
          if (hasFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (perId != null)
                      _buildFilterChip(
                        label: "Customer: $perId",
                        color: color.primary,
                        onRemove: () {
                          setState(() {
                            perId = null;
                          });
                          _loadData();
                        },
                      ),
                    if (vehicleId != null)
                      _buildFilterChip(
                        label: "Vehicle: $vehicleId",
                        color: color.secondary,
                        onRemove: () {
                          setState(() {
                            vehicleId = null;
                          });
                          _loadData();
                        },
                      ),
                    if (driverId != null)
                      _buildFilterChip(
                        label: "Driver: $driverId",
                        color: color.tertiary,
                        onRemove: () {
                          setState(() {
                            driverId = null;
                          });
                          _loadData();
                        },
                      ),
                    if (status != null)
                      _buildFilterChip(
                        label: "${tr.status}: ${_getStatusText(status)}",
                        color: _getStatusColor(status),
                        onRemove: () {
                          setState(() {
                            status = null;
                          });
                          _loadData();
                        },
                      ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: BlocBuilder<ShippingReportBloc, ShippingReportState>(
              builder: (context, state) {
                if (state is ShippingReportLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ShippingReportErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: color.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(color: color.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is ShippingReportInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 64,
                          color: color.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Shipments Overview",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Select filters and tap Load to view shipments",
                          style: TextStyle(color: color.outline),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                if (state is ShippingReportLoadedState) {
                  if (state.shp.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: color.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr.noDataFound,
                            style: TextStyle(color: color.outline),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.shp.length,
                    itemBuilder: (context, index) {
                      final shp = state.shp[index];
                      return _buildMobileShippingCard(shp, index, color, tr);
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileShippingCard(ShippingReportModel shp, int index, ColorScheme color, AppLocalizations tr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.outline.withValues(alpha: .1)),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => ShippingByIdView(shippingId: shp.shpId, perId: perId),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Date and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shp.shpMovingDate?.toFormattedDate() ?? "",
                      style: TextStyle(
                        color: color.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: ShippingStatusBadge(
                      status: shp.shpStatus ?? 0,
                      tr: tr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer and Product
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.customer,
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shp.customerName ?? "",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tr.products,
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shp.proName ?? "",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Vehicle and Driver
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 14,
                          color: color.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.vehicle,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color.outline,
                                ),
                              ),
                              Text(
                                shp.vehicle ?? "",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: color.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.driver,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color.outline,
                                ),
                              ),
                              Text(
                                shp.driverName ?? "",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Shipping Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.shippingRent,
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${shp.shpRent?.toAmount()} $_baseCurrency",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          tr.loadingSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${shp.shpLoadSize?.toDoubleAmount()} ${shp.shpUnit}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tr.unloadingSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: color.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${shp.shpUnloadSize?.toDoubleAmount()} ${shp.shpUnit}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.totalTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                    Text(
                      "${shp.total?.toAmount()} $_baseCurrency",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color.primary,
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
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  late String fromDate;
  late String toDate;
  final _personController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  int? perId;
  int? vehicleId;
  int? status;
  int? driverId;
  String _baseCurrency = "";
  String? myLocale;

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
    final now = DateTime.now();
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    fromDate = lastMonthStart.toFormattedDate();
    toDate = lastMonthEnd.toFormattedDate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShippingReportBloc>().add(ResetShippingReportEvent());
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
        _baseCurrency = comState.company.comLocalCcy ?? "";
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

   int flexDate = 2;
   int flexCustomer = 3;
   int flexProduct = 3;
   int flexVehicle = 3;
   int flexDriver = 3;
   int flexShipping = 2;
   int flexLoad = 2;
   int flexUnload = 2;
   int flexTotal = 2;
   int flexStatus = 2;
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.allShipping,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 15),
        titleSpacing: 0,
        actions: [

          if (perId != null || vehicleId != null || driverId !=null)...[
            ZOutlineButton(
              toolTip: "F5",
              icon: Icons.filter_alt_off_outlined,
              onPressed: () {
                setState(() {
                  perId = null;
                  vehicleId = null;
                  driverId = null;
                });
                context.read<ShippingReportBloc>().add(ResetShippingReportEvent());
              },
              label: Text(tr.clear),
            ),
            SizedBox(width: 8),
          ],
          ZOutlineButton(
            toolTip: "F6",
            icon: FontAwesomeIcons.fileExcel,
            backgroundHover: Colors.green,
            onPressed: onExcel,
            label: Text("EXCEL"),
          ),
          SizedBox(width: 8),
          ZOutlineButton(
            toolTip: "F6",
            icon: Icons.print,
            onPressed: onPdf,
            label: Text(tr.print),
          ),
          SizedBox(width: 8),
          ZOutlineButton(
            toolTip: "F5",
            isActive: true,
            icon: Icons.filter_alt,
            onPressed: onRefresh,
            label: Text(tr.apply),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [

                Expanded(
                  flex: 2,
                  child: DriversDropdown(
                    onSingleChanged: (driver) {
                      setState(() {
                        driverId = driver?.empId;
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: VehicleDropdown(
                    onSingleChanged: (vehicle) {
                      setState(() {
                        vehicleId = vehicle?.vclId;
                      });
                    },
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: GenericTextfield<IndividualsModel, IndividualsBloc, IndividualsState>(
                    controller: _personController,
                    title: tr.customer,
                    hintText: tr.customer,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr.required(tr.customer);
                      }
                      return null;
                    },
                    bloc: context.read<IndividualsBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(const LoadIndividualsEvent()),
                    searchFunction: (bloc, query) => bloc.add(LoadIndividualsEvent(search: query)),
                    itemBuilder: (context, ind) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("${ind.perName ?? ''} ${ind.perLastName ?? ''}"),
                    ),
                    itemToString: (individual) => "${individual.perName} ${individual.perLastName}",
                    stateToLoading: (state) => state is IndividualLoadingState,
                    stateToItems: (state) {
                      if (state is IndividualLoadedState) return state.individuals;
                      return [];
                    },
                    onSelected: (value) {
                      setState(() {
                        perId = value.perId;
                      });
                    },
                    showClearButton: true,
                  ),
                ),
                Expanded(
                  child: StatusDropdown(
                    value: status,
                    items: [
                      StatusItem(null, tr.all),
                      StatusItem(0, tr.pending),
                      StatusItem(1, tr.delivered),
                    ],
                    onChanged: (v) {
                      setState(() => status = v); // v is 1 or 0
                    },
                  ),
                ),

                Expanded(
                  child: ZRangeDatePicker(
                    label: tr.selectDate,
                    initialStartDate: DateTime.tryParse(fromDate),
                    initialEndDate: DateTime.tryParse(toDate),
                    startValue: fromDate,
                    endValue: toDate,
                    onStartDateChanged: (startDate) {
                      setState(() {
                        fromDate = startDate;
                      });
                    },
                    onEndDateChanged: (endDate) {
                      setState(() {
                        toDate = endDate;
                      });
                      onRefresh();
                    },
                    disablePastDate: false,
                    minYear: 2000,
                    maxYear: 2100,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _buildColumnHeaders(),
          const SizedBox(height: 0),

          Expanded(
            child: BlocBuilder<ShippingReportBloc, ShippingReportState>(
              builder: (context, state) {
                if (state is ShippingReportLoadingState) {
                  return Center(child: CircularProgressIndicator());
                }
                if (state is ShippingReportErrorState) {
                  return NoDataWidget(message: state.message);
                }
                if (state is ShippingReportInitial) {
                  return NoDataWidget(
                    title: "Shipments Report",
                    message: "Select filters and generate the report.",
                    enableAction: false,
                  );
                }
                if (state is ShippingReportLoadedState) {
                  if (state.shp.isEmpty) {
                    return NoDataWidget(title: tr.noData,enableAction: false,message: tr.noDataFound);
                  }
                  return _buildReportListView(context, state.shp);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }



  void onExcel() {
    final tr = AppLocalizations.of(context)!;
    final state = context.read<ShippingReportBloc>().state;

    List<ShippingReportModel> shippingList = [];

    if (state is ShippingReportLoadedState) {
      shippingList = state.shp;
    }

    if (shippingList.isEmpty) {
      ToastManager.show(
          context: context,
          title: tr.noData,
          message: "No shipment found to export",
          type: ToastType.error
      );
      return;
    }

    // Create a safe filename
    String timestamp = DateTime.now().toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .replaceAll('T', '_');
    String fileName = "Shipping_Report_$timestamp.xlsx";

    // Prepare filter texts
    String? filterCustomerText;
    String? filterVehicleText;
    String? filterStatusText;

    if (perId != null) {
      filterCustomerText = "Customer ID: $perId";
    }

    if (vehicleId != null) {
      filterVehicleText = "Vehicle ID: $vehicleId";
    }

    if (status != null) {
      filterStatusText = status == 1 ? tr.delivered : tr.pendingTitle;
    }

    // Capture the current context before any async operations
    final currentContext = context;

    // Show loading indicator
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Call Excel export service
    ShippingReportExcelService.exportToExcel(
      shippingList: shippingList,
      fromDate: fromDate,
      toDate: toDate,
      filterCustomer: filterCustomerText,
      filterVehicle: filterVehicleText,
      filterStatus: filterStatusText,
      baseCurrency: _baseCurrency,
      fileName: fileName,
      context: currentContext, // Use captured context
    ).then((_) {
      // Check if the captured context is still mounted
      if (currentContext.mounted) {
        Navigator.of(currentContext).pop(); // Close loading dialog
      }
    }).catchError((error) {
      // Check if the captured context is still mounted
      if (currentContext.mounted) {
        Navigator.of(currentContext).pop(); // Close loading dialog
        ToastManager.show(
            context: currentContext,
            title: "Error",
            message: "Failed to export: $error",
            type: ToastType.error
        );
      }
    });
  }

  Widget _buildColumnHeaders() {
    final tr = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.surface);
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .9)
      ),
      child: Row(
        children: [
          Expanded(flex: flexDate, child: Text(tr.date, style: titleStyle)),
          Expanded(flex: flexCustomer, child: Text(tr.customer, style: titleStyle)),
          Expanded(flex: flexProduct, child: Text(tr.products, style: titleStyle)),
          Expanded(flex: flexVehicle, child: Text(tr.vehicle, style: titleStyle)),
          Expanded(flex: flexDriver, child: Text(tr.driver, style: titleStyle)),
          Expanded(flex: flexShipping, child: Text(tr.shippingRent, style: titleStyle)),
          Expanded(flex: flexLoad, child: Text(tr.loadingSize, style: titleStyle)),
          Expanded(flex: flexUnload, child: Text(tr.unloadingSize, style: titleStyle)),
          Expanded(flex: flexTotal, child: Text(tr.totalTitle, style: titleStyle)),
          SizedBox(width: 100, child: Text(tr.status, style: titleStyle)),
        ],
      ),
    );
  }


  Widget _buildReportListView(BuildContext context, List<ShippingReportModel> list) {
    final tr = AppLocalizations.of(context)!;

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final shp = list[index];

        return InkWell(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) =>
                  ShippingByIdView(shippingId: shp.shpId, perId: perId),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: index.isEven
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .05)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                /// DATE
                Expanded(
                  flex: flexDate,
                  child: Text(shp.shpMovingDate?.toFormattedDate() ?? ""),
                ),

                /// CUSTOMER
                Expanded(
                    flex: flexCustomer,
                    child: Text(shp.customerName ?? "")),

                /// PRODUCT
                Expanded(
                    flex: flexProduct, child: Text(shp.proName ?? "")),

                /// VEHICLE
                Expanded(flex: flexVehicle, child: Text(shp.vehicle ?? "")),
                /// Driver
                Expanded(flex: flexDriver, child: Text(shp.driverName ?? "")),
                /// SHIPPING RENT
                Expanded(
                  flex: flexShipping,
                  child: Text("${shp.shpRent?.toAmount()} $_baseCurrency"),
                ),

                /// LOADING SIZE
                Expanded(
                  flex: flexLoad,
                  child: Text(
                    "${shp.shpLoadSize?.toDoubleAmount()} ${shp.shpUnit}",
                  ),
                ),

                /// UNLOADING SIZE
                Expanded(
                  flex: flexUnload,
                  child: Text(
                    "${shp.shpUnloadSize?.toDoubleAmount()} ${shp.shpUnit}",
                  ),
                ),
                /// TOTAL
                Expanded(
                  flex: flexTotal,
                  child: Text("${shp.total?.toAmount()} $_baseCurrency"),
                ),

                /// STATUS
                SizedBox(
                  width: 100,
                  child: ShippingStatusBadge(
                    status: shp.shpStatus ?? 0,
                    tr: tr,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onRefresh() {
    context.read<ShippingReportBloc>().add(
      LoadShippingReportEvent(
        status: status,
        customerId: perId,
        fromDate: fromDate,
        toDate: toDate,
        vehicleId: vehicleId,
        driverId: driverId
      ),
    );
  }

  // Add this PDF function
  void onPdf() {
    final tr = AppLocalizations.of(context)!;
    final state = context.read<ShippingReportBloc>().state;

    List<ShippingReportModel> shippingList = [];
    String? filterCustomer;
    String? filterVehicle;
    String? filterStatus;

    // Extract shipping list from state
    if (state is ShippingReportLoadedState) {
      shippingList = state.shp;
    } else if (state is ShippingReportLoadingState) {
      // Handle loading state if needed
    }

    if (shippingList.isEmpty) {
      ToastManager.show(context: context, title: tr.noData, message: "No shipment found", type: ToastType.error);
      return;
    }

    // Prepare filter texts for display
    if (perId != null) {
      // You need to get the customer name from your dropdown selection
      // For now, using a placeholder - you should implement this based on your UI
      filterCustomer = "Customer ID: $perId";
    }

    if (vehicleId != null) {
      // Get vehicle name from your dropdown selection
      filterVehicle = "Vehicle ID: $vehicleId";
    }

    if (status != null) {
      filterStatus = status == 1 ? tr.delivered : tr.pendingTitle;
    }

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<List<ShippingReportModel>>(
        data: shippingList,
        company: company,
        buildPreview:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return ShippingReportPdfServices().printPreview(
                company: company,
                language: language,
                pageFormat: pageFormat,
                shippingList: data,
                filterFromDate: fromDate,
                filterToDate: toDate,
                filterCustomer: filterCustomer,
                filterVehicle: filterVehicle,
                filterStatus: filterStatus?.toString(),
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
              return ShippingReportPdfServices().printDocument(
                company: company,
                language: language,
                pageFormat: pageFormat,
                selectedPrinter: selectedPrinter,
                shippingList: data,
                copies: copies,
                pages: pages,
                filterFromDate: fromDate,
                filterToDate: toDate,
                filterCustomer: filterCustomer,
                filterVehicle: filterVehicle,
                filterStatus: filterStatus?.toString(),
              );
            },
        onSave:
            ({
              required data,
              required language,
              required orientation,
              required pageFormat,
            }) {
              return ShippingReportPdfServices().createDocument(
                company: company,
                language: language,
                pageFormat: pageFormat,
                shippingList: data,
                filterFromDate: fromDate,
                filterToDate: toDate,
                filterCustomer: filterCustomer,
                filterVehicle: filterVehicle,
                filterStatus: filterStatus?.toString(),
              );
            },
      ),
    );
  }
}
