import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Widgets/no_data_widget.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Log/bloc/user_log_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../../../../../../../Features/Date/zdate_picker.dart';


class UserLogView extends StatelessWidget {
  final String? usrName;
  const UserLogView({super.key, this.usrName});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Desktop(usrName),
      desktop: _Desktop(usrName),
      tablet: _Desktop(usrName),
    );
  }
}

class _Desktop extends StatefulWidget {
  final String? usrName;
  const _Desktop(this.usrName);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {

  String fromDate = DateTime.now().toFormattedDate();
  String toDate = DateTime.now().toFormattedDate();
  Jalali shamsiFromDate = DateTime.now().toAfghanShamsi;
  Jalali shamsiToDate = DateTime.now().toAfghanShamsi;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserLogBloc>().add(
        LoadUserLogEvent(
            usrName: widget.usrName,
            fromDate: fromDate,
            toDate: toDate,
        ),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: color.surface,
      body: BlocBuilder<UserLogBloc, UserLogState>(
        builder: (context, state) {
          if (state is UserLogLoadingState) {
            return Center(child: CircularProgressIndicator());
          }
          if (state is UserLogErrorState) {
            return NoDataWidget(
              message: state.error,
              onRefresh: () {
                context.read<UserLogBloc>().add(
                  LoadUserLogEvent(usrName: widget.usrName),
                );
              },
            );
          }
          if (state is UserLogLoadedState) {
            if(state.log.isEmpty){
              return NoDataWidget(
                message: tr.noDataFound,
              );
            }
            return ListView.builder(
              itemCount: state.log.length,
              itemBuilder: (context, index) {
                final log = state.log[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? color.primary.withValues(alpha: .05)
                        : Colors.transparent,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 0),
                    visualDensity: VisualDensity(horizontal: -4,vertical: -4),
                    title: Text(log.ualType??"",style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 13
                    )),
                    subtitle: Text(log.ualDetails??"",style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color.outline,
                      fontSize: 11
                    ),),
                  )
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
  Widget datePicker() {
    String date = DateTime.now().toFormattedDate();
    return GenericDatePicker(
      label: AppLocalizations.of(context)!.date,
      initialGregorianDate: date,
      onDateChanged: (newDate) {
        setState(() {
          date = newDate;
        });
      },
    );
  }
}
