import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/textfield_entitled.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/Currencies/model/ccy_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/bloc/exchange_rate_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/model/rate_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/features/currency_drop.dart';
import '../../../../../../../../../Features/Other/thousand_separator.dart';

class AddRateView extends StatelessWidget {
  final ExchangeRateModel? rate;
  const AddRateView({super.key,this.rate});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Desktop(rate),
        tablet:_Desktop(rate),
        desktop: _Desktop(rate));
  }
}


class _Desktop extends StatefulWidget {
  final ExchangeRateModel? rate;
  const _Desktop(this.rate);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final TextEditingController rate = TextEditingController();
  String? crFrom;
  String? crTo;

  @override
  void initState() {
    crFrom = widget.rate?.crFrom ??"USD";
    crTo = widget.rate?.crTo ?? "AFN";
    rate.text = widget.rate?.crExchange.toExchangeRate() ??"";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isLoading = context.watch<ExchangeRateBloc>().state is ExchangeRateLoadingState;
    return ZFormDialog(
        width: 400,
        icon: Icons.currency_yen_rounded,
        padding: EdgeInsets.all(8),
        onAction: onSubmit,
        title: locale.newExchangeRateTitle,
        actionLabel: isLoading? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Theme.of(context).colorScheme.surface,
            )) : Text(locale.create),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
           Row(
             spacing: 8,
             children: [
               Expanded(
                 child: CurrencyDropdown(
                     title: locale.from,
                     initiallySelectedSingle: CurrenciesModel(ccyCode: crFrom),
                     isMulti: false,
                     onSingleChanged: (e){
                       setState(() {
                         crFrom = e?.ccyCode??"USD";
                       });
                     },
                     onMultiChanged: (e){}),
               ),

               Expanded(
                 child: CurrencyDropdown(
                     initiallySelectedSingle: CurrenciesModel(ccyCode: crTo),
                     title: locale.toCurrency,
                     isMulti: false,
                     onSingleChanged: (e){
                       setState(() {
                         crTo = e?.ccyCode??"AFN";
                       });
                     },
                     onMultiChanged: (e){}),
               ),
             ],
           ),
            ZTextFieldEntitled(
                isRequired: true,
                onSubmit: (_)=> onSubmit(),
                keyboardInputType: TextInputType.numberWithOptions(
                    decimal: true),
                inputFormat: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9.,]*'),
                  ),
                  SmartThousandsDecimalFormatter(decimalDigits: 6),
                ],

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return locale.required(locale.exchangeRate);
                  }

                  // Remove formatting (e.g. commas)
                  final clean = value.replaceAll(
                    RegExp(r'[^\d.]'),
                    '',
                  );
                  final amount = double.tryParse(clean);

                  if (amount == null || amount <= 0.0) {
                    return locale.amountGreaterZero;
                  }

                  return null;
                },
                controller: rate,
                title: locale.exchangeRate)
          ],
        ),
    );
  }

  void onSubmit(){
    context.read<ExchangeRateBloc>().add(AddExchangeRateEvent(newRate: ExchangeRateModel(
        crFrom: crFrom,
        crTo: crTo,
        crExchange: rate.text
    )));
  }
}

