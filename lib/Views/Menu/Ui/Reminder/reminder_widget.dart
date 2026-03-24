import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Menu/bloc/menu_bloc.dart';
import '../../../../Features/Widgets/outline_button.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../Finance/bloc/financial_tab_bloc.dart';
import 'add_edit_reminders.dart';
import 'bloc/reminder_bloc.dart';
import 'model/reminder_model.dart';


class DashboardAlertReminder extends StatefulWidget {
  const DashboardAlertReminder({super.key});

  @override
  State<DashboardAlertReminder> createState() =>
      _DashboardAlertReminderState();
}

class _DashboardAlertReminderState extends State<DashboardAlertReminder> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderBloc>().add(const LoadAlertReminders(alert: 1));
    });
  }
  String? usrName;
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    usrName = login.usrName ?? "";
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        return Stack(
          children: [
            ZCover(
              radius: 6,
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  Row(
                    children: [

                      /// Alert Icon
                      Icon(Icons.notifications_active,
                          color: Theme.of(context).colorScheme.error),

                      const SizedBox(width: 8),

                      Text(
                        AppLocalizations.of(context)!.reminders,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const Spacer(),


                      /// HEADER
                      Row(
                        children: [
                          /// New Reminder
                          ZOutlineButton(
                            icon: Icons.settings,
                            label: Text(tr.settings),
                            onPressed: () {
                              context.read<MenuBloc>().add(MenuOnChangedEvent(MenuName.finance));
                              context.read<FinanceTabBloc>().add(FinanceOnChangedEvent(FinanceTabName.reminder));
                            },
                          ),
                          const SizedBox(width: 5),

                          /// New Reminder
                          ZOutlineButton(
                            isActive: true,
                            icon: Icons.add,
                            label: Text(tr.newKeyword),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const AddEditReminderView(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// EMPTY
                  if (state.reminders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        AppLocalizations.of(context)!.noAlertReminders,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),

                  /// LIST
                  ...state.reminders.map((e) {
                    return _ReminderTile(model: e,usrName: usrName??"");
                  }),
                ],
              ),
            ),

            /// Loading overlay
            if (state.loading)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}
class _ReminderTile extends StatelessWidget {
  final ReminderModel model;
  final String usrName;

  const _ReminderTile({required this.model,required this.usrName});

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {

    final isPaid = model.rmdStatus == 1;

    return ZCover(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surface,
      radius: 5,
      child: Row(
        children: [

          /// LEFT SIDE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.rmdName == "receivable"? AppLocalizations.of(context)!.receivableDue : AppLocalizations.of(context)!.payableDue,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                /// Customer
                Text(
                  model.fullName ?? "",
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: Theme.of(context).hintColor),

                    const SizedBox(width: 2),

                    Text(
                      "${model.rmdAccount}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                /// Details
                Text(
                  model.rmdDetails ?? "",
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 6),

                /// Account + Date Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14,
                              color: Theme.of(context).hintColor),

                          const SizedBox(width: 2),

                          Text(
                            _formatDate(model.rmdAlertDate),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14,
                              color: Theme.of(context).hintColor),

                          const SizedBox(width: 2),
                          Text(
                            model.rmdAlertDate?.toDueStatus(AppLocalizations.of(context)!) ?? "",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// RIGHT SIDE
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              /// Amount
              Text(
                "${(model.rmdAmount ?? "0").toAmount()} ${model.currency}",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              /// STATUS CHECK BUTTON
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  final updated = model.copyWith(
                    rmdStatus: isPaid ? 0 : 1,
                    usrName: usrName
                  );
                  context.read<ReminderBloc>().add(UpdateReminderEvent(updated));
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPaid
                        ? Colors.green.withValues(alpha: .15)
                        : Colors.grey.withValues(alpha: .15),
                  ),
                  child: Icon(
                    isPaid
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isPaid
                        ? Colors.green
                        : Theme.of(context).colorScheme.outline,
                    size: 20,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
