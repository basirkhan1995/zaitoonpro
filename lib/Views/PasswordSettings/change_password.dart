import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import '../../../Features/Other/responsive.dart';
import '../../../Features/Other/utils.dart';
import '../../../Features/Widgets/button.dart';
import '../../../Features/Widgets/textfield_entitled.dart';
import '../../../Localizations/l10n/translations/app_localizations.dart';
import '../Auth/bloc/auth_bloc.dart';
import 'bloc/password_bloc.dart';

class PasswordSettingsView extends StatelessWidget {
  const PasswordSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Desktop(),
        tablet: _Desktop(),
        desktop: _Desktop());
  }
}

class _Desktop extends StatefulWidget {

  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {

  final formKey = GlobalKey<FormState>();
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  bool isSecure = true;
  bool isError = false;

  bool isVisible1 = true, isVisible2 = true, isVisible3 = true;
  String error = "";

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PasswordBloc>().state is PasswordLoadingState;
    final locale = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
     final login = state.loginData;
    return BlocConsumer<PasswordBloc, PasswordState>(
      listener: (context, state) {
        if(state is PasswordLoadingState){
          error = "";
        }if(state is PasswordErrorState){
          error = state.message;
        }if(state is PasswordChangedSuccessState){
          error = "";
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return ZFormDialog(
          width: 400,
          isActionTrue: false,
          padding: EdgeInsets.all(15),
          onAction: null,
          icon: Icons.lock_clock_sharp,
          title: locale.changePasswordTitle,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                const SizedBox(height: 5),
                ZTextFieldEntitled(
                  controller: oldPassword,
                  title: AppLocalizations.of(context)!.oldPassword,
                  isRequired: true,
                  securePassword: isVisible1,
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        isVisible1 = !isVisible1;
                      });
                    },
                    icon: Icon(
                      !isVisible1
                          ? Icons.visibility
                          : Icons.visibility_off_rounded,
                      size: 18,
                    ),
                  ),
                  validator: (value) {
                    if(value.isEmpty){
                      return locale.required(locale.password);
                    }if(value.isNotEmpty){
                      Utils.validatePassword(
                        value: value,
                        context: context,
                      );
                    }return null;
                  },
                ),
                ZTextFieldEntitled(
                  controller: newPassword,
                  title: AppLocalizations.of(context)!.newPasswordTitle,
                  isRequired: true,
                  securePassword: isVisible2,
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        isVisible2 = !isVisible2;
                      });
                    },
                    icon: Icon(
                      !isVisible2
                          ? Icons.visibility
                          : Icons.visibility_off_rounded,
                      size: 18,
                    ),
                  ),
                  validator: (value) {
                    if(value.isEmpty){
                      return locale.required(locale.password);
                    }if(value.isNotEmpty){
                      Utils.validatePassword(
                        value: value,
                        context: context,
                      );
                    }return null;
                  },
                ),
                ZTextFieldEntitled(
                  controller: confirmPassword,
                  title: AppLocalizations.of(context)!.confirmPassword,
                  isRequired: true,
                  securePassword: isVisible3,
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        isVisible3 = !isVisible3;
                      });
                    },
                    icon: Icon(
                      !isVisible3
                          ? Icons.visibility
                          : Icons.visibility_off_rounded,
                      size: 18,
                    ),
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return AppLocalizations.of(context)!.required(
                        locale.confirmPassword,
                      );
                    } else if (newPassword.text != confirmPassword.text) {
                      return locale.passwordNotMatch;
                    }
                    return null;
                  },
                ),

                error.isEmpty
                    ? const SizedBox()
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ZButton(
                  height: 40,
                  width: MediaQuery.sizeOf(context).width,
                  label: isLoading? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: Theme.of(context).colorScheme.surface)) : Text(
                    AppLocalizations.of(context)!.changePasswordTitle,
                  ),
                  onPressed: () => onSubmit(login.usrName),
                ),

                const SizedBox(height: 5),
              ],
            ),
          ),

        );
      },
    );
  }
  void onSubmit(dynamic credential){
    if(formKey.currentState!.validate()){
      context.read<PasswordBloc>().add(ChangePasswordEvent(
          oldPassword: oldPassword.text,
          newPassword: newPassword.text,
          usrName: credential));
    }
  }
}


