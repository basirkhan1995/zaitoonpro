import 'package:flutter/material.dart';
import 'package:zaitoon_petroleum/Features/Other/responsive.dart';
import 'package:zaitoon_petroleum/Views/Auth/Subscription/bloc/subscription_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../Features/Date/gregorian_date_picker.dart';
import '../../../../Features/Widgets/outline_button.dart';
import '../../../../Features/Widgets/textfield_entitled.dart';

class NoSubscriptionView extends StatelessWidget {
  const NoSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _MobileContent(),
      tablet: const _TabletContent(),
      desktop: const _DesktopContent(),
    );
  }
}

// Mobile Version
class _MobileContent extends StatelessWidget {
  const _MobileContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: _ActivationForm(),
      ),
    );
  }
}

// Tablet Version
class _TabletContent extends StatelessWidget {
  const _TabletContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: SizedBox(
            width: 500,
            child: _ActivationForm(),
          ),
        ),
      ),
    );
  }
}

// Desktop Version
class _DesktopContent extends StatelessWidget {
  const _DesktopContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: SizedBox(
            width: 500,
            child: _ActivationForm(),
          ),
        ),
      ),
    );
  }
}

class _ActivationForm extends StatefulWidget {
  const _ActivationForm();

  @override
  State<_ActivationForm> createState() => _ActivationFormState();
}

class _ActivationFormState extends State<_ActivationForm> {
  final _oldKeyController = TextEditingController();
  final _newKeyController = TextEditingController();
  final _expireDateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Format date to YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // Show date picker
  Future<void> _showDatePicker() async {
    DateTime? initialDate;

    // Parse existing date if any
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

    // Show the date picker dialog
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
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state is SubscriptionSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription activated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear form
          _oldKeyController.clear();
          _newKeyController.clear();
          _expireDateController.clear();
        } else if (state is SubscriptionErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is SubscriptionLoadingState;
        final color = Theme.of(context).colorScheme;

        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.key,
                size: 80,
                color: color.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Activate Subscription',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your subscription key to get started',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ZTextFieldEntitled(
                title: 'Old Key',
                hint: 'Enter old key',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter old key';
                  }
                  return null;
                },
                controller: _oldKeyController,
                icon: Icons.vpn_key,
                isRequired: true,
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
                    return 'Please enter subscription key';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Modified date field with tap to open picker
              GestureDetector(
                onTap: _showDatePicker,
                child: AbsorbPointer(
                  child: ZTextFieldEntitled(
                    title: 'Expiry Date',
                    hint: 'Tap to select date',
                    controller: _expireDateController,
                    icon: Icons.calendar_today,
                    isRequired: true,
                    readOnly: true, // Make it read-only since we use picker
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select expiry date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ZOutlineButton(
                label: Text(isLoading ? 'Activating...' : 'Activate Subscription'),
                onPressed: isLoading ? null : _activateSubscription,
                backgroundColor: color.primary,
                isActive: true,
                icon: isLoading ? null : Icons.check_circle,
                width: double.infinity,
                height: 48,
                disable: isLoading,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _activateSubscription() {
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