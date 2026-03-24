import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/models/login_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Drivers/bloc/driver_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Drivers/model/driver_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Vehicles/bloc/vehicle_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Vehicles/features/fuel_type_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Vehicles/features/ownership_drop.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Vehicles/features/vehicle_types_drop.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Vehicles/model/vehicle_model.dart';
import '../../../../../../Features/Date/zdate_picker.dart';
import '../../../../../../Features/Generic/rounded_searchable_textfield.dart';
import '../../../../../../Features/Other/image_helper.dart';
import '../../../../../../Features/Other/thousand_separator.dart';
import '../../../../../../Features/Widgets/section_title.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';

class AddEditVehicleView extends StatelessWidget {
  final VehicleModel? model;
  final bool disableUpdate;
  const AddEditVehicleView({super.key, this.model, this.disableUpdate = true});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(model,disableUpdate),
      desktop: _Desktop(model,disableUpdate),
      tablet: _Desktop(model,disableUpdate),
    );
  }
}
class _Mobile extends StatefulWidget {
  final VehicleModel? model;
  final bool isEnabledUpdate;
  const _Mobile(this.model,this.isEnabledUpdate);

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final vclModel = TextEditingController();
  final plateNo = TextEditingController();
  final vclYear = TextEditingController();
  final odometer = TextEditingController();
  final vclVinNo = TextEditingController();
  final vclEnginPower = TextEditingController();
  final vclRegNo = TextEditingController();
  final driverCtrl = TextEditingController();
  final amount = TextEditingController();

  int? driverId;
  String? ownerShipValue;
  String? vehicleCategory;
  String? fuel;
  String vehicleExpireDateGregorian = DateTime.now().toFormattedDate();
  Jalali vehicleExpireDateShamsi = DateTime.now().toAfghanShamsi;

  final formKey = GlobalKey<FormState>();
  bool showAmountField = true;
  LoginData? loginData;

  @override
  void dispose() {
    plateNo.dispose();
    vclYear.dispose();
    vclRegNo.dispose();
    vclEnginPower.dispose();
    vclModel.dispose();
    amount.dispose();
    driverCtrl.dispose();
    vclVinNo.dispose();
    odometer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    final model = (context as dynamic).widget.model;
    if (model != null) {
      final m = model as VehicleModel;
      plateNo.text = m.vclPlateNo ?? "";
      driverCtrl.text = m.driver ?? "";
      vclVinNo.text = m.vclVinNo ?? "";
      vclYear.text = m.vclYear ?? "";
      vclModel.text = m.vclModel ?? "";
      odometer.text = m.vclOdoMeter?.toString() ?? "";
      driverId = m.driverId;
      if (m.vclPurchaseAmount != null) {
        amount.text = m.vclPurchaseAmount?.toAmount() ?? "";
      }
      vclEnginPower.text = m.vclEnginPower ?? "";
      vclRegNo.text = m.vclRegNo ?? "";
      fuel = m.vclFuelType ?? "";
      vehicleCategory = m.vclBodyType ?? "";
      ownerShipValue = m.vclOwnership;
      _updateAmountFieldVisibility(m.vclOwnership);
    }
    super.initState();
  }

