import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';
import 'package:zaitoonpro/Views/Auth/Subscription/bloc/subscription_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../Features/Date/gregorian_date_picker.dart';
import '../../../../Features/Other/zForm_dialog.dart';
import '../../../../Features/Widgets/outline_button.dart';
import '../../../../Features/Widgets/textfield_entitled.dart';
import '../../bloc/auth_bloc.dart';
import '../model/sub_model.dart';
import 'no_subscription.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state is SubscriptionLoadedState) {
          final subscriptions = state.subs;

          if (subscriptions.isEmpty) {
            return const NoSubscriptionView();
          }

          final currentSub = subscriptions.first;

          return ResponsiveLayout(
            mobile: _MobileContent(subscription: currentSub),
            tablet: _TabletContent(subscription: currentSub),
            desktop: _DesktopContent(subscription: currentSub),
          );
        } else if (state is SubscriptionLoadingState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is SubscriptionErrorState) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 20),
                  ZOutlineButton(
                    label: const Text('Retry'),
                    onPressed: () {
                      context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
                    },
                    icon: Icons.refresh,
                  ),
                ],
              ),
            ),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// Mobile Version
class _MobileContent extends StatelessWidget {
  final SubscriptionModel subscription;

  const _MobileContent({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _SubscriptionDetails(subscription: subscription),
      ),
    );
  }
}

// Tablet Version
class _TabletContent extends StatelessWidget {
  final SubscriptionModel subscription;

  const _TabletContent({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _SubscriptionDetails(subscription: subscription),
      ),
    );
  }
}

// Desktop Version
class _DesktopContent extends StatelessWidget {
  final SubscriptionModel subscription;

  const _DesktopContent({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _SubscriptionDetails(subscription: subscription),
      ),
    );
  }
}

class _SubscriptionDetails extends StatelessWidget {
  final SubscriptionModel subscription;

  const _SubscriptionDetails({required this.subscription});

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  int _getDaysRemaining() {
    if (subscription.subExpireDate == null) return 0;
    final now = DateTime.now();
    final expireDate = subscription.subExpireDate!;
    return expireDate.difference(now).inDays;
  }

  bool get _isExpired {
    if (subscription.subExpireDate == null) return false;
    return subscription.subExpireDate!.isBefore(DateTime.now());
  }

  Color _getStatusColor(BuildContext context) {
    if (_isExpired) return Theme.of(context).colorScheme.error;
    final daysRemaining = _getDaysRemaining();
    if (daysRemaining <= 7) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  void _showUpdateForm(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => const _UpdateSubscriptionForm()
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpired = _isExpired;
    final daysRemaining = _getDaysRemaining();
    final expireDate = _formatDate(subscription.subExpireDate);
    final entryDate = _formatDate(subscription.subEntryDate);
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = state.loginData;
    final statusColor = _getStatusColor(context);

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: .2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.subscriptionTitle.toUpperCase(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.manageSubMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (login.usrRole == "Super")
                  ZOutlineButton(
                    label: Text(AppLocalizations.of(context)!.update.toUpperCase()),
                    icon: Icons.refresh,
                    height: 40,
                    onPressed: () => _showUpdateForm(context),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Status Badge and Days Remaining
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: statusColor.withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpired
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isExpired
                            ? "Expired"
                            : "Active",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: .3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          daysRemaining <= 0
                              ? "Expires today"
                              : "$daysRemaining days remaining",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 30),

            // Subscription Key Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withValues(alpha: .2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.vpn_key,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Subscription Key",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    subscription.subKey ?? "N/A",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Dates Grid
            Row(
              children: [
                Expanded(
                  child: _buildDateCard(
                    context,
                    icon: Icons.calendar_today,
                    label: "Expiry Date",
                    value: expireDate,
                    isExpired: isExpired,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateCard(
                    context,
                    icon: Icons.date_range,
                    label: "Entry Date",
                    value: entryDate,
                  ),
                ),
              ],
            ),

            // Warning for expired or soon expiring
            if (isExpired || (!isExpired && daysRemaining <= 7))
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isExpired
                        ? colorScheme.error
                        : Colors.orange).withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isExpired
                          ? colorScheme.error
                          : Colors.orange).withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpired ? Icons.warning : Icons.info,
                        color: isExpired ? colorScheme.error : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isExpired
                              ? "Your subscription has expired. Please update it to continue using all features."
                              : "Your subscription will expire in $daysRemaining days. Consider updating it soon.",
                          style: TextStyle(
                            color: isExpired ? colorScheme.error : Colors.orange.shade800,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        bool isExpired = false,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isExpired ? colorScheme.error : colorScheme.primary)
                  .withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isExpired ? colorScheme.error : colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isExpired ? colorScheme.error : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Update Subscription Form (using ZFormDialog)
class _UpdateSubscriptionForm extends StatefulWidget {
  const _UpdateSubscriptionForm();

  @override
  State<_UpdateSubscriptionForm> createState() => _UpdateSubscriptionFormState();
}

class _UpdateSubscriptionFormState extends State<_UpdateSubscriptionForm> {
  final _oldKeyController = TextEditingController();
  final _newKeyController = TextEditingController();
  final _expireDateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showDatePicker() async {
    DateTime? initialDate;

    if (_expireDateController.text.isNotEmpty) {
      try {
        final parts = _expireDateController.text.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          initialDate = DateTime.now();
        }
      } catch (e) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    await showDialog(
      context: context,
      builder: (context) => GregorianDatePicker(
        initialDate: initialDate,
        onDateSelected: (selectedDate) {
          setState(() {
            _expireDateController.text = _formatDate(selectedDate);
          });
        },
        minYear: 2020,
        maxYear: 2030,
        disablePastDates: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state is SubscriptionSuccessState) {
          Navigator.pop(context);
          ToastManager.show(
            context: context,
            title: "Success",
            message: "Subscription updated successfully!",
            type: ToastType.success,
          );
          context.read<SubscriptionBloc>().add(LoadSubscriptionEvent());
        } else if (state is SubscriptionErrorState) {
          ToastManager.show(
            context: context,
            title: "Error",
            message: state.message,
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is SubscriptionLoadingState;
        return ZFormDialog(
          title: 'Update Subscription',
          onAction: _updateSubscription,
          actionLabel: isLoading
              ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              color: colorScheme.surface,
              strokeWidth: 2,
            ),
          )
              : const Text('Update'),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ZTextFieldEntitled(
                  title: 'Old Key',
                  hint: 'Enter your current key',
                  controller: _oldKeyController,
                  icon: Icons.vpn_key,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter old key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ZTextFieldEntitled(
                  title: 'New Subscription Key',
                  hint: 'Enter your new key',
                  controller: _newKeyController,
                  icon: Icons.vpn_key,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: isLoading ? null : _showDatePicker,
                  child: AbsorbPointer(
                    child: ZTextFieldEntitled(
                      title: 'Expiry Date',
                      hint: 'Tap to select date',
                      controller: _expireDateController,
                      icon: Icons.calendar_today,
                      isRequired: true,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select expiry date';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                if (state is SubscriptionErrorState) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: .3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            Icons.error_outline,
                            color: colorScheme.error,
                            size: 20
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateSubscription() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SubscriptionBloc>().add(
        AddOrUpdateSubscriptionEvent(
          _newKeyController.text,
          _oldKeyController.text,
          _expireDateController.text,
        ),
      );
    }
  }

  @override
  void dispose() {
    _oldKeyController.dispose();
    _newKeyController.dispose();
    _expireDateController.dispose();
    super.dispose();
  }
}