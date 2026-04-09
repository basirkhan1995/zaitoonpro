import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import '../../../../../../../Features/Generic/zaitoon_drop.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../Ui/Currencies/bloc/currencies_bloc.dart';

class CurrencyDropdown extends StatefulWidget {
  final String? title;
  final bool isMulti;
  final double height;
  final bool disableAction;
  final bool flag;
  final ValueChanged<List<CurrenciesModel>>? onMultiChanged;
  final ValueChanged<CurrenciesModel?>? onSingleChanged;
  final List<CurrenciesModel>? initiallySelected;
  final CurrenciesModel? initiallySelectedSingle;

  const CurrencyDropdown({
    super.key,
    this.isMulti = false,
    this.onMultiChanged,
    this.onSingleChanged,
    this.height = 40,
    this.flag = true,
    this.disableAction = false,
    this.title,
    this.initiallySelected,
    this.initiallySelectedSingle,
  }) : assert(
  !isMulti || onMultiChanged != null,
  'onMultiChanged must be provided when isMulti is true'
  ),
        assert(
        isMulti || onSingleChanged != null,
        'onSingleChanged must be provided when isMulti is false'
        );

  @override
  State<CurrencyDropdown> createState() => _CurrencyDropdownState();
}

class _CurrencyDropdownState extends State<CurrencyDropdown> {
  List<CurrenciesModel> _selectedMulti = [];
  CurrenciesModel? _selectedSingle;
  String? defaultCcy;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if(authState is AuthenticatedState){
      defaultCcy = authState.loginData.company?.comLocalCcy ?? "";
    }

    context.read<CurrenciesBloc>().add(LoadCurrenciesEvent(status: 1));

    if (widget.isMulti) {
      _selectedMulti = widget.initiallySelected ?? [];
    } else {
      // Set default from auth, then override if widget provides one
      _selectedSingle = CurrenciesModel(ccyCode: defaultCcy);
      _selectedSingle = widget.initiallySelectedSingle ?? _selectedSingle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrenciesBloc, CurrenciesState>(
      builder: (context, state) {
        final bool isLoading = state is CurrenciesLoadingState;

        if (state is CurrenciesErrorState) {
          return Text('Error: ${state.message}');
        }

        // Safely cast the list to List<CurrenciesModel>
        List<CurrenciesModel> currencies = [];
        if (state is CurrenciesLoadedState) {
          currencies = state.ccy.cast<CurrenciesModel>();
        }

        return ZDropdown<CurrenciesModel>(
          disableAction: widget.disableAction,
          title: widget.title,
          height: widget.height,
          leadingBuilder: (CurrenciesModel ccy) {
            if(widget.flag) {
              return SizedBox(
                width: 30,
                child: Flag.fromString(
                  ccy.ccyCountryCode ?? "",
                  height: 20,
                  width: 30,
                  borderRadius: 2,
                  fit: BoxFit.fill,
                ),
              );
            }
            return const SizedBox.shrink();
          },
          items: currencies,
          multiSelect: widget.isMulti,
          selectedItems: widget.isMulti ? _selectedMulti : [],
          selectedItem: widget.isMulti ? null : _selectedSingle,
          itemLabel: (item) => item.ccyCode ?? "",
          initialValue: defaultCcy ?? AppLocalizations.of(context)!.currencyTitle,
          onMultiSelectChanged: widget.isMulti
              ? (selected) {
            setState(() => _selectedMulti = selected);
            widget.onMultiChanged?.call(selected);
          }
              : null,
          onItemSelected: widget.isMulti
              ? (_) {}
              : (item) {
            setState(() => _selectedSingle = item);
            widget.onSingleChanged?.call(item);
          },
          isLoading: isLoading,
        );
      },
    );
  }
}