  void _updateAmountFieldVisibility(String? ownership) {
    setState(() {
      showAmountField = ownership == "Owned";
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEdit = (context as dynamic).widget.model != null;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = state.loginData;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isEdit ? tr.update : tr.newKeyword),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: onSubmit,
            icon: context.watch<VehicleBloc>().state is VehicleLoadingState
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
                : Icon(
              Icons.check,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              isEdit ? tr.update : tr.create,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: BlocConsumer<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state is VehicleSuccessState) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Section
                  SectionTitle(title: "Basic Information"),
                  const SizedBox(height: 12),

                  // Vehicle Model
                  ZTextFieldEntitled(
                    isRequired: true,
                    isEnabled: widget.isEnabledUpdate,
                    title: tr.vehicleModel,
                    controller: vclModel,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return tr.required(tr.vehicleModel);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Driver Selection
                  GenericTextfield<DriverModel, DriverBloc, DriverState>(
                    controller: driverCtrl,
                    isEnabled: widget.isEnabledUpdate,
                    validator: (e) => null,
                    title: tr.driver,
                    hintText: tr.driver,
                    bloc: context.read<DriverBloc>(),
                    fetchAllFunction: (bloc) => bloc.add(LoadDriverEvent()),
                    searchFunction: (bloc, query) => bloc.add(LoadDriverEvent()),
                    itemBuilder: (context, driver) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          ImageHelper.stakeholderProfile(
                            imageName: driver.perPhoto,
                            size: 35,
                          ),
                          Expanded(
                            child: Text(
                              "${driver.perfullName}",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemToString: (account) => "${account.perfullName}",
                    stateToLoading: (state) => state is DriverLoadingState,
                    loadingBuilder: (context) => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1),
                    ),
                    stateToItems: (state) {
                      if (state is DriverLoadedState) {
                        return state.drivers;
                      }
                      return [];
                    },
                    onSelected: (account) {
                      setState(() {
                        driverId = account.empId;
                      });
                    },
                    noResultsText: tr.noDataFound,
                    showClearButton: true,
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Details Section
                  SectionTitle(title: tr.vehicleDetails),
                  const SizedBox(height: 12),

                  // Plate and Meter
                  ZTextFieldEntitled(
                    isRequired: true,
                    isEnabled: widget.isEnabledUpdate,
                    title: tr.vehiclePlate,
                    controller: plateNo,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return tr.required(tr.vehiclePlate);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  ZTextFieldEntitled(
                    title: tr.meter,
                    isEnabled: widget.isEnabledUpdate,
                    controller: odometer,
                    inputFormat: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),

                  ZTextFieldEntitled(
                    title: tr.manufacturedYear,
                    isEnabled: widget.isEnabledUpdate,
                    controller: vclYear,
                    inputFormat: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),

                  ZTextFieldEntitled(
                    title: tr.vinNumber,
                    controller: vclVinNo,
                  ),
                  const SizedBox(height: 12),

                  ZTextFieldEntitled(
                    title: tr.enginePower,
                    isEnabled: widget.isEnabledUpdate,
                    controller: vclEnginPower,
                  ),
                  const SizedBox(height: 12),

                  ZTextFieldEntitled(
                    isRequired: true,
                    title: tr.vclRegisteredNo,
                    isEnabled: widget.isEnabledUpdate,
                    controller: vclRegNo,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return tr.required(tr.vclRegisteredNo);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Registration and Specifications Section
                  SectionTitle(title: "Registration & Specs"),
                  const SizedBox(height: 12),

                  // Date Picker
                  GenericDatePicker(
                    label: tr.vclExpireDate,
                    isActive:  widget.isEnabledUpdate,
                    initialGregorianDate: vehicleExpireDateGregorian,
                    onDateChanged: (newDate) {
                      setState(() {
                        vehicleExpireDateGregorian = newDate;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fuel Type
                  FuelDropdown(
                    selectedFuel: fuel,
                    onFuelSelected: (e) {
                      setState(() {
                        fuel = e.toDatabaseValue();
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Vehicle Category
                  VehicleCategoryDropdown(
                    selectedVehicle: vehicleCategory,
                    onVehicleSelected: (e) {
                      setState(() {
                        vehicleCategory = e.toDatabaseValue();
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Ownership
                  OwnershipDropdown(
                    selectedOwnership: ownerShipValue,
                    onOwnershipSelected: (e) {
                      setState(() {
                        ownerShipValue = e.toDatabaseValue();
                        _updateAmountFieldVisibility(ownerShipValue);
                        if (e != VehicleOwnership.owned) {
                          amount.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Amount field (conditional)
                  if (showAmountField) ...[
                    ZTextFieldEntitled(
                      keyboardInputType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormat: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                        SmartThousandsDecimalFormatter(),
                      ],
                      controller: amount,
                      title: tr.amount,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Error Message
                  if (state is VehicleErrorState)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.message,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
    final bloc = context.read<VehicleBloc>();
    final tr = AppLocalizations.of(context)!;

    final purchaseAmount = showAmountField ? amount.text.cleanAmount : null;

    final data = VehicleModel(
      usrName: loginData?.usrName,
      vclModel: vclModel.text,
      vclYear: vclYear.text,
      vclVinNo: vclVinNo.text,
      vclFuelType: fuel ?? tr.petrol,
      vclEnginPower: vclEnginPower.text,
      vclBodyType: vehicleCategory ?? tr.truck,
      vclRegNo: vclRegNo.text,
      vclExpireDate: DateTime.tryParse(vehicleExpireDateGregorian),
      vclPlateNo: plateNo.text,
      vclOdoMeter: int.tryParse(odometer.text),
      vclOwnership: ownerShipValue ?? tr.owned,
      vclPurchaseAmount: purchaseAmount,
      driverId: driverId,
      vclStatus: 1,
      vclId: (context as dynamic).widget.model?.vclId,
    );

    if ((context as dynamic).widget.model == null) {
      bloc.add(AddVehicleEvent(data));
    } else {
      bloc.add(UpdateVehicleEvent(data));
    }
  }
}

class _Desktop extends StatefulWidget {
  final VehicleModel? model;
  final bool isEnabledUpdate;
  const _Desktop(this.model,this.isEnabledUpdate);

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  final vclModel = TextEditingController();
  final plateNo = TextEditingController();
  final vclYear = TextEditingController();
  final odometer = TextEditingController();
  final vclVinNo = TextEditingController();
  final vclEnginPower = TextEditingController();
  final vclRegNo = TextEditingController();
  final driverCtrl = TextEditingController();
  final amount = TextEditingController();

  int? driverId;
  String? ownerShipValue;
  String? vehicleCategory;
  String? fuel;
  String vehicleExpireDateGregorian = DateTime.now().toFormattedDate();
  Jalali vehicleExpireDateShamsi = DateTime.now().toAfghanShamsi;

  final formKey = GlobalKey<FormState>();

  // Track if amount field should be visible
  bool showAmountField = true;

  @override
  void dispose() {
    plateNo.dispose();
    vclYear.dispose();
    vclRegNo.dispose();
    vclEnginPower.dispose();
    vclModel.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if(widget.model != null){
      final m = widget.model!;
      plateNo.text = m.vclPlateNo??"";
      driverCtrl.text = m.driver ??"";
      vclVinNo.text = m.vclVinNo ??"";
      vclYear.text = m.vclYear ??"";
      vclModel.text = m.vclModel??"";
      odometer.text = m.vclOdoMeter?.toString() ?? "";
      driverId = m.driverId;
      // Handle amount field
      if (m.vclPurchaseAmount != null) {
        amount.text = m.vclPurchaseAmount?.toAmount() ?? "";
      }

      vclEnginPower.text = m.vclEnginPower??"";
      vclRegNo.text = m.vclRegNo??"";
      fuel = m.vclFuelType ??"";
      vehicleCategory = m.vclBodyType ??"";
      ownerShipValue = m.vclOwnership;

      // Set initial showAmountField based on ownership
      _updateAmountFieldVisibility(m.vclOwnership);
    }
    super.initState();
  }

  LoginData? loginData;

  // Method to update amount field visibility
  void _updateAmountFieldVisibility(String? ownership) {
    setState(() {
      showAmountField = ownership == "Owned";
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEdit = widget.model != null;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    loginData = state.loginData;

    return ZFormDialog(
      onAction: onSubmit,
      isActionTrue: widget.isEnabledUpdate,
      icon: Icons.fire_truck_rounded,
      title: isEdit ? tr.update : tr.newKeyword,
      actionLabel: (context.watch<VehicleBloc>().state is VehicleLoadingState)
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.surface,
        ),
      )
          : Text(isEdit ? tr.update : tr.create),

      child: BlocConsumer<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state is VehicleSuccessState) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  spacing: 12,
                  children: [
                    ZTextFieldEntitled(
                      isRequired: true,
                      title: tr.vehicleModel,
                      controller: vclModel,
                      validator: (value) {
                        if (value.isEmpty) {
                          return tr.required(tr.vehicleModel);
                        }
                        return null;
                      },
                    ),

                    // Driver Selection
                    SizedBox(
                      width: double.infinity,
                      child:
                      GenericTextfield<DriverModel, DriverBloc, DriverState>(
                        controller: driverCtrl,
                        validator: (e){
                          return null;
                        },
                        title: tr.driver,
                        hintText: tr.driver,
                        bloc: context.read<DriverBloc>(),
                        fetchAllFunction: (bloc) => bloc.add(LoadDriverEvent()),
                        searchFunction: (bloc, query) => bloc.add(LoadDriverEvent()),
                        itemBuilder: (context, driver) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            spacing: 8,
                            children: [
                              ImageHelper.stakeholderProfile(
                                imageName: driver.perPhoto,
                                size: 35,
                              ),
                              Expanded(
                                child: Text(
                                  "${driver.perfullName}",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        itemToString: (account) => "${account.perfullName}",
                        stateToLoading: (state) => state is DriverLoadingState,
                        loadingBuilder: (context) => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        ),
                        stateToItems: (state) {
                          if (state is DriverLoadedState) {
                            return state.drivers;
                          }
                          return [];
                        },
                        onSelected: (account) {
                          setState(() {
                            driverId = account.empId;
                          });
                        },
                        noResultsText: 'No driver found',
                        showClearButton: true,
                      ),
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            isRequired: true,
                            title: tr.vehiclePlate,
                            controller: plateNo,
                            validator: (value) {
                              if (value.isEmpty) {
                                return tr.required(tr.vehiclePlate);
                              }
                              return null;
                            },
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            title: tr.meter,
                            controller: odometer,
                            inputFormat: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            title: tr.manufacturedYear,
                            controller: vclYear,
                            inputFormat: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),

                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          flex: 2,
                          child: ZTextFieldEntitled(
                            title: tr.vinNumber,
                            controller: vclVinNo,
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            title: tr.enginePower,
                            controller: vclEnginPower,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            isRequired: true,
                            title: tr.vclRegisteredNo,
                            controller: vclRegNo,
                            validator: (value) {
                              if (value.isEmpty) {
                                return tr.required(tr.vclRegisteredNo);
                              }
                              return null;
                            },
                          ),
                        ),
                        Expanded(child: datePicker()),
                      ],
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: FuelDropdown(
                            selectedFuel: widget.model?.vclFuelType,
                            onFuelSelected: (e) {
                              setState(() {
                                fuel = e.toDatabaseValue(); // Changed from e.name
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: VehicleCategoryDropdown(
                            selectedVehicle: widget.model?.vclBodyType,
                            onVehicleSelected: (e) {
                              setState(() {
                                vehicleCategory = e.toDatabaseValue(); // Changed from e.name
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: OwnershipDropdown(
                            // Pass the string value from model
                            selectedOwnership: widget.model?.vclOwnership,
                            onOwnershipSelected: (e) {
                              setState(() {
                                ownerShipValue = e.toDatabaseValue();
                                _updateAmountFieldVisibility(ownerShipValue);
                                // Clear amount if not owned
                                if (e != VehicleOwnership.owned) {
                                  amount.clear();
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Conditionally show amount field
                    if (showAmountField)
                      ZTextFieldEntitled(
                        keyboardInputType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormat: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
                          SmartThousandsDecimalFormatter(),
                        ],
                        controller: amount,
                        title: tr.amount,
                      ),

                    Row(
                      children: [
                        state is VehicleErrorState? Text(state.message,style: TextStyle(color: theme.colorScheme.error),) : SizedBox.shrink(),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget datePicker() {
    String vehicleExpireDateGregorian = DateTime.now().toFormattedDate();
    return GenericDatePicker(
      label: AppLocalizations.of(context)!.vclExpireDate,
      initialGregorianDate: vehicleExpireDateGregorian,
      onDateChanged: (newDate) {
        setState(() {
          vehicleExpireDateGregorian = newDate;
        });
      },
    );
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;
    final bloc = context.read<VehicleBloc>();

    // Only include purchase amount if vehicle is owned
    final purchaseAmount = showAmountField ? amount.text.cleanAmount : null;

    final data = VehicleModel(
      usrName: loginData?.usrName,
      vclModel: vclModel.text,
      vclYear: vclYear.text,
      vclVinNo: vclVinNo.text,
      vclFuelType: fuel ?? AppLocalizations.of(context)!.petrol,
      vclEnginPower: vclEnginPower.text,
      vclBodyType: vehicleCategory ?? AppLocalizations.of(context)!.truck,
      vclRegNo: vclRegNo.text,
      vclExpireDate: DateTime.tryParse(vehicleExpireDateGregorian),
      vclPlateNo: plateNo.text,
      vclOdoMeter: int.tryParse(odometer.text),
      vclOwnership: ownerShipValue ?? AppLocalizations.of(context)!.owned,
      vclPurchaseAmount: purchaseAmount,
      driverId: driverId,
      vclStatus: 1,
      vclId: widget.model?.vclId,
    );

    if (widget.model == null) {
      bloc.add(AddVehicleEvent(data));
    } else {
      bloc.add(UpdateVehicleEvent(data));
    }
  }
}

