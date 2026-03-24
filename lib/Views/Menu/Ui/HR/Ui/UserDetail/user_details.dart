import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/cover.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/details_tab.dart';
import '../Users/model/user_model.dart';

class UserDetailsView extends StatelessWidget {
  final UsersModel usr;
  const UserDetailsView({super.key, required this.usr});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(usr),
      desktop: _Desktop(usr: usr),
      tablet: _Tablet(usr: usr),
    );
  }
}

class _Mobile extends StatelessWidget {
  final UsersModel usr;
  const _Mobile(this.usr);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("User Info"),
      ),
      body: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8)
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ZCover(
                  margin: EdgeInsets.all(5),
                  radius: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                    horizontalTitleGap: 7,
                    title: Text(usr.usrFullName??"",style: theme.titleMedium,),
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usr.usrEmail??""),
                        Text(usr.usrName??""),
                      ],
                    ),
                    leading: CircleAvatar(
                      radius: 30,
                      child: Text(usr.usrFullName!.getFirstLetter, style: theme.titleMedium),
                    ),
                  ),
                ),
                Expanded(child: UserDetailsTabView(user: usr))
              ]
          ),
        ),
      ),
    );
  }
}

class _Tablet extends StatelessWidget {
  final UsersModel usr;
  const _Tablet({required this.usr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        actionsPadding: EdgeInsets.zero,
        content: Container(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          width: MediaQuery.sizeOf(context).width * .9,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8)
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ZCover(
                    radius: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      horizontalTitleGap: 7,
                      title: Text(usr.usrFullName??"",style: theme.titleMedium,),
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usr.usrEmail??""),
                          Text(usr.usrName??""),
                        ],
                      ),
                      leading: CircleAvatar(
                        radius: 30,
                        child: Text(usr.usrFullName!.getFirstLetter, style: theme.titleMedium),
                      ),
                    ),
                  ),
                  Expanded(child: UserDetailsTabView(user: usr))
                ]
            ),
          ),
        ),
      ),
    );
  }
}

class _Desktop extends StatelessWidget {
  final UsersModel usr;
  const _Desktop({required this.usr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        actionsPadding: EdgeInsets.zero,
        content: Container(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          width: MediaQuery.sizeOf(context).width * .5,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8)
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ZCover(
                    radius: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      horizontalTitleGap: 7,
                      title: Text(usr.usrFullName??"",style: theme.titleMedium,),
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usr.usrEmail??""),
                          Text(usr.usrName??""),
                        ],
                      ),
                      leading: CircleAvatar(
                        radius: 30,
                        child: Text(usr.usrFullName!.getFirstLetter, style: theme.titleMedium),
                      ),
                    ),
                  ),
                  Expanded(child: UserDetailsTabView(user: usr))
                ]
            ),
          ),
        ),
      ),
    );
  }
}
