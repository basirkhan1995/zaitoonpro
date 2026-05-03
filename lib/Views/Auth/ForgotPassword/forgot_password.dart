import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import '../../../Features/Other/utils.dart';
import '../../../Features/Widgets/button.dart';
import '../../../Features/Widgets/textfield_entitled.dart';
import '../../../Localizations/l10n/translations/app_localizations.dart';
import 'bloc/forgot_password_bloc.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _Mobile(),
      tablet: const _Tablet(),
      desktop: const _Desktop(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.forgotPasswordTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ForgotPasswordForm(
        isMobile: true,
        animationController: _animationController,
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side with form
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: ForgotPasswordForm(
                isMobile: false,
                animationController: _animationController,
                fadeAnimation: _fadeAnimation,
                slideAnimation: _slideAnimation,
              ),
            ),
          ),
          // Right side with illustration
          Expanded(
            flex: 6,
            child: Container(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
              child: Center(
                child: AnimatedIllustration(
                  animationController: _animationController,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side with form
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(4, 0),
                  ),
                ],
              ),
              child: ForgotPasswordForm(
                isMobile: false,
                animationController: _animationController,
                fadeAnimation: _fadeAnimation,
                slideAnimation: _slideAnimation,
              ),
            ),
          ),
          // Right side with illustration
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: AnimatedIllustration(
                  animationController: _animationController,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Main Form Widget
class ForgotPasswordForm extends StatefulWidget {
  final bool isMobile;
  final AnimationController animationController;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const ForgotPasswordForm({
    super.key,
    required this.isMobile,
    required this.animationController,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final TextEditingController identityController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // OTP Controllers
  final List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());

  final GlobalKey<FormState> formKeyIdentity = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyPassword = GlobalKey<FormState>();

  Timer? _timer;
  int _remainingTime = 600; // 10 minutes
  String _verifiedEmail = '';
  String _verifiedUsername = '';
  bool _isPasswordVisible = false;

  int _currentStep = 0; // 0: identity, 1: otp, 2: new password, 3: done

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    identityController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _getOtpCode() {
    return otpControllers.map((controller) => controller.text).join();
  }

  void _clearOtpFields() {
    for (var controller in otpControllers) {
      controller.clear();
    }
  }

  String _maskEmailSmart(String email) {
    if (email.isEmpty) return '';

    List<String> parts = email.split('@');
    if (parts.length != 2) return email;

    String username = parts[0];
    String domain = parts[1];

    // Smart username masking based on length
    String maskedUsername;
    if (username.length <= 3) {
      maskedUsername = username[0] + '*' * (username.length - 1);
    } else if (username.length <= 6) {
      maskedUsername = username.substring(0, 2) + '*' * (username.length - 2);
    } else if (username.length <= 10) {
      maskedUsername = username.substring(0, 3) + '*' * (username.length - 3);
    } else {
      maskedUsername = username.substring(0, 4) + '*' * (username.length - 4);
    }

    // Smart domain masking
    List<String> domainParts = domain.split('.');
    String domainName = domainParts[0];

    String maskedDomain;
    if (domainName.length <= 4) {
      maskedDomain = domainName[0] + '*' * (domainName.length - 1);
    } else {
      maskedDomain = domainName.substring(0, 2) + '*' * (domainName.length - 2);
    }
    domainParts[0] = maskedDomain;

    return '$maskedUsername@${domainParts.join('.')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context)!;

    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is IdentityVerifiedState) {
          setState(() {
            _currentStep = 1;
            _verifiedEmail = state.email;
            _remainingTime = 600;
          });
          _startCountdown();
          widget.animationController.forward(from: 0);
        } else if (state is OtpVerifiedState) {
          setState(() {
            _currentStep = 2;
            _verifiedUsername = state.usrName;
          });
          _timer?.cancel();
          widget.animationController.forward(from: 0);
        } else if (state is PasswordResetSuccessState) {
          setState(() {
            _currentStep = 3;
          });
          widget.animationController.forward(from: 0);
        } else if (state is OtpExpiredState) {
          ToastManager.show(
            context: context,
            title: 'OTP Expired',
            message: state.message,
            type: ToastType.error,
          );
        } else if (state is OtpInvalidState) {
          ToastManager.show(
            context: context,
            title: 'Invalid OTP',
            message: state.message,
            type: ToastType.error,
          );
        } else if (state is IdentityNotFoundState) {
          ToastManager.show(
            context: context,
            title: 'User Not Found',
            message: state.message,
            type: ToastType.error,
          );
        } else if (state is PasswordResetFailedState) {
          ToastManager.show(
            context: context,
            title: 'Reset Failed',
            message: state.message,
            type: ToastType.error,
          );
        } else if (state is ForgotPasswordErrorState) {
          ToastManager.show(
            context: context,
            title: 'Error',
            message: state.message,
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isMobile) ...[
                  const SizedBox(height: 20),
                  IconButton(
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: FadeTransition(
                        opacity: widget.fadeAnimation,
                        child: SlideTransition(
                          position: widget.slideAnimation,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: _buildStepContent(context, locale, theme, state),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(BuildContext context, AppLocalizations locale, ThemeData theme, ForgotPasswordState state) {
    switch (_currentStep) {
      case 0:
        return _buildIdentityStep(context, locale, theme, state);
      case 1:
        return _buildOtpStep(context, locale, theme, state);
      case 2:
        return _buildNewPasswordStep(context, locale, theme, state);
      case 3:
        return _buildDoneStep(context, locale, theme);
      default:
        return _buildIdentityStep(context, locale, theme, state);
    }
  }

  Widget _buildIdentityStep(BuildContext context, AppLocalizations locale, ThemeData theme, ForgotPasswordState state) {
    final isLoading = state is ForgotPasswordLoadingState;

    return Form(
      key: formKeyIdentity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.fingerprint, size: 40, color: Theme.of(context).colorScheme.surface),
          ),
          const SizedBox(height: 24),
          Text(
            locale.forgotPasswordTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            locale.forgotPasswordMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ZTextFieldEntitled(
            title: locale.emailOrUsername,
            controller: identityController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return locale.required(locale.emailOrUsername);
              }
              return null;
            },
            onSubmit: (e){
              if (formKeyIdentity.currentState!.validate()) {
                context.read<ForgotPasswordBloc>().add(
                  RequestResetEvent(identity: identityController.text.trim()),
                );
              }
            },
          ),
          const SizedBox(height: 15),
          ZButton(
            width: double.infinity,
            height: 40,
            label: isLoading
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.surface),
            )
                : Text(
              locale.next,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: isLoading
                ? null
                : () {
              if (formKeyIdentity.currentState!.validate()) {
                context.read<ForgotPasswordBloc>().add(
                  RequestResetEvent(identity: identityController.text.trim()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(BuildContext context, AppLocalizations locale, ThemeData theme, ForgotPasswordState state) {
    final isLoading = state is ForgotPasswordLoadingState;
    String? errorMessage;

    if (state is OtpInvalidState) {
      errorMessage = state.message;
    } else if (state is OtpExpiredState) {
      errorMessage = state.message;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mark_email_unread_outlined, size: 40, color: Theme.of(context).colorScheme.surface),
        ),
        const SizedBox(height: 24),
        Text(
          locale.passwordResetTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                locale.otpSendMessage,
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 5),
              Text(
                _maskEmailSmart(_verifiedEmail),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // OTP Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return _buildOtpTextField(index, theme);
          }),
        ),

        const SizedBox(height: 8),

        // Timer
        if (_remainingTime > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${locale.remainingTime} ',
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                    TextSpan(
                      text: _formatTime(_remainingTime),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Error message
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                errorMessage,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Verify button
        ZButton(
          width: double.infinity,
          height: 50,
          label: isLoading
              ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.surface),
          )
              : Text(
            locale.continueTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: isLoading
              ? null
              : () {
            final otp = _getOtpCode();
            if (otp.length == 6) {
              context.read<ForgotPasswordBloc>().add(
                VerifyOtpEvent(otp: otp, email: _verifiedEmail),
              );
            } else {
              ToastManager.show(
                context: context,
                title: 'Invalid OTP',
                message: 'Please enter a valid 6-digit OTP',
                type: ToastType.error,
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // Resend option
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locale.notReceiveCode,
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
            TextButton(
              onPressed: _remainingTime == 0
                  ? () {
                context.read<ForgotPasswordBloc>().add(
                  ResendOtpEvent(identity: _verifiedEmail),
                );
                _clearOtpFields();
                setState(() {
                  _remainingTime = 600;
                });
                _startCountdown();
              }
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: _remainingTime == 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary.withValues(alpha: 0.5),
              ),
              child: Text(
                locale.resend,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpTextField(int index, ThemeData theme) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {});
        },
        child: TextField(
          controller: otpControllers[index],
          focusNode: otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1,
              ),
            ),
            filled: true,
            fillColor: otpFocusNodes[index].hasFocus
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: .07),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
            }
          },
        ),
      ),
    );
  }

  Widget _buildNewPasswordStep(BuildContext context, AppLocalizations locale, ThemeData theme, ForgotPasswordState state) {
    final isLoading = state is ForgotPasswordLoadingState;
    String? errorMessage;

    if (state is PasswordResetFailedState) {
      errorMessage = state.message;
    }

    return Form(
      key: formKeyPassword,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_reset, size: 40, color: Theme.of(context).colorScheme.surface),
          ),
          const SizedBox(height: 24),
          Text(
            locale.createPasswordTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              locale.password8Char,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),

          ZTextFieldEntitled(
            title: locale.password,
            controller: passwordController,
            icon: Icons.lock_outline,
            securePassword: !_isPasswordVisible,
            trailing: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return locale.required(locale.password);
              }
              return Utils.validatePassword(value: value, context: context);
            },
          ),

          const SizedBox(height: 16),

          ZTextFieldEntitled(
            title: locale.confirmPassword,
            controller: confirmPasswordController,
            icon: Icons.lock_outline,
            securePassword: !_isPasswordVisible,
            trailing: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return locale.required(locale.confirmPassword);
              }
              if (passwordController.text != confirmPasswordController.text) {
                return locale.passwordNotMatch;
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          if (errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),

          const SizedBox(height: 16),

          ZButton(
            width: double.infinity,
            height: 50,
            label: isLoading
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.surface),
            )
                : Text(
              locale.update,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: isLoading
                ? null
                : () {
              if (formKeyPassword.currentState!.validate()) {
                context.read<ForgotPasswordBloc>().add(
                  ResetPasswordEvent(
                    usrName: _verifiedUsername,
                    usrPass: passwordController.text,
                    otp: int.tryParse(_getOtpCode()),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep(BuildContext context, AppLocalizations locale, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.elasticOut,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.done_all, size: 50, color: Theme.of(context).colorScheme.surface),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          locale.doneTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          locale.passwordResetMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.secondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ZButton(
          width: double.infinity,
          height: 50,
          label: Text(
            locale.loginTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// Animated Illustration Widget
class AnimatedIllustration extends StatelessWidget {
  final AnimationController animationController;

  const AnimatedIllustration({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animationController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Image.asset(
          "assets/images/forgot_password.png",
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_reset,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.resetPassword,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}