import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoon_petroleum/Views/Auth/bloc/auth_bloc.dart';
import '../../../Features/Other/responsive.dart';
import '../../../Features/Other/utils.dart';
import '../../../Features/Widgets/button.dart';
import '../../../Features/Widgets/textfield_entitled.dart';
import '../../../Localizations/l10n/translations/app_localizations.dart';
import '../../PasswordSettings/bloc/password_bloc.dart';

class ForceChangePasswordView extends StatelessWidget {
  final String credential;
  const ForceChangePasswordView({super.key, required this.credential});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(AppLocalizations.of(context)!.backTitle),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<AuthBloc>().add(OnResetAuthState());
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
      body: ResponsiveLayout(
        mobile: _MobileContent(credential: credential),
        tablet: _TabletContent(credential: credential),
        desktop: _DesktopContent(credential: credential),
      ),
    );
  }
}

// Base Stateful Widget to share logic
class _BasePasswordForm extends StatefulWidget {
  final String credential;
  final Widget Function(
      BuildContext context,
      _BasePasswordFormState state,
      bool isLoading,
      String error,
      ) builder;

  const _BasePasswordForm({
    required this.credential,
    required this.builder,
  });

  @override
  State<_BasePasswordForm> createState() => _BasePasswordFormState();
}

class _BasePasswordFormState extends State<_BasePasswordForm> {
  final formKey = GlobalKey<FormState>();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  bool isVisible2 = true;
  bool isVisible3 = true;
  String error = "";

  @override
  void dispose() {
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void onSubmit() {
    if (formKey.currentState!.validate()) {
      context.read<PasswordBloc>().add(
        ForceChangePasswordEvent(
          credential: widget.credential,
          newPassword: newPassword.text,
        ),
      );
    }
  }

  void togglePasswordVisibility(int field) {
    setState(() {
      if (field == 2) {
        isVisible2 = !isVisible2;
      } else if (field == 3) {
        isVisible3 = !isVisible3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasswordBloc, PasswordState>(
      listener: (context, state) {
        if (state is PasswordLoadingState) {
          setState(() => error = "");
        } else if (state is PasswordErrorState) {
          setState(() => error = state.message);
        } else if (state is PasswordChangedSuccessState) {
          setState(() => error = "");
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is PasswordLoadingState;

        return Form(
          key: formKey,
          child: widget.builder(context, this, isLoading, error),
        );
      },
    );
  }
}

// Desktop Layout
class _DesktopContent extends StatelessWidget {
  final String credential;
  const _DesktopContent({required this.credential});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: _BasePasswordForm(
            credential: credential,
            builder: (context, state, isLoading, error) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.changePasswordTitle,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              locale.forceChangePasswordHint,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Password fields
                  ZTextFieldEntitled(
                    controller: state.newPassword,
                    title: locale.newPasswordTitle,
                    isRequired: true,
                    securePassword: state.isVisible2,
                    trailing: IconButton(
                      onPressed: () => state.togglePasswordVisibility(2),
                      icon: Icon(
                        !state.isVisible2
                            ? Icons.visibility
                            : Icons.visibility_off_rounded,
                        size: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return locale.required(locale.password);
                      }
                      return Utils.validatePassword(
                        value: value!,
                        context: context,
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  ZTextFieldEntitled(
                    controller: state.confirmPassword,
                    title: locale.confirmPassword,
                    isRequired: true,
                    securePassword: state.isVisible3,
                    trailing: IconButton(
                      onPressed: () => state.togglePasswordVisibility(3),
                      icon: Icon(
                        !state.isVisible3
                            ? Icons.visibility
                            : Icons.visibility_off_rounded,
                        size: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return locale.required(locale.confirmPassword);
                      } else if (state.newPassword.text != state.confirmPassword.text) {
                        return locale.passwordNotMatch;
                      }
                      return null;
                    },
                  ),

                  // Error message
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ZButton(
                      label: isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        locale.changePasswordTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: isLoading ? null : state.onSubmit,
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Mobile Layout - FIXED
class _MobileContent extends StatelessWidget {
  final String credential;
  const _MobileContent({required this.credential});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return _BasePasswordForm(
      credential: credential,
      builder: (context, state, isLoading, error) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Header Card
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      locale.changePasswordTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locale.forceChangePasswordHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Password fields
                    ZTextFieldEntitled(
                      controller: state.newPassword,
                      title: locale.newPasswordTitle,
                      isRequired: true,
                      securePassword: state.isVisible2,
                      trailing: IconButton(
                        onPressed: () => state.togglePasswordVisibility(2),
                        icon: Icon(
                          !state.isVisible2
                              ? Icons.visibility
                              : Icons.visibility_off_rounded,
                          size: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return locale.required(locale.password);
                        }
                        return Utils.validatePassword(
                          value: value!,
                          context: context,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    ZTextFieldEntitled(
                      controller: state.confirmPassword,
                      title: locale.confirmPassword,
                      isRequired: true,
                      securePassword: state.isVisible3,
                      trailing: IconButton(
                        onPressed: () => state.togglePasswordVisibility(3),
                        icon: Icon(
                          !state.isVisible3
                              ? Icons.visibility
                              : Icons.visibility_off_rounded,
                          size: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return locale.required(locale.confirmPassword);
                        } else if (state.newPassword.text != state.confirmPassword.text) {
                          return locale.passwordNotMatch;
                        }
                        return null;
                      },
                    ),

                    // Error message
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ZButton(
                        label: isLoading
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.surface),
                          ),
                        )
                            : Text(
                          locale.changePasswordTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: isLoading ? null : state.onSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Tablet Layout - FIXED
class _TabletContent extends StatelessWidget {
  final String credential;
  const _TabletContent({required this.credential});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 600,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: _BasePasswordForm(
            credential: credential,
            builder: (context, state, isLoading, error) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.changePasswordTitle,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              locale.forceChangePasswordHint,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Two-column layout for tablet
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: state.newPassword,
                          title: locale.newPasswordTitle,
                          isRequired: true,
                          securePassword: state.isVisible2,
                          trailing: IconButton(
                            onPressed: () => state.togglePasswordVisibility(2),
                            icon: Icon(
                              !state.isVisible2
                                  ? Icons.visibility
                                  : Icons.visibility_off_rounded,
                              size: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return locale.required(locale.password);
                            }
                            return Utils.validatePassword(
                              value: value!,
                              context: context,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: state.confirmPassword,
                          title: locale.confirmPassword,
                          isRequired: true,
                          securePassword: state.isVisible3,
                          trailing: IconButton(
                            onPressed: () => state.togglePasswordVisibility(3),
                            icon: Icon(
                              !state.isVisible3
                                  ? Icons.visibility
                                  : Icons.visibility_off_rounded,
                              size: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return locale.required(locale.confirmPassword);
                            } else if (state.newPassword.text != state.confirmPassword.text) {
                              return locale.passwordNotMatch;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  // Error message
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ZButton(
                      label: isLoading
                          ?  SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.surface),
                        ),
                      )
                          : Text(
                        locale.changePasswordTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: isLoading ? null : state.onSubmit,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}