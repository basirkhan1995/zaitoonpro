import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final ValueChanged<List<CurrenciesModel>> onMultiChanged;
  final ValueChanged<CurrenciesModel?>? onSingleChanged;
  final List<CurrenciesModel>? initiallySelected;
  final CurrenciesModel? initiallySelectedSingle;

  const CurrencyDropdown({
    super.key,
    required this.isMulti,
    required this.onMultiChanged,
    this.height = 40,
    this.flag = true,
    this.disableAction = false,
    this.onSingleChanged,
    this.title,
    this.initiallySelected,
    this.initiallySelectedSingle,
  });

  @override
  State<CurrencyDropdown> createState() => _CurrencyDropdownState();
}

class _CurrencyDropdownState extends State<CurrencyDropdown> {
  List<CurrenciesModel> _selectedMulti = [];
  CurrenciesModel? _selectedSingle;

  @override
  void initState() {
    super.initState();

    context.read<CurrenciesBloc>().add(LoadCurrenciesEvent(status: 1));

    if (widget.isMulti) {
      _selectedMulti = widget.initiallySelected ?? [];
    } else {
      _selectedSingle = widget.initiallySelectedSingle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrenciesBloc, CurrenciesState>(
      builder: (context, state) {
        final bool isLoading = state is CurrenciesLoadingState;

        Widget buildTitle() {
          if (isLoading) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.title ?? AppLocalizations.of(context)!.currencyTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
                ),

              ],
            );
          } else {
            return Text(
              widget.title ?? AppLocalizations.of(context)!.currencyTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
            );
          }
        }

        if (state is CurrenciesErrorState) {
          return Text('Error: ${state.message}');
        }

        return ZDropdown<CurrenciesModel>(
          disableAction: widget.disableAction,
          title: '', // keep empty, using customTitle
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
            } return SizedBox.shrink();
          },
          items: state is CurrenciesLoadedState ? state.ccy : [],
          multiSelect: widget.isMulti,
          selectedItems: widget.isMulti ? _selectedMulti : [],
          selectedItem: widget.isMulti ? null : _selectedSingle,
          itemLabel: (item) => item.ccyCode ?? "",
          initialValue: AppLocalizations.of(context)!.currencyTitle,
          onMultiSelectChanged: widget.isMulti
              ? (selected) {
            setState(() => _selectedMulti = selected);
            widget.onMultiChanged(selected);
          } : null,

          onItemSelected: widget.isMulti
              ? (_) {}
              : (item) {
            setState(() => _selectedSingle = item);
            widget.onSingleChanged?.call(item);
          },

          isLoading: false,
          customTitle: (widget.title != null && widget.title!.isNotEmpty)
              ? buildTitle()
              : const SizedBox.shrink(), // No space if no title
        );
      },
    );
  }
}
//✔️ Single-select usage example
// CurrencyDropdown(
// isMulti: false,
// onMultiChanged: (_) {},
// onSingleChanged: (value) {
// print("Selected currency: ${value?.ccyCode}");
// },
// )

// CurrencyDropdown(
// isMulti: true,
// onMultiChanged: (values) {
// print("Selected currencies: $values");
// },
// onSingleChanged: null,
// )
