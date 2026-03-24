import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/zForm_dialog.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/Ui/AllProjects/model/pjr_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/project_tabs.dart';

class ProjectView extends StatelessWidget {
  final ProjectsModel project;
  const ProjectView({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _ProjectViewMobile(project: project),
      tablet: _ProjectViewTablet(project: project),
      desktop: _ProjectViewDesktop(project: project),
    );
  }
}

// Mobile View - Full Screen
class _ProjectViewMobile extends StatelessWidget {
  final ProjectsModel project;
  const _ProjectViewMobile({required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProjectTabsView(project: project),
    );
  }
}

// Tablet View - Full Screen (but with better layout)
class _ProjectViewTablet extends StatelessWidget {
  final ProjectsModel project;
  const _ProjectViewTablet({required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProjectTabsView(project: project),
    );
  }
}

// Desktop View - Dialog (your existing implementation)
class _ProjectViewDesktop extends StatelessWidget {
  final ProjectsModel project;
  const _ProjectViewDesktop({required this.project});

  @override
  Widget build(BuildContext context) {
    return ZFormDialog(
      icon: Icons.folder_open_rounded,
      width: MediaQuery.of(context).size.width * 0.7,
      onAction: null,
      isActionTrue: false,
      title: project.prjName ?? "",
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ProjectTabsView(project: project),
      ),
    );
  }
}