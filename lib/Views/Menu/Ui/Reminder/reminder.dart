import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';

import '../../../../Features/Other/extensions.dart';
import '../../../../Features/Widgets/outline_button.dart';
import '../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import 'add_edit_reminders.dart';
import 'bloc/reminder_bloc.dart';
import 'model/reminder_model.dart';

class ReminderView extends StatelessWidget {
  const ReminderView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Desktop(), desktop: _Desktop(), tablet: _Desktop(),);
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      context.read<ReminderBloc>().add(LoadAlertReminders(alert: 0));
    });
  }

  DateTime _normalize(DateTime? d) {
    if (d == null) return DateTime(1900);
    return DateTime(d.year, d.month, d.day);
  }
  String? usrName;
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;
    usrName = login.usrName ?? "";
    return Scaffold(
      body: ZCover(
        radius: 5,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
        child: Column(
          children: [

            /// HEADER
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_rounded),
                  SizedBox(width: 5),
                  Text(locale.reminders,
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),

                  /// Refresh
                  ZOutlineButton(
                    icon: Icons.refresh,
                    label: Text(locale.refresh),
                    onPressed: () {
                      context.read<ReminderBloc>()
                          .add(LoadAlertReminders(alert: 0));
                    },
                  ),

                  const SizedBox(width: 5),

                  /// New Reminder
                  ZOutlineButton(
                    icon: Icons.add,
                    isActive: true,
                    label: Text(locale.newKeyword),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddEditReminderView(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            /// LIST
            Expanded(
              child: BlocBuilder<ReminderBloc, ReminderState>(
                builder: (context, state) {

                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.reminders.isEmpty) {
                    return const Center(child: Text("No Reminders"));
                  }

                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);

                  /// GROUPING
                  final overdue = state.reminders.where((r) {
                    final d = _normalize(r.rmdAlertDate);
                    return r.rmdStatus == 0 && d.isBefore(today);
                  }).toList();

                  final dueToday = state.reminders.where((r) {
                    final d = _normalize(r.rmdAlertDate);
                    return r.rmdStatus == 0 && d == today;
                  }).toList();

                  final upcoming = state.reminders.where((r) {
                    final d = _normalize(r.rmdAlertDate);
                    return r.rmdStatus == 0 && d.isAfter(today);
                  }).toList();

                  final completed = state.reminders.where((r) {
                    return r.rmdStatus == 1;
                  }).toList();

                  /// SORT
                  overdue.sort((a,b)=>a.rmdAlertDate!.compareTo(b.rmdAlertDate!));
                  upcoming.sort((a,b)=>a.rmdAlertDate!.compareTo(b.rmdAlertDate!));

                  return ListView(
                    children: [

                      if (overdue.isNotEmpty)
                        _buildGroup(context, "Overdue", overdue, Colors.red),

                      if (dueToday.isNotEmpty)
                        _buildGroup(context, "Due Today", dueToday, Colors.orange),

                      if (upcoming.isNotEmpty)
                        _buildGroup(context, "Upcoming", upcoming,
                            Theme.of(context).colorScheme.outline),

                      if (completed.isNotEmpty)
                        _buildGroup(context, "Completed", completed, Colors.green),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onRefresh()async{
    context.read<ReminderBloc>().add(LoadAlertReminders(alert: 0));
  }

  /// GROUP BUILDER
  Widget _buildGroup(
      BuildContext context,
      String title,
      List<ReminderModel> reminders,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            "$title (${reminders.length})",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ...reminders.map((r) => _buildReminderTile(context, r, color)),
      ],
    );
  }

  /// REMINDER TILE
  Widget _buildReminderTile(
      BuildContext context,
      ReminderModel r,
      Color borderColor,
      ) {

    final isCompleted = r.rmdStatus == 1;

    return ZCover(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      borderColor: borderColor.withValues(alpha: .4),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AddEditReminderView(r: r),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// ICON
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.notifications_active,
                color: borderColor,
                size: 26,
              ),

              const SizedBox(width: 10),

              /// MAIN CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.rmdName == "Receivable"? AppLocalizations.of(context)!.receivableDue : AppLocalizations.of(context)!.payableDue,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      r.fullName ?? "",
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    if ((r.rmdDetails ?? "").isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          r.rmdDetails!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),

                    const SizedBox(height: 6),

                    /// INFO ROW
                    Wrap(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_circle_outlined,size: 14),
                            const SizedBox(width: 4),
                            Text(r.rmdAccount.toString(),
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.date_range,size: 14),
                            const SizedBox(width: 4),
                            Text(r.rmdAlertDate?.toDateString ?? "",
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),

                        Row(
                          children: [
                            Icon(Icons.access_time,size: 14),
                            const SizedBox(width: 4),
                            Text(r.rmdAlertDate?.toDueStatus(AppLocalizations.of(context)!) ?? "",
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),

              /// RIGHT SIDE
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  Text(
                    "${r.rmdAmount.toAmount()} ${r.currency}",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Checkbox(
                    value: isCompleted,
                    onChanged: (_) {
                      context.read<ReminderBloc>().add(
                        UpdateReminderEvent(

                          r.copyWith(rmdStatus: isCompleted ? 0 : 1,usrName: usrName),
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}



