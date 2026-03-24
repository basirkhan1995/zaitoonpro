import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Features/Widgets/status_badge.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Transport/Shipments/features/status_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Vehicles/add_edit_vehicle.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Vehicles/bloc/vehicle_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../../Features/Widgets/zcard_mobile.dart';

class VehicleReportView extends StatelessWidget {
  const VehicleReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(), desktop: _Desktop(), tablet: _Desktop(),);
  }
}



class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  int? _selectedStatus;
  List<dynamic> _allVehicles = [];
  List<dynamic> _filteredVehicles = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterVehicles() {
    final state = context.read<VehicleBloc>().state;
    if (state is VehicleReportLoadedState) {
      setState(() {
        _allVehicles = state.vehicles;
        _filteredVehicles = _allVehicles.where((vehicle) {
          // Apply status filter
          if (_selectedStatus != null && vehicle.vclStatus != _selectedStatus) {
            return false;
          }

          // Apply search filter
          if (_searchController.text.isNotEmpty) {
            final searchTerm = _searchController.text.toLowerCase();
            final model = vehicle.vclModel?.toLowerCase() ?? '';
            final plateNo = vehicle.vclPlateNo?.toLowerCase() ?? '';
            final driver = vehicle.driver?.toLowerCase() ?? '';

            return model.contains(searchTerm) ||
                plateNo.contains(searchTerm) ||
                driver.contains(searchTerm);
          }

          return true;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final l10n = AppLocalizations.of(context)!;

    final dropdownItems = [
      StatusItem(null, l10n.all),
      StatusItem(1, l10n.active),
      StatusItem(0, l10n.inactive),
    ];

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.vehicles),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ZSearchField(
              icon: FontAwesomeIcons.magnifyingGlass,
              controller: _searchController,
              hint: tr.search,
              onChanged: (value) {
                _filterVehicles();
              },
              title: "",
            ),
          ),

          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StatusDropdown(
                items: dropdownItems,
                value: _selectedStatus,
                onChanged: (e) {
                  setState(() {
                    _selectedStatus = e;
                  });
                  _filterVehicles();
                },
              ),
            ),

          Expanded(
            child: BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, state) {
                if (state is VehicleLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is VehicleErrorState) {
                  return NoDataWidget(
                    message: state.message,
                    onRefresh: () {
                      context.read<VehicleBloc>().add(LoadVehicleReportEvent());
                    },
                  );
                }

                if (state is VehicleReportLoadedState) {
                  if (_allVehicles.isEmpty) {
                    _allVehicles = state.vehicles;
                    _filteredVehicles = state.vehicles;
                  }

                  if (_filteredVehicles.isEmpty) {
                    return NoDataWidget(
                      title: tr.noData,
                      message: tr.noDataFound,
                      onRefresh: () {
                        context.read<VehicleBloc>().add(LoadVehicleReportEvent());
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _filteredVehicles[index];

                      final List<MobileInfoItem> infoItems = [
                        MobileInfoItem(
                          icon: Icons.local_gas_station,
                          text: vehicle.vclFuelType ?? '',
                          iconColor: color.primary,
                        ),
                        MobileInfoItem(
                          icon: Icons.directions_car,
                          text: vehicle.vclBodyType ?? '',
                          iconColor: color.secondary,
                        ),
                        MobileInfoItem(
                          icon: Icons.numbers,
                          text: vehicle.vclPlateNo ?? '',
                          iconColor: color.tertiary,
                        ),
                      ];

                      if (vehicle.driver != null && vehicle.driver!.isNotEmpty) {
                        infoItems.add(
                          MobileInfoItem(
                            icon: Icons.person,
                            text: vehicle.driver!,
                            iconColor: color.primary,
                          ),
                        );
                      }

                      if (vehicle.vclOwnership != null && vehicle.vclOwnership!.isNotEmpty) {
                        infoItems.add(
                          MobileInfoItem(
                            icon: Icons.business,
                            text: vehicle.vclOwnership!,
                            iconColor: color.secondary,
                          ),
                        );
                      }

                      return MobileInfoCard(
                        title: vehicle.vclModel ?? '',
                        subtitle: vehicle.driver ?? '',
                        infoItems: infoItems,
                        status: MobileStatus(
                          label: vehicle.vclStatus == 1 ? tr.active : tr.inactive,
                          color: vehicle.vclStatus == 1
                              ? Colors.green
                              : Colors.red,
                          backgroundColor: vehicle.vclStatus == 1
                              ? Colors.green.withValues(alpha: .1)
                              : Colors.red.withValues(alpha: .1),
                        ),
                        onTap: () {
                          Utils.goto(context, AddEditVehicleView(model: vehicle));
                        },
                        accentColor: color.primary,
                        showActions: true,
                      );
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
}


class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    context.read<VehicleBloc>().add(LoadVehicleReportEvent());
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final l10n = AppLocalizations.of(context)!;
    List<StatusItem>? items;
    final dropdownItems = items ?? [
      StatusItem(null, l10n.all),
      StatusItem(1, l10n.inactive),
    ];
    return Scaffold(
        backgroundColor: color.surface,
        appBar: AppBar(
          title: Text(tr.vehicles),
          titleSpacing: 0,
        ),
        body: Column(
          children: [
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  Expanded(
                    child: ZSearchField(
                      icon: FontAwesomeIcons.magnifyingGlass,
                      controller: searchController,
                      hint: tr.search,
                      onChanged: (e) {
                        setState(() {

                        });
                      },
                      title: "",
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: StatusDropdown(
                        items: dropdownItems,
                        onChanged: (e){
                          context.read<VehicleBloc>().add(LoadVehicleReportEvent(regExpired: e));

                    }),
                  ),
                  ZOutlineButton(
                      width: 120,
                      icon: Icons.refresh,
                      onPressed: (){
                        context.read<VehicleBloc>().add(LoadVehicleReportEvent());
                      },
                      label: Text(tr.refresh)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 5),
              margin: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 1),
              child: Row(
                spacing: 5,
                children: [
                  Expanded(
                      child: Text(tr.vehicleModel,style: titleStyle)),
                  SizedBox(
                      width: 100,
                      child: Text(tr.vehiclePlate,style: titleStyle)),
                  SizedBox(
                      width: 100,
                      child: Text(tr.fuelType,style: titleStyle)),
                  SizedBox(
                      width: 100,
                      child: Text(tr.vehicleType,style: titleStyle)),
                  SizedBox(
                      width: 90,
                      child: Text(tr.status,style: titleStyle)),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<VehicleBloc, VehicleState>(
                builder: (context, state) {
                  if(state is VehicleLoadingState){
                    return Center(child: CircularProgressIndicator());
                  }
                  if(state is VehicleErrorState){
                    return NoDataWidget(
                      message: state.message,
                      onRefresh: (){
                        context.read<VehicleBloc>().add(LoadVehicleReportEvent());
                      },
                    );
                  }
                  if(state is VehicleReportLoadedState){
                    final query = searchController.text.toLowerCase().trim();
                    final filteredList = state.vehicles.where((item) {
                      final name = item.vclModel?.toLowerCase() ?? '';
                      return name.contains(query);
                    }).toList();

                    if(filteredList.isEmpty){
                      return NoDataWidget(
                        title: tr.noData,
                        message: tr.noDataFound,
                      );
                    }
                    return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context,index){
                          final vehicle = filteredList[index];
                          return InkWell(
                            onTap: (){
                              showDialog(context: context, builder: (context){
                                return AddEditVehicleView(model: vehicle,disableUpdate: false);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 8),
                              margin:  const EdgeInsets.symmetric(horizontal: 15.0),
                              decoration: BoxDecoration(
                                  color: index.isEven? color.primary.withValues(alpha: .05) : Colors.transparent
                              ),
                              child: Row(
                                spacing: 5,
                                children: [
                                  Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(vehicle.vclModel??"",style: titleStyle?.copyWith(color: color.outline.withValues(alpha: .9)),),
                                          Text(vehicle.driver??"")
                                        ],

                                      )),
                                  SizedBox(
                                      width: 100,
                                      child: Text(vehicle.vclOwnership??"")),
                                  SizedBox(
                                      width: 100,
                                      child: Text(vehicle.vclPlateNo??"")),
                                  SizedBox(
                                      width: 100,
                                      child: Text(vehicle.vclFuelType??"")),
                                  SizedBox(
                                      width: 100,
                                      child: Text(vehicle.vclBodyType??"")),

                                  SizedBox(
                                      width: 90,
                                      child: StatusBadge(status: vehicle.vclStatus!,trueValue: tr.active, falseValue: tr.inactive)),
                                ],
                              ),
                            ),
                          );
                        });
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        )
    );
  }
}
