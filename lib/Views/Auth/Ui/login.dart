import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Widgets/button.dart';
import 'package:zaitoonpro/Views/Auth/ForgotPassword/forgot_password.dart';
import 'package:zaitoonpro/Views/Auth/Subscription/Ui/no_subscription.dart';
import 'package:zaitoonpro/Views/Auth/Ui/force_change_password.dart';
import 'package:zaitoonpro/Views/Auth/bloc/auth_bloc.dart';
import 'package:zaitoonpro/Views/Menu/home.dart';
import '../../../Features/Widgets/textfield_entitled.dart';
import '../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../Localizations/locale_selector.dart';
import '../../../Themes/Ui/theme_selector.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordSecure = true;
  bool isRememberMe = false;

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            Utils.gotoReplacement(context, HomeView());
          }
          if (state is AuthErrorState) {
            ToastManager.show(
              context: context,
              title: tr.accessDenied,
              message: state.message,
              type: ToastType.error,
            );
          }
          if (state is ForceChangePasswordState) {
            Utils.goto(
              context,
              ForceChangePasswordView(credential: _emailController.text),
            );
          }
          if (state is NoSubscriptionState) {
            Utils.goto(
              context,
              NoSubscriptionView(),
            );
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title section at the top
                        _zaitoonTitle(context: context),

                        // and center its content
                        Expanded(
                          child: Center(
                            child: _loginForm(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    final locale = AppLocalizations.of(context)!;
    final isLoading = context.watch<AuthBloc>().state is AuthLoadingState;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      constraints: const BoxConstraints(
        maxWidth: 500,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                locale.welcomeBoss,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 5),
            ZTextFieldEntitled(
              controller: _emailController,
              title: locale.emailOrUsrname,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return locale.required(locale.emailOrUsrname);
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            ZTextFieldEntitled(
              controller: _passwordController,
              securePassword: isPasswordSecure,
              title: locale.password,
              trailing: IconButton(
                onPressed: () {
                  setState(() {
                    isPasswordSecure = !isPasswordSecure;
                  });
                },
                icon: Icon(
                  isPasswordSecure ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return locale.required(locale.password);
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ZButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<AuthBloc>().add(
                    LoginEvent(
                      usrName: _emailController.text,
                      usrPassword: _passwordController.text,
                      rememberMe: isRememberMe,
                    ),
                  );
                }
              },
              label: isLoading
                  ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )
                  : Text(locale.login),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Utils.goto(context, ForgotPasswordView());
              },
              child: Text(locale.forgotPassword),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zaitoonTitle({required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Theme and Language selectors
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Row(
              children: [
                const Flexible(child: ThemeSelector()),
                const SizedBox(width: 10),
                const Flexible(child: LanguageSelector()),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Logo and title
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(3),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: .09),
                  ),
                ),
                child: Image.asset('assets/images/zaitoonLogo.png'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.zPetroleum.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: "NotoSans",
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.zaitoonSlogan,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _Tablet extends StatefulWidget {
  const _Tablet();

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordSecure = true;
  bool isRememberMe = false;

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            Utils.gotoReplacement(context, HomeView());
          }
          if (state is AuthErrorState) {
            ToastManager.show(context: context,title: tr.accessDenied, message: state.message, type: ToastType.error);
          }
          if (state is ForceChangePasswordState) {
            Utils.goto(
              context,
              ForceChangePasswordView(credential: _emailController.text),
            );
          }
          if (state is NoSubscriptionState) {
            Utils.goto(
              context,
              NoSubscriptionView(),
            );
          }
        },
        child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox.expand(
          child: Column(
            children: [
              /// Header Section (Logo + Language/Theme)
              _zaitoonTitle(context: context),

              /// Spacer pushes body to center
              Expanded(child: Center(child: _body())),
            ],
          ),
        ),
      ),
),
    );
  }

  Widget _zaitoonTitle({required BuildContext context}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - Localization & Theme Selector
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            spacing: 5,
            children: [ThemeSelector(width: 150), LanguageSelector(width: 150)],
          ),
        ),
        SizedBox(height: 10),
        Row(
          spacing: 8,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(3),
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .09),
                ),
              ),
              child: Image.asset('assets/images/zaitoonLogo.png'),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 0,
              children: [
                Text(
                  AppLocalizations.of(context)!.zPetroleum.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: "NotoSans",
                    fontSize: 40,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.zaitoonSlogan,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _body() {
    final locale = AppLocalizations.of(context)!;
    final isLoading = context.watch<AuthBloc>().state is AuthLoadingState;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .5),
            blurRadius: 3,
            spreadRadius: .5,
          ),
        ],
      ),
      width: 400,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                locale.welcomeBoss,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 10),
            ZTextFieldEntitled(
              controller: _emailController,
              title: locale.emailOrUsrname,
              validator: (value) {
                if (value.isEmpty) {
                  return locale.required(locale.emailOrUsrname);
                }
                return null;
              },
            ),
            SizedBox(height: 5),

            ZTextFieldEntitled(
              controller: _passwordController,
              securePassword: isPasswordSecure,
              title: locale.password,
              trailing: IconButton(
                onPressed: () {
                  setState(() {
                    isPasswordSecure = !isPasswordSecure;
                  });
                },
                icon: Icon(
                  isPasswordSecure ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return locale.required(locale.password);
                }
                return null;
              },
            ),

            SizedBox(height: 20),

            ZButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<AuthBloc>().add(
                    LoginEvent(
                      usrName: _emailController.text,
                      usrPassword: _passwordController.text,
                      rememberMe: isRememberMe,
                    ),
                  );
                }
              },
              label: isLoading
                  ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )
                  : Text(locale.login),
            ),
            SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Utils.goto(context, ForgotPasswordView());
              },
              child: Text(locale.forgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordSecure = true;
  bool isRememberMe = false;

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            Utils.gotoReplacement(context, HomeView());
          }
          if (state is AuthErrorState) {
            ToastManager.show(context: context,title: tr.accessDenied, message: state.message, type: ToastType.error);
          }
          if (state is ForceChangePasswordState) {
            Utils.goto(
              context,
              ForceChangePasswordView(credential: _emailController.text),
            );
          }  if (state is NoSubscriptionState) {
            Utils.goto(
              context,
              NoSubscriptionView(),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Column(
              children: [
                /// Header Section (Logo + Language/Theme)
                _zaitoonTitle(context: context),

                /// Spacer pushes body to center
                Expanded(child: Center(child: _body())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _zaitoonTitle({required BuildContext context}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(3),
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .09),
                ),
              ),
              child: Image.asset('assets/images/zaitoonLogo.png'),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 0,
              children: [
                Text(
                  AppLocalizations.of(context)!.zPetroleum.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: "NotoSans",
                    fontSize: 40,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.zaitoonSlogan,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
        // Header - Localization & Theme Selector
        Row(
          spacing: 5,
          children: [ThemeSelector(width: 150), LanguageSelector(width: 150)],
        ),
      ],
    );
  }

  Widget _body() {
    final locale = AppLocalizations.of(context)!;
    final isLoading = context.watch<AuthBloc>().state is AuthLoadingState;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .5),
                blurRadius: 3,
                spreadRadius: .5,
              ),
            ],
          ),
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    locale.welcomeBoss,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SizedBox(height: 10),
                ZTextFieldEntitled(
                  controller: _emailController,
                  onSubmit: (_) => onSubmit(),
                  title: locale.emailOrUsrname,
                  validator: (value) {
                    if (value.isEmpty) {
                      return locale.required(locale.emailOrUsrname);
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                ZTextFieldEntitled(
                  controller: _passwordController,
                  securePassword: isPasswordSecure,
                  onSubmit: (_) => onSubmit(),
                  title: locale.password,
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordSecure = !isPasswordSecure;
                      });
                    },
                    icon: Icon(
                      isPasswordSecure
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return locale.required(locale.password);
                    }
                    return null;
                  },
                ),

                SizedBox(height: 15),

                ZButton(
                  onPressed: onSubmit,
                  label: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        )
                      : Text(locale.login),
                ),
                SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Utils.goto(context, ForgotPasswordView());
                  },
                  child: Text(locale.forgotPassword),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void onSubmit() {
    if (formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginEvent(
          usrName: _emailController.text.trim(),
          usrPassword: _passwordController.text,
          rememberMe: isRememberMe,
        ),
      );
    }
  }
}
