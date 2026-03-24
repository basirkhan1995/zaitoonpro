import 'package:flutter/material.dart';
import 'package:zaitoonpro/Views/PasswordSettings/change_password.dart';
import '../../../../../../../../Features/Other/responsive.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';

class PasswordView extends StatelessWidget {
  const PasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        tablet: _Desktop(),
        mobile: _Mobile(),
        desktop: _Desktop());
  }
}

class _Desktop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ZOutlineButton(
                      icon: Icons.lock_clock_rounded,
                      backgroundHover: Theme.of(context).colorScheme.primary,
                      height: 50,
                      width: 250,
                      label: Text(AppLocalizations.of(context)!.changePasswordTitle),
                      onPressed: (){
                        showDialog(context: context, builder: (context){
                          return const PasswordSettingsView();
                        });
                      }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ZOutlineButton(
                        icon: Icons.lock_clock_rounded,
                        backgroundHover: Theme.of(context).colorScheme.primary,
                        height: 50,
                        label: Text(AppLocalizations.of(context)!.changePasswordTitle),
                        onPressed: (){
                          showDialog(context: context, builder: (context){
                            return const PasswordSettingsView();
                          });
                        }),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

