import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Drivers/bloc/driver_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Transport/Ui/Drivers/model/driver_model.dart';
import '../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';


class DriversDropdown extends StatefulWidget {
  final ValueChanged<DriverModel?>? onSingleChanged;
  final ValueChanged<List<DriverModel>>? onMultiChanged;
  final String? initialValue;
  final bool isMulti;
  final int? initialVehicleId;

  const DriversDropdown({
    super.key,
    this.onSingleChanged,
    this.initialValue,
    this.onMultiChanged,
    this.isMulti = false,
    this.initialVehicleId,
  });

  @override
  State<DriversDropdown> createState() => _DriversDropdownState();
}

class _DriversDropdownState extends State<DriversDropdown> {
  DriverModel? _selectedSingle;
  List<DriverModel> _selectedMulti = [];

  @override
  void initState() {
    super.initState();

    context.read<DriverBloc>().add(const LoadDriverEvent());

    if (!widget.isMulti && widget.initialVehicleId != null) {
      final state = context.read<DriverBloc>().state;
      if (state is DriverLoadedState) {
        _selectedSingle = state.drivers
            .where((v) => v.empId == widget.initialVehicleId)
            .firstOrNull;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverBloc, DriverState>(
      builder: (context, state) {
        if (state is DriverErrorState) {
          return Text(state.message);
        }

        final vehicles =
        state is DriverLoadedState ? state.drivers : <DriverModel>[];

        return ZDropdown<DriverModel>(
          title: AppLocalizations.of(context)!.drivers,
          items: vehicles,
          initialValue: widget.initialValue ?? AppLocalizations.of(context)!.all,
          multiSelect: widget.isMulti,
          isLoading:  state is DriverLoadingState,
          selectedItem: widget.isMulti ? null : _selectedSingle,
          selectedItems: widget.isMulti ? _selectedMulti : [],

          itemLabel: _driverLabel,

          onItemSelected: widget.isMulti
              ? (_) {}
              : (v) {
            _selectedSingle = v;
            widget.onSingleChanged?.call(v);
            setState(() {});
          },

          onMultiSelectChanged: widget.isMulti
              ? (list) {
            _selectedMulti = list;
            widget.onMultiChanged?.call(list);
            setState(() {});
          }
              : null,
        );
      },
    );
  }
  String _driverLabel(DriverModel v) {
    final model = v.perfullName ?? '';

    if (model.isEmpty) {
      return 'Driver ${v.empId}';
    }
    return [
      model,
    ].join(' ');
  }
}
